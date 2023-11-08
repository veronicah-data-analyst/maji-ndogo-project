USE md_water_services;

-- replace the space with . to get a proper email formart 
-- the the script below 
SELECT
REPLACE(employee_name, ' ','.')  
FROM
employee;

-- change the name to lower case, email are normally written in lower case
SELECT
LOWER(REPLACE(employee_name, ' ','.'))  /* Make it all lower case*/
FROM
employee;

-- combine the above 2 scripts and add the extension to get a full email 
-- we know the official email ends with @ndogowater.gov
SELECT
CONCAT(LOWER(REPLACE(employee_name, ' ', '.')), '@ndogowater.gov') AS new_email /* add it all together*/
FROM
employee;

-- let's update the emails in the tables 
-- Disable safe update mode to be able to udate a table 
SET SQL_SAFE_UPDATES = 0;
UPDATE employee
SET email = CONCAT(LOWER(REPLACE(employee_name, ' ', '.')),'@ndogowater.gov');

-- Re-enable safe update mode (recommended after updates)
SET SQL_SAFE_UPDATES = 1;

-- the length of phone numbers should 12. We see that we have 13 here 
SELECT
LENGTH(phone_number)
FROM
employee;

-- let's trim to remove spaces and get the right phone numbers. Our mas SMS should work perfectly 
-- after removing the spaces
-- check the length now. It is 12!
SELECT length(trim(phone_number))
FROM
employee;


-- let's update our phone numbers in the table 
SET SQL_SAFE_UPDATES = 0;

UPDATE employee
SET phone_number = TRIM(phone_number);

-- Re-enable safe update mode (recommended after your updates)
SET SQL_SAFE_UPDATES = 1;


-- see emplyee names and the towns they live in 
SELECT employee_name, town_name
FROM employee;

-- lets how many of our employee live in each town 
SELECT town_name, COUNT(*) AS employee_count
FROM employee
GROUP BY town_name;

-- The number of our employee living in rural areas
SELECT 
COUNT(employee_name) as NUmber_of_Employees_Rural
FROM
employee
WHERE 
town_name="Rural";

-- Let's see the top 3 employees and the number of locations they visited
-- We can go find out thier names using the employee IDs
SELECT assigned_employee_id, COUNT(*) AS number_of_locations_visited
FROM visits 
GROUP BY assigned_employee_id
ORDER BY number_of_locations_visited DESC
LIMIT 3;

-- Lets see out top 3 employees
-- they visited the most locations. Let's include thier contact information. We can decided to award them
SELECT 
employee_name, email, phone_number 
FROM 
employee
WHERE 
assigned_employee_id= 1 OR assigned_employee_id=30 OR assigned_employee_id=34;

-- what locations do we have?
SELECT 
*
FROM
Location;

-- Let's see the number of records per town 
SELECT
town_name, COUNT(*) as number_of_records_per_town
FROM location 
GROUP BY town_name;

-- Let's see the number of towns per province 
SELECT
province_name, COUNT(*) as number_of_records_per_province
FROM location 
GROUP BY province_name;

-- Let's group towns and their numbre of records 
-- To avoid wrongs results, lets group provinces first, then groups individual towns per province and get the records per town 
-- I wanted to have them in  a descending order 
SELECT 
province_name, town_name,COUNT(*) as records_per_town
FROM location
GROUP BY province_name, town_name
ORDER BY province_name ASC, records_per_town DESC;

-- let's find out the number of sources we have in different location types 
SELECT location_type, COUNT(*) as number_of_sources
FROM location 
GROUP BY location_type;

-- just trying arithmets to get a % here 
SELECT 23740 / (15910 + 23740) * 100;

-- How many people did we survey in total? Just thinking out loud 
-- Let's find out 
SELECT 
SUM(number_of_people_served) 
FROM 
water_source; 

-- How many wells, taps and rivers are there? 
SELECT type_of_water_source, COUNT(*) as number_of_sources
FROM water_source
GROUP BY type_of_water_source;

-- How many people share particular types of water sources on average?
SELECT 
type_of_water_source, 
AVG(number_of_people_served) AS average_people_served
FROM 
water_source
GROUP BY 
type_of_water_source;

-- The total number of people sharing a water source 
SELECT 
type_of_water_source,
SUM(number_of_people_served) as population_served
FROM 
water_source
GROUP BY type_of_water_source
ORDER BY population_served DESC;

-- What is the percentage of people using each water source ? 
SELECT
type_of_water_source, 
SUM(number_of_people_served) as number_of_people,
ROUND(SUM(number_of_people_served) / (SELECT SUM(number_of_people_served) FROM water_source) * 100) AS percentage_of_people_served
FROM
water_source
GROUP BY
type_of_water_source
ORDER BY number_of_people DESC;

-- Let's rank the water sources according the number of people using the water 
-- It was hard to get the window functions but I finally did 
SELECT
type_of_water_source,
SUM(number_of_people_served) AS number_of_people,
RANK() OVER (ORDER BY SUM(number_of_people_served)DESC) AS rank_order 
FROM water_source
WHERE type_of_water_source != 'tap_in_home'
GROUP BY type_of_water_source;

