USE md_water_services;

SELECT
REPLACE(employee_name, ' ','.')   /*Replace the space with a full stop*/
FROM
employee;

SELECT
LOWER(REPLACE(employee_name, ' ','.'))  /* Make it all lower case*/
FROM
employee;

SELECT
CONCAT(LOWER(REPLACE(employee_name, ' ', '.')), '@ndogowater.gov') AS new_email /* add it all together*/
FROM
employee;

/*Disable safe update mode*/
SET SQL_SAFE_UPDATES = 0;

UPDATE employee
SET email = CONCAT(LOWER(REPLACE(employee_name, ' ', '.')),'@ndogowater.gov');

-- Re-enable safe update mode (recommended after your updates)
SET SQL_SAFE_UPDATES = 1;

SELECT
LENGTH(phone_number)
FROM
employee;

SELECT length(trim(phone_number))
FROM
employee;

/*Disable safe update mode*/
SET SQL_SAFE_UPDATES = 0;

UPDATE employee
SET phone_number = TRIM(phone_number);

-- Re-enable safe update mode (recommended after your updates)
SET SQL_SAFE_UPDATES = 1;

SELECT employee_name, town_name
FROM employee;

SELECT town_name, COUNT(*) AS employee_count
FROM employee
GROUP BY town_name;

SELECT 
COUNT(employee_name) as NUmber_of_Employees_Rural
FROM
employee
WHERE 
town_name="Rural";

SELECT assigned_employee_id, COUNT(*) AS number_of_locations_visited
FROM visits 
GROUP BY assigned_employee_id
ORDER BY number_of_locations_visited DESC
LIMIT 3;

SELECT 
employee_name, email, phone_number 
FROM 
employee
WHERE 
assigned_employee_id= 1 OR assigned_employee_id=30 OR assigned_employee_id=34;

SELECT 
*
FROM
Location;

SELECT
town_name, COUNT(*) as number_of_records_per_town
FROM location 
GROUP BY town_name;

SELECT
province_name, COUNT(*) as number_of_records_per_province
FROM location 
GROUP BY province_name;

SELECT 
province_name, town_name,COUNT(*) as records_per_town
FROM location
GROUP BY province_name, town_name
ORDER BY province_name ASC, records_per_town DESC;

SELECT location_type, COUNT(*) as number_of_sources
FROM location 
GROUP BY location_type;

SELECT 23740 / (15910 + 23740) * 100;

/*How many people did we survey in total?*/
SELECT 
SUM(number_of_people_served) 
FROM 
water_source; 

/*How many wells, taps and rivers are there?*/
SELECT type_of_water_source, COUNT(*) as number_of_sources
FROM water_source
GROUP BY type_of_water_source;

/*How many people share particular types of water sources on average?*/
SELECT 
type_of_water_source, 
AVG(number_of_people_served) AS average_people_served
FROM 
water_source
GROUP BY 
type_of_water_source;


SELECT 
type_of_water_source,
SUM(number_of_people_served) as population_served
FROM 
water_source
GROUP BY type_of_water_source
ORDER BY population_served DESC;

SELECT
type_of_water_source, SUM(number_of_people_served) as number_of_people,
ROUND(SUM(number_of_people_served) / (SELECT SUM(number_of_people_served) FROM water_source) * 100) AS percentage_of_people_served
FROM
water_source
GROUP BY
type_of_water_source
ORDER BY number_of_people DESC;

SELECT
type_of_water_source,
SUM(number_of_people_served) AS number_of_people,
RANK() OVER (ORDER BY SUM(number_of_people_served)DESC) AS rank_order 
FROM water_source
WHERE type_of_water_source != 'tap_in_home'
GROUP BY type_of_water_source;

/*1. The sources within each type should be assigned a rank.*/
SELECT
  source_id,
  type_of_water_source,
  number_of_people_served,
  RANK() OVER (PARTITION BY type_of_water_source ORDER BY number_of_people_served DESC) AS Priority_rank
FROM water_source
WHERE type_of_water_source != 'tap_in_home';

/*Limit the results to only improvable sources.*/
SELECT
  source_id,
  type_of_water_source,
  number_of_people_served,
  DENSE_RANK() OVER (PARTITION BY type_of_water_source ORDER BY number_of_people_served DESC) AS Priority_rank
FROM water_source
WHERE type_of_water_source != 'tap_in_home';

/*1. How long did the survey take?*/

SELECT
  TIMESTAMPDIFF(DAY, MIN(time_of_record), MAX(time_of_record)) AS survey_duration_in_days
FROM visits;

/*2. What is the average total queue time for water?*/
SELECT
AVG(NULLIF(time_in_queue, 0)) AS average_queue_time
FROM visits;

