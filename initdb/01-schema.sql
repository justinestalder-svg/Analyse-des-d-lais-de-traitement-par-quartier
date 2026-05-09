-- ===========================================================
-- SCHEMA.SQL - VERSION SIMPLE
-- Gestion Mobilier Urbain Yverdon-les-Bains
-- ===========================================================

-- ===========================================================
-- 1. NETTOYER COMPLÈTEMENT
-- ===========================================================

DROP TABLE IF EXISTS interventions CASCADE;
DROP TABLE IF EXISTS signalements CASCADE;
DROP TABLE IF EXISTS inventaire_mobilier CASCADE;
DROP TABLE IF EXISTS fournisseurs_contacts CASCADE;

-- ===========================================================
-- 2. CRÉER LES 4 TABLES FINALES
-- ===========================================================

CREATE TABLE inventaire_mobilier (
    id TEXT PRIMARY KEY,
    type VARCHAR(50),
    materiau VARCHAR(50),
    lieu VARCHAR(255),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    date_installation DATE,
    etat VARCHAR(50),
    remarques TEXT
);

CREATE TABLE interventions (
    id SERIAL PRIMARY KEY,
    date DATE,
    objet VARCHAR(255),
    type_intervention VARCHAR(100),
    technicien VARCHAR(100),
    duree_heures NUMERIC(5,1),
    cout_materiel DECIMAL(10,2),
    remarques TEXT,
    lieu VARCHAR(255),
    priorite VARCHAR(50)
);

CREATE TABLE signalements (
    id SERIAL PRIMARY KEY,
    date DATE,
    signale_par VARCHAR(150),
    objet VARCHAR(255),
    description TEXT,
    urgence VARCHAR(50),
    statut VARCHAR(50),
    lieu VARCHAR(255)
);

CREATE TABLE fournisseurs_contacts (
    id SERIAL PRIMARY KEY,
    entreprise VARCHAR(150) UNIQUE,
    contact VARCHAR(150),
    telephone VARCHAR(30),
    email VARCHAR(150),
    type_materiel VARCHAR(255),
    remarques TEXT
);

-- ===========================================================
-- 3. INDEX
-- ===========================================================

CREATE INDEX idx_inventaire_type
ON inventaire_mobilier(type);

CREATE INDEX idx_inventaire_etat
ON inventaire_mobilier(etat);

CREATE INDEX idx_inventaire_lieu
ON inventaire_mobilier(lieu);

CREATE INDEX idx_inventaire_geom
ON inventaire_mobilier(latitude, longitude);

CREATE INDEX idx_interventions_date
ON interventions(date);

CREATE INDEX idx_interventions_technicien
ON interventions(technicien);

CREATE INDEX idx_interventions_type
ON interventions(type_intervention);

CREATE INDEX idx_interventions_priorite
ON interventions(priorite);

CREATE INDEX idx_signalements_date
ON signalements(date);

CREATE INDEX idx_signalements_urgence
ON signalements(urgence);

CREATE INDEX idx_signalements_statut
ON signalements(statut);

CREATE INDEX idx_signalements_objet
ON signalements(objet);

CREATE INDEX idx_signalements_lieu
ON signalements(lieu);

CREATE INDEX idx_fournisseurs_entreprise
ON fournisseurs_contacts(entreprise);

CREATE INDEX idx_fournisseurs_type
ON fournisseurs_contacts(type_materiel);

-- ===========================================================
-- 4. VÉRIFICATION
-- ===========================================================

SELECT 'Tables créées avec succès !' AS message;

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;