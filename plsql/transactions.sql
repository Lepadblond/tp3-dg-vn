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
    -- Si statut n'est pas dans le check in
    IF p_statut NOT IN ('En cours', 'Terminée', 'Annulée') THEN
        RAISE_APPLICATION_ERROR(-20010, 'Parametre de statut invalide ' || p_statut); 
    END IF;

    --Insertion dans experience
    INSERT INTO EXPERIENCE (id_projet, titre_exp, date_realisation, resultat, statut)
    VALUES (p_id_projet, p_titre_exp, p_date_real, p_resultat, p_statut);

    -- Savepoint avant affectation
    SAVEPOINT sv_avant_modification_affectation;
    DBMS_OUTPUT.PUT_LINE('Savepoint sv_avant_modification_affectation defini');

    BEGIN
        affecter_equipement(p_id_projet, p_id_equipement, p_date_real, 1);
    EXCEPTION
        WHEN OTHERS THEN
            -- Retour au savepoint
            ROLLBACK TO sv_avant_modification_affectation;

            journaliser_action(
                'EXPERIENCE', 'ERREUR_PLANIF', 
                'Erreur lors de l''affectation de l''équipement pour exp '|| p_id_exp || ' : ' || SQLERRM,
                
            );
            RAISE;
    END;

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
        journaliser_action('EXPERIENCE', 'ERREUR_PLANIF_GLOBAL',
         'Erreur globale dans planifier_experience: ' || SQLERRM
        );
        RAISE;
END planifier_experience;
/
-- 6B.Sécurité des données
CREATE OR REPLACE VIEW V_PROJETS_PUBLICS AS
SELECT id_projet, titre, domaine, budget, date_debut, date_fin, id_chercheur_resp
FROM PROJET
WHERE date_fin IS NOT NULL
AND date_fin <= SYSDATE;
/

CREATE OR REPLACE VIEW V_RESULTATS_EXPERIENCE AS
SELECT
    e.id_exp AS id_exp,
    e.titre_exp AS titre_exp,
    e.date_realisation AS date_realisation,
    e.statut AS statut,
    p.titre AS titre_projet,
    p.domaine AS domaine_projet,
    c.nom AS nom_chercheur,
    c.prenom AS prenom_chercheur,
    COUNT(ect.id_echantillon) AS nb_echantillons,
    AVG(ect.mesure) AS moyenne_mesure,
    e.resultat AS resultat_exp,
    (p.date_fin - p.date_debut)AS duree_projet
FROM EXPERIENCE e
JOIN PROJET p
ON e.id_projet = p.id_projet
JOIN CHERCHEUR c
ON p.id_chercheur_resp = c.id_chercheur
LEFT JOIN ECHANTILLON ect
ON ect.id_exp = e.id_exp
GROUP BY
    e.id_exp,
    e.titre_exp,
    e.date_realisation,
    e.statut,
    p.titre,
    p.domaine,
    c.nom,
    c.prenom,
    e.resultat,
    p.date_fin,
    p.date_debut
/
-- Chiffrement des données sensibles
-- Hachage de Chercheur.Nom
CREATE OR REPLACE FUNCTION hash_nom(p_nom IN VARCHAR2)
RETURN VARCHAR2
IS
BEGIN
    RETURN STANDARD_HASH(p_nom, 'SHA256');
END;
/

CREATE OR REPLACE TRIGGER trg_chercheur_hash_nom
BEFORE INSERT OR UPDATE OF nom ON CHERCHEUR
FOR EACH ROW
BEGIN
    :NEW.nom := hash_nom(:NEW.nom);
END;
/

-- Hachage Echantillon.mesure
-- Hashage d'un nombre numerique??
-- Ajustement Table pour 2 version d'ehcantillon 
-- (version Publique, privee)
ALTER TABLE ECHANTILLON
ADD (
    mesure_hash VARCHAR2(64) DEFAULT NULL
);

