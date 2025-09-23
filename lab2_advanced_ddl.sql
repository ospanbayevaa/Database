-- Part 1
-- Task 1.1: Database Creation with Parameters


CREATE DATABASE university_main
WITH OWNER = postgres
ENCODING = 'UTF8'
TEMPLATE = template0;

CREATE DATABASE university_archive
WITH OWNER = postgres
CONNECTION LIMIT = 50
TEMPLATE = template0;

CREATE DATABASE university_test
WITH OWNER = postgres
CONNECTION LIMIT = 10
TEMPLATE = template0;


UPDATE pg_database
SET datistemplate = TRUE
WHERE datname = 'university_test';

-- Task 1.2: Tablespace Operations


CREATE TABLESPACE student_data
LOCATION '/data/students';


CREATE TABLESPACE course_data
OWNER postgres
LOCATION '/data/courses';


CREATE DATABASE university_test
    TEMPLATE = template0
    CONNECTION LIMIT = 10
    IS_TEMPLATE = true;


-- Part 2
-- Task 2.1: University Management System


-- Student table
CREATE TABLE students (
    student_id SERIAL PRIMARY KEY, 
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone CHAR(15),
    date_of_birth DATE,
    enrollment_date DATE,
    gpa DECIMAL(3,2), 
    is_active BOOLEAN DEFAULT TRUE,
    graduation_year SMALLINT
);

-- Professors table
CREATE TABLE professors (
    professor_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    office_number VARCHAR(20),
    hire_date DATE,
    salary DECIMAL(12,2), 
    is_tenured BOOLEAN DEFAULT FALSE,
    years_experience INT
);

