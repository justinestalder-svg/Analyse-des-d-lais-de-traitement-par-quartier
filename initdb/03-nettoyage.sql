-- ===========================================================
-- 03-IMPORT-ET-NETTOYAGE.SQL
-- ===========================================================
TRUNCATE TABLE staging.inventaire_mobilier;
TRUNCATE TABLE staging.interventions;
TRUNCATE TABLE staging.signalements;
TRUNCATE TABLE staging.fournisseurs_contacts;

COPY staging.inventaire_mobilier
FROM '/data/inventaire_mobilier.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ';', ENCODING 'UTF8');

COPY staging.interventions
FROM '/data/interventions.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ';', ENCODING 'UTF8');

COPY staging.signalements
FROM '/data/signalements.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ';', ENCODING 'UTF8');

COPY staging.fournisseurs_contacts
FROM '/data/fournisseurs_contacts.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ';', ENCODING 'UTF8');

TRUNCATE TABLE public.interventions RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.signalements RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.fournisseurs_contacts RESTART IDENTITY CASCADE;
TRUNCATE TABLE public.inventaire_mobilier CASCADE;


-- ===========================================================
-- INVENTAIRE MOBILIER
-- ===========================================================
INSERT INTO public.inventaire_mobilier (
    id,
    type,
    materiau,
    lieu,
    latitude,
    longitude,
    date_installation,
    etat,
    remarques
)
SELECT DISTINCT ON (TRIM(id))
    TRIM(id),

    CASE
        WHEN LOWER(TRIM(type)) IN ('banc', 'banc public') THEN 'banc'
        WHEN LOWER(TRIM(type)) IN ('lampadaire', 'lampadaire led', 'lampadaire sodium') THEN 'lampadaire'
        WHEN LOWER(TRIM(type)) IN ('poubelle', 'corbeille', 'poubelle tri') THEN 'poubelle'
        WHEN LOWER(TRIM(type)) IN ('fontaine', 'fontaine publique') THEN 'fontaine'
        WHEN LOWER(TRIM(type)) IN ('borne ev', 'borne recharge', 'borne recharge ev', 'borne_ev', 'borne') THEN 'borne'
        WHEN LOWER(TRIM(type)) IN ('panneau', 'panneau info', 'panneau affichage') THEN 'panneau'
        ELSE LOWER(TRIM(type))
    END AS type,

    CASE
        WHEN materiau IS NULL OR TRIM(materiau) = '' THEN 'inconnu'
        WHEN LOWER(TRIM(materiau)) IN ('metal', 'métal') THEN 'métal'
        WHEN LOWER(TRIM(materiau)) IN ('beton', 'béton') THEN 'béton'
        WHEN LOWER(TRIM(materiau)) IN ('bois traite', 'bois traité') THEN 'bois traité'
        WHEN LOWER(TRIM(materiau)) IN ('plastique recycle', 'plastique recyclé') THEN 'plastique recyclé'
        WHEN LOWER(TRIM(materiau)) IN ('led', 'sodium') THEN LOWER(TRIM(materiau))
        ELSE LOWER(TRIM(materiau))
    END AS materiau,

    CASE
        WHEN LOWER(TRIM(lieu)) IN ('heig-vd', 'heig vd') THEN 'HEIG-VD'
        WHEN LOWER(TRIM(lieu)) IN ('y-parc', 'y parc') THEN 'Y-Parc'
        ELSE INITCAP(TRIM(lieu))
    END AS lieu,

    CASE
        WHEN latitude IS NULL OR TRIM(latitude) = '' THEN NULL
        WHEN REPLACE(TRIM(latitude), ',', '.') ~ '^-?[0-9]+(\.[0-9]+)?$'
            THEN REPLACE(TRIM(latitude), ',', '.')::NUMERIC(10,8)
        ELSE NULL
    END AS latitude,

    CASE
        WHEN longitude IS NULL OR TRIM(longitude) = '' THEN NULL
        WHEN REPLACE(TRIM(longitude), ',', '.') ~ '^-?[0-9]+(\.[0-9]+)?$'
            THEN REPLACE(TRIM(longitude), ',', '.')::NUMERIC(11,8)
        ELSE NULL
    END AS longitude,

    CASE
        WHEN date_installation IS NULL OR TRIM(date_installation) = '' THEN NULL
        WHEN TRIM(date_installation) LIKE '%.%.%' THEN TO_DATE(TRIM(date_installation), 'DD.MM.YYYY')
        WHEN TRIM(date_installation) LIKE '____-__-__' THEN TO_DATE(TRIM(date_installation), 'YYYY-MM-DD')
        WHEN TRIM(date_installation) ~ '^\d{4}$' THEN TO_DATE(TRIM(date_installation) || '-01-01', 'YYYY-MM-DD')
        ELSE NULL
    END AS date_installation,

    CASE
        WHEN etat IS NULL OR TRIM(etat) = '' THEN 'bon'
        WHEN LOWER(TRIM(etat)) IN ('bon', 'bon état', 'correct') THEN 'bon'
        WHEN LOWER(TRIM(etat)) IN ('moyen', 'usé', 'use') THEN 'moyen'
        WHEN LOWER(TRIM(etat)) IN ('mauvais', 'abime', 'abîmé', 'à remplacer', 'a remplacer') THEN 'mauvais'
        ELSE LOWER(TRIM(etat))
    END AS etat,

    CASE
        WHEN remarques IS NULL OR TRIM(remarques) = '' THEN NULL
        WHEN LOWER(TRIM(remarques)) = '22kw' THEN '22 kW'
        WHEN LOWER(TRIM(remarques)) = '50kw rapide' THEN '50 kW rapide'
        WHEN LOWER(TRIM(remarques)) = 'offert par le lions club' THEN 'offert par le Lions Club'
        WHEN LOWER(TRIM(remarques)) = 'face au lac' THEN 'Face au lac'
        WHEN LOWER(TRIM(remarques)) = 'sous un arbre' THEN 'Sous un arbre'
        WHEN LOWER(TRIM(remarques)) = 'eau potable' THEN 'Eau potable'
        WHEN LOWER(TRIM(remarques)) = 'historique' THEN 'Historique'
        WHEN LOWER(TRIM(remarques)) = 'plaque commémorative' THEN 'Plaque commémorative'
        WHEN LOWER(TRIM(remarques)) = 'double tête' THEN 'Double tête'
        WHEN LOWER(TRIM(remarques)) = 'éclairage passage piéton' THEN 'Éclairage passage piéton'
        WHEN LOWER(TRIM(remarques)) = 'mât 6m' THEN 'Mât 6 m'
        ELSE INITCAP(TRIM(remarques))
    END AS remarques

