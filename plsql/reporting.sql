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
-- ===========================================================
-- FONCTION : statistiques_equipements
-- OBJECTIF  : Retourne le nombre d’équipements par état (disponible, occupé).
-- PARAMETRES :
-- RETOURNE : Retourne un tableau de RECORD.
--   NUMBER : Moyenne des mesures (NULL si aucune mesure)
-- EXCEPTIONS :
-- ===========================================================
CREATE OR REPLACE PACKAGE pkg_statistiques AS

    TYPE r_statistiques_equipements IS RECORD(
        etat_equipement VARCHAR2(30),
        nb_equipement NUMBER
    );
    


    TYPE t_statistiques_equipements IS TABLE OF r_statistiques_equipements;

    FUNCTION statistiques_equipements
        RETURN t_statistiques_equipements;

END pkg_statistiques;
/
CREATE OR REPLACE PACKAGE BODY pkg_statistiques AS
    FUNCTION statistiques_equipements
    RETURN t_statistiques_equipements
    IS
        v_tab t_statistiques_equipements := t_statistiques_equipements();
        v_nb_occupe NUMBER;
        v_nb_disponibile NUMBER;
        v_nb_maintenance NUMBER;
        v_nb_hors_service NUMBER;

        c_etat_occupe   CONSTANT VARCHAR2(30) := 'Occupe';
        c_etat_disponible   CONSTANT VARCHAR2(30) := 'Disponible';
        c_etat_maintenance  CONSTANT VARCHAR2(30) := 'En maintenance';
        c_etat_hors_service CONSTANT VARCHAR2(30) := 'Hors service';
    BEGIN
        --v_occupe
        SELECT COUNT(*)
        INTO v_nb_occupe
        FROM AFFECTATION_EQUIP ae
        JOIN EQUIPEMENT eq 
        ON ae.id_equipement = eq.id_equipement
        WHERE eq.etat = c_etat_disponible;

        v_tab.EXTEND();
        v_tab(v_tab.LAST).etat_equipement := c_etat_occupe;
        v_tab(v_tab.LAST).nb_equipement := v_nb_occupe;
        -- Est-ce que c'est disponible non associee ou equipement qui sont disponible/utilisable?
        --v_nb_disponibile
        SELECT COUNT(*)
        INTO v_nb_disponibile
        FROM EQUIPEMENT
        WHERE etat = c_etat_disponible;

        v_tab.EXTEND();
        v_tab(v_tab.LAST).etat_equipement := c_etat_disponible;
        v_tab(v_tab.LAST).nb_equipement := v_nb_disponibile - v_nb_occupe;

        --v_nb_maintenance 
        SELECT COUNT(*)
        INTO v_nb_maintenance
        FROM EQUIPEMENT
        WHERE etat = c_etat_maintenance;

        v_tab.EXTEND();
        v_tab(v_tab.LAST).etat_equipement := c_etat_maintenance;
        v_tab(v_tab.LAST).nb_equipement := v_nb_maintenance;

        --v_nb_hors_service
        SELECT COUNT(*)
        INTO v_nb_hors_service
        FROM EQUIPEMENT
        WHERE etat = c_etat_hors_service;

        v_tab.EXTEND();
        v_tab(v_tab.LAST).etat_equipement := c_etat_hors_service;
        v_tab(v_tab.LAST).nb_equipement := v_nb_hors_service;
    
        return v_tab;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Erreur dans statistiques_equipements: '|| SQLERRM);
    END statistiques_equipements;
END pkg_statistiques;
--Bloc Anonyme d'execution de test de code
DECLARE
    v_statistiques pkg_statistiques.t_statistiques_equipements;
BEGIN
    v_statistiques := pkg_statistiques.statistiques_equipements();

    FOR i IN 1 .. v_statistiques.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(v_statistiques(i).etat_equipement || ' = ' || v_statistiques(i).nb_equipement);
    END LOOP;
END;
/