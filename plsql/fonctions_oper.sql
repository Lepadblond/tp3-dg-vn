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
-- ===========================================================
-- FONCTION : verifier_disponibilite_equipement
-- OBJECTIF  : Vérifier si un équipement est libre
-- PARAMETRES :
--   p_id_equipement NUMBER : Identifiant de l'équipement
-- RETOURNE :
--   NUMBER : 1 si disponible, 0 sinon
-- EXCEPTIONS :
--   - Equipement inexistant
-- ===========================================================
CREATE OR REPLACE FUNCTION verifier_disponibilite_equipement(p_id_equipement IN NUMBER)
RETURN NUMBER
IS
    TYPE t_equipement IS RECORD (
        id_equipement NUMBER,
        etat         VARCHAR2(20)
    );
    TYPE t_tab_equip IS TABLE OF t_equipement;

    v_tab t_tab_equip;
BEGIN
    SELECT id_equipement, etat
    BULK COLLECT INTO v_tab
    FROM EQUIPEMENT
    WHERE id_equipement = p_id_equipement;
    IF v_tab.COUNT = 0 THEN
        RETURN 0; 
    END IF;
    IF v_tab(1).etat = 'Disponible' THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erreur vérifier disponibilité : ' || SQLERRM);
        RETURN 0;
END;
/
-- ===========================================================
-- FONCTION : moyenne_mesures_experience
-- OBJECTIF  : Calculer la moyenne des mesures pour une expérience donnée
-- PARAMETRES :
--   p_id_exp NUMBER : Identifiant de l'expérience
-- RETOURNE :
--   NUMBER : Moyenne des mesures (NULL si aucune mesure)
-- EXCEPTIONS :
--   - Expérience inexistante
-- ===========================================================
CREATE OR REPLACE FUNCTION moyenne_mesures_experience(p_id_exp IN NUMBER)
RETURN NUMBER
IS
    v_moyenne NUMBER;
BEGIN
    SELECT AVG(mesure)
    INTO v_moyenne
    FROM ECHANTILLON
    WHERE id_exp = p_id_exp;
    RETURN v_moyenne;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20007, 'Aucune mesure pour l''expérience : ' || p_id_exp);
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20008, 'Erreur calcul moyenne mesures : ' || SQLERRM);
END;
/

