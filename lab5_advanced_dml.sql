--Database Constraints - Laboratory Work #5
--Student: Altynbekov Yernazar
--ID: 24B031629
--Part 1: CHECK Constraints
--Task 1.1: Basic CHECK Constraint
DROP TABLE IF EXISTS employees CASCADE;
CREATE TABLE employees(
    employee_id INTEGER PRIMARY KEY,
    first_name TEXT,
    last_name TEXT,
    age INTEGER CHECK (age BETWEEN 18 and 65),
    salary NUMERIC(12,2) CHECK (salary > 0)
);
/* CHECK Constraint:
   -age must be between 18 and 65
   -salary must be > 0
*/
--Insertion of valid data:
INSERT INTO employees
VALUES
    (1, 'Yernazar', 'Altynbekov', 18, 999999),
    (2, 'Malika', 'Top', 18, 999999);

--Task 1.2: Named CHECK Constraint
DROP TABLE IF EXISTS products_catalog CASCADE;
CREATE TABLE products_catalog(
    product_id INTEGER PRIMARY KEY ,
    product_name TEXT,
    regular_price NUMERIC(12,2),
    discount_price NUMERIC(12,2),
    CONSTRAINT valid_discount CHECK (
        regular_price > 0
        AND discount_price > 0
        AND discount_price < regular_price
        )
);
--Insertion of valid data:
INSERT INTO products_catalog
VALUES
    (1, 'Phone', 10000.10, 9990.00),
    (2, 'watch', 7000.00, 6990.00);
-- Invalid attempts:
--Insert regular_price<0 and discount_price<0 and disc_price>regu_price

--Task 1.3: Multiple Column CHECK
DROP TABLE IF EXISTS bookings CASCADE;
CREATE TABLE bookings(
    booking_id INTEGER PRIMARY KEY ,
    check_in_date DATE,
    check_out_date DATE,
    num_guests INTEGER,
    CONSTRAINT ensure CHECK (
        num_guests BETWEEN 1 AND 10
        AND check_out_date > check_in_date
        )
);
--Insertion of valid data:
INSERT INTO bookings
VALUES
    (1, '2025-10-10', '2025-12-12', 3),
    (2, '2024-12-12', '2025-05-05', 6);
-- Invalid attempts:
--num_guests is not between 1 and 10
--check_out_date before check_in_date

--Part 2: NOT NULL Constraints
--Task 2.1: NOT NULL Implementation
DROP TABLE IF EXISTS customers;
CREATE TABLE customers(
    customer_id INTEGER NOT NULL PRIMARY KEY ,
    email TEXT NOT NULL,
    phone TEXT, --can be NULL
    registration_date DATE NOT NULL,
);

--Task 2.2: Combining Constraints
DROP TABLE IF EXISTS inventory;
CREATE TABLE inventory(
    item_id INTEGER NOT NULL ,
    item_name TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK ( quantity >= 0 ),
    unit_price NUMERIC(12,2) NOT NULL CHECK ( unit_price >0 ),
    last_updated TIMESTAMP NOT NULL
);

--Task 2.3: Testing NOT NULL
--Successfully insert complete records:
INSERT INTO customers
VALUES
    (1, 'yera@gmail.com','+77077077777', '2025-05-05' ),
    (2, 'di@icloud.com', '+7055055555', '2025-05-05');

INSERT INTO inventory
VALUES
    (1, 'chto-to', 1000, 900.00, NOW()),
    (2,'OPIAT', 2000, 1000.00,NOW() );
--Attempt to insert records with NULL values in NOT NULL columns, Insert records with NULL values in nullable columns
--INSERT INTO customers
--VALUES (NULL, NULL, 1000, NULL)
--ERROR: 1, 3, 4 COLUMNS ARE NULL

--INSERT INTO inventory
--VALUES (1, NULL, NULL, -9999, NULL AND -9999, NULL)
--ERROR COLUMNS ARE NULL OR INTEGER IS NEGATIVE

