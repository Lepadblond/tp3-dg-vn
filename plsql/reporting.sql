-- ===========================================================
-- PROCÉDURE : rapport_projets_par_chercheur
-- OBJECTIF   : Afficher la liste des projets d'un chercheur et le budget total
-- PARAMETRES :
--   p_id_chercheur NUMBER : Identifiant du chercheur
-- EXCEPTIONS :
--   - Chercheur inexistant
-- ===========================================================
CREATE OR REPLACE PROCEDURE rapport_projets_par_chercheur(p_id_chercheur IN NUMBER)
IS
    v_budget_total NUMBER := 0;
BEGIN
    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM CHERCHEUR WHERE id_chercheur = p_id_chercheur;
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20009, 'Chercheur inexistant : ' || p_id_chercheur);
        END IF;
    END;
    DBMS_OUTPUT.PUT_LINE('--- Projets du chercheur ID ' || p_id_chercheur || ' ---');
    FOR r_projet IN (
        SELECT id_projet, titre, domaine, budget
        FROM PROJET
        WHERE id_chercheur_resp = p_id_chercheur
        ORDER BY id_projet
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('ID Projet : ' || r_projet.id_projet
                             || ', Titre : ' || r_projet.titre
                             || ', Domaine : ' || r_projet.domaine
                             || ', Budget : ' || r_projet.budget);
        v_budget_total := v_budget_total + r_projet.budget;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Budget total : ' || v_budget_total);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erreur rapport projets : ' || SQLERRM);
END;
/
