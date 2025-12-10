-- ===========================================================
-- TRIGGER : TRG_PROJET_BEFORE_INSERT
-- OBJECTIF : Valider les données d'un projet avant insertion.
--   - Vérifier que date_fin >= date_debut
--   - Vérifier que budget > 0
-- ACTION : Affiche un message via DBMS_OUTPUT et bloque l'insertion.
-- ===========================================================
CREATE OR REPLACE TRIGGER TRG_PROJET_BEFORE_INSERT
BEFORE INSERT ON PROJET
FOR EACH ROW
DECLARE
  e_invalid EXCEPTION;
BEGIN
  IF :NEW.date_fin < :NEW.date_debut THEN
    DBMS_OUTPUT.PUT_LINE('Erreur : La date de fin doit être >= à la date de début.');
    RAISE e_invalid;  
  END IF;
  IF :NEW.budget <= 0 THEN
    DBMS_OUTPUT.PUT_LINE('Erreur : Le budget doit être strictement positif.');
    RAISE e_invalid;  
  END IF;

EXCEPTION
  WHEN e_invalid THEN
    RAISE;
END;
/
-- ===========================================================
-- TRIGGER : TRG_AFFECTATION_BEFORE_INSERT
-- OBJECTIF : Valider qu'un équipement est disponible avant son affectation.
--   - Vérifier que EQUIPEMENT.etat = 'DISPONIBLE'
-- ACTION : Affiche un message via DBMS_OUTPUT et bloque l'insertion.
-- ===========================================================

CREATE OR REPLACE TRIGGER TRG_AFFECTATION_BEFORE_INSERT
BEFORE INSERT ON AFFECTATION_EQUIP
FOR EACH ROW
DECLARE
    v_etat EQUIPEMENT.etat%TYPE;
    e_invalid EXCEPTION;
BEGIN
    SELECT etat INTO v_etat
    FROM EQUIPEMENT
    WHERE id_equipement = :NEW.id_equipement;

    IF UPPER(v_etat) <> 'DISPONIBLE' THEN
        DBMS_OUTPUT.PUT_LINE('Erreur : L''équipement n''est pas disponible.');
        RAISE e_invalid;
    END IF;
EXCEPTION
    WHEN e_invalid THEN
        RAISE;
END;
/
