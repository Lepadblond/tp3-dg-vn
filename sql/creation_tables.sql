SET SERVEROUTPUT ON;

-- ===========================================================
-- ÉTAPE 1 : CRÉATION DES RÔLES
-- ===========================================================

CREATE ROLE ROLE_ADMIN_LAB;
CREATE ROLE ROLE_GEST_LAB;
CREATE ROLE ROLE_LECT_LAB;

-- ===========================================================
-- ÉTAPE 2 : CRÉATION DES UTILISATEURS
-- ===========================================================

CREATE USER ADMIN_LAB IDENTIFIED BY adminlab
  DEFAULT TABLESPACE users
  TEMPORARY TABLESPACE temp
  QUOTA UNLIMITED ON users;

CREATE USER GEST_LAB IDENTIFIED BY gestlab
  DEFAULT TABLESPACE users
  TEMPORARY TABLESPACE temp;

CREATE USER LECT_LAB IDENTIFIED BY lectlab
  DEFAULT TABLESPACE users
  TEMPORARY TABLESPACE temp;

-- ===========================================================
-- ÉTAPE 3 : ATTRIBUTION DES RÔLES AUX UTILISATEURS
-- ===========================================================

GRANT ROLE_ADMIN_LAB TO ADMIN_LAB;
GRANT ROLE_GEST_LAB TO GEST_LAB;
GRANT ROLE_LECT_LAB TO LECT_LAB;

-- ===========================================================
-- ÉTAPE 4 : PRIVILÈGES DES RÔLES
-- ===========================================================

-- ADMIN : tout pour gérer le schéma
GRANT CONNECT, RESOURCE TO ROLE_ADMIN_LAB;
GRANT CREATE VIEW, CREATE SEQUENCE, CREATE PROCEDURE, CREATE TRIGGER TO ROLE_ADMIN_LAB;
GRANT CREATE SESSION TO ROLE_ADMIN_LAB;

-- GESTIONNAIRE
GRANT CREATE SESSION TO ROLE_GEST_LAB;
GRANT EXECUTE ANY PROCEDURE TO ROLE_GEST_LAB;
GRANT INSERT ANY TABLE TO ROLE_GEST_LAB;

-- LECTEUR
GRANT CREATE SESSION TO ROLE_LECT_LAB;

