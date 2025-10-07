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
