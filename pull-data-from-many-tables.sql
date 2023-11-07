USE md_water_services;
SELECT * FROM auditor_report;
SELECT * FROM visits;
SELECT * FROM water_quality;

SELECT
    ar.location_id AS audit_location,
     v.record_id,
    ar.true_water_source_score AS auditor_score,
    wq.subjective_quality_score AS employee_score
FROM
    auditor_report AS ar
JOIN
    visits AS v
ON
    ar.location_id = v.location_id
JOIN
    (
    SELECT record_id, subjective_quality_score
    FROM water_quality
    ) AS wq
ON
    v.record_id = wq.record_id
WHERE
v.visit_count = 1
AND
ar.true_water_source_score-wq.subjective_quality_score<>0
LIMIT 10000;

SELECT
     ar.location_id AS audit_location,
    ws.type_of_water_source,
	v.record_id,
    ar.true_water_source_score AS auditor_score,
    wq.subjective_quality_score AS employee_score
FROM
    auditor_report AS ar
JOIN
    visits AS v
ON
    ar.location_id = v.location_id
JOIN
    water_quality AS wq
ON
    v.record_id = wq.record_id
JOIN
    water_source AS ws
ON
    v.source_id = ws.source_id
WHERE
    v.visit_count = 1
    AND ar.true_water_source_score = wq.subjective_quality_score;

WITH incorrect_records AS (
SELECT 
     ar.location_id AS audit_location,
    ws.type_of_water_source,
	v.record_id,
    ar.true_water_source_score AS auditor_score,
    wq.subjective_quality_score AS employee_score,
	e.employee_name AS employee_name

FROM
    auditor_report AS ar
JOIN
    visits AS v
ON
    ar.location_id = v.location_id
JOIN
    water_quality AS wq
ON
    v.record_id = wq.record_id
JOIN
    water_source AS ws
ON
    v.source_id = ws.source_id
JOIN 
	employee AS e
ON 
    e.assigned_employee_id=v.assigned_employee_id
WHERE
    v.visit_count = 1
    AND ar.true_water_source_score <>wq.subjective_quality_score
)

SELECT DISTINCT employee_name
FROM incorrect_records;

SELECT DISTINCT employee_name
FROM incorrect_records;

SELECT employee_name, COUNT(*) AS mistake_count
FROM (
    SELECT 
        ar.location_id AS audit_location,
        ws.type_of_water_source,
        v.record_id,
        ar.true_water_source_score AS auditor_score,
        wq.subjective_quality_score AS employee_score,
        e.employee_name AS employee_name
    FROM
        auditor_report AS ar
    JOIN
        visits AS v
    ON
        ar.location_id = v.location_id
    JOIN
        water_quality AS wq
    ON
        v.record_id = wq.record_id
    JOIN
        water_source AS ws
    ON
        v.source_id = ws.source_id
    JOIN 
        employee AS e
    ON 
        e.assigned_employee_id = v.assigned_employee_id
    WHERE
        v.visit_count = 1
        AND ar.true_water_source_score <> wq.subjective_quality_score
) AS Incorrect_records
GROUP BY employee_name
ORDER BY mistake_count DESC;


SELECT AVG(mistake_count) AS avg_error_count_per_empl
FROM (
    SELECT employee_name, COUNT(*) AS mistake_count
	FROM (
		SELECT 
			ar.location_id AS audit_location,
			ws.type_of_water_source,
			v.record_id,
			ar.true_water_source_score AS auditor_score,
			wq.subjective_quality_score AS employee_score,
			e.employee_name AS employee_name
		FROM
			auditor_report AS ar
		JOIN
			visits AS v
		ON
			ar.location_id = v.location_id
		JOIN
			water_quality AS wq
		ON
			v.record_id = wq.record_id
		JOIN
			water_source AS ws
		ON
			v.source_id = ws.source_id
		JOIN 
			employee AS e
		ON 
			e.assigned_employee_id = v.assigned_employee_id
		WHERE
			v.visit_count = 1
        AND ar.true_water_source_score <> wq.subjective_quality_score
) AS Incorrect_records
GROUP BY employee_name
) AS mistake_count;