FROM staging.inventaire_mobilier
WHERE id IS NOT NULL
  AND TRIM(id) <> ''
ORDER BY TRIM(id)
ON CONFLICT (id) DO NOTHING;

-- ===========================================================
-- INTERVENTIONS
-- ===========================================================

INSERT INTO public.interventions (
    date,
    objet,
    type_intervention,
    technicien,
    duree_heures,
    cout_materiel,
    remarques,
    lieu,
    priorite
)
SELECT
    CASE
        WHEN date IS NULL OR TRIM(date) = '' THEN NULL
        WHEN TRIM(date) LIKE '%.%.%' THEN TO_DATE(TRIM(date), 'DD.MM.YYYY')
        WHEN TRIM(date) LIKE '____-__-__' THEN TO_DATE(TRIM(date), 'YYYY-MM-DD')
        ELSE NULL
    END AS date,

    CASE
        WHEN LOWER(TRIM(objet)) ~ '^(banc public|banc)' THEN 'banc'
        WHEN LOWER(TRIM(objet)) ~ '^(lampadaire led|lampadaire sodium|lampadaire)' THEN 'lampadaire'
        WHEN LOWER(TRIM(objet)) ~ '^(poubelle tri|poubelle|corbeille)' THEN 'poubelle'
        WHEN LOWER(TRIM(objet)) ~ '^(fontaine publique|fontaine)' THEN 'fontaine'
        WHEN LOWER(TRIM(objet)) ~ '^(panneau info|panneau affichage|panneau)' THEN 'panneau'
        WHEN LOWER(TRIM(objet)) ~ '^(borne ev|borne recharge|borne)' THEN 'borne'
        ELSE LOWER(TRIM(objet))
    END AS objet,

    CASE
        WHEN LOWER(TRIM(type_intervention)) LIKE '%remplacement%' THEN 'remplacement'
        WHEN LOWER(TRIM(type_intervention)) LIKE '%réparation%' OR LOWER(TRIM(type_intervention)) LIKE '%reparation%' THEN 'réparation'
        WHEN LOWER(TRIM(type_intervention)) LIKE '%nettoyage%' THEN 'nettoyage'
        WHEN LOWER(TRIM(type_intervention)) LIKE '%peinture%' THEN 'peinture'
        WHEN LOWER(TRIM(type_intervention)) LIKE '%hivernage%' THEN 'maintenance'
        WHEN LOWER(TRIM(type_intervention)) LIKE '%détartrage%' OR LOWER(TRIM(type_intervention)) LIKE '%detartrage%' THEN 'maintenance'
        WHEN LOWER(TRIM(type_intervention)) LIKE '%remise en service%' THEN 'maintenance'
        WHEN LOWER(TRIM(type_intervention)) LIKE '%redressage%' THEN 'réparation'
        ELSE LOWER(TRIM(type_intervention))
    END AS type_intervention,

    CASE
        WHEN LOWER(TRIM(technicien)) IN ('jm', 'jean-marc', 'jean marc') THEN 'Jean-Marc Bonvin'
        WHEN LOWER(TRIM(technicien)) IN ('p. alves', 'pedro', 'alves', 'alves pedro') THEN 'Alves Pedro'
        WHEN LOWER(TRIM(technicien)) IN ('koffi marc', 'marc koffi') THEN 'Koffi Marc'
        WHEN LOWER(TRIM(technicien)) = 'stagiaire' THEN 'Stagiaire'
        ELSE INITCAP(TRIM(technicien))
    END AS technicien,

    CASE
        WHEN duree IS NULL OR TRIM(duree) = '' THEN NULL
        WHEN LOWER(TRIM(duree)) = '30 min' THEN 0.5
        WHEN LOWER(TRIM(duree)) = '1h' THEN 1.0
        WHEN LOWER(TRIM(duree)) = '1h30' THEN 1.5
        WHEN LOWER(TRIM(duree)) = '2h' THEN 2.0
        WHEN LOWER(TRIM(duree)) = '3h' THEN 3.0
        WHEN LOWER(TRIM(duree)) = '4h' THEN 4.0
        WHEN LOWER(TRIM(duree)) = 'une matinée' THEN 4.0
        WHEN LOWER(TRIM(duree)) = 'une journée' THEN 8.0
        WHEN REPLACE(TRIM(duree), ',', '.') ~ '^[0-9]+(\.[0-9]+)?$'
            THEN REPLACE(TRIM(duree), ',', '.')::NUMERIC(5,1)
        ELSE NULL
    END AS duree_heures,

    CASE
        WHEN cout_materiel IS NULL OR TRIM(cout_materiel) = '' THEN
            CASE
                WHEN LOWER(TRIM(remarques)) LIKE '%garantie%' THEN 0
                ELSE NULL
            END
        WHEN LOWER(TRIM(cout_materiel)) = 'gratuit' THEN 0
        WHEN REPLACE(REGEXP_REPLACE(TRIM(cout_materiel), '[^0-9,\.]', '', 'g'), ',', '.') ~ '^[0-9]+(\.[0-9]+)?$'
            THEN REPLACE(REGEXP_REPLACE(TRIM(cout_materiel), '[^0-9,\.]', '', 'g'), ',', '.')::DECIMAL(10,2)
        ELSE NULL
    END AS cout_materiel,

    CASE
        WHEN remarques IS NULL OR TRIM(remarques) = '' THEN NULL
        WHEN LOWER(TRIM(remarques)) IN ('piece commandee', 'pièce commandée') THEN 'Pièce commandée'
        WHEN LOWER(TRIM(remarques)) IN ('piece spéciale commandée', 'pièce spéciale commandée') THEN 'Pièce spéciale commandée'
        WHEN LOWER(TRIM(remarques)) = 'garantie fournisseur' THEN 'Garantie fournisseur'
        WHEN LOWER(TRIM(remarques)) = 'à surveiller' THEN 'À surveiller'
        WHEN LOWER(TRIM(remarques)) = 'plombier externe' THEN 'Plombier externe'
        WHEN LOWER(TRIM(remarques)) = 'latte fendue' THEN 'Latte fendue'
        WHEN LOWER(TRIM(remarques)) = 'bois humide' THEN 'Bois humide'
        ELSE INITCAP(TRIM(remarques))
    END AS remarques,

    CASE
        WHEN LOWER(TRIM(
            REGEXP_REPLACE(
                objet,
                '^(banc public|banc|lampadaire led|lampadaire sodium|lampadaire|poubelle tri|poubelle|corbeille|fontaine publique|fontaine|panneau info|panneau affichage|panneau|borne ev|borne recharge|borne)\s+',
                '',
                'i'
            )
        )) IN ('heig-vd', 'heig vd') THEN 'HEIG-VD'

        WHEN LOWER(TRIM(
            REGEXP_REPLACE(
                objet,
                '^(banc public|banc|lampadaire led|lampadaire sodium|lampadaire|poubelle tri|poubelle|corbeille|fontaine publique|fontaine|panneau info|panneau affichage|panneau|borne ev|borne recharge|borne)\s+',
                '',
                'i'
            )
        )) IN ('y-parc', 'y parc') THEN 'Y-Parc'

        ELSE INITCAP(
            TRIM(
                REGEXP_REPLACE(
                    objet,
                    '^(banc public|banc|lampadaire led|lampadaire sodium|lampadaire|poubelle tri|poubelle|corbeille|fontaine publique|fontaine|panneau info|panneau affichage|panneau|borne ev|borne recharge|borne)\s+',
                    '',
                    'i'
                )
            )
        )
    END AS lieu,

    CASE
        WHEN LOWER(TRIM(type_intervention)) LIKE '%remplacement complet%' THEN 'haute'
        WHEN LOWER(TRIM(type_intervention)) LIKE '%réparation électrique%' OR LOWER(TRIM(type_intervention)) LIKE '%reparation electrique%' THEN 'haute'
        WHEN LOWER(TRIM(type_intervention)) LIKE '%remplacement pompe%' THEN 'haute'
        WHEN LOWER(TRIM(type_intervention)) LIKE '%réparation fuite%' OR LOWER(TRIM(type_intervention)) LIKE '%reparation fuite%' THEN 'haute'
        WHEN LOWER(TRIM(type_intervention)) LIKE '%nettoyage%' THEN 'basse'
        WHEN LOWER(TRIM(type_intervention)) LIKE '%peinture%' THEN 'basse'
        ELSE 'normale'
    END AS priorite

