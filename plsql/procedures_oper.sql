-- ===========================================================
-- PROCÉDURE : ajouter_projet
-- OBJECTIF   : Ajouter un nouveau projet en vérifiant que le chercheur responsable existe.
-- PARAMÈTRES :
--   p_id_projet         NUMBER      : Identifiant du projet
--   p_titre             VARCHAR2    : Titre du projet
--   p_domaine           VARCHAR2    : Domaine du projet
--   p_budget            NUMBER      : Budget du projet (doit être > 0)
--   p_date_debut        DATE        : Date de début
--   p_date_fin          DATE        : Date de fin (optionnelle)
--   p_id_chercheur_resp NUMBER      : Identifiant du chercheur responsable
-- EXCEPTIONS :
--   - Chercheur inexistant
--   - Erreur d’insertion ou violation de contraintes
-- ===========================================================

CREATE OR REPLACE PROCEDURE ajouter_projet(
    p_id_projet         IN NUMBER,
    p_titre             IN VARCHAR2,
    p_domaine           IN VARCHAR2,
    p_budget            IN NUMBER,
    p_date_debut        IN DATE,
    p_date_fin          IN DATE,
    p_id_chercheur_resp IN NUMBER
)
IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM CHERCHEUR
    WHERE id_chercheur = p_id_chercheur_resp;
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Le chercheur responsable n''existe pas.');
    END IF;
    INSERT INTO PROJET(id_projet, titre, domaine, budget, date_debut, date_fin, id_chercheur_resp)
    VALUES (p_id_projet, p_titre, p_domaine, p_budget, p_date_debut, p_date_fin, p_id_chercheur_resp);
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Projet ajouté avec succès : ' || p_titre);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Erreur ajout projet : ' || SQLERRM);
END;
/
-- ===========================================================
-- PROCÉDURE : affecter_equipement
-- OBJECTIF   : Affecte un équipement à un projet après vérification de sa disponibilité.
-- PARAMÈTRES :
--   p_id_affect     NUMBER : Identifiant de l'affectation
--   p_id_projet     NUMBER : Identifiant du projet
--   p_id_equipement NUMBER : Identifiant de l'équipement
--   p_duree_jours   NUMBER : Durée prévue d'utilisation
-- EXCEPTIONS :
--   - Equipement non disponible ou inexistant
--   - Erreur d’insertion
-- ===========================================================
CREATE OR REPLACE PROCEDURE affecter_equipement(
    p_id_affect     IN NUMBER,
    p_id_projet     IN NUMBER,
    p_id_equipement IN NUMBER,
    p_duree_jours   IN NUMBER
)
IS
    v_disponibilite VARCHAR2(20);
BEGIN
    v_disponibilite := verifier_disponibilite_equipement(p_id_equipement);

    IF v_disponibilite <> 'Disponible' THEN
        RAISE_APPLICATION_ERROR(-20002, 'Equipement non disponible ou inexistant : ' || v_disponibilite);
    END IF;
    INSERT INTO AFFECTATION_EQUIP(id_affect, id_projet, id_equipement, date_affectation, duree_jours)
    VALUES (p_id_affect, p_id_projet, p_id_equipement, SYSDATE, p_duree_jours);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Equipement affecté au projet avec succès.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Erreur affectation équipement : ' || SQLERRM);
