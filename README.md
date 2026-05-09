# Analyse des Délais de Traitement par Quartier — Mobilier Urbain

## 📋 Présentation du projet

Ce projet SQL analyse les délais de traitement des signalements liés au mobilier urbain dans la ville d’Yverdon-les-Bains.

L’objectif principal est d’identifier les quartiers où les interventions prennent le plus de temps afin d’améliorer la gestion des réparations et la maintenance du mobilier public.

Le projet repose sur un pipeline ETL simple utilisant PostgreSQL, Docker et plusieurs fichiers CSV contenant les données brutes.

---

# 🎯 Objectifs

L’analyse permet notamment de répondre aux questions suivantes :

* Quels quartiers présentent les délais de traitement les plus longs ?
* Combien de signalements restent ouverts après 30 jours ?
* Quel est le taux de résolution des signalements par trimestre ?
* Existe-t-il des différences importantes entre les quartiers ?
* Les interventions suivent-elles correctement les signalements ?

---

# 🗂️ Structure du projet

```text
Analyse-des-delais-de-traitement-par-quartier/
│
├── data/
│   ├── fournisseurs_contacts.csv
│   ├── interventions.csv
│   ├── inventaire_mobilier.csv
│   └── signalements.csv
│
├── initdb/
│   ├── 01-schema.sql
│   ├── 02-staging.sql
│   ├── 03-nettoyage.sql
│   └── 04-briefB.sql
│
├── docker-compose.yml
├── README.md
└── MCD.drawio
```

---

# ⚙️ Technologies utilisées

* PostgreSQL 16
* SQL
* Docker / Docker Compose
* DBeaver
* Git / GitHub

---

# 🚀 Installation du projet

## 1️⃣ Cloner le repository

```bash
git clone https://github.com/justinestalder-svg/Analyse-des-d-delais-de-traitement-par-quartier.git
```

## 2️⃣ Accéder au dossier

```bash
cd Analyse-des-delais-de-traitement-par-quartier
```

## 3️⃣ Lancer Docker

```bash
docker compose up -d
```

---

# 📥 Données utilisées

Le projet utilise plusieurs fichiers CSV :

| Fichier                     | Description                   |
| --------------------------- | ----------------------------- |
| `signalements.csv`          | Signalements des citoyens     |
| `interventions.csv`         | Interventions réalisées       |
| `inventaire_mobilier.csv`   | Inventaire du mobilier urbain |
| `fournisseurs_contacts.csv` | Fournisseurs et contacts      |

---

# 🧱 Pipeline ETL

Le projet suit une logique ETL en plusieurs étapes :

```text
CSV → STAGING → NETTOYAGE → ANALYSE
```

## 1. `01-schema.sql`

Création des tables et de la structure de la base de données.

## 2. `02-staging.sql`

Import des données brutes CSV dans des tables temporaires.

## 3. `03-nettoyage.sql`

Nettoyage et normalisation des données :

* suppression des doublons
* uniformisation des textes
* gestion des NULL
* conversion des types
* nettoyage des dates

## 4. `04-briefB.sql`

Création des vues analytiques demandées dans le Brief B.

---

# 📊 Analyses réalisées

## ✅ Livrable 1 — Délais par quartier

Vue SQL :

```sql
v_delai_par_quartier
```

Cette vue affiche :

* le nombre de signalements
* le nombre d’interventions
* le délai moyen de traitement
* le délai médian
* les quartiers concernés

### Méthode utilisée

Chaque signalement est relié uniquement à la première intervention correspondante afin d’éviter les doublons.

---

## ✅ Livrable 2 — Signalements ouverts depuis plus de 30 jours

Vue SQL :

```sql
v_signalements_ouverts
```

Cette vue permet d’identifier :

* les signalements encore en attente
* les signalements en cours
* les objets concernés
* les coordonnées GPS du mobilier

---

## ✅ Livrable 3 — Taux de résolution par trimestre

Vue SQL :

```sql
v_taux_resolution
```

Cette vue calcule :

* le nombre total de signalements
* le nombre de signalements résolus
* le taux de résolution trimestriel

---

# 📈 Résultats observés

Les analyses montrent que certains quartiers présentent des délais de traitement particulièrement élevés.

Plusieurs signalements restent ouverts pendant de longues périodes, ce qui peut indiquer :

* un manque de ressources
* une surcharge d’interventions
* des priorités mal réparties

Le suivi trimestriel permet également d’observer l’évolution de l’efficacité des interventions au fil du temps.

---

# 🛠️ Difficultés rencontrées

## Gestion des dates

Les formats de dates étaient hétérogènes selon les fichiers CSV.

## Jointures complexes

Certaines relations entre signalements et interventions devaient être reconstituées à partir du lieu et du type d’objet.

## Doublons

Plusieurs lignes correspondaient au même mobilier ou à la même intervention.

---


# 👩‍💻 Auteur

Projet réalisé dans le cadre du cours de bases de données à l'HEIG-VD.

Auteur : **Justine Stalder & Amira Gassab**

---

# 📄 Licence

Projet pédagogique à usage académique uniquement.

---

# 📅 Dernière mise à jour

Mai 2026
