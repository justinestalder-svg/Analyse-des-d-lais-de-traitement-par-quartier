-- =========================================================
-- 03-NETTOYAGE.SQL
-- Remplissage du MLD depuis staging
-- =========================================================

TRUNCATE TABLE
    interventions,
    signalements,
    inventaires_mobiliers,
    fournisseurs_de_contact,
    types_materiels,
    types_interventions,
    statuts,
    quartiers,
    etats,
    materiaux,

    types
RESTART IDENTITY CASCADE;



-- =========================================================
-- TYPES
-- =========================================================

INSERT INTO types (libelle)
SELECT DISTINCT
    CASE
        WHEN LOWER(TRIM(type)) IN ('borne ev', 'borne recharge', 'borne recharge ev')
            THEN 'borne'

        WHEN LOWER(TRIM(type)) IN ('panneau info', 'panneau affichage')
            THEN 'panneau'

        WHEN LOWER(TRIM(type)) IN ('fontaine', 'fontaine publique')
            THEN 'fontaine'

        WHEN LOWER(TRIM(type)) IN ('lampadaire led', 'lampadaire sodium')
            THEN 'lampadaire'

        WHEN LOWER(TRIM(type)) IN ('banc public', 'banc')
            THEN 'banc'

        WHEN LOWER(TRIM(type)) IN ('corbeille', 'poubelle tri', 'poubelle')
            THEN 'poubelle'

        ELSE LOWER(TRIM(type))
    END AS libelle
FROM staging.inventaire_mobilier
WHERE type IS NOT NULL
  AND TRIM(type) <> '';
-- =========================================================
-- MATERIAUX
-- =========================================================
INSERT INTO materiaux (libelle)
SELECT DISTINCT
    CASE
        WHEN materiau IS NULL OR TRIM(materiau) = '' THEN 'inconnu'
        WHEN LOWER(TRIM(materiau)) IN ('metal', 'métal') THEN 'métal'
        WHEN LOWER(TRIM(materiau)) IN ('beton', 'béton') THEN 'béton'
        ELSE LOWER(TRIM(materiau))
    END
FROM staging.inventaire_mobilier
ON CONFLICT (libelle) DO NOTHING;

-- =========================================================
-- ETATS
-- =========================================================
INSERT INTO etats (libelle)
SELECT DISTINCT
    CASE
        WHEN etat IS NULL OR TRIM(etat) = '' THEN 'bon'
        WHEN LOWER(TRIM(etat)) IN ('bon', 'bon état', 'correct') THEN 'bon'
        WHEN LOWER(TRIM(etat)) IN ('moyen', 'usé', 'use') THEN 'moyen'
        WHEN LOWER(TRIM(etat)) IN ('mauvais', 'abime', 'abîmé') THEN 'mauvais'
        ELSE LOWER(TRIM(etat))
    END
FROM staging.inventaire_mobilier
ON CONFLICT (libelle) DO NOTHING;

-- =========================================================
-- QUARTIERS
-- =========================================================
INSERT INTO quartiers (nom)
SELECT DISTINCT INITCAP(TRIM(quartier))
FROM staging.inventaire_mobilier_quartiers
WHERE quartier IS NOT NULL AND TRIM(quartier) <> ''
ON CONFLICT (nom) DO NOTHING;

-- =========================================================
-- STATUTS
-- =========================================================
INSERT INTO statuts (libelle)
SELECT DISTINCT
    CASE
        WHEN statut IS NULL OR TRIM(statut) = '' THEN 'en attente'
        WHEN LOWER(TRIM(statut)) IN ('fait', 'résolu', 'resolu', 'fermé', 'ferme') THEN 'résolu'
        WHEN LOWER(TRIM(statut)) = 'en cours' THEN 'en cours'
        ELSE 'en attente'
    END
FROM staging.signalements
ON CONFLICT (libelle) DO NOTHING;

