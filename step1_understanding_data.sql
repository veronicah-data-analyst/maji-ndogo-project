-- choosing the database to use 
USE md_water_services;
-- 1. Get to know data:
-- Start by retrieving the first few records from each table.
-- How many tables are there in our database? What are the names of these tables?
-- What information does each table contain?

-- show all the tables in the database for easy understanding and exploration 
SHOW TABLES;

-- using that killer query, SELECT * but remembering to limit it
SELECT * FROM location LIMIT 3;
SELECT * FROM visits LIMIT 5;
SELECT * FROM water_source LIMIT 5;

-- this query give the uniques water sources available 
SELECT DISTINCT type_of_water_source FROM water_source;

-- NOTE!!!!
-- An important note on the home taps: About 6-10 million people have running water installed in their homes in Maji Ndogo, including
-- broken taps. If we were to document this, we would have a row of data for each home, so that one record is one tap. That means our
-- database would contain about 1 million rows of data, which may slow our systems down. For now, the surveyors combined the data of
-- many households together into a single record.

-- For example, the first record, AkHa00000224 is for a tap_in_home that serves 956 people. What this means is that the records of about
-- 160 homes nearby were combined into one record, with an average of 6 people living in each house 160 x 6  956. So 1 tap_in_home
-- or tap_in_home_broken record actually refers to multiple households, with the sum of the people living in these homes equal to number_
-- of_people_served.

-- LET'S RUN THE QUERY AGAIN FOR WATER SOURCES 
SELECT * FROM water_source LIMIT 5;

-- Retrieve  all records from this table where the time_in_queue is more than some crazy time, say 500 min.
-- How does it feel to queue 8 hours for water?
SELECT * FROM visits WHERE time_in_queue >= 500;

-- I am wondering what type of water sources take this long to queue for. Let's find out using some IDs from the above query 

SELECT source_id, type_of_water_source, number_of_people_served 
FROM water_source 
WHERE source_id="AkKi00881224" OR source_id="HaZa21742224";

-- Let's assess the quality of water sources: The quality of our water sources is the whole point of this survey.
-- But we should first see the table and its data 
SHow COLUMNS FROM water_quality;
SELECT * FROM water_quality;

-- From the data dictionary, we know that where water qulaity was good (10) the serveyors did not make a second visit. 
-- they also only revisited shared taps 
-- Let's check if a source with good quality got multiple visists
-- You find out that a 218 taps in home were visited twice!!

SELECT *
FROM water_quality
WHERE subjective_quality_score = 10
AND visit_count = 2;

-- this should not be happening! I think some of our employees may have made mistakes.
-- To be honest, I'll be surprised if there are no errors in our data at this scale!
    
-- Investigating pollution issues  
-- View well pollution data 
SELECT * 
FROM well_pollution 
LIMIT 5;
    
-- Some wells are contaminated with biological contaminants, while others are polluted with an excess of heavy metals and other pollutants.
-- Based on the results, each well was classified as Clean, Contaminated: Biological or Contaminated: Chemical.
-- It is important to know this because wells that are polluted with bio- or other contaminants are not safe to drink. 
-- The source_id of each test was recorded, so we can link it to a source, at some place in Maji Ndogo.

-- Let's check the integrity of the data. The worst case is if we have contamination, but we think we don't. 
-- People can get sick, so we need to make sure there are no errors here.
-- we just need to make sure that if a source result is clean, biological column is 0 and anything above 0.01 is contaminated and not safe

-- let's check if a contaminated source was labled clean, we have some trouble here
SELECT *
FROM well_pollution 
	WHERE results="Clean" 
	AND biological > 0.01
LIMIT 10;

-- But if we scroll the data, we see human error. Someone used the description column to determine if water was clean. 
-- That's why maybe water with biological > 0.01 is labled clean. Let's fix that 

-- We need to find and remove the “Clean” part from all the descriptions that do have a biological contamination 
-- so this mistake is not made again.
-- We need also to find all the results that have a value greater than 0.01 in the biological column 
-- and have been set to Clean in the results column

-- Records that mistakenly have the word Clean in the description
SELECT *
FROM well_pollution
WHERE description LIKE "Clean_%";

-- Looking at the results we can see two different descriptions that we need to fix:
-- 1. All records that mistakenly have Clean Bacteria: E. coli should updated to Bacteria: E. coli
-- 2. All records that mistakenly have Clean Bacteria: Giardia Lamblia should updated to Bacteria: Giardia Lamblia
-- 3. We need to update the results column from Clean to Contaminated: Biological where the biological column has a value greater than 0.01.

-- I don't want to mess up the data. Let me create a copy of the table and play with it ... hahahah I am not always like this I promise
CREATE TABLE 
md_water_services.well_pollution_copy
AS(
SELECT 
*
FROM 
md_water_services.well_pollution
);

-- let me if there is something in this table.. The mistake I checked on the main data, and it is there, so we're good 
SELECT *
FROM well_pollution_copy
WHERE description LIKE "Clean_%";

-- updating the copy table 
SET SQL_SAFE_UPDATES = 0;

UPDATE
well_pollution_copy
SET
description = 'Bacteria: E. coli'
WHERE
description = 'Clean Bacteria: E. coli';

UPDATE
well_pollution_copy
SET
description = 'Bacteria: Giardia Lamblia'
WHERE
description = 'Clean Bacteria: Giardia Lamblia';

UPDATE
well_pollution_copy
SET
results = 'Contaminated: Biological'
WHERE
biological > 0.01 AND results = 'Clean';

SET SQL_SAFE_UPDATES = 1;

-- check if the errors are fixed 
SELECT
*
FROM
well_pollution_copy
WHERE
description LIKE "Clean_%"
OR (results = "Clean" AND biological > 0.01);

-- There are no errors in our copy table. Let's update our main table and but first, drop the copy table
-- We have seen what we needed to see.

DROP TABLE
md_water_services.well_pollution_copy;

-- updating the main table
SET SQL_SAFE_UPDATES = 0;

UPDATE well_pollution 
SET description ="Bacteria: E. coli"
WHERE description ="Clean Bacteria: E. coli";

UPDATE well_pollution 
SET description ="Bacteria: Giardia Lamblia"
WHERE description ="Clean Bacteria: Giardia Lamblia";

UPDATE well_pollution 
SET results = "Contaminated: Biological"
WHERE biological >0.01;

SET SQL_SAFE_UPDATES = 1;

-- just confirm one last time we don't have errors any more
SELECT 
*
FROM
well_pollution
WHERE 
description LIKE "Clean_%"
OR (RESULTS ="Clean" AND biological>0.01);



  
    
    
    
    
    
    
    
    