-- The sources within each type should be assigned a rank.
-- I am just ranking the different sources, If we have 25 rivers and 30 wells, I will rank the rivers, finish then rank the well and so on 
-- Just realizing how important a windows function is 
SELECT
  source_id,
  type_of_water_source,
  number_of_people_served,
  RANK() OVER (PARTITION BY type_of_water_source ORDER BY number_of_people_served DESC) AS Priority_rank
FROM water_source
WHERE type_of_water_source != 'tap_in_home';

-- Limit the results to only improvable sources.
-- our homes with taps don't need improvement they're already good. Let's not look at them here 
SELECT
  source_id,
  type_of_water_source,
  number_of_people_served,
  DENSE_RANK() OVER (PARTITION BY type_of_water_source ORDER BY number_of_people_served DESC) AS Priority_rank
FROM water_source
WHERE type_of_water_source != 'tap_in_home';

--  How long did the survey take?
-- 924 days 
SELECT
  TIMESTAMPDIFF(DAY, MIN(time_of_record), MAX(time_of_record)) AS survey_duration_in_days
FROM visits;

-- 30 months 
SELECT
  TIMESTAMPDIFF(MONTH, MIN(time_of_record), MAX(time_of_record)) AS survey_duration_in_Months 
FROM visits;

-- 2 years 
SELECT
  TIMESTAMPDIFF(YEAR, MIN(time_of_record), MAX(time_of_record)) AS survey_duration_in_years 
FROM visits;

-- 22180 hours 
SELECT
  TIMESTAMPDIFF(HOUR, MIN(time_of_record), MAX(time_of_record)) AS survey_duration_in_hours
FROM visits;

-- What is the average total queue time for water?
SELECT
AVG(NULLIF(time_in_queue, 0)) AS average_queue_time
FROM visits;

-- What is the average queue time on different days?
SELECT
DAYNAME(time_of_record) AS day_of_week,
ROUND(AVG(NULLIF(time_in_queue, 0))) AS average_queue_time
FROM visits
GROUP BY day_of_week;

-- How can we communicate this information efficiently?
-- Let's breakdown the information into every hours 
SELECT
TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,
AVG(time_in_queue) AS average_time_queue
FROM visits
GROUP BY hour_of_day
ORDER BY hour_of_day ASC;

-- Use the CASE function to get every hour of every day on a weekly basis
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



-- Seeing what different date formarts will look like
SELECT CONCAT(monthname(time_of_record), " ", day(time_of_record), ", ", year(time_of_record)) FROM visits;
SELECT CONCAT(day(time_of_record), " ", monthname(time_of_record), " ", year(time_of_record)) FROM visits;
SELECT CONCAT(day(time_of_record), " ", month(time_of_record), " ", year(time_of_record)) FROM visits;
SELECT day(time_of_record), monthname(time_of_record), year(time_of_record) FROM visits;

-- How visits did each employee make? 
-- How are they performing ? Who should I reward ? etc
SELECT
  e.employee_name,
  COUNT(v.assigned_employee_id) AS visit_count
FROM employee e
LEFT JOIN visits v ON e.assigned_employee_id = v.assigned_employee_id
GROUP BY e.employee_name
ORDER BY visit_count;

-- 
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
    
-- employee is DAhabu only 
SELECT COUNT(*) AS employees_in_dahabu
FROM employee
WHERE town_name = 'Dahabu';
  
 -- The number of people living in  employees_in_harare_kilimani
SELECT COUNT(*) AS employees_in_harare_kilimani
FROM employee
WHERE town_name = 'Harare';

-- Average number of people who use well water
SELECT ROUND(AVG(number_of_people_served), 0) AS average_people_served_well
FROM water_source
WHERE type_of_water_source = 'well';

-- TOtal populataion served 
SELECT
SUM(number_of_people_served) AS population_served
FROM
water_source
ORDER BY
population_served;


-- Average time in queue for each location ID
SELECT 
    location_id,
    AVG(time_in_queue) OVER (PARTITION BY location_id ORDER BY visit_count) AS total_avg_queue_time
FROM 
    visits
WHERE 
visit_count > 1 -- Only shared taps were visited > 1
ORDER BY 
    location_id, time_of_record;
    
-- Trim removes spaces 
SELECT LENGTH(TRIM('33 Angelique Kidjo Avenue  '));
-- Rank employees and according  to number of visits
SELECT
e.employee_name,
COUNT(v.assigned_employee_id) AS number_of_visits,
RANK() OVER (ORDER BY COUNT(v.assigned_employee_id) ASC) AS rank_order 
FROM employee e
JOIN visits v ON e.assigned_employee_id = v.assigned_employee_id
GROUP BY e.employee_name
ORDER BY rank_order;

-- Seeing the difference in these queries? 
SELECT day(time_of_record), monthname(time_of_record), year(time_of_record) FROM visits;
SELECT CONCAT(monthname(time_of_record), " ", day(time_of_record), ", ", year(time_of_record)) FROM visits;
SELECT CONCAT(day(time_of_record), " ", month(time_of_record), " ", year(time_of_record)) FROM visits;

-- average number of people per well
SELECT ROUND(AVG(number_of_people_served)) AS average_people_well
FROM water_source
WHERE type_of_water_source LIKE '%well%';

























