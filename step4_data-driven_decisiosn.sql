/*Let's summarise the data we need, and where to find it:
• All of the information about the location of a water source is in the location table, specifically the town and province of that water source.
• water_source has the type of source and the number of people served by each source.
• visits has queue information, and connects source_id to location_id. There were multiple visits to sites, so we need to be careful to
include duplicate data (visit_count > 1 ).
• well_pollution has information about the quality of water from only wells, so we need to keep that in mind when we join this table.*/

/*Previously, we couldn't link provinces and towns to the type of water sources, the number of people served by those sources, queue times, or pollution
data, but we can now. So, what type of relationships can we look at?*/

/*Things that spring to mind for me:
1. Are there any specific provinces, or towns where some sources are more abundant?
2. We identified that tap_in_home_broken taps are easy wins. Are there any towns where this is a particular problem?

To answer question 1, we will need province_name and town_name from the location table. We also need to know type_of_water_source and
number_of_people_served from the water_source table.

The problem is that the location table uses location_id while water_source only has source_id. So we won't be able to join these tables directly.
But the visits table maps location_id and source_id. So if we use visits as the table we query from, we can join location where
the location_id matches, and water_source where the source_id matches.
Before we can analyse, we need to assemble data into a table first. It is quite complex, but once we're done, the analysis is much simpler!*/


/*Start by joining location to visits.*/
USE md_water_services;
SELECT * FROM location;
SELECT * FROM visits;

SELECT 
	l.province_name,
	l.town_name,
	ws.type_of_water_source,
	l.location_type,
	v.time_in_queue, 
	ws.number_of_people_served,
    wp.results
FROM visits AS v
JOIN location AS l
ON v.location_id=l.location_id
JOIN water_source AS ws
ON v.source_id=ws.source_id
LEFT JOIN
well_pollution AS wp
ON wp.source_id = v.source_id 
WHERE v.visit_count = 1;

CREATE VIEW combined_analysis_table AS
/*This view assembles data from different tables into one to simplify analysis*/
SELECT
water_source.type_of_water_source AS source_type,
location.town_name,
location.province_name,
location.location_type,
water_source.number_of_people_served AS people_served,
visits.time_in_queue,
well_pollution.results
FROM
visits
LEFT JOIN
well_pollution
ON well_pollution.source_id = visits.source_id
INNER JOIN
location
ON location.location_id = visits.location_id
INNER JOIN
water_source
ON water_source.source_id = visits.source_id
WHERE
visits.visit_count = 1;

SELECT * FROM combined_analysis_table;