SELECT employee_name, COUNT(*) AS mistake_count
FROM (
    SELECT 
        ar.location_id AS audit_location,
        ws.type_of_water_source,
        v.record_id,
        ar.true_water_source_score AS auditor_score,
        wq.subjective_quality_score AS employee_score,
        e.employee_name AS employee_name
    FROM
        auditor_report AS ar
    JOIN
        visits AS v
    ON
        ar.location_id = v.location_id
    JOIN
        water_quality AS wq
    ON
        v.record_id = wq.record_id
    JOIN
        water_source AS ws
    ON
        v.source_id = ws.source_id
    JOIN 
        employee AS e
    ON 
        e.assigned_employee_id = v.assigned_employee_id
    WHERE
        v.visit_count = 1
        AND ar.true_water_source_score <> wq.subjective_quality_score
) AS Incorrect_records
GROUP BY employee_name
HAVING mistake_count > (
    SELECT AVG(mistake_count) AS avg_error_count_per_empl
    FROM (
        SELECT employee_name, COUNT(*) AS mistake_count
        FROM (
            SELECT 
                ar.location_id AS audit_location,
                ws.type_of_water_source,
                v.record_id,
                ar.true_water_source_score AS auditor_score,
                wq.subjective_quality_score AS employee_score,
                e.employee_name AS employee_name
            FROM
                auditor_report AS ar
            JOIN
                visits AS v
            ON
                ar.location_id = v.location_id
            JOIN
                water_quality AS wq
            ON
                v.record_id = wq.record_id
            JOIN
                water_source AS ws
            ON
                v.source_id = ws.source_id
            JOIN 
                employee AS e
            ON 
                e.assigned_employee_id = v.assigned_employee_id
            WHERE
                v.visit_count = 1
                AND ar.true_water_source_score <> wq.subjective_quality_score
        ) AS Subquery
        GROUP BY employee_name
    ) AS AvgMistakeCounts
)
ORDER BY mistake_count DESC;


CREATE VIEW incorrect_records AS (
SELECT
auditor_report.location_id,
visits.record_id,
employee.employee_name,
auditor_report.true_water_source_score AS auditor_score,
wq.subjective_quality_score AS employee_score,
auditor_report.statements AS statements
FROM
auditor_report
JOIN
visits
ON auditor_report.location_id = visits.location_id
JOIN
water_quality AS wq
ON visits.record_id = wq.record_id
JOIN
employee
ON employee.assigned_employee_id = visits.assigned_employee_id
WHERE
visits.visit_count =1
AND auditor_report.true_water_source_score != wq.subjective_quality_score);


WITH error_count AS (
    SELECT 
        employee_name,
        COUNT(*) AS number_of_mistakes
    FROM
        Incorrect_records
    GROUP BY
        employee_name
)
-- Query
SELECT AVG(number_of_mistakes) AS average_mistakes FROM error_count;


WITH error_count AS (
    SELECT 
        employee_name,
        COUNT(*) AS mistake_count
    FROM
        Incorrect_records
    GROUP BY
        employee_name
)
SELECT employee_name, mistake_count
FROM error_count
WHERE mistake_count < (SELECT AVG(mistake_count) FROM error_count);


WITH error_count AS (
    SELECT 
        employee_name,
        COUNT(*) AS mistake_count
    FROM
        Incorrect_records
    GROUP BY
        employee_name
),
suspect_list AS (
    SELECT employee_name, mistake_count
    FROM error_count
    WHERE mistake_count > (SELECT AVG(mistake_count) FROM error_count)
)
-- Query
SELECT employee_name, mistake_count
FROM suspect_list;


WITH error_count AS (
    SELECT 
        employee_name,
        COUNT(*) AS mistake_count
    FROM
        Incorrect_records
    GROUP BY
        employee_name
),
suspect_list AS (
    SELECT employee_name, mistake_count
    FROM error_count
    WHERE mistake_count > (SELECT AVG(mistake_count) FROM error_count)
)
-- Modified Incorrect_records CTE
, Incorrect_records AS (
    SELECT 
        ar.location_id AS audit_location,
        ws.type_of_water_source,
        v.record_id,
        ar.true_water_source_score AS auditor_score,
        wq.subjective_quality_score AS employee_score,
        e.employee_name AS employee_name,
        statements -- Assuming statements column exists in your schema
    FROM
        auditor_report AS ar
    JOIN
        visits AS v
    ON
        ar.location_id = v.location_id
    JOIN
        water_quality AS wq
    ON
        v.record_id = wq.record_id
    JOIN
        water_source AS ws
    ON
        v.source_id = ws.source_id
    JOIN 
        employee AS e
    ON 
        e.assigned_employee_id = v.assigned_employee_id
    WHERE
        v.visit_count = 1
        AND ar.true_water_source_score <> wq.subjective_quality_score
)

