# Analyse des délais de traitement par quartier
**Gestion du mobilier urbain — Yverdon-les-Bains**

---

## Contexte

Ce projet analyse les délais de traitement des signalements de mobilier urbain (bancs, lampadaires, fontaines, bornes, poubelles, panneaux) dans la ville d'Yverdon-les-Bains. L'objectif est de comprendre combien de temps s'écoule entre un signalement et l'intervention correspondante, et d'identifier les quartiers les plus en difficulté.

---

## Structure du projet

```
initdb/
├── 01-schema.sql       # Création des tables (MLD final)
├── 02-staging.sql      # Schéma de staging (import brut des CSV)
├── 03-nettoyage.sql    # Nettoyage et transfert staging → MLD
└── 04-briefB.sql       # Vues et analyses (livrables)
data/
├── inventaire_mobilier.csv
├── inventaire_mobilier_quartiers.csv
├── signalements.csv
├── interventions.csv
├── fournisseurs_contacts.csv
├── fournisseur_inventaire.csv
└── techniciens_contacts.csv
```

---

## Étapes réalisées

### 1. Import des données brutes en staging

Les fichiers CSV ont d'abord été chargés tels quels dans un schéma `staging`, sans transformation. Cela permet de conserver les données originales intactes et de travailler le nettoyage séparément.

Les tables staging reproduisent exactement la structure des CSV (colonnes en `TEXT`, séparateur `;`).

---

### 2. Nettoyage et normalisation (`03-nettoyage.sql`)

Les données brutes présentaient plusieurs problèmes qu'il a fallu corriger avant d'insérer dans le MLD final.

#### Données manquantes et valeurs vides
- Les champs vides ont été remplacés par des valeurs par défaut cohérentes (ex. : état inconnu → `'bon'`, statut vide → `'en attente'`, urgence vide → `'normale'`).
- Les champs non renseignés ont été convertis en `NULL` avec `NULLIF`.

#### Formats de dates incohérents
Les CSV contenaient deux formats de dates mélangés :
- `YYYY-MM-DD` (ex. : `2024-07-08`)
- `DD.MM.YYYY` (ex. : `08.05.2022`)

Traitement appliqué :
```sql
CASE
    WHEN TRIM(date) LIKE '____-__-__' THEN TO_DATE(TRIM(date), 'YYYY-MM-DD')
    WHEN TRIM(date) LIKE '%.%.%'      THEN TO_DATE(TRIM(date), 'DD.MM.YYYY')
    ELSE NULL
END
```

#### Libellés dupliqués ou orthographes variables
De nombreux libellés désignaient la même chose avec des orthographes différentes. Des regroupements ont été appliqués :

| Valeurs brutes | Valeur normalisée |
|---|---|
| `borne ev`, `borne recharge`, `borne recharge ev` | `borne` |
| `banc public`, `banc` | `banc` |
| `lampadaire led`, `lampadaire sodium` | `lampadaire` |
| `fontaine`, `fontaine publique` | `fontaine` |
| `panneau info`, `panneau affichage` | `panneau` |
| `corbeille`, `poubelle tri`, `poubelle` | `poubelle` |
| `metal`, `métal` | `métal` |
| `bon`, `bon état`, `correct` | `bon` |
| `fait`, `résolu`, `fermé` | `résolu` |

#### Noms de techniciens
Plusieurs variantes désignaient les mêmes personnes (`jm`, `jean-marc`, `Jean-Marc Bonvin` → `Jean-Marc Bonvin`).

#### Coordonnées GPS
Certaines coordonnées utilisaient une virgule comme séparateur décimal (`46,77932`) au lieu d'un point. Traitement :
```sql
NULLIF(REPLACE(TRIM(latitude), ',', '.'), '')::NUMERIC
```

---

### 3. Volumétrie finale

| Table | Nombre d'enregistrements |
|---|---|
| inventaires_mobiliers | 120 |
| signalements | 203 |
| interventions | 150 |
| fournisseurs_de_contact | 13 |

