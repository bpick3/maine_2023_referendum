WITH votes AS (
  SELECT
    pv.person_id,
    pv.state_code,
    SAFE_CAST(pv.vote_g_2023 AS BOOL) AS voted_2023,
    SAFE_CAST(pv.vote_g_2023_method_absentee AS BOOL) AS absentee_2023,
    SAFE_CAST(pv.vote_g_2023_method_early AS BOOL) AS early_2023,
    pv.last_primary_party
  FROM
    `democrats.analytics_me.person_votes` pv
  WHERE
    pv.state_code = 'ME'
),

party_votes AS (
  SELECT
    v.person_id,
    v.state_code,
    v.voted_2023,
    v.absentee_2023,
    v.early_2023,

    -- Age
    CASE 
      WHEN p.age_combined BETWEEN 18 AND 24.99 THEN '18 - 24'
      WHEN p.age_combined BETWEEN 25 AND 34.99 THEN '25 - 34'
      WHEN p.age_combined BETWEEN 35 AND 44.99 THEN '35 - 44'
      WHEN p.age_combined BETWEEN 45 AND 54.99 THEN '45 - 54'
      WHEN p.age_combined BETWEEN 55 AND 64.99 THEN '55 - 64'
      WHEN p.age_combined >= 65 THEN '65+'
      ELSE 'Unspecified'
    END AS age,

    -- Gender
    CASE 
      WHEN p.gender_combined = 'F' THEN 'Female'
      WHEN p.gender_combined = 'M' THEN 'Male'
      ELSE 'Unspecified'
    END AS gender,

    -- Ethnicity
    CASE 
      WHEN p.ethnicity_combined = 'W' THEN 'White'
      WHEN p.ethnicity_combined = 'B' THEN 'Black'
      WHEN p.ethnicity_combined = 'N' THEN 'Native'
      WHEN p.ethnicity_combined = 'A' THEN 'Asian'
      WHEN p.ethnicity_combined = 'H' THEN 'Latinx'
      ELSE 'Unspecified'
    END AS ethnicity,

    -- Geography
    p.media_market AS dma,
    p.county_name,
    p.voting_city,
    p.van_precinct_name,

    -- Party and Likely Party
    CASE 
      WHEN p.party_name_dnc IS NULL THEN 'Unknown'
      WHEN p.party_name_dnc = 'Democratic' THEN 'Democrat'
      WHEN p.party_name_dnc = 'Republican' THEN 'Republican'
      WHEN p.party_name_dnc = 'Nonpartisan' THEN 'Nonpartisan'
      WHEN p.party_name_dnc = 'Unaffiliated' THEN 'Unaffiliated'
      ELSE 'Other'
    END AS party,
    
    CASE 
      WHEN s.dnc_2022_dem_party_support BETWEEN 0 AND 0.199 THEN 'Strong GOP'
      WHEN s.dnc_2022_dem_party_support BETWEEN 0.2 AND 0.399 THEN 'Lean GOP'
      WHEN s.dnc_2022_dem_party_support BETWEEN 0.4 AND 0.599 THEN 'Independent'
      WHEN s.dnc_2022_dem_party_support BETWEEN 0.6 AND 0.799 THEN 'Lean Dem'
      WHEN s.dnc_2022_dem_party_support BETWEEN 0.8 AND 1 THEN 'Strong Dem'
      ELSE 'Unknown'
    END AS party_indicator_dnc

  FROM votes v
  LEFT JOIN `democrats.analytics_me.person` p
    ON v.person_id = p.person_id
  LEFT JOIN `democrats.scores_me.all_scores_2022` s
    ON v.person_id = s.person_id
)

SELECT
  party,
  party_indicator_dnc,
  age,
  gender,
  ethnicity,
  dma,
  COUNT(*) AS total_voters,
  COUNTIF(voted_2023) AS total_voted_2023,
  COUNTIF(NOT voted_2023) AS total_not_voted_2023
FROM party_votes
GROUP BY party, party_indicator_dnc, age, gender, ethnicity, dma;
