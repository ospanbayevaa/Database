CREATE DATABASE lab_4;

-- Create tables
CREATE TABLE employees (
employee_id SERIAL PRIMARY KEY,
first_name VARCHAR(50),
last_name VARCHAR(50),
department VARCHAR(50),
salary NUMERIC(10,2),
hire_date DATE,
manager_id INTEGER,
email VARCHAR(100)
);
CREATE TABLE projects (
project_id SERIAL PRIMARY KEY,
project_name VARCHAR(100),
budget NUMERIC(12,2),
start_date DATE,
end_date DATE,
status VARCHAR(20)
);
CREATE TABLE assignments (
assignment_id SERIAL PRIMARY KEY,
employee_id INTEGER REFERENCES employees(employee_id),
project_id INTEGER REFERENCES projects(project_id),
hours_worked NUMERIC(5,1),
assignment_date DATE
);

-- Insert sample data
INSERT INTO employees (first_name, last_name, department,
salary, hire_date, manager_id, email) VALUES
('John', 'Smith', 'IT', 75000, '2020-01-15', NULL,
'john.smith@company.com'),
('Sarah', 'Johnson', 'IT', 65000, '2020-03-20', 1,
'sarah.j@company.com'),
('Michael', 'Brown', 'Sales', 55000, '2019-06-10', NULL,
'mbrown@company.com'),
('Emily', 'Davis', 'HR', 60000, '2021-02-01', NULL,
'emily.davis@company.com'),
('Robert', 'Wilson', 'IT', 70000, '2020-08-15', 1, NULL),
('Lisa', 'Anderson', 'Sales', 58000, '2021-05-20', 3,
'lisa.a@company.com');
INSERT INTO projects (project_name, budget, start_date,
end_date, status) VALUES
('Website Redesign', 150000, '2024-01-01', '2024-06-30',
'Active'),
('CRM Implementation', 200000, '2024-02-15', '2024-12-31',
'Active'),
('Marketing Campaign', 80000, '2024-03-01', '2024-05-31',
'Completed'),
('Database Migration', 120000, '2024-01-10', NULL, 'Active');
INSERT INTO assignments (employee_id, project_id,
hours_worked, assignment_date) VALUES
(1, 1, 120.5, '2024-01-15'),
(2, 1, 95.0, '2024-01-20'),
(1, 4, 80.0, '2024-02-01'),
(3, 3, 60.0, '2024-03-05'),
(5, 2, 110.0, '2024-02-20'),
(6, 3, 75.5, '2024-03-10');

-- Task 1.1
SELECT
  employee_id,
  first_name || ' ' || last_name AS full_name,
  department,
  salary
FROM employees;

-- Task 1.2
SELECT DISTINCT department
FROM employees
ORDER BY department;

-- Task 1.3
SELECT
  project_id,
  project_name,
  budget,
  CASE
    WHEN budget > 150000 THEN 'Large'
    WHEN budget BETWEEN 100000 AND 150000 THEN 'Medium'
    ELSE 'Small'
  END AS budget_category
FROM projects;

-- Task 1.4
SELECT
  employee_id,
  first_name || ' ' || last_name AS full_name,
  COALESCE(email, 'No email provided') AS email
FROM employees;

-- Task 2.1
SELECT
  employee_id,
  first_name || ' ' || last_name AS full_name,
  hire_date
FROM employees
WHERE hire_date > DATE '2020-01-01';

-- Task 2.2
SELECT
  employee_id,
  first_name || ' ' || last_name AS full_name,
  salary
FROM employees
WHERE salary BETWEEN 60000 AND 70000;

-- Task 2.3
SELECT
  employee_id,
  first_name || ' ' || last_name AS full_name,
  last_name
FROM employees
WHERE last_name LIKE 'S%' OR last_name LIKE 'J%';

-- Task 2.4
SELECT
  employee_id,
  first_name || ' ' || last_name AS full_name,
  department,
  manager_id
FROM employees
WHERE manager_id IS NOT NULL
  AND department = 'IT';

-- Task 3.1
SELECT
  employee_id,
  UPPER(first_name || ' ' || last_name) AS name_upper,
  LENGTH(last_name) AS last_name_length,
  SUBSTRING(COALESCE(email, '') FROM 1 FOR 3) AS email_first3
FROM employees;

-- Task 3.2
SELECT
  employee_id,
  first_name || ' ' || last_name AS full_name,
  salary AS monthly_base, -- assuming salary column is annual; if salary is annual, adjust names accordingly
  (salary) AS annual_salary,
  ROUND((salary / 12)::numeric, 2) AS monthly_salary,
  ROUND((salary * 0.10)::numeric, 2) AS ten_percent_raise
FROM employees;

-- Task 3.3
SELECT
  project_id,
  format('Project: %s - Budget: $%s - Status: %s', project_name, budget, status) AS project_info
FROM projects;

