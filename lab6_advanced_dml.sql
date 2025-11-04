--Part 1: Database Setup
--Step 1.1: Create Sample Tables
DROP TABLE IF EXISTS employees;
CREATE TABLE IF NOT EXISTS employees(
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(50),
    dept_id INT,
    salary DECIMAL(10, 2)
);
DROP TABLE IF EXISTS departments;
CREATE TABLE IF NOT EXISTS departments(
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location VARCHAR(50)
);
DROP TABLE IF EXISTS projects;
CREATE TABLE IF NOT EXISTS projects (
    project_id INT PRIMARY KEY,
    project_name VARCHAR(50),
    dept_id INT,
    budget DECIMAL(10, 2)
);
--Step 1.2: Insert Sample Data
-- Insert data into employees
INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES
(1, 'John Smith', 101, 50000),
(2, 'Jane Doe', 102, 60000),
(3, 'Mike Johnson', 101, 55000),
(4, 'Sarah Williams', 103, 65000),
(5, 'Tom Brown', NULL, 45000);
-- Insert data into departments
INSERT INTO departments (dept_id, dept_name, location) VALUES
(101, 'IT', 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Finance', 'Building C'),
(104, 'Marketing', 'Building D');
-- Insert data into projects
INSERT INTO projects (project_id, project_name, dept_id,
budget) VALUES
(1, 'Website Redesign', 101, 100000),
(2, 'Employee Training', 102, 50000),
(3, 'Budget Analysis', 103, 75000),
(4, 'Cloud Migration', 101, 150000),
(5, 'AI Research', NULL, 200000);

--Part 2: CROSS JOIN Exercises
--Exercise 2.1: Basic CROSS JOIN
SELECT e.emp_name, d.dept_name
FROM employees e CROSS JOIN departments d;
-- Answer: 5*4 = 20
--Exercise 2.2: Alternative CROSS JOIN Syntax
SELECT e.emp_name, d.dept_name
FROM employees e, departments d;

SELECT e.emp_name, d.dept_name
FROM employees e INNER JOIN departments d ON TRUE;
--Exercise 2.3: Practical CROSS JOIN
SELECT  e.emp_name, p.project_name
FROM employees e CROSS JOIN projects p
ORDER BY e.emp_name, p.project_name;
-- N*M = 5*5 = 25

--Part 3: INNER JOIN Exercises
--Exercise 3.1: Basic INNER JOIN with ON
SELECT e.emp_name, d.dept_name, d.location
FROM employees e INNER JOIN departments d
    ON e.dept_id = d.dept_id;
-- return 4 rows where dept_id in employees equal to dept_id in departments
-- Tom Brown not included, because his dept_id = to NULL
--Exercise 3.2: INNER JOIN with USING
SELECT e.emp_name, d.dept_name, d.location
FROM employees e INNER JOIN departments d USING (dept_id);
-- ON we can use with difference colum's names, but USING only with equal names. end when we select all table with ON we take 2 colum with equal variables, but with USING only one.
--Exercise 3.3: NATURAL INNER JOIN
SELECT emp_name, dept_name, location
FROM employees NATURAL INNER JOIN departments;
--Exercise 3.4: Multi-table INNER JOIN
SELECT employees.emp_name, departments.dept_name, projects.project_name
FROM employees
INNER JOIN departments USING  (dept_id)
INNER JOIN projects USING (dept_id);

SELECT employees.emp_name, departments.dept_name, projects.project_name
FROM employees
INNER JOIN departments ON employees.dept_id = departments.dept_id
INNER JOIN projects ON projects.dept_id = departments.dept_id;

SELECT employees.emp_name, departments.dept_name, projects.project_name
FROM employees
NATURAL INNER JOIN departments
NATURAL INNER JOIN projects;
--Part 4: LEFT JOIN Exercises
SELECT
    e.emp_name,
    e.dept_id AS emp_dept,
    d.dept_id AS dept_dept,
    d.dept_name
FROM employees e LEFT JOIN departments d ON e.dept_id = d.dept_id;
-- all id will be equal to NULL, because in LEFT JOIN result depends  from first left table;
--Exercise 4.2: LEFT JOIN with USING
SELECT
    e.emp_name,
    e.dept_id AS emp_dept,
    d.dept_id AS dept_dept,
    d.dept_name
FROM employees e LEFT JOIN departments d USING (dept_id);
--Exercise 4.3: Find Unmatched Records
SELECT e.emp_name, d.dept_name
FROM employees e LEFT JOIN  departments d USING (dept_id) WHERE d.dept_id IS NULL;
--Exercise 4.4: LEFT JOIN with Aggregation
SELECT
    d.dept_name,
    COUNT(e.emp_id) AS employee_count
FROM departments d LEFT JOIN employees e USING (dept_id)
GROUP BY d.dept_id, d.dept_name
ORDER BY employee_count DESC;
--Part 5: RIGHT JOIN Exercises
--Exercise 5.1: Basic RIGHT JOIN
SELECT e.emp_name, d.dept_name
FROM employees e RIGHT JOIN departments d ON e.dept_id = d.dept_id;
--Exercise 5.2: Convert to LEFT JOIN
SELECT e.emp_name, d.dept_name
FROM departments d LEFT JOIN employees e ON d.dept_id = e.dept_id;
--Exercise 5.3: Find Departments Without Employees
SELECT d.dept_name, d.location
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL;

--Part 6: FULL JOIN Exercises
--Exercise 6.1: Basic FULL JOIN
SELECT
    e.emp_name,
    e.dept_id AS emp_dept,
    d.dept_id AS dept_dept,
    d.dept_name
FROM employees e
FULL JOIN departments d
    ON e.dept_id = d.dept_id;
-- employees have NULL value on the left side, and departments on tj=he right side
--Exercise 6.2: FULL JOIN with Projects
SELECT
    d.dept_name,
    p.project_name,
    p.budget
FROM departments d
FULL JOIN projects p
    ON d.dept_id = p.dept_id;
--Exercise 6.3: Find Orphaned Records
SELECT
    CASE
        WHEN e.emp_id IS NULL THEN 'Department without
employees'
        WHEN d.dept_id IS NULL THEN 'Employee without
department'
        ELSE 'Matched'
    END AS record_status,
    e.emp_name,
    d.dept_name
 FROM employees e
 FULL JOIN departments d ON e.dept_id = d.dept_id
 WHERE e.emp_id IS NULL OR d.dept_id IS NULL;
--Part 7: ON vs WHERE Clause
--Exercise 7.1: Filtering in ON Clause (Outer Join)
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d
    ON e.dept_id = d.dept_id
   AND d.location = 'Building A';
--Exercise 7.2: Filtering in WHERE Clause (Outer Join)
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d
  ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';
-- Query 1 (ON clause): Applies the filter BEFORE the join, so all employees are included, but only departments in Building A are matched.
-- Query 2 (WHERE clause): Applies the filter AFTER the join, so employees are excluded if their department is not in Building A.
--Exercise 7.3: ON vs WHERE with INNER JOIN
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
INNER JOIN departments d
  ON e.dept_id = d.dept_id
 AND d.location = 'Building A';

SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
INNER JOIN departments d
  ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';
--No difference.
-- Because INNER JOIN only keeps rows that match in both tables,
-- and the filter (d.location = 'Building A') applies to those same matched rows,
-- regardless of whether it’s placed in the ON clause or the WHERE clause
--Part 8: Complex JOIN Scenarios
--Exercise 8.1: Multiple Joins with Different Types
SELECT
    d.dept_name,
    e.emp_name,
    e.salary,
    p.project_name,
    p.budget
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p ON d.dept_id = p.dept_id
ORDER BY d.dept_name, e.emp_name;
--Exercise 8.2: Self Join
ALTER TABLE employees
ADD COLUMN manager_id INT;

UPDATE employees SET manager_id = 3 WHERE emp_id = 1;  -- John Smith → Mike Johnson
UPDATE employees SET manager_id = 3 WHERE emp_id = 2;  -- Jane Doe → Mike Johnson
UPDATE employees SET manager_id = NULL WHERE emp_id = 3; -- Mike Johnson сам менеджер
UPDATE employees SET manager_id = 3 WHERE emp_id = 4;  -- Sarah Williams → Mike Johnson
UPDATE employees SET manager_id = 3 WHERE emp_id = 5;  -- Tom Brown → Mike Johnson

SELECT
    e.emp_name AS employee,
    m.emp_name AS manager
FROM employees e
LEFT JOIN employees m
    ON e.manager_id = m.emp_id;
--Exercise 8.3: Join with Subquery
SELECT
    d.dept_name,
    AVG(e.salary) AS avg_salary
FROM departments d
INNER JOIN employees e
    ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
HAVING AVG(e.salary) > 50000;

-- ANSWERS TO QUESTIONS

-- 1. What is the difference between INNER JOIN and LEFT JOIN?
-- INNER JOIN возвращает только те строки, у которых есть совпадения в обеих таблицах.
-- LEFT JOIN возвращает все строки из левой таблицы, даже если совпадений нет (а справа будут NULL).

-- 2. When would you use CROSS JOIN in a practical scenario?
-- CROSS JOIN используют, когда нужно получить все возможные комбинации строк из двух таблиц.
-- Например: создание календаря расписания или генерация матрицы цен.

-- 3. Explain why the position of a filter condition (ON vs WHERE) matters for outer joins but not for inner joins.
-- Для INNER JOIN фильтр в ON и WHERE не меняет результат — строки без совпадений всё равно удалятся.
-- Для OUTER JOIN фильтр в WHERE может убрать строки, которые LEFT/RIGHT JOIN должен был сохранить.
-- Поэтому условия на связи пишут в ON, а условия фильтрации итоговых данных — в WHERE.

-- 4. What is the result of: SELECT COUNT(*) FROM table1 CROSS JOIN table2 if table1 has 5 rows and table2 has 10 rows?
-- CROSS JOIN создаёт декартово произведение: 5 * 10 = 50 строк.

-- 5. How does NATURAL JOIN determine which columns to join on?
-- NATURAL JOIN автоматически соединяет таблицы по всем столбцам с одинаковыми именами.

-- 6. What are the potential risks of using NATURAL JOIN?
-- Опасность: если колонка с таким же именем появится в таблице позже, join будет происходить по ней тоже.
-- Это может случайно сломать запрос и дать неправильный результат.
-- Лучше явно указывать поля в JOIN.

-- 7. Convert this LEFT JOIN to a RIGHT JOIN: SELECT * FROM A LEFT JOIN B ON A.id = B.id
-- LEFT JOIN = RIGHT JOIN, если поменять таблицы местами:
-- SELECT * FROM B RIGHT JOIN A ON A.id = B.id;

-- 8. When should you use FULL OUTER JOIN instead of other join types?
-- FULL OUTER JOIN используют, когда нужно получить все строки из обеих таблиц,
-- включая те, у которых нет совпадений — полезно для анализа различий между наборами данных.

-- Additional Challenges
--1
SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS dept_dept, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id

UNION

SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS dept_dept, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id;

--2
SELECT e.emp_name, d.dept_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IN (
    SELECT dept_id
    FROM projects
    WHERE dept_id IS NOT NULL
    GROUP BY dept_id
    HAVING COUNT(project_id) > 1
);

--3
SELECT
    e.emp_name AS employee,
    m.emp_name AS manager,
    mm.emp_name AS top_manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id
LEFT JOIN employees mm ON m.manager_id = mm.emp_id;

--4
SELECT
    e1.emp_name AS employee1,
    e2.emp_name AS employee2,
    d.dept_name
FROM employees e1
INNER JOIN employees e2
    ON e1.dept_id = e2.dept_id
   AND e1.emp_id < e2.emp_id
INNER JOIN departments d
    ON e1.dept_id = d.dept_id;

