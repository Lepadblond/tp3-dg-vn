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
    -- Vérifier si le chercheur existe
    SELECT COUNT(*) INTO v_count
    FROM CHERCHEUR
    WHERE id_chercheur = p_id_chercheur_resp;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Le chercheur responsable n''existe pas.');
    END IF;

    -- Insertion du projet
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