---

### 4. La difficulté principale : relier interventions et signalements

C'est la partie la plus complexe du projet. **Les données sources ne contenaient aucun identifiant commun** entre les interventions et les signalements — il était donc impossible de faire une jointure directe.

La solution adoptée repose sur le **mobilier urbain comme table pivot**.

#### Étape 1 — Relier les signalements aux mobiliers (via `JOIN LATERAL`)

Le champ `objet` des signalements contenait soit l'identifiant du mobilier, soit une description textuelle de son emplacement. La jointure a été faite par correspondance textuelle :

```sql
JOIN LATERAL (
    SELECT im.id
    FROM inventaires_mobiliers im
    LEFT JOIN types t ON t.id = im.type_id
    WHERE LOWER(TRIM(s.objet)) = LOWER(TRIM(im.id))
       OR LOWER(TRIM(s.objet)) LIKE '%' || LOWER(TRIM(im.lieu)) || '%'
    ORDER BY
        CASE
            WHEN LOWER(TRIM(s.objet)) = LOWER(TRIM(im.id)) THEN 0
            WHEN LOWER(TRIM(s.objet)) LIKE '%' || LOWER(TRIM(t.libelle)) || '%' THEN 1
            ELSE 2
        END,
        LENGTH(im.lieu) DESC
    LIMIT 1
) im ON true
```

Le `JOIN LATERAL` avec `LIMIT 1` garantit qu'on prend le meilleur match disponible (d'abord par ID exact, ensuite par lieu).

#### Étape 2 — Relier les interventions aux mobiliers

Le champ `objet` des interventions suivait le format `type lieu` (ex. : `Banc Chemin de Maillefer`). On a reconstruit dynamiquement ce libellé depuis le type et le lieu du mobilier pour faire la correspondance :

```sql
WHERE LOWER(TRIM(i.objet)) = LOWER(
    CASE
        WHEN t.libelle = 'banc'      THEN 'banc ' || im.lieu
        WHEN t.libelle = 'lampadaire' THEN 'lampadaire ' || im.lieu
        WHEN t.libelle = 'fontaine'  THEN 'fontaine ' || im.lieu
        WHEN t.libelle = 'borne'     THEN 'borne ev ' || im.lieu
        WHEN t.libelle = 'panneau'   THEN 'panneau ' || im.lieu
        WHEN t.libelle = 'poubelle'  THEN 'poubelle ' || im.lieu
        ELSE im.lieu
    END
)
```

#### Étape 3 — Lien final

Une fois que l'intervention et le signalement pointaient tous les deux vers le même mobilier, le `signalement_id` a pu être récupéré via ce pivot commun :

```sql
JOIN signalements s ON s.inventaires_mobiliers_id = im.id
```

Un `ROW_NUMBER()` a ensuite été utilisé pour éviter les doublons en cas de plusieurs signalements sur un même mobilier.

---

## Analyses produites (`04-briefB.sql`)

- **Délai moyen et médian par quartier** entre la date de signalement et la date d'intervention
- **Signalements ouverts depuis plus de 30 jours** (sans intervention associée)
- **Taux de résolution par trimestre** pour suivre l'évolution de la qualité du service

---

## Conclusions

- Le mobilier le plus souvent signalé est le **lampadaire**, suivi des **bancs**.
- Certains quartiers présentent des délais de traitement nettement plus élevés, ce qui peut indiquer une surcharge des équipes ou une concentration d'incidents.
- Le délai médian est plus représentatif que le délai moyen, car quelques cas exceptionnellement longs tirent la moyenne vers le haut.
- Des signalements restent ouverts depuis plusieurs mois, principalement concernant des lampadaires et des bancs dans des quartiers périphériques.
- Le taux de résolution varie selon les trimestres, montrant des périodes de meilleure prise en charge que d'autres.