-- =========================================================
-- TYPES INTERVENTIONS
-- =========================================================
INSERT INTO types_interventions (libelle)
SELECT DISTINCT
    CASE
        WHEN LOWER(TRIM(type_intervention)) LIKE '%remplacement%' THEN 'remplacement'
        WHEN LOWER(TRIM(type_intervention)) LIKE '%réparation%'
          OR LOWER(TRIM(type_intervention)) LIKE '%reparation%' THEN 'réparation'
        WHEN LOWER(TRIM(type_intervention)) LIKE '%nettoyage%' THEN 'nettoyage'
        WHEN LOWER(TRIM(type_intervention)) LIKE '%peinture%' THEN 'peinture'
        ELSE LOWER(TRIM(type_intervention))
    END
FROM staging.interventions
WHERE type_intervention IS NOT NULL AND TRIM(type_intervention) <> ''
ON CONFLICT (libelle) DO NOTHING;

-- =========================================================
-- TYPES MATERIELS
-- =========================================================

INSERT INTO types_materiels (libelle)
SELECT DISTINCT
    CASE
        WHEN LOWER(TRIM(type_materiel)) LIKE '%borne%'
            THEN 'borne'

        WHEN LOWER(TRIM(type_materiel)) LIKE '%panneau%'
            THEN 'panneau'

        WHEN LOWER(TRIM(type_materiel)) LIKE '%fontaine%'
            THEN 'fontaine'

        WHEN LOWER(TRIM(type_materiel)) LIKE '%lampadaire%'
          OR LOWER(TRIM(type_materiel)) LIKE '%éclairage%'
            THEN 'lampadaire'

        WHEN LOWER(TRIM(type_materiel)) LIKE '%banc%'
          OR LOWER(TRIM(type_materiel)) LIKE '%poubelle%'
          OR LOWER(TRIM(type_materiel)) LIKE '%corbeille%'
            THEN 'poubelle'

        ELSE LOWER(TRIM(type_materiel))
    END AS libelle
FROM staging.fournisseurs_contacts
WHERE type_materiel IS NOT NULL
  AND TRIM(type_materiel) <> '';


-- FOURNISSEURS DE CONTACT
-- =========================================================
-- FOURNISSEURS DE CONTACT
-- =========================================================

INSERT INTO fournisseurs_de_contact (
    entreprise,
    contact,
    telephone,
    email,
    type_materiel_id,
    remarque
)
SELECT DISTINCT
    INITCAP(TRIM(f.entreprise)) AS entreprise,
    NULLIF(INITCAP(TRIM(f.contact)), '') AS contact,
    NULLIF(TRIM(f.telephone), '') AS telephone,
    NULLIF(LOWER(TRIM(f.email)), '') AS email,
    tm.id AS type_materiel_id,
    NULLIF(TRIM(f.remarques), '') AS remarque

FROM staging.fournisseurs_contacts f

JOIN types_materiels tm
    ON tm.libelle =
        CASE
            WHEN LOWER(TRIM(f.type_materiel)) LIKE '%borne%'
                THEN 'borne'

            WHEN LOWER(TRIM(f.type_materiel)) LIKE '%panneau%'
                THEN 'panneau'

            WHEN LOWER(TRIM(f.type_materiel)) LIKE '%fontaine%'
                THEN 'fontaine'

            WHEN LOWER(TRIM(f.type_materiel)) LIKE '%lampadaire%'
              OR LOWER(TRIM(f.type_materiel)) LIKE '%éclairage%'
                THEN 'lampadaire'

            WHEN LOWER(TRIM(f.type_materiel)) LIKE '%banc%'
              OR LOWER(TRIM(f.type_materiel)) LIKE '%poubelle%'
              OR LOWER(TRIM(f.type_materiel)) LIKE '%corbeille%'
                THEN 'poubelle'

            ELSE LOWER(TRIM(f.type_materiel))
        END

WHERE f.entreprise IS NOT NULL
  AND TRIM(f.entreprise) <> '';



-- INVENTAIRES MOBILIERS
-- =========================================================
-- INVENTAIRES MOBILIERS
-- =========================================================