FROM staging.interventions
WHERE objet IS NOT NULL
  AND TRIM(objet) <> '';
-- ===========================================================
-- SIGNALEMENTS
-- ===========================================================
INSERT INTO public.signalements (
    date,
    signale_par,
    objet,
    description,
    urgence,
    statut,
    lieu
)
SELECT
    CASE
        WHEN date IS NULL OR TRIM(date) = '' THEN NULL
        WHEN TRIM(date) LIKE '%.%.%' THEN TO_DATE(TRIM(date), 'DD.MM.YYYY')
        WHEN TRIM(date) LIKE '____-__-__' THEN TO_DATE(TRIM(date), 'YYYY-MM-DD')
        ELSE NULL
    END AS date,

    CASE
        WHEN signale_par IS NULL OR TRIM(signale_par) = '' THEN 'Non Renseigné'
        WHEN LOWER(TRIM(signale_par)) IN ('un habitant', 'habitant du quartier') THEN 'Habitant'
        WHEN LOWER(TRIM(signale_par)) = 'email citoyen' THEN 'Citoyen'
        WHEN LOWER(TRIM(signale_par)) = 'patrouille jm' THEN 'Patrouille JM'
        WHEN LOWER(TRIM(signale_par)) = 'un passant' THEN 'Passant'
        ELSE INITCAP(TRIM(signale_par))
    END AS signale_par,

    CASE
        WHEN LOWER(TRIM(objet)) ~ '^(le |la |l'' )?(banc public|banc)' THEN 'banc'
        WHEN LOWER(TRIM(objet)) ~ '^(le |la |l'' )?(lampadaire led|lampadaire sodium|lampadaire)' THEN 'lampadaire'
        WHEN LOWER(TRIM(objet)) ~ '^(le |la |l'' )?(poubelle tri|poubelle|corbeille)' THEN 'poubelle'
        WHEN LOWER(TRIM(objet)) ~ '^(le |la |l'' )?(fontaine publique|fontaine)' THEN 'fontaine'
        WHEN LOWER(TRIM(objet)) ~ '^(le |la |l'' )?(panneau info|panneau affichage|panneau)' THEN 'panneau'
        WHEN LOWER(TRIM(objet)) ~ '^(le |la |l'' )?(borne ev|borne recharge|borne)' THEN 'borne'
        ELSE LOWER(TRIM(objet))
    END AS objet,

    CASE
        WHEN description IS NULL OR TRIM(description) = '' THEN NULL
        WHEN LOWER(TRIM(description)) IN ('tags', 'tags / graffitis', 'tags/graffitis') THEN 'Graffitis'
        WHEN LOWER(TRIM(description)) = 'éclaire mal' THEN 'Mauvais éclairage'
        WHEN LOWER(TRIM(description)) LIKE 'clignote%' THEN 'Clignotement'
        WHEN LOWER(TRIM(description)) = 'ampoule grillée' THEN 'Ampoule grillée'
        WHEN LOWER(TRIM(description)) = 'vitre cassée' THEN 'Vitre cassée'
        WHEN LOWER(TRIM(description)) = 'vitrine cassée' THEN 'Vitrine cassée'
        WHEN LOWER(TRIM(description)) = 'bois pourri côté gauche' THEN 'Bois pourri'
        WHEN LOWER(TRIM(description)) = 'bois pourri' THEN 'Bois pourri'
        WHEN LOWER(TRIM(description)) = 'un pied est tordu' THEN 'Pied tordu'
        WHEN LOWER(TRIM(description)) = 'pied tordu' THEN 'Pied tordu'
        WHEN LOWER(TRIM(description)) = 'mousse/algues' THEN 'Mousse / algues'
        WHEN LOWER(TRIM(description)) = 'câble manquant' THEN 'Câble manquant'
        WHEN LOWER(TRIM(description)) = 'écran cassé' THEN 'Écran cassé'
        WHEN LOWER(TRIM(description)) = 'ne charge plus' THEN 'Ne charge plus'
        WHEN LOWER(TRIM(description)) = 'ne coule plus' THEN 'Ne coule plus'
        WHEN LOWER(TRIM(description)) = 'ne s''allume plus' THEN 'Ne s''allume plus'
        WHEN LOWER(TRIM(description)) = 'mât penché après la tempête' THEN 'Mât penché après la tempête'
        WHEN LOWER(TRIM(description)) = 'vis qui dépassent' THEN 'Vis qui dépassent'
        WHEN LOWER(TRIM(description)) = 'le dossier est fendu' THEN 'Dossier fendu'
        WHEN LOWER(TRIM(description)) = 'lattes cassées' THEN 'Lattes cassées'
        WHEN LOWER(TRIM(description)) = 'affichage décollé' THEN 'Affichage décollé'
        WHEN LOWER(TRIM(description)) = 'gel a abîmé la tuyauterie' THEN 'Gel a abîmé la tuyauterie'
        WHEN LOWER(TRIM(description)) = 'déborde régulièrement' THEN 'Déborde régulièrement'
        WHEN LOWER(TRIM(description)) = 'couvercle cassé' THEN 'Couvercle cassé'
        WHEN LOWER(TRIM(description)) = 'fuit au sol' THEN 'Fuit au sol'
        WHEN LOWER(TRIM(description)) = 'brûlée' THEN 'Brûlée'
        WHEN LOWER(TRIM(description)) = 'renversée' THEN 'Renversée'
        WHEN LOWER(TRIM(description)) = 'penché' THEN 'Penché'
        ELSE INITCAP(TRIM(description))
    END AS description,

    CASE
        WHEN urgence IS NULL OR TRIM(urgence) = '' THEN 'normale'
        WHEN LOWER(TRIM(urgence)) IN ('urgent', 'haute', 'élevée', 'elevee') THEN 'haute'
        WHEN LOWER(TRIM(urgence)) IN ('normal', 'normale', 'moyenne') THEN 'normale'
        WHEN LOWER(TRIM(urgence)) IN ('basse', 'faible') THEN 'basse'
        ELSE LOWER(TRIM(urgence))
    END AS urgence,

    CASE
        WHEN statut IS NULL OR TRIM(statut) = '' THEN 'en attente'
        WHEN LOWER(TRIM(statut)) IN ('fait', 'résolu', 'resolu', 'fermé', 'ferme') THEN 'résolu'
        WHEN LOWER(TRIM(statut)) = 'en cours' THEN 'en cours'
        WHEN LOWER(TRIM(statut)) IN ('ouvert', 'en attente') THEN 'en attente'
        ELSE LOWER(TRIM(statut))
    END AS statut,

    CASE
        WHEN LOWER(
            TRIM(
                REGEXP_REPLACE(
                    REGEXP_REPLACE(
                        REGEXP_REPLACE(
                            objet,
                            '^(le |la |l'' )?(banc public|banc|lampadaire led|lampadaire sodium|lampadaire|poubelle tri|poubelle|corbeille|fontaine publique|fontaine|panneau info|panneau affichage|panneau|borne ev|borne recharge|borne)\s+',
                            '',
                            'i'
                        ),
                        '^(près de |devant |ev près de |ev devant |ev )',
                        '',
                        'i'
                    ),
                    'garre',
                    'gare',
                    'i'
                )
            )
        ) IN ('heig-vd', 'heig vd') THEN 'HEIG-VD'

        WHEN LOWER(
            TRIM(
                REGEXP_REPLACE(
                    REGEXP_REPLACE(
                        REGEXP_REPLACE(
                            objet,
                            '^(le |la |l'' )?(banc public|banc|lampadaire led|lampadaire sodium|lampadaire|poubelle tri|poubelle|corbeille|fontaine publique|fontaine|panneau info|panneau affichage|panneau|borne ev|borne recharge|borne)\s+',
                            '',
                            'i'
                        ),
                        '^(près de |devant |ev près de |ev devant |ev )',
                        '',
                        'i'
                    ),
                    'garre',
                    'gare',
                    'i'
                )
            )
        ) IN ('y-parc', 'y parc') THEN 'Y-Parc'

        ELSE INITCAP(
            TRIM(
                REGEXP_REPLACE(
                    REGEXP_REPLACE(
                        REGEXP_REPLACE(
                            objet,
                            '^(le |la |l'' )?(banc public|banc|lampadaire led|lampadaire sodium|lampadaire|poubelle tri|poubelle|corbeille|fontaine publique|fontaine|panneau info|panneau affichage|panneau|borne ev|borne recharge|borne)\s+',
                            '',
                            'i'
                        ),
                        '^(près de |devant |ev près de |ev devant |ev )',
                        '',
                        'i'
                    ),
                    'garre',
                    'gare',
                    'i'
                )
            )
        )
    END AS lieu