--Part 3: UNIQUE Constraints
--Task 3.1: Single Column UNIQUE
DROP TABLE IF EXISTS  users CASCADE;
CREATE TABLE  users (
    user_id INTEGER PRIMARY KEY ,
    username TEXT UNIQUE ,
    email TEXT UNIQUE ,
    created_at TIMESTAMP
);
--Task 3.2: Multi-Column UNIQUE
DROP TABLE IF EXISTS course_enrollments CASCADE;
CREATE TABLE course_enrollments(
    enrollment_id INTEGER PRIMARY KEY ,
    student_id INTEGER,
    course_code TEXT,
    semester TEXT,
    CONSTRAINT unique_student_course_semester UNIQUE (student_id, course_code, semester)
);
--Task 3.3: Named UNIQUE Constraints
--Modify the users table from Task 3.1:
DROP TABLE IF EXISTS  users CASCADE;
CREATE TABLE  users (
    user_id INTEGER PRIMARY KEY ,
    username TEXT UNIQUE ,
    email TEXT UNIQUE ,
    created_at TIMESTAMP,
    CONSTRAINT unique_username UNIQUE (username), --Add a named UNIQUE constraint called unique_username on username
    CONSTRAINT unique_email UNIQUE (email) --Add a named UNIQUE constraint called unique_email on email
);

--Test by trying to insert duplicate usernames and emails:
--INSERT INTO users
--VALUES
--    (1, 'YERNAZAR', 'YERA@GMAIL.COM', NOW()),
--    (2, 'YERNAZAR', 'YERA@GMAIL.COM', NOW());
--ERROR BECAUSE OF DUBLICATES

--Part 4: PRIMARY KEY Constraints
--Task 4.1: Single Column Primary Key
DROP TABLE IF EXISTS departments CASCADE;
CREATE TABLE departments(
    dept_id INTEGER PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location TEXT
);

INSERT INTO departments
VALUES
    (1, 'IT', 'ALMATY'),
    (2, 'HR', 'ASTANA'),
    (3,'DESIGN', 'OSKEMEN');

-- Invalid attempts
-- INSERT INTO departments
-- VALUES (1,'IT','Taraz');
-- ERROR: dept_id that is primary_key was dublicated
-- INSERT INTO departments VALUES (4,Null,'Atyrau');
-- ERROR: null value in column "dept_id" violates not-null constraint

--Task 4.2: Composite Primary Key
DROP TABLE IF EXISTS  student_courses CASCADE;
CREATE TABLE  student_courses(
    student_id INTEGER NOT NULL,
    course_id INTEGER NOT NULL,
    enrollment_date DATE,
    grade TEXT,
    PRIMARY KEY (student_id, course_id) --combination of (student_id, course_id)
);

--Task 4.3: Comparison Exercise
    --The difference between UNIQUE and PRIMARY KEY
/*Both make sure values are not repeated in a column.
PRIMARY KEY is the main key of the table. It makes each row unique and doesn’t allow NULL values.
A table can have only one PRIMARY KEY, because it’s the main identifier.
But it can have many UNIQUE constraints if you want other columns to also be unique.
 */
    --When to use a single-column vs. composite PRIMARY KEY
/*
 Single-column PRIMARY KEY
Use this when one column is enough to make each row unique.
It’s simple and easy to understand.
 Composite PRIMARY KEY
Use this when one column is not enough,
and you need two or more columns together to make a unique row.
 One student can take many courses.
One course can have many students.
But each student + course pair is unique.
 */
    --Why a table can have only one PRIMARY KEY but multiple UNIQUE constraints
/*
 The PRIMARY KEY is the main identifier of the table — it tells which column (or columns) are used to find each row.
Because a table can have only one main way to identify a row, it can have only one PRIMARY KEY
 UNIQUE means “no duplicates allowed.”
You can have many UNIQUE columns if you want more than one field to be unique.
These columns are not the main identifier — they just must not
 */

