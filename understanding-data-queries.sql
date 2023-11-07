USE md_water_services;
SHOW TABLES;
SELECT * FROM location LIMIT 5;
SELECT  * FROM visits;
SELECT  * FROM water_source LIMIT 5;
SELECT DISTINCT type_of_water_source FROM water_source;
SELECT * FROM visits WHERE time_in_queue >= 500;
SELECT source_id, type_of_water_source, number_of_people_served FROM water_source WHERE source_id="AkRu05234224" OR source_id="HaZa21742224";
SHow COLUMNS FROM water_quality;
SELECT * FROM water_quality;
SELECT * FROM water_quality, water_source, visits WHERE subjective_quality_score =10 AND type_of_water_source="tap_in_home";
SELECT *
FROM water_quality, water_source
WHERE subjective_quality_score = 10
AND type_of_water_source="tap_in_home"
AND visit_count =2;
    
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
  
    
    
    
    
    
    
    
    