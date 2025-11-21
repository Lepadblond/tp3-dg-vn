-- ===========================================================
-- FONCTION : calculer_duree_projet
-- OBJECTIF  : Calculer la durée d'un projet en jours
-- PARAMETRES :
--   p_id_projet NUMBER : Identifiant du projet
-- RETOURNE :
--   NUMBER : Durée totale du projet en jours (date_fin - date_debut)
-- EXCEPTIONS :
--   - Projet inexistant
-- ===========================================================
CREATE OR REPLACE FUNCTION calculer_duree_projet(p_id_projet IN NUMBER)
RETURN NUMBER
IS
    v_date_debut DATE;
    v_date_fin   DATE;
    v_duree      NUMBER;
BEGIN
    SELECT date_debut, date_fin
    INTO v_date_debut, v_date_fin
    FROM PROJET
    WHERE id_projet = p_id_projet;
    IF v_date_fin IS NULL THEN
        v_duree := SYSDATE - v_date_debut; 
    ELSE
        v_duree := v_date_fin - v_date_debut;
    END IF;
    RETURN v_duree;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20005, 'Projet inexistant : ' || p_id_projet);
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20006, 'Erreur calcul durée projet : ' || SQLERRM);
END;
/
