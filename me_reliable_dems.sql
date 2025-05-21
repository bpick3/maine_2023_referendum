WITH person_base AS (
  SELECT
    pv.person_id,

    -- General election vote history
    SAFE_CAST(pv.vote_g_2016 AS BOOL) AS voted_g_2016,
    SAFE_CAST(pv.vote_g_2018 AS BOOL) AS voted_g_2018,
    SAFE_CAST(pv.vote_g_2020 AS BOOL) AS voted_g_2020,
    SAFE_CAST(pv.vote_g_2022 AS BOOL) AS voted_g_2022,
    SAFE_CAST(pv.vote_g_2024 AS BOOL) AS voted_g_2024,
    SAFE_CAST(pv.vote_g_2023 AS BOOL) AS voted_g_2023,

    -- Party info
    p.party_name_dnc,
    s.dnc_2022_dem_party_support,

    -- Demographics
    CASE 
      WHEN p.age_combined BETWEEN 18 AND 24.99 THEN '18 - 24'
      WHEN p.age_combined BETWEEN 25 AND 34.99 THEN '25 - 34'
      WHEN p.age_combined BETWEEN 35 AND 44.99 THEN '35 - 44'
      WHEN p.age_combined BETWEEN 45 AND 54.99 THEN '45 - 54'
      WHEN p.age_combined BETWEEN 55 AND 64.99 THEN '55 - 64'
      WHEN p.age_combined >= 65 THEN '65+'
      ELSE 'Unspecified'
    END AS age,

    CASE 
      WHEN p.gender_combined = 'F' THEN 'Female'
      WHEN p.gender_combined = 'M' THEN 'Male'
      ELSE 'Unspecified'
    END AS gender,

    CASE 
      WHEN p.ethnicity_combined = 'W' THEN 'White'
      WHEN p.ethnicity_combined = 'B' THEN 'Black'
      WHEN p.ethnicity_combined = 'N' THEN 'Native'
      WHEN p.ethnicity_combined = 'A' THEN 'Asian'
      WHEN p.ethnicity_combined = 'H' THEN 'Latinx'
      ELSE 'Unspecified'
    END AS ethnicity,

    p.media_market AS dma

  FROM `democrats.analytics_me.person_votes` pv
  LEFT JOIN `democrats.analytics_me.person` p
    ON pv.person_id = p.person_id
  LEFT JOIN `democrats.scores_me.all_scores_2022` s
    ON pv.person_id = s.person_id
  WHERE pv.state_code = 'ME'
),

labeled AS (
  SELECT *,
    CASE 
      WHEN party_name_dnc = 'Democratic' THEN 'Democrat'
      WHEN party_name_dnc = 'Republican' THEN 'Republican'
      WHEN party_name_dnc = 'Unaffiliated' THEN 'Unaffiliated'
      WHEN party_name_dnc IS NULL THEN 'Unknown'
      ELSE 'Other'
    END AS party,

    CASE 
      WHEN dnc_2022_dem_party_support BETWEEN 0.8 AND 1 THEN 'Strong Dem'
      WHEN dnc_2022_dem_party_support BETWEEN 0.6 AND 0.799 THEN 'Lean Dem'
      WHEN dnc_2022_dem_party_support BETWEEN 0.4 AND 0.599 THEN 'Independent'
      WHEN dnc_2022_dem_party_support BETWEEN 0.2 AND 0.399 THEN 'Lean GOP'
      WHEN dnc_2022_dem_party_support BETWEEN 0 AND 0.199 THEN 'Strong GOP'
      ELSE 'Unknown'
    END AS likely_party
  FROM person_base
),

reliable_dems AS (
  SELECT *,
    (CAST(voted_g_2016 AS INT64) +
     CAST(voted_g_2018 AS INT64) +
     CAST(voted_g_2020 AS INT64) +
     CAST(voted_g_2022 AS INT64) +
     CAST(voted_g_2024 AS INT64)) AS total_prior_votes
  FROM labeled
  WHERE 
    (party = 'Democrat' OR likely_party IN ('Lean Dem', 'Strong Dem'))
    AND NOT voted_g_2023
)

SELECT
  age,
  gender,
  ethnicity,
  dma,
  COUNT(*) AS reliable_dems_did_not_vote_2023,
  COUNTIF(total_prior_votes >= 4) AS highly_reliable_dems,
  COUNTIF(total_prior_votes = 3) AS reliable_dems,
  COUNTIF(total_prior_votes = 2) AS moderate_reliable_dems
FROM reliable_dems
GROUP BY age, gender, ethnicity, dma;
