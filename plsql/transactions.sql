CREATE OR REPLACE PROCEDURE planifier_experience (
    p_id_projet IN EXPERIENCE.id_projet%TYPE,
    p_titre_exp IN EXPERIENCE.titre_exp%TYPE,
    p_date_real IN EXPERIENCE.date_realisation%TYPE DEFAULT NULL,
    p_id_equipement IN EQUIPEMENT.id_equipement%TYPE,
    p_resultat IN EXPERIENCE.resultat%TYPE DEFAULT NULL,
    p_statut IN EXPERIENCE.statut%TYPE
)
IS

BEGIN
    IF p_statut NOT IN ('En cours', 'Terminée', 'Annulée') THEN
        RAISE_APPLICATION_ERROR(-20010, 'Parametre de statut invalide ' || p_statut); 
    END IF;

    INSERT INTO EXPERIENCE (id_projet, titre_exp, date_realisation, resultat, statut)
    VALUES (p_id_projet, p_titre_exp, p_date_real, p_resultat, p_statut);

    -- Savepoint avant affectation
    SAVEPOINT sv_avant_modification_affectation;
    DBMS_OUTPUT.PUT_LINE('Savepoint sv_avant_modification_affectation defini');

    BEGIN
        affecter_equipement(p_id_projet, p_id_equipement, p_date_real, 1);

    EXCEPTION
        WHEN OTHERS THEN
            -- If anything fails during equipment assignment, revert to SAVEPOINT
            ROLLBACK TO sv_avant_modification_affectation;

            journaliser_action(
                'EXPERIENCE', 'ERREUR_PLANIF', 
                'Erreur lors de l''affectation de l''équipement pour exp '|| p_id_exp || ' : ' || SQLERRM,
                
            );
            RAISE;
    END;

    -- If we reach here, everything went fine: log and commit
    journaliser_action(
        p_table      => 'EXPERIENCE',
        p_operation  => 'INSERT',
        p_description => 'Planification de l''expérience ' || p_id_exp,
        SYS_CONTEXT('USERENV','CURRENT_USER');
    );

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        -- Lorsque erreur, declencher SAVEPOINT
        ROLLBACK;
        --Journalisation?
        -- DBMS_OUTPUT.PUT_LINE();
        RAISE;
END planifier_experience;

-- 6B.Gestion des privileges
-- Accord tous les fonctions de reporting sauf 
GRANT EXECUTE ON rapport_projets_par_chercheur TO LECT_LAB;
GRANT EXECUTE ON rapport_activite_projets      TO LECT_LAB;
GRANT EXECUTE ON statistiques_equipements      TO LECT_LAB;
GRANT EXECUTE ON budget_moyen_par_domaine      TO LECT_LAB;

-- 6B.Gestion des privileges
-- Accorder toutes les procédures au rôle GEST_LAB sauf supprimer_projet
GRANT EXECUTE ON ajouter_projet        TO GEST_LAB;
GRANT EXECUTE ON affecter_equipement   TO GEST_LAB;
GRANT EXECUTE ON planifier_experience  TO GEST_LAB;
GRANT EXECUTE ON journaliser_action    TO GEST_LAB;