FROM staging.signalements
WHERE objet IS NOT NULL
  AND TRIM(objet) <> '';

-- ===========================================================
-- 4. FOURNISSEURS CONTACTS
-- ===========================================================
INSERT INTO public.fournisseurs_contacts (
    entreprise,
    contact,
    telephone,
    email,
    type_materiel,
    remarques
)
SELECT DISTINCT ON (LOWER(TRIM(entreprise)))

    CASE
        WHEN LOWER(TRIM(entreprise)) = 'abb suisse' THEN 'ABB Suisse'
        ELSE REPLACE(
                REPLACE(
                    REPLACE(
                        INITCAP(TRIM(entreprise)),
                        ' Sa',
                        ' SA'
                    ),
                    ' Ag',
                    ' AG'
                ),
                ' Gmbh',
                ' GmbH'
             )
    END AS entreprise,

    CASE
        WHEN contact IS NULL OR TRIM(contact) = '' THEN NULL
        WHEN LOWER(TRIM(contact)) = 'voir site web' THEN NULL
        ELSE INITCAP(TRIM(contact))
    END AS contact,

    CASE
        WHEN telephone IS NULL OR TRIM(telephone) = '' THEN NULL
        WHEN REGEXP_REPLACE(telephone, '[^0-9]', '', 'g') LIKE '41%'
            THEN '0' || SUBSTRING(REGEXP_REPLACE(telephone, '[^0-9]', '', 'g') FROM 3)
        ELSE REGEXP_REPLACE(telephone, '[^0-9]', '', 'g')
    END AS telephone,

    CASE
        WHEN email IS NULL OR TRIM(email) = '' THEN NULL
        WHEN LOWER(TRIM(email)) ~ '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$'
            THEN LOWER(TRIM(email))
        ELSE NULL
    END AS email,

    CASE
        WHEN type_materiel IS NULL OR TRIM(type_materiel) = ''
            THEN 'non renseigné'

        WHEN LOWER(TRIM(type_materiel)) LIKE '%banc%'
            THEN 'bancs'

        WHEN LOWER(TRIM(type_materiel)) LIKE '%poubelle%'
            THEN 'poubelles'

        WHEN LOWER(TRIM(type_materiel)) LIKE '%lampadaire%'
          OR LOWER(TRIM(type_materiel)) LIKE '%éclairage%'
          OR LOWER(TRIM(type_materiel)) LIKE '%eclairage%'
            THEN 'éclairage'

        WHEN LOWER(TRIM(type_materiel)) LIKE '%fontaine%'
            THEN 'fontaines'

        WHEN LOWER(TRIM(type_materiel)) LIKE '%borne%'
            THEN 'bornes'

        WHEN LOWER(TRIM(type_materiel)) LIKE '%panneau%'
            THEN 'panneaux'

        WHEN LOWER(TRIM(type_materiel)) LIKE '%abri%'
            THEN 'abris bus'

        WHEN LOWER(TRIM(type_materiel)) LIKE '%tag%'
          OR LOWER(TRIM(type_materiel)) LIKE '%nettoyage%'
            THEN 'nettoyage tags'

        WHEN LOWER(TRIM(type_materiel)) LIKE '%plantation%'
          OR LOWER(TRIM(type_materiel)) LIKE '%paysage%'
            THEN 'aménagement paysager'

        WHEN LOWER(TRIM(type_materiel)) LIKE '%reprise ancien mobilier%'
          OR LOWER(TRIM(type_materiel)) LIKE '%récupération%'
          OR LOWER(TRIM(type_materiel)) LIKE '%recuperation%'
            THEN 'recyclage mobilier'

        ELSE LOWER(TRIM(type_materiel))
    END AS type_materiel,

    CASE
        WHEN remarques IS NULL OR TRIM(remarques) = '' THEN NULL

        WHEN LOWER(TRIM(remarques)) = 'grands projets uniquement'
            THEN 'Grands projets uniquement'

        WHEN LOWER(TRIM(remarques)) = 'pas notre domaine direct'
            THEN 'Pas notre domaine direct'

        WHEN LOWER(TRIM(remarques)) = 'bon fournisseur, délai 2 sem.'
            THEN 'Bon fournisseur, délai 2 sem.'

        WHEN LOWER(TRIM(remarques)) = 'artisan, travail soigné mais cher'
            THEN 'Artisan, travail soigné mais cher'

        WHEN LOWER(TRIM(remarques)) = 'contrat maintenance inclus'
            THEN 'Contrat maintenance inclus'

        WHEN LOWER(TRIM(remarques)) = 'fermé depuis mars 2025'
            THEN 'Fermé depuis mars 2025'

        WHEN LOWER(TRIM(remarques)) = 'rapide pour les urgences'
            THEN 'Rapide pour les urgences'

        WHEN LOWER(TRIM(remarques)) = 'pour les urgences'
            THEN 'Pour les urgences'

        WHEN LOWER(TRIM(remarques)) = 'payent au kilo'
            THEN 'Payent au kilo'

        WHEN LOWER(TRIM(remarques)) = 'contrat annuel chf 8000.-'
            THEN 'Contrat annuel CHF 8000.-'

        WHEN LOWER(TRIM(remarques)) = 'germanophone'
            THEN 'Germanophone uniquement'

        ELSE REPLACE(
                INITCAP(TRIM(remarques)),
                'Chf',
                'CHF'
             )
    END AS remarques

FROM staging.fournisseurs_contacts

WHERE entreprise IS NOT NULL
  AND TRIM(entreprise) <> ''

ORDER BY LOWER(TRIM(entreprise))

ON CONFLICT (entreprise) DO NOTHING;
-- ===========================================================
-- VÉRIFICATION PUBLIC
-- ===========================================================

SELECT 'public inventaire' AS table_nom, COUNT(*) FROM public.inventaire_mobilier
UNION ALL
SELECT 'public interventions', COUNT(*) FROM public.interventions
UNION ALL
SELECT 'public signalements', COUNT(*) FROM public.signalements
UNION ALL
SELECT 'public fournisseurs', COUNT(*) FROM public.fournisseurs_contacts;