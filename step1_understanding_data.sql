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

SELECT count(*)
FROM water_quality
WHERE subjective_quality_score = 10
AND visit_count >=2;


    
SELECT * 
FROM well_pollution 
LIMIT 5;
    
SELECT *
FROM well_pollution 
	WHERE results="Clean" 
	AND biological > 0.01
LIMIT 10;

SELECT *
FROM well_pollution
WHERE description LIKE "Clean_%";

UPDATE well_pollution 
SET description ="Bacteria: E. coli"
WHERE description ="Clean Bacteria: E. coli";

SET SQL_SAFE_UPDATES = 0;

UPDATE well_pollution 
SET description ="Bacteria: Giardia Lamblia"
WHERE description ="Clean Bacteria: Giardia Lamblia";

UPDATE well_pollution 
SET results = "Contaminated: Biological"
WHERE biological >0.01;

CREATE TABLE 
md_water_services.well_pollution_copy
AS(
SELECT 
*
FROM 
md_water_services.well_pollution
);

SELECT
*
FROM 
md_water_services.well_pollution_copy;

SELECT 
*
FROM
md_water_services.well_pollution_copy
WHERE 
description LIKE "Clean_%"
OR (RESULTS ="Clean" AND biological>0.01);

SELECT address
FROM employee
WHERE employee_name ="Bello Azibo";

SELECT 
* 
FROM water_source;

SELECT 
employee_name, phone_number
FROM employee 
WHERE position="Micro Biologist";

SELECT source_id
FROM water_source
WHERE number_of_people_served = (SELECT MAX(number_of_people_served) FROM water_source);


SELECT table_name, column_name
FROM data_dictionary
WHERE description LIKE '%population%';


SELECT pop_n
FROM global_water_access
WHERE name = 'Maji Ndogo';

CREATE TEMPORARY TABLE tmp_last_names AS
SELECT SUBSTRING_INDEX(employee_name, ' ', -1) AS last_name
FROM employee;

SELECT *
FROM your_table_name
WHERE last_name IN (SELECT last_name FROM tmp_last_names);

SELECT *
FROM employee
WHERE 
    phone_number LIKE "%86%" OR phone_number LIKE "%11%"
	AND employee_name IN (SELECT last_name FROM tmp_last_names)
    AND position = "Field Surveyor";
    
SELECT *
FROM employee
WHERE
    (phone_number LIKE '%86%' OR phone_number LIKE '%11%')
    AND (SUBSTRING_INDEX(employee_name, ' ', -1) LIKE 'A%' OR SUBSTRING_INDEX(employee_name, ' ', -1) LIKE 'M%')
    AND position = 'Field Surveyor';

SELECT *
FROM well_pollution
WHERE description LIKE 'Clean_%' OR results = 'Clean' AND biological < 0.01;

SELECT * FROM water_quality WHERE visit_count >= 2 AND subjective_quality_score = 10;
SELECT * FROM water_quality WHERE visit_count > 1 AND subjective_quality_score > 10;
SELECT * FROM water_quality WHERE visit_count = 2 OR subjective_quality_score = 10;
SELECT * FROM water_quality WHERE visit_count = 2 AND subjective_quality_score = 10;
    
   
SELECT * 
FROM well_pollution
WHERE description
IN ('Parasite: Cryptosporidium', 'biologically contaminated')
OR (results = 'Clean' AND biological > 0.01);
  
    
    
    
    
    
    
    
    