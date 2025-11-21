-- Test de la procédure ajouter_projet
DECLARE
    v_id_projet         NUMBER := 101;
    v_titre             VARCHAR2(100) := 'Projet Test';
    v_domaine           VARCHAR2(50) := 'bd';
    v_budget            NUMBER := 50000;
    v_date_debut        DATE := SYSDATE;
    v_date_fin          DATE := SYSDATE + 30;
    v_id_chercheur_resp NUMBER := 1; 
BEGIN
    BEGIN
        INSERT INTO CHERCHEUR(id_chercheur, nom, prenom, specialite)
        VALUES (v_id_chercheur_resp, 'girard', 'dave', 'bd');
        COMMIT;
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN NULL; 
    END;
    ajouter_projet(
        p_id_projet         => v_id_projet,
        p_titre             => v_titre,
        p_domaine           => v_domaine,
        p_budget            => v_budget,
        p_date_debut        => v_date_debut,
        p_date_fin          => v_date_fin,
        p_id_chercheur_resp => v_id_chercheur_resp
    );
    DELETE FROM PROJET WHERE id_projet = v_id_projet;
    DELETE FROM CHERCHEUR WHERE id_chercheur = v_id_chercheur_resp;
    COMMIT;
END;
/
-- Test de la procédure affecter_equipement
DECLARE
    v_id_affect     NUMBER := 201;
    v_id_projet     NUMBER := 101;
    v_id_equipement NUMBER := 301;
    v_duree_jours   NUMBER := 15;
BEGIN
    BEGIN
        INSERT INTO CHERCHEUR(id_chercheur, nom, prenom, specialite)
        VALUES (1, 'Doe', 'John', 'IA');
        INSERT INTO PROJET(id_projet, titre, domaine, budget, date_debut, id_chercheur_resp)
        VALUES (v_id_projet, 'Projet Test Equip', 'IA', 10000, SYSDATE, 1);
        INSERT INTO EQUIPEMENT(id_equipement, nom, categorie, etat)
        VALUES (v_id_equipement, 'Equip Test', 'Robotique', 'Disponible');
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
    affecter_equipement(
        p_id_affect     => v_id_affect,
        p_id_projet     => v_id_projet,
        p_id_equipement => v_id_equipement,
        p_duree_jours   => v_duree_jours
    );
    DELETE FROM AFFECTATION_EQUIP WHERE id_affect = v_id_affect;
    DELETE FROM PROJET WHERE id_projet = v_id_projet;
    DELETE FROM CHERCHEUR WHERE id_chercheur = 1;
    DELETE FROM EQUIPEMENT WHERE id_equipement = v_id_equipement;
    COMMIT;
END;
/
-- Test de la procédure creer_experience
DECLARE
    v_id_exp        NUMBER := 401;
    v_id_projet     NUMBER := 101;
    v_id_equipement NUMBER := 301;
BEGIN
    BEGIN
        INSERT INTO CHERCHEUR(id_chercheur, nom, prenom, specialite)
        VALUES (1, 'Doe', 'John', 'IA');
        INSERT INTO PROJET(id_projet, titre, domaine, budget, date_debut, id_chercheur_resp)
        VALUES (v_id_projet, 'Projet Test Exp', 'IA', 10000, SYSDATE, 1);
        INSERT INTO EQUIPEMENT(id_equipement, nom, categorie, etat)
        VALUES (v_id_equipement, 'Equip Test Exp', 'Robotique', 'Disponible');
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
    planifier_experience(
        p_id_exp        => v_id_exp,
        p_id_projet     => v_id_projet,
        p_titre_exp     => 'Expérience Test',
        p_id_equipement => v_id_equipement,
        p_duree_affect  => 10
    );
    DELETE FROM AFFECTATION_EQUIP WHERE id_affect = v_id_exp;
    DELETE FROM EXPERIENCE WHERE id_exp = v_id_exp;
    DELETE FROM PROJET WHERE id_projet = v_id_projet;
    DELETE FROM CHERCHEUR WHERE id_chercheur = 1;
    DELETE FROM EQUIPEMENT WHERE id_equipement = v_id_equipement;
    COMMIT;
END;
/