-- Task 3.4
SELECT
  employee_id,
  first_name || ' ' || last_name AS full_name,
  hire_date,
  FLOOR(EXTRACT(YEAR FROM AGE(CURRENT_DATE, hire_date)))::INT AS years_with_company
FROM employees;

-- Task 4.1
SELECT
  department,
  ROUND(AVG(salary)::numeric, 2) AS avg_salary
FROM employees
GROUP BY department;

-- Task 4.2
SELECT
  p.project_id,
  p.project_name,
  COALESCE(SUM(a.hours_worked), 0) AS total_hours
FROM projects p
LEFT JOIN assignments a ON p.project_id = a.project_id
GROUP BY p.project_id, p.project_name;

-- Task 4.3
SELECT
  department,
  COUNT(*) AS employee_count
FROM employees
GROUP BY department
HAVING COUNT(*) > 1;

-- Task 4.4
SELECT
  MAX(salary) AS max_salary,
  MIN(salary) AS min_salary,
  SUM(salary) AS total_payroll
FROM employees;

-- Task 5.1
-- Query 1
SELECT employee_id, first_name || ' ' || last_name AS full_name, salary
FROM employees
WHERE salary > 65000
UNION
-- Query 2
SELECT employee_id, first_name || ' ' || last_name AS full_name, salary
FROM employees
WHERE hire_date > DATE '2020-01-01'
ORDER BY full_name;

-- Task 5.2
SELECT employee_id, first_name || ' ' || last_name AS full_name, salary
FROM employees
WHERE department = 'IT'
INTERSECT
SELECT employee_id, first_name || ' ' || last_name AS full_name, salary
FROM employees
WHERE salary > 65000;

-- Task 5.3
SELECT employee_id, first_name || ' ' || last_name AS full_name
FROM employees
EXCEPT
SELECT e.employee_id, e.first_name || ' ' || e.last_name AS full_name
FROM employees e
JOIN assignments a ON e.employee_id = a.employee_id
ORDER BY full_name;

-- Task 6.1
SELECT
  e.employee_id,
  e.first_name || ' ' || e.last_name AS full_name
FROM employees e
WHERE EXISTS (
  SELECT 1 FROM assignments a WHERE a.employee_id = e.employee_id
);

-- Task 6.2
SELECT DISTINCT
  e.employee_id,
  e.first_name || ' ' || e.last_name AS full_name
FROM employees e
WHERE e.employee_id IN (
  SELECT a.employee_id
  FROM assignments a
  WHERE a.project_id IN (
    SELECT project_id FROM projects WHERE status = 'Active'
  )
);

-- Task 6.3
SELECT
  employee_id,
  first_name || ' ' || last_name AS full_name,
  salary
FROM employees
WHERE salary > ANY (
  SELECT salary FROM employees WHERE department = 'Sales'
);

-- Task 7.1
SELECT
  e.employee_id,
  e.first_name || ' ' || e.last_name AS full_name,
  e.department,
  ROUND(COALESCE(avg_hours, 0)::numeric, 2) AS avg_hours_worked,
  RANK() OVER (PARTITION BY e.department ORDER BY e.salary DESC) AS salary_rank_in_department
FROM employees e
LEFT JOIN (
  SELECT employee_id, AVG(hours_worked) AS avg_hours
  FROM assignments
  GROUP BY employee_id
) ah ON e.employee_id = ah.employee_id
ORDER BY e.department, salary_rank_in_department;

-- Task 7.2
SELECT
  p.project_id,
  p.project_name,
  SUM(a.hours_worked) AS total_hours,
  COUNT(DISTINCT a.employee_id) AS num_employees_assigned
FROM projects p
JOIN assignments a ON p.project_id = a.project_id
GROUP BY p.project_id, p.project_name
HAVING SUM(a.hours_worked) > 150
ORDER BY total_hours DESC;

-- Task 7.3
WITH dept_stats AS (
  SELECT
    department,
    COUNT(*) AS total_employees,
    ROUND(AVG(salary)::numeric, 2) AS avg_salary,
    MAX(salary) AS max_salary,
    MIN(salary) AS min_salary
  FROM employees
  GROUP BY department
)
SELECT
  ds.department,
  ds.total_employees,
  ds.avg_salary,
  ds.max_salary,
  ds.min_salary,
  -- highest paid employee name (if ties, returns one via DISTINCT ON)
  hp.full_name AS highest_paid_employee,
  -- demonstrate GREATEST and LEAST usage:
  GREATEST(ds.max_salary, ds.avg_salary) AS greatest_of_max_and_avg,
  LEAST(ds.min_salary, ds.avg_salary) AS least_of_min_and_avg
FROM dept_stats ds
LEFT JOIN LATERAL (
  SELECT e.first_name || ' ' || e.last_name AS full_name
  FROM employees e
  WHERE e.department = ds.department
  ORDER BY e.salary DESC, e.employee_id
  LIMIT 1
) hp ON true
ORDER BY ds.department;
