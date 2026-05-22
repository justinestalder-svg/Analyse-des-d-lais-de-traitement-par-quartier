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

ORDER BY delai_moyen_jours DESC;

SELECT *
FROM v_delai_par_quartier;
-- ===========================================================
-- LIVRABLE 2
-- Signalements ouverts depuis plus de 30 jours
-- ===========================================================

DROP VIEW IF EXISTS v_signalements_ouverts;
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

SELECT COUNT(DISTINCT signalement_id)

    AS signalements_avec_intervention

FROM interventions;

SELECT COUNT(*) AS signalements_sans_intervention

FROM signalements s

LEFT JOIN interventions i

    ON i.signalement_id = s.id

WHERE i.id IS NULL;

-- ===========================================================
-- LIVRABLE 3
-- Taux de résolution par trimestre
-- ===========================================================

DROP VIEW IF EXISTS v_taux_resolution;
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
L’analyse des délais de traitement met en évidence des différences entre les quartiers d’Yverdon. 
Certains quartiers présentent un nombre plus élevé de signalements ainsi qu’un délai moyen d’intervention 
plus important. Cela peut indiquer une surcharge des équipes techniques ou une priorité 
différente selon le type de mobilier concerné. Le délai médian permet également de limiter l’influence 
des cas exceptionnels très longs et donne une vision plus représentative du temps de traitement habituel.

La vue des signalements ouverts montre plusieurs demandes encore en attente ou en cours depuis plus de 30 jours. 
Ces signalements concernent principalement des lampadaires, des bancs ou des fontaines situés dans différents 
quartiers. Ces données permettent d’identifier les zones nécessitant une intervention prioritaire et d’améliorer 
l’organisation des interventions futures.

Enfin, l’analyse du taux de résolution par trimestre montre l’évolution de l’efficacité des services techniques. 
Certains trimestres présentent un taux de résolution élevé, indiquant une bonne capacité de traitement des 
incidents, tandis que d’autres montrent une accumulation de signalements non résolus. Ces indicateurs 
permettent à la municipalité de suivre la qualité du service et d’adapter les ressources techniques 
selon les besoins observés.
*/