/*3. What is the average queue time on different days?*/
SELECT
DAYNAME(time_of_record) AS day_of_week,
ROUND(AVG(NULLIF(time_in_queue, 0))) AS average_queue_time
FROM visits
GROUP BY day_of_week;

/*4. How can we communicate this information efficiently?*/
SELECT
TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,
AVG(time_in_queue) AS average_time_queue
FROM visits
GROUP BY hour_of_day
ORDER BY hour_of_day ASC;

SELECT
TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,
ROUND(AVG(CASE
WHEN DAYNAME(time_of_record) = 'Sunday' THEN time_in_queue
ELSE NULL
END),0)
AS Sunday,
ROUND(AVG(CASE
WHEN DAYNAME(time_of_record) = 'Monday' THEN time_in_queue
ELSE NULL
END),0)
AS Monday,
ROUND(AVG(CASE
WHEN DAYNAME(time_of_record) = 'Tuesday' THEN time_in_queue
ELSE NULL
END 
),0)
AS Tuesday,
ROUND(AVG(CASE
WHEN DAYNAME(time_of_record) = 'Wednesday' THEN time_in_queue
ELSE NULL
END),0)
 AS Wednesday,
ROUND(AVG(CASE
WHEN DAYNAME(time_of_record) = 'Thursday' THEN time_in_queue
ELSE NULL
END
),0)
AS Thursday,
ROUND(AVG(CASE
WHEN DAYNAME(time_of_record) = 'Friday' THEN time_in_queue
ELSE NULL
END),0)
AS Friday,
ROUND(AVG(CASE
WHEN DAYNAME(time_of_record) = 'Saturday' THEN time_in_queue
ELSE NULL
END),0)
AS Saturday
FROM
visits
WHERE
time_in_queue != 0 -- this exludes other sources with 0 queue times.
GROUP BY hour_of_day
ORDER BY hour_of_day;



SELECT CONCAT(monthname(time_of_record), " ", day(time_of_record), ", ", year(time_of_record)) FROM visits;
SELECT CONCAT(day(time_of_record), " ", monthname(time_of_record), " ", year(time_of_record)) FROM visits;
SELECT CONCAT(day(time_of_record), " ", month(time_of_record), " ", year(time_of_record)) FROM visits;
SELECT day(time_of_record), monthname(time_of_record), year(time_of_record) FROM visits;

SELECT
  e.employee_name,
  COUNT(v.assigned_employee_id) AS visit_count
FROM employee e
LEFT JOIN visits v ON e.assigned_employee_id = v.assigned_employee_id
GROUP BY e.employee_name
ORDER BY visit_count;

SELECT 
    location_id,
    time_in_queue,
    AVG(time_in_queue) OVER (PARTITION BY location_id ORDER BY visit_count) AS total_avg_queue_time
FROM 
    visits
WHERE 
visit_count > 1 -- Only shared taps were visited > 1
ORDER BY 
    location_id, time_of_record;
    
SELECT COUNT(*) AS employees_in_dahabu
FROM employee
WHERE town_name = 'Dahabu';
  
SELECT COUNT(*) AS employees_in_harare_kilimani
FROM employee
WHERE town_name = 'Harare';

SELECT ROUND(AVG(number_of_people_served), 0) AS average_people_served
FROM water_source
WHERE type_of_water_source = 'well';

SELECT
SUM(number_of_people_served) AS population_served
FROM
water_source
ORDER BY
population_served;

 SELECT 
 *
 FROM 
 employee;

SELECT COUNT(*) AS employees_in_harare_kilimani
FROM employee
WHERE town_name='Dahabu';


SELECT 
    location_id,
    time_in_queue,
    AVG(time_in_queue) OVER (PARTITION BY location_id ORDER BY visit_count) AS total_avg_queue_time
FROM 
    visits
WHERE 
visit_count > 1 -- Only shared taps were visited > 1
ORDER BY 
    location_id, time_of_record;
SELECT length(TRIM('33 Angelique Kidjo Avenue  '));

SELECT
e.employee_name,
COUNT(v.assigned_employee_id) AS number_of_visits,
RANK() OVER (ORDER BY COUNT(v.assigned_employee_id) ASC) AS rank_order 
FROM employee e
JOIN visits v ON e.assigned_employee_id = v.assigned_employee_id
GROUP BY e.employee_name
ORDER BY rank_order;

SELECT day(time_of_record), monthname(time_of_record), year(time_of_record) FROM visits;
SELECT CONCAT(monthname(time_of_record), " ", day(time_of_record), ", ", year(time_of_record)) FROM visits;
SELECT CONCAT(day(time_of_record), " ", month(time_of_record), " ", year(time_of_record)) FROM visits;

SELECT ROUND(AVG(number_of_people_served)) AS average_people_per_well
FROM water_source
WHERE type_of_water_source LIKE '%well%';

select * from water_source;
