INSERT INTO inventaires_mobiliers (
    id,
    date_installation,
    etat_id,
    remarque,
    type_id,
    materiel_id,
    lieu,
    latitude,
    longitude,
    quartier_id
)
SELECT DISTINCT
    TRIM(i.id) AS id,

    CASE
        WHEN i.date_installation IS NULL
          OR TRIM(i.date_installation) = ''
            THEN NULL

        WHEN TRIM(i.date_installation) LIKE '____-__-__'
            THEN TO_DATE(TRIM(i.date_installation), 'YYYY-MM-DD')

        WHEN TRIM(i.date_installation) LIKE '__.__.____'
            THEN TO_DATE(TRIM(i.date_installation), 'DD.MM.YYYY')

        ELSE NULL
    END AS date_installation,

    e.id AS etat_id,

    NULLIF(TRIM(i.remarques), '') AS remarque,

    t.id AS type_id,

    m.id AS materiel_id,

    INITCAP(TRIM(i.lieu)) AS lieu,

    NULLIF(REPLACE(TRIM(i.latitude), ',', '.'), '')::NUMERIC AS latitude,

    NULLIF(REPLACE(TRIM(i.longitude), ',', '.'), '')::NUMERIC AS longitude,

    q.id AS quartier_id

FROM staging.inventaire_mobilier i

JOIN etats e
    ON e.libelle = LOWER(TRIM(i.etat))

JOIN types t
    ON t.libelle =
        CASE
            WHEN LOWER(TRIM(i.type)) IN ('borne ev', 'borne recharge', 'borne recharge ev')
                THEN 'borne'

            WHEN LOWER(TRIM(i.type)) IN ('panneau info', 'panneau affichage')
                THEN 'panneau'

            WHEN LOWER(TRIM(i.type)) IN ('fontaine', 'fontaine publique')
                THEN 'fontaine'

            WHEN LOWER(TRIM(i.type)) IN ('lampadaire led', 'lampadaire sodium')
                THEN 'lampadaire'

            WHEN LOWER(TRIM(i.type)) IN ('banc public', 'banc')
                THEN 'banc'

            WHEN LOWER(TRIM(i.type)) IN ('corbeille', 'poubelle tri', 'poubelle')
                THEN 'poubelle'

            ELSE LOWER(TRIM(i.type))
        END

JOIN materiaux m
    ON m.libelle = LOWER(TRIM(i.materiau))

JOIN staging.inventaire_mobilier_quartiers iq
    ON iq.id = i.id

JOIN quartiers q
    ON LOWER(TRIM(q.nom))
       = LOWER(TRIM(iq.quartier))

WHERE i.id IS NOT NULL
  AND TRIM(i.id) <> '';

-- =========================================================
-- SIGNALEMENTS
-- =========================================================

INSERT INTO signalements (
    date,
    signale_par,
    inventaires_mobiliers_id,
    description,
    urgence,
    statut_id
)
SELECT
    CASE
        WHEN s.date IS NULL OR TRIM(s.date) = ''
            THEN NULL
        WHEN TRIM(s.date) LIKE '%.%.%'
            THEN TO_DATE(TRIM(s.date), 'DD.MM.YYYY')
        WHEN TRIM(s.date) LIKE '____-__-__'
            THEN TO_DATE(TRIM(s.date), 'YYYY-MM-DD')
        ELSE NULL
    END AS date,

    CASE
        WHEN s.signale_par IS NULL OR TRIM(s.signale_par) = ''
            THEN 'Non renseigné'
        WHEN LOWER(TRIM(s.signale_par)) LIKE '%habitant%'
            THEN 'Habitant'
        WHEN LOWER(TRIM(s.signale_par)) LIKE '%passant%'
            THEN 'Passant'
        WHEN LOWER(TRIM(s.signale_par)) LIKE '%email%'
            THEN 'Email citoyen'
        WHEN LOWER(TRIM(s.signale_par)) LIKE '%patrouille%'
            THEN 'Patrouille JM'
        WHEN LOWER(TRIM(s.signale_par)) LIKE '%non renseign%'
            THEN 'Non renseigné'
        ELSE INITCAP(TRIM(s.signale_par))
    END AS signale_par,

    im.id AS inventaires_mobiliers_id,

    CASE
        WHEN LOWER(TRIM(s.description)) IN ('tags', 'tags / graffitis')
            THEN 'Tags / graffitis'
        WHEN LOWER(TRIM(s.description)) = 'éclaire mal'
            THEN 'Éclaire mal'
        WHEN LOWER(TRIM(s.description)) = 'ne charge plus'
            THEN 'Ne charge plus'
        WHEN LOWER(TRIM(s.description)) IN ('brûlée', 'brulee', 'brûlé', 'brule')
            THEN 'Brûlé'
        WHEN LOWER(TRIM(s.description)) IN ('ne s''allume plus', 'ne s’allume plus')
            THEN 'Ne s''allume plus'
        WHEN LOWER(TRIM(s.description)) IN ('gel a abîmé la tuyauterie', 'gel a abime la tuyauterie')
            THEN 'Gel a abîmé la tuyauterie'
        ELSE INITCAP(LOWER(TRIM(s.description)))
    END AS description,

    CASE
        WHEN s.urgence IS NULL OR TRIM(s.urgence) = ''
            THEN 'normale'
        WHEN LOWER(TRIM(s.urgence)) IN ('urgent', 'haute', 'élevée', 'elevee')
            THEN 'haute'
        WHEN LOWER(TRIM(s.urgence)) IN ('basse', 'faible')
            THEN 'basse'
        ELSE 'normale'
    END AS urgence,

    st.id AS statut_id

