-- ===========================================================
-- BRIEF B
-- Analyse des délais de traitement par quartier
-- Gestion Mobilier Urbain Yverdon-les-Bains
-- ===========================================================

-- ===========================================================
-- LIVRABLE 1
-- Délai moyen et médian par quartier
-- ===========================================================
CREATE OR REPLACE VIEW v_delai_par_quartier AS
SELECT
    q.nom AS quartier,

    COUNT(DISTINCT s.id) AS nombre_signalements,

    COUNT(DISTINCT i.id) AS nombre_interventions,

    ROUND(
        AVG(i.date - s.date),
        2
    ) AS delai_moyen_jours,

    PERCENTILE_CONT(0.5) WITHIN GROUP (
        ORDER BY i.date - s.date
    ) AS delai_median_jours

FROM signalements s

JOIN inventaires_mobiliers im
    ON im.id = s.inventaires_mobiliers_id

JOIN quartiers q
    ON q.id = im.quartier_id

LEFT JOIN interventions i
    ON i.signalement_id = s.id
   AND i.date >= s.date

GROUP BY q.nom

ORDER BY delai_moyen_jours DESC NULLS LAST;

SELECT *
FROM v_delai_par_quartier;

-- ===========================================================
-- LIVRABLE 2
-- Signalements ouverts depuis plus de 30 jours
-- ===========================================================

CREATE OR REPLACE VIEW v_signalements_ouverts AS
SELECT
    s.date AS date_signalement,
    im.id AS objet_concerne,
    s.description,
    im.latitude,
    im.longitude,
    q.nom AS quartier,
    st.libelle AS statut

FROM signalements s

JOIN statuts st
    ON st.id = s.statut_id

JOIN inventaires_mobiliers im
    ON im.id = s.inventaires_mobiliers_id

JOIN quartiers q
    ON q.id = im.quartier_id

WHERE st.libelle IN ('en attente', 'en cours')
  AND s.date < CURRENT_DATE - INTERVAL '30 days'

ORDER BY s.date ASC;

SELECT *
FROM v_signalements_ouverts;

-- ===========================================================
-- LIVRABLE 3
-- Taux de résolution par trimestre
-- ===========================================================

CREATE OR REPLACE VIEW v_taux_resolution AS
SELECT
    EXTRACT(YEAR FROM s.date)::INT AS annee,
    CONCAT('Q', EXTRACT(QUARTER FROM s.date)::INT) AS trimestre,

    COUNT(*) AS nombre_total_signalements,

    COUNT(*) FILTER (
        WHERE st.libelle = 'résolu'
    ) AS nombre_signalements_resolus,

    ROUND(
        COUNT(*) FILTER (WHERE st.libelle = 'résolu') * 100.0
        / COUNT(*),
        2
    ) AS taux_resolution_pourcent

FROM signalements s

JOIN statuts st
    ON st.id = s.statut_id

GROUP BY
    EXTRACT(YEAR FROM s.date),
    EXTRACT(QUARTER FROM s.date)

ORDER BY
    annee,
    trimestre;

SELECT
    annee,
    trimestre,
    nombre_total_signalements,
    nombre_signalements_resolus,
    taux_resolution_pourcent
FROM v_taux_resolution;

-- ===========================================================
-- INTERPRÉTATION DES RÉSULTATS
-- ===========================================================
/*
LIVRABLE 1 — Délais par quartier

Les délais de traitement varient fortement d'un quartier à l'autre.
Maillefer affiche le délai moyen le plus élevé avec environ 414 jours,
suivi de Perreux (380 jours) et du Centre-Ville (263 jours). Les quartiers
Rives (218 jours) et Les Bains (207 jours) sont les mieux traités.

Le délai médian est particulièrement utile ici : à Perreux, la médiane
(440 jours) dépasse la moyenne, ce qui indique que plus de la moitié des
signalements attendent plus d'un an avant intervention — la situation y est
donc encore plus grave que la moyenne ne le laisse paraître.

Concernant la plainte spécifique sur le quartier de la Gare, ce quartier
ne ressort pas comme le plus problématique en termes de délais bruts, mais
le Centre-Ville (qui inclut la zone Gare) concentre à lui seul la majorité
des signalements (126 sur 203), ce qui peut expliquer un sentiment de lenteur
chez les habitants malgré un délai moyen plus modéré.

LIVRABLE 2 — Signalements ouverts

128 signalements sont actuellement ouverts (statut "en attente" ou "en cours")
depuis plus de 30 jours. Cela représente plus de 60 % du total des signalements,
ce qui révèle un retard structurel important dans le traitement des demandes.
Ces signalements non traités concernent tous les quartiers et tous types de
mobilier. Une priorisation par quartier et par type de mobilier serait
recommandée pour résorber ce stock.

LIVRABLE 3 — Taux de résolution par trimestre

Le taux de résolution est globalement faible et irrégulier. Les meilleurs
trimestres sont Q3 2022 (100 %, mais seulement 2 signalements) et Q4 2022
(75 %). À partir de 2023, avec l'augmentation du volume de signalements, le
taux oscille entre 23 % et 50 %. Les trimestres récents (2025) montrent une
tendance à la baisse, autour de 26-31 %, ce qui suggère que les équipes
peinent à absorber le volume croissant de demandes. Une révision des ressources
disponibles ou des priorités d'intervention semble nécessaire.
*/