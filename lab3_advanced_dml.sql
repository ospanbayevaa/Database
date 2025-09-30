CREATE DATABASE advanced_lab;



CREATE TABLE employees
(
    emp_id     SERIAL PRIMARY KEY,
    first_name VARCHAR(100),
    last_name  VARCHAR(100),
    department VARCHAR(100),
    salary     INT,
    hire_date  DATE,
    status    VARCHAR(100) DEFAULT 'ACTIVE'
);
CREATE TABLE departments
(
    dept_id    SERIAL PRIMARY KEY,
    dept_name  VARCHAR(100),
    budget     INT,
    manager_id INT
);

CREATE TABLE projects
(
    project_id   SERIAL PRIMARY KEY,
    project_name VARCHAR(100),
    dept_id      INT,
    start_date   DATE,
    end_date     DATE,
    budget       INT
);
-- PART B
-- 2
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES
('Dakl', 'Shmakl','IT',100000,'2023-09-29','ACTIVE'),
('Akl', 'Shmakl', 'HR', 5000000,'2023-09-29', 'ACTIVE'),
('Samikosh','Urmanova', 'CEO',9999999,'2023-09-29','ACNIVE');
-- 3
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Jane', 'Smith', 'Sales', DEFAULT, CURRENT_DATE, DEFAULT);
-- 4
INSERT INTO departments (dept_name, budget, manager_id)
VALUES
('IT', 200000, NULL),
('Sales', 120000, NULL),
('HR', 80000, NULL);
--5
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Alice', 'Williams', 'HR', 50000 * 1.1, CURRENT_DATE);

-- 6
CREATE TEMP TABLE temp_employees AS
SELECT * FROM employees WHERE department = 'IT';

-- 7
UPDATE employees
SET salary = salary * 1.10;


-- 8
UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < '2020-01-01';


-- 9
UPDATE employees
SET department = CASE
    WHEN salary > 80000 THEN 'Management'
    WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
    ELSE 'Junior'
    END;


-- 10
UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';


-- 11
UPDATE departments d
SET budget = (
    SELECT AVG(e.salary) * 1.20
    FROM employees e
    WHERE e.department = d.dept_name
)
WHERE EXISTS (
    SELECT 1 FROM employees e WHERE e.department = d.dept_name
);


-- 12
UPDATE employees
SET salary = salary * 1.15,
    status = 'Promoted'
WHERE department = 'Sales';


-- 13
DELETE FROM employees
WHERE status = 'Terminated';


-- 14
DELETE FROM employees
WHERE salary < 40000
  AND hire_date > '2023-01-01'
  AND department IS NULL;


-- 15
DELETE FROM departments
WHERE dept_id NOT IN (
    SELECT DISTINCT d.dept_id
    FROM departments d
             JOIN employees e ON d.dept_name = e.department
    WHERE e.department IS NOT NULL
);


-- 16
DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;

-- 17
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Null', 'Case', NULL, NULL, CURRENT_DATE, 'Active');


-- 18
UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;


-- 19
DELETE FROM employees
WHERE salary IS NULL
   OR department IS NULL;

 -- 20
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Return', 'Tester', 'IT', 55000, CURRENT_DATE)
RETURNING emp_id, first_name || ' ' || last_name AS full_name;


-- 21
UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING emp_id,
    salary - 5000 AS old_salary,
    salary AS new_salary;


-- 22
DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;
 -- 23

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT 'Unique', 'Person', 'R&D', 60000, CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM employees
    WHERE first_name = 'Unique' AND last_name = 'Person'
);



UPDATE employees e
SET salary = salary * CASE
                          WHEN (SELECT d.budget FROM departments d WHERE d.dept_name = e.department) > 100000
                              THEN 1.10
                          ELSE 1.05
    END;



-- 25
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES
    ('Bulk1', 'Emp', 'IT', 50000, CURRENT_DATE),
    ('Bulk2', 'Emp', 'Sales', 48000, CURRENT_DATE),
    ('Bulk3', 'Emp', 'HR', 47000, CURRENT_DATE),
    ('Bulk4', 'Emp', 'R&D', 52000, CURRENT_DATE),
    ('Bulk5', 'Emp', 'Support', 45000, CURRENT_DATE);


UPDATE employees
SET salary = salary * 1.10
WHERE first_name LIKE 'Bulk%';


-- 26
-- 1
CREATE TABLE IF NOT EXISTS employee_archive AS
SELECT * FROM employees WHERE 1=0;

-- 2
INSERT INTO employee_archive
SELECT * FROM employees WHERE status = 'Inactive';

-- 3
DELETE FROM employees
WHERE status = 'Inactive';


-- 27
UPDATE projects p
SET end_date = end_date + INTERVAL '30 days'
WHERE budget > 50000
  AND (
          SELECT COUNT(*)
          FROM employees e
          WHERE e.department = (SELECT d.dept_name
                                FROM departments d
                                WHERE d.dept_id = p.dept_id
                                );