-- ===========================================================
-- TRIGGER : TRG_PROJET_BEFORE_INSERT
-- OBJECTIF : Valider les données d'un projet avant insertion.
--   - Vérifier que date_fin >= date_debut
--   - Vérifier que budget > 0
-- ACTION : Affiche un message via DBMS_OUTPUT et bloque l'insertion.
-- ===========================================================
CREATE OR REPLACE TRIGGER TRG_PROJET_BEFORE_INSERT
BEFORE INSERT ON PROJET
FOR EACH ROW
DECLARE
  e_invalid EXCEPTION;
BEGIN
  IF :NEW.date_fin < :NEW.date_debut THEN
    DBMS_OUTPUT.PUT_LINE('Erreur : La date de fin doit être >= à la date de début.');
    RAISE e_invalid;  
  END IF;
  IF :NEW.budget <= 0 THEN
    DBMS_OUTPUT.PUT_LINE('Erreur : Le budget doit être strictement positif.');
    RAISE e_invalid;  
  END IF;

EXCEPTION
  WHEN e_invalid THEN
    RAISE;
END;
/
-- ===========================================================
-- TRIGGER : TRG_AFFECTATION_BEFORE_INSERT
-- OBJECTIF : Valider qu'un équipement est disponible avant son affectation.
--   - Vérifier que EQUIPEMENT.etat = 'DISPONIBLE'
-- ACTION : Affiche un message via DBMS_OUTPUT et bloque l'insertion.
-- ===========================================================

CREATE OR REPLACE TRIGGER TRG_AFFECTATION_BEFORE_INSERT
BEFORE INSERT ON AFFECTATION_EQUIP
FOR EACH ROW
DECLARE
    v_etat EQUIPEMENT.etat%TYPE;
    e_invalid EXCEPTION;
BEGIN
    SELECT etat INTO v_etat
    FROM EQUIPEMENT
    WHERE id_equipement = :NEW.id_equipement;

    IF UPPER(v_etat) <> 'DISPONIBLE' THEN
        DBMS_OUTPUT.PUT_LINE('Erreur : L''équipement n''est pas disponible.');
        RAISE e_invalid;
    END IF;
EXCEPTION
    WHEN e_invalid THEN
        RAISE;
END;
/
-- ===========================================================
-- TRIGGER : TRG_AFFECTATION_AFTER_INSERT
-- OBJECTIF : Marquer automatiquement l'équipement comme "OCCUPÉ"
--            après son affectation à un projet.
-- ACTION : Mise à jour de EQUIPEMENT.etat = 'OCCUPÉ'.
-- NOTE    : Assure la cohérence automatique entre projet et ressource.
-- ===========================================================

CREATE OR REPLACE TRIGGER TRG_AFFECTATION_AFTER_INSERT
AFTER INSERT ON AFFECTATION_EQUIP
FOR EACH ROW
BEGIN
    UPDATE EQUIPEMENT
    SET etat = 'OCCUPÉ'
    WHERE id_equipement = :NEW.id_equipement;
END;
/
-- ===========================================================
-- TRIGGER : TRG_AFFECTATION_AFTER_DELETE
-- OBJECTIF : Libérer l'équipement associé lorsqu'une affectation est supprimée.
-- ACTION : Mise à jour de EQUIPEMENT.etat = 'DISPONIBLE'.
-- NOTE    : Maintient la disponibilité des équipements.
-- ===========================================================

CREATE OR REPLACE TRIGGER TRG_AFFECTATION_AFTER_DELETE
AFTER DELETE ON AFFECTATION_EQUIP
FOR EACH ROW
BEGIN
    UPDATE EQUIPEMENT
    SET etat = 'DISPONIBLE'
    WHERE id_equipement = :OLD.id_equipement;
END;
/
-- ===========================================================
-- TRIGGER : TRG_EXPERIENCE_AFTER_INSERT
-- OBJECTIF : Journaliser automatiquement toute nouvelle expérience.
-- ACTION : Insère une entrée dans LOG_OPERATION indiquant la table,
--          l'utilisateur et la date.
-- ===========================================================

CREATE OR REPLACE TRIGGER TRG_EXPERIENCE_AFTER_INSERT
AFTER INSERT ON EXPERIENCE
FOR EACH ROW
BEGIN
    INSERT INTO LOG_OPERATION (
        id_log,
        table_concernee,
        operation,
        utilisateur,
        date_op,
        description
    ) VALUES (
        SEQ_LOG.NEXTVAL,
        'EXPERIENCE',
        'INSERT',
        USER,
        SYSDATE,
        'Nouvelle expérience enregistrée'
    );
END;
/
-- ===========================================================
-- TRIGGER : TRG_ECHANTILLON_BEFORE_INSERT
-- OBJECTIF : Vérification temporelle stricte entre la date de
--            prélèvement et la date de réalisation de l'expérience.
-- ACTION : Lève une exception si date_prelevement < date_realisation.
-- NOTE    : Assure la cohérence entre expériences et échantillons.
-- ===========================================================
CREATE OR REPLACE TRIGGER TRG_ECHANTILLON_BEFORE_INSERT
BEFORE INSERT ON ECHANTILLON
FOR EACH ROW
DECLARE
    v_date_exp DATE;
    e_invalid  EXCEPTION;
BEGIN
    SELECT date_realisation
    INTO v_date_exp
    FROM EXPERIENCE
    WHERE id_exp = :NEW.id_exp;

    IF :NEW.date_prelevement < v_date_exp THEN
        DBMS_OUTPUT.PUT_LINE('Erreur : La date de prélèvement doit être >= à la date de réalisation.');
        RAISE e_invalid;
    END IF;

EXCEPTION
    WHEN e_invalid THEN
        RAISE;
END;
/
-- ===========================================================
-- TRIGGER : TRG_LOG_BEFORE_INSERT
-- OBJECTIF : Normaliser la saisie d'opérations de log
--            (capitalisation automatique).
-- ACTION : Convertit automatiquement l'opération en majuscules
--          pour assurer l'uniformité des journaux.
-- ===========================================================

CREATE OR REPLACE TRIGGER TRG_LOG_BEFORE_INSERT
BEFORE INSERT ON LOG_OPERATION
FOR EACH ROW
BEGIN
    :NEW.operation := UPPER(:NEW.operation);
END;
/
-- ===========================================================
-- TRIGGER : TRG_SECURITE_AFTER_UPDATE
-- OBJECTIF : Journaliser toute modification d'un chercheur
--            (ex. nom, spécialité, etc.).
-- ACTION : Insère automatiquement une entrée dans LOG_OPERATION
--          avec l'utilisateur courant et la date.
-- NOTE    : Assure l'audit obligatoire des changements
--           dans les profils des chercheurs.
-- ===========================================================
CREATE OR REPLACE TRIGGER TRG_SECURITE_AFTER_UPDATE
AFTER UPDATE ON CHERCHEUR
FOR EACH ROW
BEGIN
    INSERT INTO LOG_OPERATION (
        id_log,
        table_concernee,
        operation,
        utilisateur,
        date_op,
        description
    ) VALUES (
        SEQ_LOG.NEXTVAL,
        'CHERCHEUR',
        'UPDATE',
        USER,
        SYSDATE,
        'Modification d''un chercheur'
    );
END;
/