--Part 5: FOREIGN KEY Constraints
--Task 5.1: Basic Foreign Key
DROP TABLE IF EXISTS employees_dept CASCADE;
CREATE TABLE employees_dept(
    emp_id INTEGER PRIMARY KEY,
    emp_name TEXT NOT NULL,
    dept_id INTEGER REFERENCES departments(dept_id) ,
    hire_date DATE
);
-- Valid (dept_id exists)
INSERT INTO employees_dept
VALUES
    (4, 'Ya', 1, '2024-12-12'),
    (5, 'Mi', 2, '2025-10-10');
--ERROR IF dept_id = 5, since we dont have 5
--INSERT INTO employees_dept VALUES (6,'NonExistDept',3,'2025-10-10');
-- ERROR: insert or update on table "employees_dept" violates foreign key constraint

--Task 5.2: Multiple Foreign Keys
DROP TABLE IF EXISTS authors CASCADE;
CREATE TABLE authors(
    author_id INTEGER PRIMARY KEY,
    author_name TEXT NOT NULL,
    country TEXT
);

DROP TABLE IF EXISTS publishers CASCADE;
CREATE TABLE publishers (
    publisher_id   INTEGER PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city           TEXT
);

DROP TABLE IF EXISTS books CASCADE;
CREATE TABLE books
(
    book_id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INTEGER REFERENCES authors(author_id),
    publisher_id INTEGER REFERENCES publishers(publisher_id),
    publication_year INTEGER,
    isbn TEXT UNIQUE
);
--Insert sample data into all tables.
INSERT INTO authors
VALUES
(1,'Charles Dickens','England'),
(2,'Abay Kunanbayuly','Kazakhstan'),
(3,'Jane Austen one love','United Kingdom');

INSERT INTO publishers
VALUES
(1,'Leo Tolstoy','Yasnaya Polyana'),
(2,'Jane Austen','Steventon');

INSERT INTO books
VALUES
(1,'Great Expectations',1,1,1861,'978-1-85326-004-9'),
(2,'Abay Zholy',2,2,1942,'9786018011607'),
(3,'Pride and Prejudice one love',3,1,1813,'978-1-85326-000-1');

--Task 5.3: ON DELETE Options
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS products_fk CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;


CREATE TABLE categories (
    category_id   INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL
);

CREATE TABLE products_fk (
    product_id   INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id  INTEGER REFERENCES categories(category_id) ON DELETE RESTRICT
    -- RESTRICT: cannot delete a category if products reference it
);

CREATE TABLE orders (
    order_id   INTEGER PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE order_items (
    item_id    INTEGER PRIMARY KEY,
    order_id   INTEGER REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_fk(product_id),
    quantity   INTEGER CHECK (quantity > 0)
    -- CASCADE: deleting an order deletes its order_items
);

INSERT INTO categories VALUES (1, 'Electronics');
INSERT INTO products_fk VALUES (101, 'Smartphone', 1);

INSERT INTO orders VALUES (1, '2025-10-15');
INSERT INTO order_items VALUES (1, 1, 101, 2);

--1)Try to delete a category that has products (should fail with RESTRICT):
    --Action:
--DELETE FROM categories WHERE category_id = 1;
    --Result:  ERROR
    --ERROR:  update or delete on table "categories" violates foreign key constraint
    --DETAIL:  Key (category_id)=(1) is still referenced from table "products_fk".
--Explanation:
--Because of ON DELETE RESTRICT, you cannot delete the category — it still has products linked to it.

--2)Delete an order and see what happens to order_items (CASCADE)
    --Action:
--DELETE FROM orders WHERE order_id = 1;
--Result: Success
--The order with order_id = 1 is deleted.
--The linked record in order_items is also deleted automatically.
--Explanation:
--ON DELETE CASCADE makes the database automatically remove child records when the parent is deleted.


/*
 RESTRICT - Prevents deleting a category that still has products
 CASCADE - Automatically deletes order_items when an order is deleted
 */

--Part 6: Practical Application
--Task 6.1: E-commerce Database Design
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS order_details CASCADE;

CREATE TABLE customers (
    customer_id       INTEGER PRIMARY KEY,
    name              TEXT    NOT NULL,
    email             TEXT    NOT NULL UNIQUE,
    phone             TEXT,
    registration_date DATE    NOT NULL
);

