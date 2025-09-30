-- коменты написал для своего удобства
CREATE DATABASE advanced_lab;

-- Task A. Создание таблиц
CREATE TABLE IF NOT EXISTS employees (
    emp_id     SERIAL PRIMARY KEY,       --SERIAL = INTEGER + AUTO_INCREMENT
    first_name VARCHAR(100),
    last_name  VARCHAR(100),
    department VARCHAR(100),
    salary     INTEGER,
    hire_date  DATE,
    status     VARCHAR(50) DEFAULT 'Active'  -- по умолчанию Active
);

CREATE TABLE IF NOT EXISTS departments (
    dept_id    SERIAL PRIMARY KEY,
    dept_name  VARCHAR(100),
    budget     INTEGER,
    manager_id INTEGER
);

CREATE TABLE IF NOT EXISTS projects (
    project_id    SERIAL PRIMARY KEY,
    project_name  VARCHAR(150),
    dept_id       INTEGER,
    start_date    DATE,
    end_date      DATE,
    budget        INTEGER
);

-- Task B. INSERT операции
INSERT INTO employees (emp_id, first_name, last_name, department)
VALUES
    (DEFAULT,
     'MAYTO',
     'TI',
     'KAIF');

INSERT INTO employees (first_name, last_name, department, salary, status)
VALUES
    ('Data',
     'Bases',
     'IT',
     DEFAULT,
     DEFAULT);

INSERT INTO departments (dept_name, budget, manager_id)
VALUES
    ('IT', 200000, 1),
    ('WEB', 150000, 2),
    ('Finance', 300000, 1);               -- множественная вставка

INSERT INTO employees (first_name, last_name, department, hire_date, salary)
VALUES
    ('KIRISHIMA',
     'MI',
     'Sales',
     CURRENT_DATE, 50000 * 1.1);

DROP TABLE IF EXISTS temp_employees;
CREATE TEMP TABLE temp_employees AS
SELECT * FROM employees WHERE department = 'IT';

-- Part C. UPDATE операции
UPDATE employees
SET salary = salary * 1.10;

UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < '2020-01-01';

UPDATE employees
SET department = CASE
    WHEN salary > 80000 THEN 'Management'
    WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
    ELSE 'Junior'
END;

UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

UPDATE departments d
SET budget = (
  SELECT AVG(e.salary) * 1.20
  FROM employees e
  WHERE e.department = d.dept_name
);

UPDATE employees
SET salary = salary * 1.15,
    status = 'Promoted'
WHERE department = 'Sales';

-- Part D. DELETE операции
DELETE FROM employees
WHERE status = 'Terminated';              -- простое условие

DELETE FROM employees
WHERE salary < 40000
  AND hire_date > '2023-01-01'
  AND department IS NULL;                 -- сложное условие

DELETE FROM departments d
WHERE d.dept_name NOT IN (
  SELECT DISTINCT department
  FROM employees
  WHERE department IS NOT NULL
);                                        -- удаление с подзапросом

DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;                              -- удаление с RETURNING

-- Part E. NULL значения
INSERT INTO employees (first_name, last_name, department, salary)
VALUES ('KIRISHIMA', 'MI', NULL, NULL);         -- вставка с NULL

UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;                 -- обновление NULL → значение

DELETE FROM employees
WHERE salary IS NULL
   OR department IS NULL;                 -- удаление по NULL

-- Part F. RETURNING
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Return', 'Test', 'QA', 45000, CURRENT_DATE)
RETURNING emp_id, (first_name || ' ' || last_name) AS full_name; -- возвращаем ID и ФИО

UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING emp_id,
          salary - 5000 AS old_salary,
          salary AS new_salary;           -- возврат старой и новой зарплаты

DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;                              -- возврат всех полей удалённых строк

-- Part G. Сложные операции
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT 'Unique', 'Person', 'R&D', 52000, CURRENT_DATE
WHERE NOT EXISTS (                        -- условный INSERT
  SELECT 1
  FROM employees
  WHERE first_name = 'Unique' AND last_name = 'Person'
);

UPDATE employees e
SET salary = salary * CASE                 -- обновление с подзапросом
  WHEN (
    SELECT d.budget
    FROM departments d
    WHERE d.dept_name = e.department
  ) > 100000 THEN 1.10
  ELSE 1.05
END;

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES
  ('I','for','depa',40000,CURRENT_DATE),
  ('dont','create','depa',42000,CURRENT_DATE),
  ('have','new','depa',44000,CURRENT_DATE),
  ('a','names','depa',46000,CURRENT_DATE),
  ('fantasy','all time','depa',48000,CURRENT_DATE); -- bulk вставка

UPDATE employees
SET salary = salary * 1.10
WHERE department = 'depa';                -- массовое обновление

-- Архивная таблица
CREATE TABLE IF NOT EXISTS employee_archive AS
SELECT * FROM employees WHERE 1=0;        -- копия структуры employees

INSERT INTO employee_archive
SELECT *
FROM employees
WHERE status = 'Inactive';                -- перенос неактивных сотрудников

DELETE FROM employees
WHERE status = 'Inactive';

-- 27. Сложная логика для проектов
UPDATE projects p
SET end_date = COALESCE(end_date, CURRENT_DATE) + INTERVAL '30 days'
WHERE p.budget > 50000
  AND (
    SELECT COUNT(*)
    FROM employees e
    WHERE e.department = (
      SELECT d.dept_name
      FROM departments d
      WHERE d.dept_id = p.dept_id
    )
  ) > 3;                                  -- продлеваем проект на 30 дней