-- Query to retrieve records for the suspects
SELECT *
FROM Incorrect_records
WHERE employee_name IN (SELECT employee_name FROM suspect_list);

WITH error_count AS ( -- This CTE calculates the number of mistakes each employee made
SELECT
employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM
Incorrect_records
/* Incorrect_records is a view that joins the audit report to the database
for records where the auditor and
employees scores are different*/
GROUP BY
employee_name),
suspect_list AS (-- This CTE SELECTS the employees with above−average mistakes
SELECT
employee_name,
number_of_mistakes
FROM
error_count
WHERE
number_of_mistakes > (SELECT AVG(number_of_mistakes) FROM error_count))
-- This query filters all of the records where the "corrupt" employees gathered data.
SELECT
employee_name,
location_id,
statements
FROM
Incorrect_records
WHERE
employee_name in (SELECT employee_name FROM suspect_list);


WITH error_count AS ( -- This CTE calculates the number of mistakes each employee made
SELECT
employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM
Incorrect_records
/* Incorrect_records is a view that joins the audit report to the database
for records where the auditor and
employees scores are different*/
GROUP BY
employee_name),
suspect_list AS (-- This CTE SELECTS the employees with above−average mistakes
SELECT
employee_name,
number_of_mistakes
FROM
error_count
WHERE
number_of_mistakes > (SELECT AVG(number_of_mistakes) FROM error_count))
-- This query filters all of the records where the "corrupt" employees gathered data.
SELECT *
FROM Incorrect_records
WHERE employee_name IN (SELECT employee_name FROM suspect_list)
AND statements LIKE '%cash%';



WITH error_count AS ( -- This CTE calculates the number of mistakes each employee made
SELECT
employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM
Incorrect_records
/* Incorrect_records is a view that joins the audit report to the database
for records where the auditor and
employees scores are different*/
GROUP BY
employee_name),
suspect_list AS (-- This CTE SELECTS the employees with above−average mistakes
SELECT
employee_name,
number_of_mistakes
FROM
error_count
WHERE
number_of_mistakes > (SELECT AVG(number_of_mistakes) FROM error_count))
-- This query filters all of the records where the "corrupt" employees gathered data.
SELECT *
FROM Incorrect_records
WHERE employee_name NOT IN (SELECT employee_name FROM suspect_list)
AND statements LIKE '%cash%';

/* The Real Exam */
SELECT
    auditorRep.location_id,
    visitsTbl.record_id,
    Empl_Table.employee_name,
    auditorRep.true_water_source_score AS auditor_score,
    wq.subjective_quality_score AS employee_score
FROM auditor_report AS auditorRep
JOIN visits AS visitsTbl
ON auditorRep.location_id = visitsTbl.location_id
JOIN water_quality AS wq
ON visitsTbl.record_id = wq.record_id
JOIN employee as Empl_Table
ON Empl_Table.assigned_employee_id = visitsTbl.assigned_employee_id
LIMIT 10000;

WITH Incorrect_records AS ( /*This CTE fetches all of the records with wrong scores*/
SELECT
    auditorRep.location_id,
    visitsTbl.record_id,
    Empl_Table.employee_name,
    auditorRep.true_water_source_score AS auditor_score,
    wq.subjective_quality_score AS employee_score
FROM auditor_report AS auditorRep
JOIN visits AS visitsTbl
ON auditorRep.location_id = visitsTbl.location_id
JOIN water_quality AS wq
ON visitsTbl.record_id = wq.record_id
JOIN employee as Empl_Table
ON Empl_Table.assigned_employee_id = visitsTbl.assigned_employee_id
WHERE visitsTbl.visit_count =1 AND auditorRep.true_water_source_score != wq.subjective_quality_score)

SELECT
    employee_name,
    count(employee_name)
FROM Incorrect_records
GROUP BY Employee_name;