CREATE TABLE products (
    product_id     INTEGER PRIMARY KEY,
    name           TEXT    NOT NULL,
    description    TEXT,
    price          NUMERIC(12,2) NOT NULL CHECK (price >= 0),
    stock_quantity INTEGER NOT NULL CHECK (stock_quantity >= 0)
);

CREATE TABLE orders (
    order_id     INTEGER PRIMARY KEY,
    customer_id  INTEGER NOT NULL REFERENCES customers(customer_id) ON DELETE RESTRICT,
    order_date   DATE    NOT NULL,
    total_amount NUMERIC(14,2) NOT NULL CHECK (total_amount >= 0),
    status       TEXT    NOT NULL CHECK (status IN ('pending','processing','shipped','delivered','cancelled'))
);

CREATE TABLE order_details (
    order_detail_id INTEGER PRIMARY KEY,
    order_id        INTEGER NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id      INTEGER NOT NULL REFERENCES products(product_id),
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    unit_price      NUMERIC(12,2) NOT NULL CHECK (unit_price > 0)
);

--At least 5 sample records per table:
-- customers
INSERT INTO customers VALUES
(1, 'kto-to', 'ktoto777@mail.com', '77777', '2025-01-05'),
(2, 'chelovek123', 'chel_123@inbox.kz', '99999', '2025-02-14'),
(3, 'anonim', 'anon@@example.com', '00000', '2025-03-01'),
(4, 'prosto ya', 'ya_tut@mail.ru', '707070', '2025-03-20'),
(5, 'ne pomnyu', 'nepomnyu@mail.com', '12345', '2025-04-09');

-- products
INSERT INTO products VALUES
(1, 'telefon kak u vseh', 'chernyi, rabotaet', 500.00, 7),
(2, 'noutik norm', 's ekranom bolshim', 1100.50, 3),
(3, 'naushniki po akcii', 'pochti novye', 99.99, 15),
(4, 'myska', 'belaia, svetitsya', 25.00, 40),
(5, 'klava top', 'klik-klak, s podsvetkoi', 70.00, 25);

-- orders
INSERT INTO orders VALUES
(1, 1, '2025-09-25', 500.00, 'pending'),
(2, 2, '2025-09-27', 1100.50, 'processing'),
(3, 3, '2025-09-30', 99.99, 'shipped'),
(4, 4, '2025-10-02', 25.00, 'delivered'),
(5, 5, '2025-10-04', 70.00, 'cancelled');

-- order_details
INSERT INTO order_details VALUES
(1, 1, 1, 1, 500.00),
(2, 2, 2, 1, 1100.50),
(3, 3, 3, 1, 99.99),
(4, 4, 4, 1, 25.00),
(5, 5, 5, 1, 70.00);

--a) Test UNIQUE (email must be unique)
-- This should fail because ktoto777@mail.com already exists
--INSERT INTO customers VALUES (6, 'Alice Copy', 'ktoto777@mail.com', '999-999', '2025-10-15');
--Result:  Error - duplicate key value violates unique constraint on email.

--b) Test CHECK (negative price not allowed)
-- Should fail because price < 0
--INSERT INTO products VALUES (6, 'Broken Item', 'Invalid price', -10.00, 5);

--c) Test CHECK (invalid order status)
-- Should fail because status not in allowed list
--INSERT INTO orders VALUES (6, 1, '2025-10-15', 500.00, 'waiting');
--Result: Error — check constraint on "status" failed.

--d) Test ON DELETE RESTRICT
-- Try to delete a product that appears in order_details
--DELETE FROM products WHERE product_id = 1;
--Result: Error — cannot delete product because it's used in order_details.

--e) Test ON DELETE CASCADE
-- Delete order #1; its order_details should also be deleted
--DELETE FROM orders WHERE order_id = 1;

-- Check:
--SELECT * FROM order_details WHERE order_id = 1;
--Result: The order_details for order_id = 1 are automatically deleted