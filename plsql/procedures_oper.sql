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
    -- Vérifier disponibilité de l'équipement
    v_disponibilite := verifier_disponibilite_equipement(p_id_equipement);

    IF v_disponibilite <> 'Disponible' THEN
        RAISE_APPLICATION_ERROR(-20002, 'Equipement non disponible ou inexistant : ' || v_disponibilite);
    END IF;

    -- Insertion de l'affectation
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

