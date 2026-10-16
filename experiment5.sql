-- ASHISH KUMAR RAWAT | 25LBCS3229 | BTECH CSE AIML - 3
-- EXPERIMENT 5
-- Aim: Using the Employee schema, demonstrate:
-- SQL Views (Department Salary Summary, Employee Hierarchy),
-- Updatability of Views (simple, CHECK OPTION, aggregate),
-- Recursive CTE to display Reporting Chains

USE EmployeeDB;

-- ADD MANAGER COLUMN (SETUP FOR HIERARCHY)
ALTER TABLE Employee
ADD COLUMN manager_id INT NULL;

UPDATE Employee
SET manager_id = NULL
WHERE emp_id = 1;

UPDATE Employee
SET manager_id = FLOOR((emp_id - 2) / 5) + 1
WHERE emp_id > 1;

ALTER TABLE Employee
ADD CONSTRAINT fk_emp_manager
FOREIGN KEY (manager_id) REFERENCES Employee(emp_id);

SELECT emp_id, emp_name, manager_id
FROM Employee;

-- VIEW 1 - DEPARTMENT SALARY SUMMARY
CREATE OR REPLACE VIEW dept_salary_summary AS
SELECT
    d.dept_id,
    d.dept_name,
    COUNT(e.emp_id) AS total_employees,
    SUM(e.salary) AS total_salary,
    ROUND(AVG(e.salary), 2) AS avg_salary,
    MIN(e.salary) AS min_salary,
    MAX(e.salary) AS max_salary
FROM Department d
LEFT JOIN Employee e
    ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name;

SELECT * FROM dept_salary_summary;

-- VIEW 2 - EMPLOYEE HIERARCHY
CREATE OR REPLACE VIEW emp_hierarchy AS
SELECT
    e.emp_id,
    e.emp_name,
    d.dept_name,
    e.manager_id,
    m.emp_name AS manager_name
FROM Employee e
LEFT JOIN Employee m
    ON e.manager_id = m.emp_id
LEFT JOIN Department d
    ON e.dept_id = d.dept_id;

SELECT * FROM emp_hierarchy
ORDER BY manager_id, emp_id;

-- UPDATABILITY TEST 1 - SIMPLE VIEW (UPDATABLE)
CREATE OR REPLACE VIEW emp_basic_view AS
SELECT emp_id, emp_name, dept_id, salary
FROM Employee;

UPDATE emp_basic_view
SET salary = salary + 1000
WHERE emp_id = 1;

SELECT emp_id, emp_name, salary
FROM Employee
WHERE emp_id = 1;

UPDATE emp_basic_view
SET salary = salary - 1000
WHERE emp_id = 1;

-- UPDATABILITY TEST 2 - VIEW WITH CHECK OPTION
CREATE OR REPLACE VIEW sciences_emp_view AS
SELECT emp_id, emp_name, dept_id, salary
FROM Employee
WHERE dept_id = 2
WITH CHECK OPTION;

-- Allowed: row still satisfies dept_id = 2
UPDATE sciences_emp_view
SET salary = salary + 500
WHERE emp_id = 2;

-- Rejected: new row would violate dept_id = 2
UPDATE sciences_emp_view
SET dept_id = 1
WHERE emp_id = 2;

-- Revert the valid change
UPDATE sciences_emp_view
SET salary = salary - 500
WHERE emp_id = 2;

-- UPDATABILITY TEST 3 - AGGREGATE VIEW (NOT UPDATABLE)
UPDATE dept_salary_summary
SET avg_salary = 100000
WHERE dept_id = 1;

-- CHECK UPDATABLE STATUS OF ALL VIEWS
SELECT
    table_name AS view_name,
    is_updatable
FROM information_schema.views
WHERE table_schema = DATABASE();

-- RECURSIVE CTE - REPORTING CHAIN (TOP DOWN)
WITH RECURSIVE reporting_chain AS
(
    SELECT
        emp_id,
        emp_name,
        manager_id,
        1 AS level,
        CAST(emp_name AS CHAR(500)) AS chain
    FROM Employee
    WHERE manager_id IS NULL

    UNION ALL

    SELECT
        e.emp_id,
        e.emp_name,
        e.manager_id,
        rc.level + 1,
        CONCAT(rc.chain, ' -> ', e.emp_name)
    FROM Employee e
    JOIN reporting_chain rc
        ON e.manager_id = rc.emp_id
)
SELECT emp_id, emp_name, level, chain
FROM reporting_chain
ORDER BY level, emp_id;

-- RECURSIVE CTE - REPORTING CHAIN OF ONE EMPLOYEE (BOTTOM UP)
WITH RECURSIVE upward_chain AS
(
    SELECT
        emp_id,
        emp_name,
        manager_id,
        0 AS steps_above
    FROM Employee
    WHERE emp_id = 27

    UNION ALL

    SELECT
        e.emp_id,
        e.emp_name,
        e.manager_id,
        uc.steps_above + 1
    FROM Employee e
    JOIN upward_chain uc
        ON e.emp_id = uc.manager_id
)
SELECT emp_id, emp_name, steps_above
FROM upward_chain
ORDER BY steps_above;