WITH province_totals AS (-- This CTE calculates the population of each province
SELECT
province_name,
SUM(people_served) AS total_ppl_serv
FROM
combined_analysis_table
GROUP BY
province_name
)
SELECT
ct.province_name,
-- These case statements create columns for each type of source.
-- The results are aggregated and percentages are calculated
ROUND((SUM(CASE WHEN source_type = 'river'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN source_type = 'shared_tap'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN source_type = 'well'
THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
JOIN
province_totals pt ON ct.province_name = pt.province_name
GROUP BY
ct.province_name
ORDER BY
ct.province_name;

WITH province_totals AS (-- This CTE calculates the population of each province
SELECT
province_name,
SUM(people_served) AS total_ppl_serv
FROM
combined_analysis_table
GROUP BY
province_name
)
SELECT
*
FROM
province_totals;

CREATE TEMPORARY TABLE town_aggregated_water_access
WITH town_totals AS ( -- This CTE calculates the population of each town
-- Since there are two Harare towns, we have to group by province_name and town_name
SELECT province_name, town_name, SUM(people_served) AS total_ppl_serv
FROM combined_analysis_table
GROUP BY province_name,town_name
)
SELECT
ct.province_name,
ct.town_name,
ROUND((SUM(CASE WHEN source_type = 'river'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN source_type = 'shared_tap'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN source_type = 'well' 
THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
JOIN -- Since the town names are not unique, we have to join on a composite key
town_totals tt ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name
GROUP BY -- We group by province first, then by town.
ct.province_name,
ct.town_name
ORDER BY
ct.town_name;

SELECT * FROM town_aggregated_water_access;
SELECT MAX(river) FROM town_aggregated_water_access
where province_name='Amanzi';

SELECT province_name
FROM town_aggregated_water_access
WHERE shared_tap < 50 AND tap_in_home_broken < 50;


-- Create a temporary table to store subquery results
CREATE TEMPORARY TABLE temp_town_aggregated AS
SELECT DISTINCT province_name
FROM town_aggregated_water_access
WHERE (tap_in_home + tap_in_home_broken) >= 50;

-- Query to find provinces where all towns have less than 50% access to home taps
SELECT DISTINCT t.province_name
FROM town_aggregated_water_access t
LEFT JOIN temp_town_aggregated temp
ON t.province_name = temp.province_name
WHERE temp.province_name IS NULL;

-- Drop the temporary table when done (optional)
DROP TEMPORARY TABLE IF EXISTS temp_town_aggregated;


SELECT
province_name,
town_name,
ROUND(tap_in_home_broken / (tap_in_home_broken + tap_in_home) * 100,0) AS Pct_broken_taps
FROM
town_aggregated_water_access;

-- This query creates the Project_progress table:
CREATE TABLE Project_progress (
Project_id SERIAL PRIMARY KEY,
/* Project_id −− Unique key for sources in case we visit the same
source more than once in the future.
*/
source_id VARCHAR(20) NOT NULL REFERENCES water_source(source_id) ON DELETE CASCADE ON UPDATE CASCADE,
/* source_id −− Each of the sources we want to improve should exist,
and should refer to the source table. This ensures data integrity.
*/
Address VARCHAR(50), -- Street address
Town VARCHAR(30),
Province VARCHAR(30),
Source_type VARCHAR(50),
Improvement VARCHAR(50), -- What the engineers should do at that place
Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In progress', 'Complete')),
/* Source_status −− We want to limit the type of information engineers can give us, so we
limit Source_status.
− By DEFAULT all projects are in the "Backlog" which is like a TODO list.
− CHECK() ensures only those three options will be accepted. This helps to maintain clean data.
*/
Date_of_completion DATE, -- Engineers will add this the day the source has been upgraded.
Comments TEXT -- Engineers can leave comments. We use a TEXT type that has no limit on char length
);

/*At a high level, the Improvements are as follows:
1. Rivers → Drill wells
2. wells: if the well is contaminated with chemicals → Install RO filter
3. wells: if the well is contaminated with biological contaminants → Install UV and RO filter
4. shared_taps: if the queue is longer than 30 min (30 min and above) → Install X taps nearby where X number of taps is calculated using X
= FLOOR(time_in_queue / 30).
5. tap_in_home_broken → Diagnose local infrastructure*/

-- Project_progress_query
SELECT
location.address,
location.town_name,
location.province_name,
water_source.source_id,
water_source.type_of_water_source,
well_pollution.results
FROM
water_source
LEFT JOIN
well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
visits ON water_source.source_id = visits.source_id
INNER JOIN
location ON location.location_id = visits.location_id
WHERE
visits.visit_count = 1 -- This must always be true
	AND ( well_pollution.results!= 'Clean'
		OR water_source.type_of_water_source IN ('tap_in_home_broken','river')
		OR (water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue>=30)
        )
 LIMIT 60000;
 
ALTER TABLE Project_progress
DROP CONSTRAINT project_progress_chk_1;

INSERT INTO Project_progress (source_id, address, town, province, source_type, improvement, 
source_status, date_of_completion, comments)
SELECT
    water_source.source_id,
    location.address,
    location.town_name,
    location.province_name,
    water_source.type_of_water_source,
    CASE
        WHEN well_pollution.results = 'Contaminated: Biological' THEN 'Install UV filter'
        WHEN well_pollution.results = 'Contaminated: Chemical' THEN 'Install RO filter'
        WHEN water_source.type_of_water_source = 'river' THEN 'Drill Well'
		WHEN water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30 THEN CONCAT("Install ", FLOOR(visits.time_in_queue / 30), " taps nearby")
		WHEN water_source.type_of_water_source = 'tap_in_home_broken' THEN 'Diagnose local infrastructure.' 
        ELSE NULL
    END AS Improvement,
    well_pollution.results,
	CURRENT_DATE(), -- You can leave date_of_completion as NULL for now
    NULL  -- You can leave comments as NULL for now
FROM water_source
LEFT JOIN well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN visits ON water_source.source_id = visits.source_id
INNER JOIN location ON location.location_id = visits.location_id;



/*Parctice*/
-- Disable safe update mode
SET SQL_SAFE_UPDATES = 0;

UPDATE Project_progress
SET Improvement = 
    CASE
        WHEN source_type = 'river' THEN 'Drill Well'
        ELSE NULL
    END;   

-- Re-enable safe update mode (recommended)
SET SQL_SAFE_UPDATES = 1;

-- Disable safe update mode
SET SQL_SAFE_UPDATES = 0;

UPDATE Project_progress AS p
JOIN visits AS v ON p.source_id = v.source_id
SET p.Improvement =
    CASE
        WHEN p.source_type = 'shared_tap' AND v.time_in_queue >= 30 THEN CONCAT("Install ", FLOOR(v.time_in_queue / 30), " taps nearby")
        ELSE NULL
    END;
    
-- Re-enable safe update mode (recommended)
SET SQL_SAFE_UPDATES = 1;


SET SQL_SAFE_UPDATES = 0;
UPDATE Project_progress 
SET Improvement =
    CASE
        WHEN source_type = 'tap_in_home_broken' THEN 'Diagnose local infrastructure.'
        ELSE NULL
    END;
-- Re-enable safe update mode (recommended)
SET SQL_SAFE_UPDATES = 1;

SELECT count(*)  FROM Project_progress
WHERE Improvement IS NOT NULL;

SELECT COUNT(*) AS NonNullImprovementCount
FROM Project_progress
WHERE Improvement IS NOT NULL;

/* end of practice*/

SELECT town, COUNT(*) as COUNT FROM Project_progress
WHERE source_type='shared_tap'
group by 
town
order by count DESC; 

SELECT * FROM Project_progress;


SELECT
project_progress.Project_id, 
project_progress.Town, 
project_progress.Province, 
project_progress.Source_type, 
project_progress.Improvement,
Water_source.number_of_people_served,
RANK() OVER(PARTITION BY Province ORDER BY number_of_people_served)
FROM  project_progress 
JOIN water_source 
ON water_source.source_id = project_progress.source_id
WHERE Improvement = "Drill Well"
ORDER BY Province DESC, number_of_people_served;


