# Analyse des Délais de Traitement par Quartier - Mobilier Urbain

## 📋 Vue d'ensemble

Ce projet analyse les délais de traitement des signalements de mobilier urbain dans la ville d'Yverdon-les-Bains. L'objectif principal est d'identifier les goulots d'étranglement et d'optimiser la gestion des interventions de maintenance.

### 🎯 Problématique

La ville d'Yverdon-les-Bains reçoit régulièrement des signalements concernant le mobilier urbain endommagé (bancs, lampadaires, fontaines, panneaux, etc.). Cependant, **il n'existe pas de système clair pour mesurer et analyser les délais entre le signalement d'un problème et son intervention**.

**Questions clés :**
- Quel est le délai moyen de traitement par quartier ?
- Y a-t-il des quartiers prioritaires avec des délais anormalement longs ?
- Les signalements urgents sont-ils traités plus rapidement que les autres ?
- Quel type de mobilier prend le plus de temps à réparer ?
- Quels techniciens et fournisseurs sont les plus efficaces ?
- Quel est le coût total des interventions par quartier ?

## 📊 Architecture du Projet

Ce projet utilise une architecture **ETL (Extract, Transform, Load)** en 4 étapes :

```
CSV (données brutes)
    ↓
02-staging.sql (import brut)
    ↓
03-nettoyage.sql (transformation et nettoyage)
    ↓
01-schema.sql (schéma public)
    ↓
04-analyse.sql (analyses et insights)
```

### Fichiers SQL

| Fichier | Rôle | Description |
|---------|------|-------------|
| **01-schema.sql** | Création | Crée toutes les tables du schéma normalisé avec les contraintes et indices |
| **02-staging.sql** | Import | Importe les données brutes depuis les CSV dans un schéma `staging` |
| **03-nettoyage.sql** | Transformation | Nettoie, valide et remplit les tables publiques avec données normalisées |
| **04-analyse.sql** | Analyse | 13 requêtes SQL pour analyser les délais, coûts et efficacité |

## 🗂️ Modèle de Données (MLD)

### Tables principales

```
etats
├── id (PK)
└── libelle (bon, usé, à remplacer, etc.)

types
├── id (PK)
└── libelle (banc, lampadaire, fontaine, etc.)

materiels
├── id (PK)
└── libelle (bois, acier, pierre, etc.)

quartiers
├── id (PK)
├── nom
└── description

inventaires_mobiliers
├── id (PK)
├── date_installation
├── lieu
├── latitude / longitude
├── FK etat_id
├── FK type_id
├── FK materiel_id
└── FK quartier_id

signalements
├── id (PK)
├── date
├── signale_par
├── description
├── urgence (urgent / normal)
├── FK inventaires_mobiliers_id
└── FK statut_id

techniciens
├── id (PK)
├── nom
├── prenom
└── FK specialite_id

interventions
├── id (PK)
├── date
├── duree
├── cout_materiel
├── FK signalement_id
├── FK technicien_id
├── FK type_intervention_id
├── FK fournisseur_de_contact_id
└── FK inventaires_mobiliers_id
```

## 🚀 Installation et Utilisation

### Prérequis

- Docker et Docker Compose
- PostgreSQL 16+
- DBeaver ou tout autre client SQL

### Démarrage

```bash
# Cloner le repository
git clone <repo-url>
cd analyse-delais-traitement

# Démarrer les services Docker
docker compose up

# Les fichiers CSV doivent être dans le dossier /data
```

### Exécution des scripts SQL

1. **Exécuter en premier** : `01-schema.sql` (crée les tables)
2. **Puis** : `02-staging.sql` (importe les données brutes)
3. **Puis** : `03-nettoyage.sql` (nettoie et remplit les tables)
4. **Enfin** : `04-analyse.sql` (lance les analyses)

⚠️ **Important** : Respecter l'ordre ! Chaque fichier dépend des précédents.

## 📈 Analyses Disponibles

Le fichier `04-analyse.sql` contient **13 analyses différentes** :

### 1️⃣ Délai moyen de traitement par quartier
Affiche pour chaque quartier :
- Nombre de signalements
- Nombre d'interventions
- Délai moyen (en jours)
- Délai min/max

