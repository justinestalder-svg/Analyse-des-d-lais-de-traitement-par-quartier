DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;

-- =========================================================
-- TABLES DE RÉFÉRENCE
-- =========================================================

CREATE TABLE etats (
    id SERIAL PRIMARY KEY,
    libelle TEXT NOT NULL UNIQUE
);

CREATE TABLE types (
    id SERIAL PRIMARY KEY,
    libelle TEXT NOT NULL UNIQUE
);

CREATE TABLE materiaux (
    id SERIAL PRIMARY KEY,
    libelle TEXT NOT NULL UNIQUE
);

CREATE TABLE quartiers (
    id SERIAL PRIMARY KEY,
    nom TEXT NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE statuts (
    id SERIAL PRIMARY KEY,
    libelle TEXT NOT NULL UNIQUE
);

CREATE TABLE types_interventions (
    id SERIAL PRIMARY KEY,
    libelle TEXT NOT NULL UNIQUE
);

CREATE TABLE types_materiels (
    id SERIAL PRIMARY KEY,
    libelle TEXT NOT NULL UNIQUE
);

-- =========================================================
-- FOURNISSEURS DE CONTACT
-- =========================================================

CREATE TABLE fournisseurs_de_contact (
    id SERIAL PRIMARY KEY,
    entreprise TEXT NOT NULL,
    contact TEXT,
    telephone TEXT UNIQUE,
    email TEXT UNIQUE,
    type_materiel_id INT NOT NULL,
    remarque TEXT,

    FOREIGN KEY (type_materiel_id)
        REFERENCES types_materiels(id)
);

-- =========================================================
-- INVENTAIRES MOBILIERS
-- =========================================================

CREATE TABLE inventaires_mobiliers (
    id TEXT PRIMARY KEY,
    date_installation DATE,
    etat_id INT NOT NULL,
    remarque TEXT,
    type_id INT NOT NULL,
    materiel_id INT NOT NULL,
    lieu TEXT NOT NULL,
    latitude NUMERIC,
    longitude NUMERIC,
    quartier_id INT NOT NULL,

    FOREIGN KEY (etat_id)
        REFERENCES etats(id),

    FOREIGN KEY (type_id)
        REFERENCES types(id),

    FOREIGN KEY (materiel_id)
        REFERENCES materiaux(id),

    FOREIGN KEY (quartier_id)
        REFERENCES quartiers(id)
);

-- =========================================================
-- SIGNALEMENTS
-- =========================================================

CREATE TABLE signalements (
    id SERIAL PRIMARY KEY,
    date DATE NOT NULL,
    signale_par TEXT NOT NULL,
    inventaires_mobiliers_id TEXT NOT NULL,
    description TEXT NOT NULL,
    urgence TEXT NOT NULL,
    statut_id INT NOT NULL,

    FOREIGN KEY (inventaires_mobiliers_id)
        REFERENCES inventaires_mobiliers(id),

    FOREIGN KEY (statut_id)
        REFERENCES statuts(id)
);

-- =========================================================
-- INTERVENTIONS
-- =========================================================

CREATE TABLE interventions (
    id SERIAL PRIMARY KEY,
    date DATE NOT NULL,
    fournisseur_de_contact_id INT NOT NULL,
    signalement_id INT NOT NULL,
    type_intervention_id INT NOT NULL,
    technicien TEXT NOT NULL,
    duree TEXT,
    cout_materiel NUMERIC,
    remarque TEXT,
    inventaire_mobilier_id TEXT NOT NULL,

    FOREIGN KEY (fournisseur_de_contact_id)
        REFERENCES fournisseurs_de_contact(id),

    FOREIGN KEY (signalement_id)
        REFERENCES signalements(id),

    FOREIGN KEY (type_intervention_id)
        REFERENCES types_interventions(id),

    FOREIGN KEY (inventaire_mobilier_id)
        REFERENCES inventaires_mobiliers(id)
);