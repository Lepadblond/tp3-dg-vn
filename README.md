# Projet : Gestion de Laboratoire

## Contributeurs
| Nom          | Numéro d'attestation |
|--------------|--------------------|
| David Girard | 2101643            |
| Vosa Neo     | [Numéro à compléter] |

## Répartition des tâches

| Composant | Responsable | Description |
|-----------|------------|-------------|
| Procédures | David Girard & Vosa Neo | `ajouter_projet`, `affecter_equipement`, `planifier_experience`, `supprimer_projet`, `rapport_projets_par_chercheur` |
| Fonctions | David Girard & Vosa Neo  | `verifier_disponibilite_equipement`, `calculer_duree_projet`, `moyenne_mesures_experience` |
| Reporting | David Girard & Vosa Neo| Procédures et fonctions pour générer des rapports : <br> - `rapport_projets_par_chercheur(p_id_chercheur)` <br> - `rapport_experiences_par_projet(p_id_projet)` <br> - Fonctions auxiliaires comme `calculer_duree_projet` et `moyenne_mesures_experience` |
| Déclencheurs | David Girard & Vosa Neo | Déclencheurs pour journalisation et contraintes automatisées (si applicable) |
| Rapport | David Girard & Vosa Neo | Génération des rapports par chercheur et par projet |

## Instructions de lancement

1. **Connexion à Oracle**  
   - Ouvrir SQL*Plus ou SQL Developer  
   - Se connecter avec un utilisateur disposant des droits suffisants (`CONNECT` et `RESOURCE`)  

2. **Exécution des scripts**  
   - Créer les rôles et utilisateurs : `roles_et_utilisateurs.sql`  
   - Créer les tables : `tables_laboratoire.sql`  
   - Créer les procédures et fonctions : `procedures_fonctions.sql`  
   - Créer les déclencheurs : `declencheurs.sql` (si applicable)  

3. **Tests**  
   - Chaque procédure opérationnelle contient un bloc anonyme de test à exécuter séparément  
   - Vérifier la sortie avec `DBMS_OUTPUT.PUT_LINE`  

## Date de remise
- **Date :** [JJ/MM/AAAA]  
- **État du projet :** Incomplet