CREATE OR REPLACE TRIGGER trg_hash_mesure
BEFORE INSERT OR UPDATE OF mesure
ON ECHANTILLON
FOR EACH ROW
BEGIN
    IF :NEW.mesure IS NOT NULL THEN
        :NEW.mesure_hash :=
            STANDARD_HASH(
                TO_CHAR(:NEW.mesure),
                'SHA256'
            );
    ELSE
        :NEW.mesure_hash := NULL;
    END IF;
END;
/
-- Nouvelle version de la fonction puisque Echantillon hachee
CREATE OR REPLACE VIEW V_RESULTATS_EXPERIENCE_OFFUSQUEE AS
SELECT
    e.id_exp AS id_exp,
    e.titre_exp AS titre_exp,
    e.date_realisation AS date_realisation,
    e.statut AS statut,
    p.titre AS titre_projet,
    p.domaine AS domaine_projet,
    --Valeurs offusquee
    c.nom AS nom_chercheur,
    c.prenom AS prenom_chercheur,

    COUNT(ect.id_echantillon) AS nb_echantillons,
    STANDARD_HASH(
        LISTAGG(TO_CHAR(ect.mesure), '|') WITHIN GROUP (ORDER BY ect.id_echantillon), 'SHA256'
    ) AS mesure_hash

    e.resultat AS resultat_exp,
    (p.date_fin - p.date_debut) AS duree_projet
FROM EXPERIENCE e
JOIN PROJET p
ON e.id_projet = p.id_projet
JOIN CHERCHEUR c
ON p.id_chercheur_resp = c.id_chercheur
LEFT JOIN ECHANTILLON ect
ON ect.id_exp = e.id_exp
GROUP BY
    e.id_exp,
    e.titre_exp,
    e.date_realisation,
    e.statut,
    p.titre,
    p.domaine,
    c.nom,
    c.prenom,
    e.resultat,
    p.date_fin,
    p.date_debut
/


-- 6B.Gestion des privileges
-- Accord des views
GRANT SELECT ON V_RESULTATS_EXPERIENCE_OFFUSQUEE TO LECT_LAB;
GRANT SELECT ON V_PROJETS_PUBLICS                TO LECT_LAB;

-- Accord tous les fonctions de reporting sauf 
GRANT EXECUTE ON rapport_projets_par_chercheur TO LECT_LAB;
GRANT EXECUTE ON rapport_activite_projets TO LECT_LAB;
GRANT EXECUTE ON statistiques_equipements TO LECT_LAB;
GRANT EXECUTE ON budget_moyen_par_domaine TO LECT_LAB;

-- 6B.Gestion des privileges
-- Accorder toutes les procédures au rôle GEST_LAB sauf supprimer_projet
GRANT EXECUTE ON ajouter_projet TO GEST_LAB;
GRANT EXECUTE ON affecter_equipement TO GEST_LAB;
GRANT EXECUTE ON planifier_experience TO GEST_LAB;
GRANT EXECUTE ON journaliser_action TO GEST_LAB;

-- 6B.Journalisation
-- Toutes les actions d’insertion/suppression doivent être inscrites dans
-- LOG_OPERATION.
CREATE OR REPLACE TRIGGER trg_log_experience
AFTER INSERT OR DELETE ON EXPERIENCE
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        journaliser_action(
            'EXPERIENCE','INSERT', USER, 'Insertion de l''expérience ID=' || :NEW.id_exp
        );

    ELSIF DELETING THEN
        journaliser_action(
            'EXPERIENCE',
            'DELETE',
            USER,
            'Suppression de l''expérience ID=' || :OLD.id_exp
        );
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_log_projet
AFTER INSERT OR DELETE ON PROJET
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        journaliser_action(
            'PROJET',
            'INSERT',
            USER,
            'Insertion du projet ID=' || :NEW.id_projet
        );

    ELSIF DELETING THEN
        journaliser_action(
            'PROJET',
            'DELETE',
            USER,
            'Suppression du projet ID=' || :OLD.id_projet
        );
    END IF;
END;
/