END;
/
-- ===========================================================
-- PROCÉDURE : planifier_experience
-- OBJECTIF   : Créer une expérience pour un projet donné, affecter un équipement et journaliser l'action.
-- PARAMÈTRES :
--   p_id_exp         NUMBER : Identifiant de l'expérience
--   p_id_projet      NUMBER : Identifiant du projet
--   p_titre_exp      VARCHAR2 : Titre de l'expérience
--   p_id_equipement  NUMBER : Identifiant de l'équipement à affecter
--   p_duree_affect   NUMBER : Durée prévue pour l'affectation
-- EXCEPTIONS :
--   - Projet inexistant
--   - Equipement non disponible
--   - Erreur insertion ou affectation
-- ===========================================================
CREATE OR REPLACE PROCEDURE planifier_experience(
    p_id_exp        IN NUMBER,
    p_id_projet     IN NUMBER,
    p_titre_exp     IN VARCHAR2,
    p_id_equipement IN NUMBER,
    p_duree_affect  IN NUMBER
)
IS
BEGIN
    -- Vérifier que le projet existe
    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM PROJET
        WHERE id_projet = p_id_projet;

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Projet inexistant : ' || p_id_projet);
        END IF;
    END;
    INSERT INTO EXPERIENCE(id_exp, id_projet, titre_exp, statut)
    VALUES (p_id_exp, p_id_projet, p_titre_exp, 'En cours');
    affecter_equipement(
        p_id_affect     => p_id_exp, 
        p_id_projet     => p_id_projet,
        p_id_equipement => p_id_equipement,
        p_duree_jours   => p_duree_affect
    );
    journaliser_action(
        p_table_concernee => 'EXPERIENCE',
        p_operation       => 'INSERT',
        p_utilisateur     => USER,
        p_description     => 'Création expérience ' || p_titre_exp || ' pour projet ' || p_id_projet
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Expérience planifiée avec succès : ' || p_titre_exp);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Erreur planification expérience : ' || SQLERRM);
END;
/
-- ===========================================================
-- PROCÉDURE : supprimer_projet
-- OBJECTIF   : Supprimer un projet et toutes ses dépendances (EXPÉRIENCES et AFFECTATIONS)
-- PARAMÈTRES :
--   p_id_projet NUMBER : Identifiant du projet à supprimer
-- EXCEPTIONS :
--   - Projet inexistant
--   - Erreurs lors de la suppression
-- ===========================================================
CREATE OR REPLACE PROCEDURE supprimer_projet(p_id_projet IN NUMBER)
IS
    CURSOR c_experiences IS
        SELECT id_exp FROM EXPERIENCE WHERE id_projet = p_id_projet;
BEGIN
    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM PROJET WHERE id_projet = p_id_projet;
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20004, 'Projet inexistant : ' || p_id_projet);
        END IF;
    END;
    FOR r_exp IN c_experiences LOOP
        DELETE FROM AFFECTATION_EQUIP
        WHERE id_exp = r_exp.id_exp;
        DELETE FROM ECHANTILLON
        WHERE id_exp = r_exp.id_exp;
        DELETE FROM EXPERIENCE
        WHERE id_exp = r_exp.id_exp;

        journaliser_action(
            p_table_concernee => 'EXPERIENCE',
            p_operation       => 'DELETE',
            p_utilisateur     => USER,
            p_description     => 'Suppression expérience ID ' || r_exp.id_exp || ' du projet ' || p_id_projet
        );
    END LOOP;
    DELETE FROM PROJET WHERE id_projet = p_id_projet;

    journaliser_action(
        p_table_concernee => 'PROJET',
        p_operation       => 'DELETE',
        p_utilisateur     => USER,
        p_description     => 'Suppression projet ID ' || p_id_projet
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Projet et dépendances supprimés avec succès : ' || p_id_projet);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Erreur suppression projet : ' || SQLERRM);
END;
/
-- ===========================================================
-- PROCÉDURE : journaliser_action
-- OBJECTIF   : Insérer une ligne dans LOG_OPERATION pour tracer une action.
-- PARAMÈTRES :
--   p_table_concernee VARCHAR2 : Nom de la table concernée
--   p_operation       VARCHAR2 : Type d'opération (INSERT, UPDATE, DELETE)
--   p_utilisateur     VARCHAR2 : Nom de l'utilisateur effectuant l'action
--   p_description     VARCHAR2 : Description détaillée de l'action
-- EXCEPTIONS :
--   - Erreur d'insertion dans LOG_OPERATION
-- ===========================================================
CREATE OR REPLACE PROCEDURE journaliser_action(
    p_table_concernee IN VARCHAR2,
    p_operation       IN VARCHAR2,
    p_utilisateur     IN VARCHAR2,
    p_description     IN VARCHAR2
)
IS
    v_id_log NUMBER;
BEGIN
    SELECT NVL(MAX(id_log),0) + 1 INTO v_id_log FROM LOG_OPERATION;
    INSERT INTO LOG_OPERATION(
        id_log, table_concernee, operation, utilisateur, date_op, description
    ) VALUES (
        v_id_log, p_table_concernee, p_operation, p_utilisateur, SYSDATE, p_description
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Action journalisée : ' || p_operation || ' sur ' || p_table_concernee);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Erreur journalisation : ' || SQLERRM);
END;
/