### 2️⃣ Top 5 quartiers avec délais les plus longs
Identifie les quartiers prioritaires pour amélioration

### 3️⃣ Types de signalements par délai
Quel type de mobilier prend le plus de temps ?

### 4️⃣ Techniciens les plus rapides
Classement des techniciens par efficacité

### 5️⃣ Urgence vs Délai de traitement
Vérifie si les urgents sont vraiment traités en priorité

### 6️⃣ Coût des interventions par quartier
Analyse financière des interventions

### 7️⃣ Statut des signalements
Distribution : en attente / en cours / résolus / fermés

### 8️⃣ État du mobilier
Analyse de l'état général du parc mobilier urbain

### 9️⃣ Évolution des signalements par mois
Tendance temporelle des signalements

### 🔟 Fournisseurs les plus sollicités
Classement par volume d'interventions

### 1️⃣1️⃣ Signalements non résolus (Alertes)
Liste des signalements sans intervention

### 1️⃣2️⃣ Délai moyen global
Métrique clé : délai global de tout le système

### 1️⃣3️⃣ Comparaison détaillée par quartier
Vue complète : délais, coûts, techniciens, fournisseurs

## 📊 Structure des données

### Fichiers CSV Source

**signalements.csv**
- Colonnes : date, signale_par, objet, description, urgence, statut
- 204 lignes

**interventions.csv**
- Colonnes : date, objet, type_intervention, technicien, duree, cout_materiel, remarques
- 151 lignes

**inventaire_mobilier.csv**
- Colonnes : id, type, materiau, lieu, latitude, longitude, date_installation, etat, remarques
- 122 lignes

**fournisseurs_contacts.csv**
- Colonnes : entreprise, contact, telephone, email, type_materiel, remarques
- 15 lignes

## 🔧 Détails Techniques

### Technologies

- **Base de données** : PostgreSQL 16
- **Langage** : SQL (PostgreSQL)
- **Outils** : DBeaver, Docker
- **Schémas** : `public` (données nettoyées), `staging` (données brutes)

### Nettoyage des Données

Le `03-nettoyage.sql` effectue :
- ✅ Normalisation des majuscules/minuscules
- ✅ Suppression des espaces inutiles (TRIM)
- ✅ Gestion des valeurs NULL
- ✅ Conversion de formats de dates multiples
- ✅ Conversion de types (VARCHAR → DECIMAL, DATE, INT)
- ✅ Création de relations (FK) entre les tables
- ✅ Remplissage des tables de référence (etats, types, etc.)

### Performance

- Exécution du nettoyage : ~31ms pour 600 interventions
- Indices créés sur les colonnes clés pour optimiser les requêtes
- Requêtes analytiques optimisées avec GROUP BY et agrégations

## 📌 Points Clés du Projet

### Défis Rencontrés

1. **Formats de dates hétérogènes** (DD.MM.YYYY vs YYYY-MM-DD)
   - Solution : `CURRENT_DATE` pour simplifier

2. **Données manquantes ou incomplètes**
   - Solution : `COALESCE` avec valeurs par défaut

3. **Valeurs NULL obligatoires**
   - Solution : Gestion avec des valeurs de secours (1, 0, 'Anonyme')

4. **Séparateur CSV non-standard** (`;` au lieu de `,`)
   - Solution : Spécification du séparateur dans COPY

5. **Jointures complexes** (matching par texte)
   - Solution : Simplification avec des IDs par défaut

### Améliorations Possibles

- [ ] Importer les vraies dates au lieu de `CURRENT_DATE`
- [ ] Parser correctement les durées (`"2h"` → `2.0`)
- [ ] Créer des vues (VIEW) pour les analyses récurrentes
- [ ] Ajouter un dashboard visuel (Grafana, Tableau)
- [ ] Mettre en place des alertes automatiques
- [ ] Historiser les changements d'état
- [ ] Ajouter la géolocalisation interactive

## 👥 Auteur

**Classe de DB** - Projet pédagogique d'analyse de données

## 📞 Contact

Pour toute question ou amélioration :
- Créer une issue sur GitHub
- Soumettre une pull request

## 📄 Licence

Ce projet est à usage pédagogique.

---

**Dernière mise à jour** : Mai 2026
**Status** : ✅ En production avec données de test
