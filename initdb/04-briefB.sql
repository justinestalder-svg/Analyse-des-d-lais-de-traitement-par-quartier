-- ===========================================================
-- BRIEF B
-- Analyse des délais de traitement par quartier
-- Gestion Mobilier Urbain Yverdon-les-Bains
-- ===========================================================

-- ===========================================================
-- LIVRABLE 1
-- Délai moyen et médian par quartier
-- ===========================================================

DROP VIEW IF EXISTS v_delai_par_quartier;

CREATE VIEW v_delai_par_quartier AS
SELECT
s.lieu AS quartier,
COUNT(s.id) AS nombre_signalements,
COUNT(i.id) AS nombre_interventions,
ROUND(AVG(i.date-s.date),1) AS delai_moyen_jours,
PERCENTILE_CONT(0.5) WITHIN GROUP (
ORDER BY (i.date-s.date)
) AS delai_median_jours
FROM public.signalements s
LEFT JOIN LATERAL (
SELECT i.id,i.date
FROM public.interventions i
WHERE LOWER(i.objet)=LOWER(s.objet)
AND LOWER(i.lieu)=LOWER(s.lieu)
AND i.date>=s.date
ORDER BY i.date
LIMIT 1
) i ON true
GROUP BY s.lieu
HAVING COUNT(i.id)>0;

SELECT * FROM v_delai_par_quartier
ORDER BY delai_moyen_jours DESC;

-- ===========================================================
-- LIVRABLE 2
-- Signalements ouverts depuis plus de 30 jours
-- ===========================================================

DROP VIEW IF EXISTS v_signalements_ouverts;

CREATE VIEW v_signalements_ouverts AS
SELECT DISTINCT ON (s.id)
s.date,
s.objet,
s.description,
s.statut,
s.lieu,
m.latitude,
m.longitude
FROM public.signalements s
LEFT JOIN public.inventaire_mobilier m
ON LOWER(s.objet)=LOWER(m.type)
AND LOWER(s.lieu)=LOWER(m.lieu)
WHERE s.statut IN ('en attente','en cours')
AND s.date<=CURRENT_DATE-INTERVAL '30 days'
ORDER BY s.id,m.id;

SELECT * FROM v_signalements_ouverts
ORDER BY date;

-- ===========================================================
-- LIVRABLE 3
-- Taux de résolution par trimestre
-- ===========================================================

DROP VIEW IF EXISTS v_taux_resolution;

CREATE VIEW v_taux_resolution AS
SELECT
CONCAT('Q',EXTRACT(QUARTER FROM date),' ',EXTRACT(YEAR FROM date)) AS trimestre,
COUNT(*) AS total_signalements,
COUNT(*) FILTER (WHERE statut='résolu') AS signalements_resolus,
ROUND((COUNT(*) FILTER (WHERE statut='résolu')::NUMERIC/COUNT(*))*100,1) AS taux_resolution
FROM public.signalements
GROUP BY EXTRACT(YEAR FROM date),EXTRACT(QUARTER FROM date)
ORDER BY EXTRACT(YEAR FROM date),EXTRACT(QUARTER FROM date);

SELECT * FROM v_taux_resolution;

-- ===========================================================
-- INTERPRÉTATION DES RÉSULTATS
-- ===========================================================
-- Ces vues permettent d’analyser les délais de traitement
-- des signalements selon les lieux/quartiers d’Yverdon-les-Bains.
--
-- Pour le premier livrable, chaque signalement est associé
-- uniquement à la première intervention correspondante
-- ayant lieu après la date du signalement.
--
-- Les quartiers sans intervention associée sont exclus
-- du calcul des délais afin d’éviter les valeurs NULL.
--
-- La deuxième vue liste les signalements encore ouverts
-- depuis plus de 30 jours, avec les coordonnées GPS
-- lorsqu’un mobilier correspondant existe dans l’inventaire.
--
-- La troisième vue permet de suivre le taux de résolution
-- des signalements trimestre par trimestre.