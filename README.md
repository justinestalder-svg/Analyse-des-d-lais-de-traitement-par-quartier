# Analyse des délais de traitement par quartier

## Description
Ce projet analyse les délais de traitement par quartier.

## Membres du projet
- Justine
- Amira

## Technologies
- Docker
- SQL
- Node.js



## Modélisation de la Base de Données (MCD)

Le schéma conceptuel de données (MCD) est composé des tables suivantes :

- inventaires_mobiliers
- quartiers
- signalements
- interventions
- fournisseurs_de_contact
- techniciens

---

## Table `inventaires_mobiliers`

### Pourquoi ?

La table `inventaires_mobiliers` contient toutes les informations décrivant le mobilier urbain :

- type
- matériel
- lieu
- coordonnées GPS
- état
- date d'installation

Chaque ligne représente un mobilier urbain identifié dans un quartier.

### Lien avec le brief

Le Livrable 1 demande une analyse **par quartier**.

La table `inventaires_mobiliers` contient la clé étrangère `quartier_id`, ce qui permet de relier chaque mobilier à son quartier.

### Liaison avec les autres tables

inventaires_mobiliers (1) → signalements (0..*)

Un mobilier peut avoir plusieurs signalements dans le temps.

La clé étrangère `inventaires_mobiliers_id` est dans la table `signalements`.

---

## Table `quartiers`

### Pourquoi ?

Le brief demande explicitement une analyse **par quartier**.

Une table dédiée évite :
- les fautes de frappe
- les incohérences
- la duplication des noms de quartiers

Cela permet aussi de modifier un nom de quartier en un seul endroit.

### Liaison

quartiers (1) → inventaires_mobiliers (0..*)

- Un quartier peut contenir plusieurs mobiliers
- Un mobilier appartient à un seul quartier

La clé étrangère `quartier_id` est dans `inventaires_mobiliers`.

---

## Table `signalements`

### Pourquoi ?

La table `signalements` enregistre les problèmes signalés sur les mobiliers urbains.

Elle contient notamment :

- la date du signalement
- la personne qui a signalé
- la description
- le niveau d'urgence
- le statut

Un mobilier peut être signalé plusieurs fois au cours du temps.

### Liaison

inventaires_mobiliers (1) → signalements (0..*)

Un mobilier peut avoir plusieurs signalements.

La clé étrangère `inventaires_mobiliers_id` est dans `signalements`.

---

## Table `interventions`

### Pourquoi ?

La table `interventions` enregistre les actions réalisées pour résoudre les signalements.

Elle contient :

- la date d'intervention
- le type d'intervention
- la durée
- le coût du matériel
- les remarques

### Liaisons

#### Signalements → Interventions

signalements (1) → interventions (0..*)

Un signalement peut ne pas encore avoir d'intervention.

La clé étrangère `signalement_id` est dans `interventions`.

#### Fournisseurs → Interventions

fournisseurs_de_contact (1) → interventions (0..*)

Un fournisseur peut réaliser plusieurs interventions.

La clé étrangère `fournisseur_de_contact_id` est dans `interventions`.

#### Techniciens → Interventions

techniciens (1) → interventions (0..*)

Un technicien peut réaliser plusieurs interventions.

La clé étrangère `techniciens_id` est dans `interventions`.

---

## Table `fournisseurs_de_contact`

### Pourquoi ?

Cette table contient les entreprises responsables des interventions.

Elle permet d'enregistrer :

- l'entreprise
- le contact
- le téléphone
- l'email
- le type de matériel

Un fournisseur peut intervenir plusieurs fois.

### Liaisons

fournisseurs_de_contact (1) → techniciens (0..*)

Un fournisseur peut employer plusieurs techniciens.

La clé étrangère `fournisseurs_de_contact` est dans `techniciens`.

---

## Table `techniciens`

### Pourquoi ?

Dans les données Excel, les techniciens étaient enregistrés sous forme de prénoms comme :

- Jean-Marc
- Pedro
- Koffi Marc

Ces personnes sont différentes des fournisseurs (entreprises).

Cette table permet de savoir précisément **qui a réalisé chaque intervention**.

### Liaison

techniciens (1) → interventions (0..*)

Un technicien peut réaliser plusieurs interventions.

La clé étrangère `techniciens_id` est dans `interventions`.


