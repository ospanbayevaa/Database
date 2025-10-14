-- Database Constraints - Laboratory Work
-- Student: Ospanbayeva Adina
-- Student ID: 24B030310

-- Task 1.1: 
CREATE TABLE employees (
    employee_id INTEGER,
    first_name TEXT,
    last_name TEXT,
    age INTEGER CHECK (age BETWEEN 18 AND 65), 
    salary NUMERIC CHECK (salary > 0)           
);

-- Task 1.2
CREATE TABLE products_catalog (
    product_id INTEGER,
    product_name TEXT,
    regular_price NUMERIC,
    discount_price NUMERIC,
    CONSTRAINT valid_discount CHECK (
        regular_price > 0
        AND discount_price > 0
        AND discount_price < regular_price
    )
);

-- Task 1.3
CREATE TABLE bookings (
    booking_id INTEGER,
    check_in_date DATE,
    check_out_date DATE,
    num_guests INTEGER CHECK (num_guests BETWEEN 1 AND 10),
    CHECK (check_out_date > check_in_date) -- check-out after check-in
);

-- Task 1.4
INSERT INTO employees (employee_id, first_name, last_name, age, salary) VALUES
(1, 'Aida', 'Kaidar', 25, 500.00),
(2, 'Bulat', 'Tasbol', 45, 1200.50);

-- Successful inserts (products_catalog)
INSERT INTO products_catalog (product_id, product_name, regular_price, discount_price) VALUES
(10, 'Notebook', 1000.00, 900.00),
(11, 'Pen Set', 10.00, 7.50);

-- Successful inserts (bookings)
INSERT INTO bookings (booking_id, check_in_date, check_out_date, num_guests) VALUES
(100, '2025-10-01', '2025-10-05', 2),
(101, '2025-12-15', '2025-12-20', 4);

-- Task 2.1
CREATE TABLE customers (
    customer_id INTEGER NOT NULL,
    email TEXT NOT NULL,
    phone TEXT, -- может быть NULL
    registration_date DATE NOT NULL
);

-- Task 2.2
CREATE TABLE inventory (
    item_id INTEGER NOT NULL,
    item_name TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity >= 0), 
    unit_price NUMERIC NOT NULL CHECK (unit_price > 0), 
    last_updated TIMESTAMP NOT NULL
);

-- Task 2.3
-- Successful inserts (customers)
INSERT INTO customers (customer_id, email, phone, registration_date) VALUES
(1, 'alice@example.com', '77001112233', '2025-01-10'),
(2, 'bob@example.com', NULL, '2025-02-20'); -- phone NULL is allowed


-- Successful inserts (inventory)
INSERT INTO inventory (item_id, item_name, quantity, unit_price, last_updated) VALUES
(1, 'USB Cable', 50, 3.50, NOW()),
(2, 'Mouse', 20, 12.99, NOW());

-- Task 3.1: Single Column UNIQUE
CREATE TABLE users (
    user_id INTEGER,
    username TEXT,
    email TEXT,
    created_at TIMESTAMP
);

-- Add UNIQUE constraints 
ALTER TABLE users ADD CONSTRAINT unique_username UNIQUE (username);
ALTER TABLE users ADD CONSTRAINT unique_email UNIQUE (email);

-- Task 3.2
CREATE TABLE course_enrollments (
    enrollment_id INTEGER,
    student_id INTEGER,
    course_code TEXT,
    semester TEXT,
    CONSTRAINT unique_enrollment_per_semester UNIQUE (student_id, course_code, semester)
);

-- Task 3.3

-- Successful inserts
INSERT INTO users (user_id, username, email, created_at) VALUES
(1, 'albina', 'albina@mail.com', NOW()),
(2, 'oleg', 'oleg@mail.com', NOW());

-- Successful inserts (course_enrollments)
INSERT INTO course_enrollments (enrollment_id, student_id, course_code, semester) VALUES
(1, 101, 'CS101', '2025-Fall'),
(2, 102, 'CS101', '2025-Fall');

-- Task 4.1
CREATE TABLE departments (
    dept_id INTEGER PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location TEXT
);

-- Insert departments
INSERT INTO departments (dept_id, dept_name, location) VALUES
(1, 'HR', 'Almaty'),
(2, 'IT', 'Almaty'),
(3, 'Sales', 'Astana');

-- Task 4.2
CREATE TABLE student_courses (
    student_id INTEGER,
    course_id INTEGER,
    enrollment_date DATE,
    grade TEXT,
    PRIMARY KEY (student_id, course_id)
);

-- Insert sample student_courses
INSERT INTO student_courses (student_id, course_id, enrollment_date, grade) VALUES
(201, 301, '2025-09-01', 'A'),
(202, 301, '2025-09-01', 'B');

-- Task 5.1
CREATE TABLE employees_dept (
    emp_id INTEGER PRIMARY KEY,
    emp_name TEXT NOT NULL,
    dept_id INTEGER REFERENCES departments(dept_id),
    hire_date DATE
);

