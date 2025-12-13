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
-- PARAMETRES : Aucune
-- RETOURNE : Retourne un tableau de RECORD. Contenant le nombre d'equipement disponible de chaque etat
-- EXCEPTIONS : Others? Tables existantes?
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
/
-- Fonction statistiques_equipements
DECLARE
    v_statistiques pkg_statistiques.t_statistiques_equipements;
BEGIN
    v_statistiques := pkg_statistiques.statistiques_equipements();

    FOR i IN 1 .. v_statistiques.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(v_statistiques(i).etat_equipement || ' = ' || v_statistiques(i).nb_equipement);
    END LOOP;
END;
/
-- ===========================================================
-- PROCÉDURE : rapport_activite_projets()
-- OBJECTIF   : Affiche le nombre d’expériences réalisées par projet et leur taux de réussite.
-- EXTERIEUR:
--   Appelle moyenne_mesures_experience.
-- EXCEPTIONS :
--   - Chercheur inexistant
-- ===========================================================
CREATE OR REPLACE PROCEDURE rapport_activite_projets
IS
    TYPE r_rapport_projet IS RECORD(
        id_projet NUMBER,
        nb_experiences NUMBER,
        taux_accomplit NUMBER,
        moyenne_mesures NUMBER
    );
    TYPE t_rapport_projets IS TABLE OF r_rapport_projet;
    TYPE t_projet_id IS TABLE OF NUMBER;
    TYPE t_exp_id IS TABLE OF NUMBER;

    t_rapports t_rapport_projets := t_rapport_projets();
    t_projets t_projet_id := t_projet_id();
    t_exps t_exp_id;


    v_nb_terminee NUMBER;
    v_mesure_moyen_somme NUMBER;
BEGIN
    --SELECTION DISTINCTE DES PORJETS
    SELECT DISTINCT id_projet
    BULK COLLECT INTO t_projets
    FROM PROJET;

    FOR i IN 1.. t_projets.COUNT LOOP
        --Incrementation de la table
        t_rapports.EXTEND();

        --Identifiant projet
        t_rapports(t_rapports.LAST).id_projet := t_projets(i);
        
        --nb d'experiences
        SELECT COUNT(*)
        INTO t_rapports(t_rapports.LAST).nb_experiences
        FROM EXPERIENCE
        WHERE id_projet = t_projets(i);
        
        --taux accomplit
        SELECT COUNT(*)
        INTO v_nb_terminee
        FROM EXPERIENCE
        WHERE id_projet = t_projets(i) AND statut = 'Terminée';
        
        IF t_rapports(t_rapports.LAST).nb_experiences > 0 THEN
            t_rapports(t_rapports.LAST).taux_accomplit := 100 * (v_nb_terminee / t_rapports(t_rapports.LAST).nb_experiences);
        ELSE
            t_rapports(t_rapports.LAST).taux_accomplit := 100 * v_nb_terminee;
        END IF;
        
        --moyenne_mesures
        t_exps := t_exp_id();

        SELECT DISTINCT id_exp
        BULK COLLECT INTO t_exps
        FROM EXPERIENCE
        WHERE id_projet = t_projets(i);
        
        v_mesure_moyen_somme := 0;
        FOR j IN 1.. t_exps.COUNT LOOP
            v_mesure_moyen_somme := v_mesure_moyen_somme + NVL(moyenne_mesures_experience(t_exps(j)),0);
        END LOOP;
        
        IF t_exps.COUNT = 0 THEN
            t_rapports(t_rapports.LAST).moyenne_mesures := v_mesure_moyen_somme;
        ELSE
            t_rapports(t_rapports.LAST).moyenne_mesures := v_mesure_moyen_somme / t_exps.COUNT;
        END IF;
        
    END LOOP;

    --Itération de l'information
    FOR i IN 1.. t_rapports.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('ID PROJET: '|| t_rapports(i).id_projet);
        DBMS_OUTPUT.PUT_LINE('Nombre d''expérience totale :' || t_rapports(i).nb_experiences);
        DBMS_OUTPUT.PUT_LINE('Taux de complétion des expériences :' || t_rapports(i).taux_accomplit || '%');
        DBMS_OUTPUT.PUT_LINE('Moyenne des mesures collectées des expériences: ' || t_rapports(i).moyenne_mesures);
        DBMS_OUTPUT.PUT_LINE('');

    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erreur dans statistiques_equipements: '|| SQLERRM);
END rapport_activite_projets;
-- EXEC rapport_activite_projets;

-- ===========================================================
-- FONCTION : budget_moyen_par_domaine()
-- OBJECTIF   : Calcule le budget moyen par domaine scientifique.
-- RETOURNE: Tableau en mémoire
-- ===========================================================
--Objet existant dans shéma
CREATE OR REPLACE TYPE budget_moyen_obj AS OBJECT (
    nom_domaine  VARCHAR2(50),
    budget_moyen NUMBER
);
/
CREATE OR REPLACE TYPE budget_moyen_tab AS TABLE OF budget_moyen_obj;
/
-- Fonction princiapel
CREATE OR REPLACE FUNCTION budget_moyen_par_domaine
RETURN budget_moyen_tab
IS
    CURSOR c_projet IS
        SELECT domaine AS nom_domaine, AVG(budget) AS budget_moyen FROM PROJET GROUP BY domaine;
    v_projet c_projet%ROWTYPE;
    v_table budget_moyen_tab := budget_moyen_tab();
BEGIN
    OPEN c_projet;
    LOOP
        FETCH c_projet INTO v_projet;
        EXIT WHEN c_projet%NOTFOUND;
        v_table.EXTEND;
        v_table(v_table.LAST) := budget_moyen_obj(v_projet.nom_domaine, v_projet.budget_moyen);
    END LOOP;
    CLOSE c_projet;
    RETURN v_table;
END;
/
-- Fonction budget_moyen_par_domaine()
SELECT * FROM TABLE(budget_moyen_par_domaine());
/