FROM staging.signalements s

JOIN LATERAL (
    SELECT im.id
    FROM inventaires_mobiliers im
    LEFT JOIN types t
        ON t.id = im.type_id
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

JOIN statuts st
    ON st.libelle =
        CASE
            WHEN s.statut IS NULL OR TRIM(s.statut) = ''
                THEN 'en attente'
            WHEN LOWER(TRIM(s.statut)) IN ('fait', 'résolu', 'resolu', 'fermé', 'ferme')
                THEN 'résolu'
            WHEN LOWER(TRIM(s.statut)) = 'en cours'
                THEN 'en cours'
            ELSE 'en attente'
        END

WHERE s.objet IS NOT NULL
  AND TRIM(s.objet) <> '';


-- =========================================================
-- INTERVENTIONS
-- =========================================================
-- =========================================================
-- INTERVENTIONS
-- =========================================================
-- =========================================================
-- INTERVENTIONS
-- =========================================================
TRUNCATE TABLE interventions RESTART IDENTITY;
-- =========================================================
-- INTERVENTIONS
-- =========================================================

WITH correspondances AS (
    SELECT
        i.date,
        i.objet,
        i.type_intervention,
        i.technicien,
        i.duree,
        i.cout_materiel,
        i.remarques,

        im.id AS inventaire_mobilier_id,
        s.id AS signalement_id,
        fc.id AS fournisseur_de_contact_id,

        ROW_NUMBER() OVER (
            PARTITION BY i.date, i.objet, i.type_intervention, i.technicien
            ORDER BY im.id
        ) AS rn

    FROM staging.interventions i

    JOIN inventaires_mobiliers im
        ON TRUE

    JOIN types t
        ON t.id = im.type_id

    JOIN signalements s
        ON s.inventaires_mobiliers_id = im.id

    JOIN staging.fournisseur_inventaire fi
        ON fi.id_inventaire = im.id

    JOIN fournisseurs_de_contact fc
        ON LOWER(TRIM(fc.entreprise)) = LOWER(TRIM(fi.entreprise))

    WHERE LOWER(TRIM(i.objet)) = LOWER(
        CASE
            WHEN t.libelle = 'banc'
                THEN 'banc ' || im.lieu

            WHEN t.libelle = 'poubelle'
                THEN 'poubelle ' || im.lieu

            WHEN t.libelle = 'fontaine'
                THEN 'fontaine ' || im.lieu

            WHEN t.libelle = 'lampadaire'
                THEN 'lampadaire ' || im.lieu

            WHEN t.libelle = 'borne'
                THEN 'borne ev ' || im.lieu

            WHEN t.libelle = 'panneau'
                THEN 'panneau ' || im.lieu

            ELSE im.lieu
        END
    )
)

INSERT INTO interventions (
    date,
    fournisseur_de_contact_id,
    signalement_id,
    type_intervention_id,
    technicien,
    duree,
    cout_materiel,
    remarque,
    inventaire_mobilier_id
)
SELECT
    CASE
        WHEN TRIM(date) LIKE '____-__-__'
            THEN TO_DATE(TRIM(date), 'YYYY-MM-DD')
        WHEN TRIM(date) LIKE '__.__.____'
            THEN TO_DATE(TRIM(date), 'DD.MM.YYYY')
        ELSE NULL
    END,

    fournisseur_de_contact_id,

    signalement_id,

    ti.id,

    CASE
        WHEN LOWER(TRIM(technicien)) IN ('jm', 'jean-marc', 'jean-marc bonvin')
            THEN 'Jean-Marc Bonvin'
        WHEN LOWER(TRIM(technicien)) IN ('pedro', 'p. alves', 'alves pedro')
            THEN 'Alves Pedro'
        ELSE TRIM(technicien)
    END,

    CASE
        WHEN LOWER(TRIM(duree)) = '30 min' THEN '30 minutes'
        WHEN LOWER(TRIM(duree)) = '1h' THEN '60 minutes'
        WHEN LOWER(TRIM(duree)) = '1h30' THEN '90 minutes'
        WHEN LOWER(TRIM(duree)) = '2h' THEN '120 minutes'
        WHEN LOWER(TRIM(duree)) = '3h' THEN '180 minutes'
        WHEN LOWER(TRIM(duree)) = 'une matinée' THEN '240 minutes'
        WHEN LOWER(TRIM(duree)) = 'une journée' THEN '480 minutes'
        ELSE TRIM(duree)
    END,

    NULLIF(
        REGEXP_REPLACE(cout_materiel, '[^0-9]', '', 'g'),
        ''
    )::NUMERIC,

    NULLIF(TRIM(remarques), ''),

    inventaire_mobilier_id

FROM correspondances c

JOIN types_interventions ti
    ON LOWER(TRIM(ti.libelle)) = LOWER(TRIM(c.type_intervention))

WHERE rn = 1;
-- VERIFICATION
SELECT 'types' AS table_nom, COUNT(*) FROM types
UNION ALL
SELECT 'materiaux', COUNT(*) FROM materiaux
UNION ALL
SELECT 'etats', COUNT(*) FROM etats
UNION ALL
SELECT 'quartiers', COUNT(*) FROM quartiers
UNION ALL
SELECT 'statuts', COUNT(*) FROM statuts
UNION ALL
SELECT 'types_interventions', COUNT(*) FROM types_interventions
UNION ALL
SELECT 'types_materiels', COUNT(*) FROM types_materiels
UNION ALL
SELECT 'fournisseurs_de_contact', COUNT(*) FROM fournisseurs_de_contact
UNION ALL
SELECT 'inventaires_mobiliers', COUNT(*) FROM inventaires_mobiliers
UNION ALL
SELECT 'signalements', COUNT(*) FROM signalements
UNION ALL
SELECT 'interventions', COUNT(*) FROM interventions;







SELECT
    i.id,
    im.id AS mobilier,
    t.libelle AS type,
    fc.entreprise,
    ti.libelle AS intervention,
    s.description
FROM interventions i
JOIN inventaires_mobiliers im
    ON i.inventaire_mobilier_id = im.id
JOIN types t
    ON im.type_id = t.id
JOIN fournisseurs_de_contact fc
    ON i.fournisseur_de_contact_id = fc.id
JOIN types_interventions ti
    ON i.type_intervention_id = ti.id
JOIN signalements s
    ON i.signalement_id = s.id
LIMIT 20;

SELECT *
FROM staging.interventions i
WHERE NOT EXISTS (
    SELECT 1
    FROM inventaires_mobiliers im
    JOIN types t ON t.id = im.type_id
    WHERE LOWER(TRIM(i.objet)) = LOWER(TRIM(t.libelle || ' ' || im.lieu))
);