-- FIN DU DDL
/
-- ===========================================================
-- CRÉATION DES TABLES
DECLARE
    PROCEDURE drop_table(table_name IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE ' || table_name || ' CASCADE CONSTRAINTS';
        DBMS_OUTPUT.PUT_LINE('Table ' || table_name || ' supprimée.');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE = -942 THEN
            DBMS_OUTPUT.PUT_LINE('Table ' || table_name || ' n''existe pas, rien à supprimer.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Erreur lors de la suppression de la table ' || table_name || ' : ' || SQLERRM);
        END IF;
    END;
BEGIN
    -- ==========================
    -- Suppression 
    -- ==========================

    drop_table('ECHANTILLON');
    drop_table('EXPERIENCE');
    drop_table('AFFECTATION_EQUIP');
    drop_table('EQUIPEMENT');
    drop_table('PROJET');
    drop_table('CHERCHEUR');
    drop_table('LOG_OPERATION');

  END;
    -- ==========================
    -- Création des tables
    -- ==========================

    BEGIN
        EXECUTE IMMEDIATE '
            CREATE TABLE CHERCHEUR (
                id_chercheur     NUMBER PRIMARY KEY,
                nom              VARCHAR2(50) NOT NULL,
                prenom           VARCHAR2(50) NOT NULL,
                specialite       VARCHAR2(20) NOT NULL,
                date_embauche    DATE DEFAULT SYSDATE,
                CONSTRAINT chk_specialite
                    CHECK (specialite IN (''Biotech'', ''IA'', ''Physique'', ''Chimie'', ''Mathématiques'', ''Autre''))
            )';
        DBMS_OUTPUT.PUT_LINE('Table CHERCHEUR créée.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erreur CHERCHEUR : ' || SQLERRM);
    END;

    BEGIN
        EXECUTE IMMEDIATE '
            CREATE TABLE PROJET (
                id_projet         NUMBER PRIMARY KEY,
                titre             VARCHAR2(100) NOT NULL,
                domaine           VARCHAR2(50) NOT NULL,
                budget            NUMBER CHECK (budget > 0),
                date_debut        DATE NOT NULL,
                date_fin          DATE,
                id_chercheur_resp NUMBER NOT NULL,
                CONSTRAINT fk_projet_responsable FOREIGN KEY (id_chercheur_resp)
                    REFERENCES CHERCHEUR(id_chercheur),
                CONSTRAINT chk_dates_projet
                    CHECK (date_fin IS NULL OR date_fin >= date_debut)
            )';
        DBMS_OUTPUT.PUT_LINE('Table PROJET créée.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erreur PROJET : ' || SQLERRM);
    END;

    BEGIN
        EXECUTE IMMEDIATE '
            CREATE TABLE EQUIPEMENT (
                id_equipement     NUMBER PRIMARY KEY,
                nom               VARCHAR2(100) NOT NULL,
                categorie         VARCHAR2(50) NOT NULL,
                date_acquisition  DATE DEFAULT SYSDATE,
                etat              VARCHAR2(20) NOT NULL,
                CONSTRAINT chk_etat
                    CHECK (etat IN (''Disponible'', ''En maintenance'', ''Hors service''))
            )';
        DBMS_OUTPUT.PUT_LINE('Table EQUIPEMENT créée.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erreur EQUIPEMENT : ' || SQLERRM);
    END;

    BEGIN
        EXECUTE IMMEDIATE '
            CREATE TABLE AFFECTATION_EQUIP (
                id_affect        NUMBER PRIMARY KEY,
                id_projet        NUMBER NOT NULL,
                id_equipement    NUMBER NOT NULL,
                date_affectation DATE DEFAULT SYSDATE,
                duree_jours      NUMBER CHECK (duree_jours >= 0),
                CONSTRAINT fk_affect_projet FOREIGN KEY (id_projet)
                    REFERENCES PROJET(id_projet),
                CONSTRAINT fk_affect_equip FOREIGN KEY (id_equipement)
                    REFERENCES EQUIPEMENT(id_equipement)
            )';
        DBMS_OUTPUT.PUT_LINE('Table AFFECTATION_EQUIP créée.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erreur AFFECTATION_EQUIP : ' || SQLERRM);
    END;

    BEGIN
        EXECUTE IMMEDIATE '
            CREATE TABLE EXPERIENCE (
                id_exp           NUMBER PRIMARY KEY,
                id_projet        NUMBER NOT NULL,
                titre_exp        VARCHAR2(100) NOT NULL,
                date_realisation DATE,
                resultat         VARCHAR2(4000),
                statut           VARCHAR2(20) NOT NULL,
                CONSTRAINT fk_experience_projet FOREIGN KEY (id_projet)
                    REFERENCES PROJET(id_projet),
                CONSTRAINT chk_statut_exp CHECK (statut IN (''En cours'', ''Terminée'', ''Annulée''))
            )';
        DBMS_OUTPUT.PUT_LINE('Table EXPERIENCE créée.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erreur EXPERIENCE : ' || SQLERRM);
    END;

    BEGIN
        EXECUTE IMMEDIATE '
            CREATE TABLE ECHANTILLON (
                id_echantillon   NUMBER PRIMARY KEY,
                id_exp           NUMBER NOT NULL,
                type_echantillon VARCHAR2(50) NOT NULL,
                date_prelevement DATE NOT NULL,
                mesure           NUMBER CHECK (mesure >= 0),
                CONSTRAINT fk_echantillon_exp FOREIGN KEY (id_exp)
                    REFERENCES EXPERIENCE(id_exp)
            )';
        DBMS_OUTPUT.PUT_LINE('Table ECHANTILLON créée.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erreur ECHANTILLON : ' || SQLERRM);
    END;

    BEGIN
        EXECUTE IMMEDIATE '
            CREATE TABLE LOG_OPERATION (
                id_log          NUMBER PRIMARY KEY,
                table_concernee VARCHAR2(50) NOT NULL,
                operation       VARCHAR2(10) CHECK (operation IN (''INSERT'', ''UPDATE'', ''DELETE'')),
                utilisateur     VARCHAR2(50),
                date_op         DATE DEFAULT SYSDATE,
                description     VARCHAR2(4000)
            )';
        DBMS_OUTPUT.PUT_LINE('Table LOG_OPERATION créée.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erreur LOG_OPERATION : ' || SQLERRM);
    END;

END;
/