-- Insert employees with valid dept_id
INSERT INTO employees_dept (emp_id, emp_name, dept_id, hire_date) VALUES
(1001, 'Samat', 1, '2024-05-10'),
(1002, 'Dinara', 2, '2025-02-15');

-- Task 5.2
CREATE TABLE authors (
    author_id INTEGER PRIMARY KEY,
    author_name TEXT NOT NULL,
    country TEXT
);

CREATE TABLE publishers (
    publisher_id INTEGER PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city TEXT
);

CREATE TABLE books (
    book_id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INTEGER REFERENCES authors(author_id),
    publisher_id INTEGER REFERENCES publishers(publisher_id),
    publication_year INTEGER,
    isbn TEXT UNIQUE
);

-- Insert sample data into authors/publishers/books
INSERT INTO authors (author_id, author_name, country) VALUES
(1, 'Orhan Pamuk', 'Turkey'),
(2, 'Gabriel Garcia Marquez', 'Colombia'),
(3, 'Kazakh Author', 'Kazakhstan');

INSERT INTO publishers (publisher_id, publisher_name, city) VALUES
(1, 'Penguin', 'London'),
(2, 'Vintage', 'New York'),
(3, 'LocalPress', 'Almaty');

INSERT INTO books (book_id, title, author_id, publisher_id, publication_year, isbn) VALUES
(10, 'My Name Is Red', 1, 1, 1998, 'ISBN-0001'),
(11, 'One Hundred Years of Solitude', 2, 2, 1967, 'ISBN-0002'),
(12, 'Local Tales', 3, 3, 2020, 'ISBN-0003');

-- Task 5.3: ON DELETE Options
CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL
);

CREATE TABLE products_fk (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id INTEGER REFERENCES categories(category_id) ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE order_items (
    item_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_fk(product_id),
    quantity INTEGER CHECK (quantity > 0)
);

-- Insert categories and products
INSERT INTO categories VALUES (1, 'Electronics'), (2, 'Books');
INSERT INTO products_fk VALUES (100, 'Smartphone', 1), (101, 'Novel', 2);

-- Insert an order and order_items
INSERT INTO orders VALUES (5001, '2025-10-01');
INSERT INTO order_items VALUES (1, 5001, 100, 2), (2, 5001, 101, 1);

--task 6.1

CREATE TABLE ecommerce_customers (
    customer_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone TEXT,
    registration_date DATE NOT NULL
);

CREATE TABLE ecommerce_products (
    product_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC NOT NULL CHECK (price >= 0),
    stock_quantity INTEGER NOT NULL CHECK (stock_quantity >= 0)
);

CREATE TABLE ecommerce_orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER REFERENCES ecommerce_customers(customer_id) ON DELETE RESTRICT, -- не удалять клиента, если есть заказы
    order_date DATE NOT NULL,
    total_amount NUMERIC NOT NULL CHECK (total_amount >= 0),
    status TEXT NOT NULL CHECK (status IN ('pending','processing','shipped','delivered','cancelled'))
);

CREATE TABLE ecommerce_order_details (
    order_detail_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES ecommerce_orders(order_id) ON DELETE CASCADE, -- при удалении заказа удалить детали
    product_id INTEGER REFERENCES ecommerce_products(product_id) ON DELETE RESTRICT, -- запретить удаление продукта если есть детали
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC NOT NULL CHECK (unit_price >= 0)
);

-- Sample records (at least 5 per table)
INSERT INTO ecommerce_customers VALUES
(1, 'Aida Ospan', 'aida@example.com', '77001234567', '2024-06-01'),
(2, 'Bulat S', 'bulat@example.com', '77007654321', '2024-07-15'),
(3, 'Dinara K', 'dinara@example.com', NULL, '2025-01-10'),
(4, 'Elena P', 'elena@example.com', '77005554433', '2025-03-20'),
(5, 'Fedor M', 'fedor@example.com', '77008887766', '2025-05-05');

INSERT INTO ecommerce_products VALUES
(10, 'T-shirt', 'Cotton T-shirt', 15.00, 100),
(11, 'Jeans', 'Blue jeans', 40.00, 50),
(12, 'Sneakers', 'Sport shoes', 60.00, 30),
(13, 'Hat', 'Sun hat', 12.00, 200),
(14, 'Backpack', 'Travel backpack', 80.00, 20);

INSERT INTO ecommerce_orders VALUES
(9001, 1, '2025-09-01', 70.00, 'pending'),
(9002, 2, '2025-09-10', 52.00, 'processing'),
(9003, 3, '2025-09-12', 15.00, 'shipped'),
(9004, 1, '2025-09-20', 120.00, 'delivered'),
(9005, 5, '2025-10-01', 80.00, 'cancelled');

INSERT INTO ecommerce_order_details VALUES
(1, 9001, 10, 2, 15.00), 
(2, 9001, 13, 1, 40.00), 
(3, 9002, 11, 1, 52.00),
(4, 9003, 13, 1, 15.00),
(5, 9004, 14, 1, 120.00);