-- Course table
CREATE TABLE courses (
    course_id SERIAL PRIMARY KEY,
    course_code CHAR(8) UNIQUE NOT NULL,
    course_title VARCHAR(100) NOT NULL,
    description TEXT,
    credits SMALLINT,
    max_enrollment INT,
    course_fee DECIMAL(10,2),
    is_online BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Task 2.2: Time-based and Specialized Tables


-- Class schedule table
CREATE TABLE class_schedule (
    schedule_id SERIAL PRIMARY KEY,
    course_id INT NOT NULL,
    professor_id INT NOT NULL,
    classroom VARCHAR(20),
    class_date DATE,
    start_time TIME WITHOUT TIME ZONE,
    end_time TIME WITHOUT TIME ZONE,
    duration INTERVAL
);

-- Student records table
CREATE TABLE student_records (
    record_id SERIAL PRIMARY KEY,
    student_id INT NOT NULL,
    course_id INT NOT NULL,
    semester VARCHAR(20),
    year INT,
    grade CHAR(2),
    attendance_percentage DECIMAL(4,1),
    submission_timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Part 3
-- Task 3.1: Modifying Existing Tables

-- Students table modifications
ALTER TABLE students
ADD COLUMN middle_name VARCHAR(30),
ADD COLUMN student_status VARCHAR(20) DEFAULT 'ACTIVE';

ALTER TABLE students
ALTER COLUMN phone TYPE VARCHAR(20);

ALTER TABLE students
ALTER COLUMN gpa SET DEFAULT 0.00;

-- Professors table modifications
ALTER TABLE professors
ADD COLUMN department_code CHAR(5),
ADD COLUMN research_area TEXT,
ADD COLUMN last_promotion_date DATE;

ALTER TABLE professors
ALTER COLUMN years_experience TYPE SMALLINT,
ALTER COLUMN is_tenured SET DEFAULT FALSE;

-- Courses table modifications
ALTER TABLE courses
ADD COLUMN prerequisite_course_id INT,
ADD COLUMN difficulty_level SMALLINT,
ADD COLUMN lab_required BOOLEAN DEFAULT FALSE;

ALTER TABLE courses
ALTER COLUMN course_code TYPE VARCHAR(10),
ALTER COLUMN credits SET DEFAULT 3;

-- Task 3.2: Column Management Operations

-- Class_schedule modifications
ALTER TABLE class_schedule
ADD COLUMN room_capacity INT,
ADD COLUMN session_type VARCHAR(15),
ADD COLUMN equipment_needed TEXT;

ALTER TABLE class_schedule
DROP COLUMN duration;

ALTER TABLE class_schedule
ALTER COLUMN classroom TYPE VARCHAR(30);

-- Student_records modifications
ALTER TABLE student_records
ADD COLUMN extra_credit_points DECIMAL(4,1) DEFAULT 0.0,
ADD COLUMN final_exam_date DATE;

ALTER TABLE student_records
ALTER COLUMN grade TYPE VARCHAR(5);

ALTER TABLE student_records
DROP COLUMN last_updated;

-- Part 4
-- Task 4.1: Additional Supporting Tables

-- Departments table
CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL,
    department_code CHAR(5) UNIQUE NOT NULL,
    building VARCHAR(50),
    phone VARCHAR(15),
    budget DECIMAL(15,2),
    established_year INT
);

-- Library books table
CREATE TABLE library_books (
    book_id SERIAL PRIMARY KEY,
    isbn CHAR(13) UNIQUE NOT NULL,
    title VARCHAR(200) NOT NULL,
    author VARCHAR(100),
    publisher VARCHAR(100),
    publication_date DATE,
    price DECIMAL(10,2),
    is_available BOOLEAN DEFAULT TRUE,
    acquisition_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Student book loans table
CREATE TABLE student_book_loans (
    loan_id SERIAL PRIMARY KEY,
    student_id INT NOT NULL,
    book_id INT NOT NULL,
    loan_date DATE,
    due_date DATE,
    return_date DATE,
    fine_amount DECIMAL(10,2) DEFAULT 0.00,
    loan_status VARCHAR(20)
);

-- Task 4.2: Table Modifications for Integration

-- Add foreign key columns (но пока без связей)
ALTER TABLE professors
ADD COLUMN department_id INT;

ALTER TABLE students
ADD COLUMN advisor_id INT;

ALTER TABLE courses
ADD COLUMN department_id INT;

-- Lookup table: Grade scale
CREATE TABLE grade_scale (
    grade_id SERIAL PRIMARY KEY,
    letter_grade CHAR(2) UNIQUE NOT NULL,
    min_percentage DECIMAL(4,1),
    max_percentage DECIMAL(4,1),
    gpa_points DECIMAL(3,2)
);

-- Lookup table: Semester calendar
CREATE TABLE semester_calendar (
    semester_id SERIAL PRIMARY KEY,
    semester_name VARCHAR(20) NOT NULL,
    academic_year INT,
    start_date DATE,
    end_date DATE,
    registration_deadline TIMESTAMPTZ,
    is_current BOOLEAN DEFAULT FALSE
);

-- Part 5
-- Task 5.1: Conditional Table Operations

-- Drop tables if they exist
DROP TABLE IF EXISTS student_book_loans;
DROP TABLE IF EXISTS library_books;
DROP TABLE IF EXISTS grade_scale;

-- Recreate grade_scale with modified structure
CREATE TABLE grade_scale (
    grade_id SERIAL PRIMARY KEY,
    letter_grade CHAR(2) UNIQUE NOT NULL,
    min_percentage DECIMAL(4,1),
    max_percentage DECIMAL(4,1),
    gpa_points DECIMAL(3,2),
    description TEXT
);

-- Drop and recreate semester_calendar with CASCADE
DROP TABLE IF EXISTS semester_calendar CASCADE;

CREATE TABLE semester_calendar (
    semester_id SERIAL PRIMARY KEY,
    semester_name VARCHAR(20) NOT NULL,
    academic_year INT,
    start_date DATE,
    end_date DATE,
    registration_deadline TIMESTAMPTZ,
    is_current BOOLEAN DEFAULT FALSE
);

-- Task 5.2: Database Cleanup

-- Drop databases if they exist
DROP DATABASE IF EXISTS university_test;
DROP DATABASE IF EXISTS university_distributed;

-- Create backup database using university_main as template
CREATE DATABASE university_backup
WITH TEMPLATE university_main
OWNER postgres;
