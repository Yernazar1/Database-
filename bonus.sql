--Bonus laboratory work
--Student: Altynbekov Yernazar
--ID: 24B031629
--THIS CODE WAS CREATED BY YERNAZAR ALTYNBEKOV, SO DON'T COPY IT!

-- Drop existing objects
DROP MATERIALIZED VIEW IF EXISTS salary_batch_summary CASCADE;
DROP VIEW IF EXISTS suspicious_activity_view CASCADE;
DROP VIEW IF EXISTS daily_transaction_report CASCADE;
DROP VIEW IF EXISTS customer_balance_summary CASCADE;
DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS transaction_log CASCADE;
DROP TABLE IF EXISTS exchange_rate CASCADE;
DROP TABLE IF EXISTS account CASCADE;
DROP TABLE IF EXISTS customer CASCADE;

--Database Schema
CREATE TABLE customer(
    customer_id SERIAL PRIMARY KEY,
    iin VARCHAR(12) UNIQUE NOT NULL CHECK (length(iin) = 12),
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'blocked', 'frozen')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    daily_limit_kzt DECIMAL(15, 2) DEFAULT 10000000.00
);

CREATE TABLE account(
    account_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customer(customer_id),
    account_number VARCHAR(34) UNIQUE NOT NULL,
    currency VARCHAR(3) NOT NULL CHECK (currency IN ('KZT', 'USD', 'EUR', 'RUB')),
    balance DECIMAL(15, 2) NOT NULL DEFAULT 0.00 CHECK (balance >= 0),
    is_active BOOLEAN DEFAULT TRUE,
    opened_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP,
    CONSTRAINT account_closed_check CHECK (closed_at IS NULL OR closed_at >= opened_at)
);

CREATE TABLE exchange_rate(
    rate_id SERIAL PRIMARY KEY,
    from_currency VARCHAR(3) NOT NULL CHECK (from_currency IN ('KZT', 'USD', 'EUR', 'RUB')),
    to_currency VARCHAR(3) NOT NULL CHECK (to_currency IN ('KZT', 'USD', 'EUR', 'RUB')),
    rate DECIMAL(15, 6) NOT NULL CHECK (rate > 0),
    valid_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP,
    CONSTRAINT diff_currency CHECK (from_currency != to_currency)
);

CREATE TABLE transaction_log(
     transaction_id SERIAL PRIMARY KEY,
    from_account_id INTEGER REFERENCES account(account_id),
    to_account_id INTEGER REFERENCES account(account_id),
    amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
    currency VARCHAR(3) NOT NULL,
    exchange_rate DECIMAL(15, 6),
    amount_kzt DECIMAL(15, 2) NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('transfer', 'deposit', 'withdrawal')),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'reversed')),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

CREATE TABLE audit_log (
    log_id SERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id INTEGER NOT NULL,
    action VARCHAR(10) NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    old_values JSONB,
    new_values JSONB,
    changed_by VARCHAR(255) DEFAULT CURRENT_USER,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET
);

--Populate each table with at least 10 meaningful records for testing.

INSERT INTO customer(iin, full_name, phone, email, status, daily_limit_kzt)
    VALUES
        ('061219550291', 'Yernazar Altynbekov', '+7 706 418 99 09', 'yernazar@gmail.com', 'active', 777777777.00 ),
        ('010101010101', 'Miss Elizabeth Bennet', '+7 777 777 77 77', 'MissElizabethBennet@gmail.com', 'frozen', 999999999.00),
        ('020202020202', 'Mr. Fitzwilliam Darcy', '+7 700 700 70 70', 'MrFitzwilliamDarcy@gmail.com', 'active', 9999999999.00),
        ('030303030303','Mr. Bennet', '+7 701 701 0101', 'MrBennet@gmail.com', 'active', 99999999999.00),
        ('040404040404', 'Miss Jane Bennet', '+7 702 702 02 02', 'MissJaneBennet@gmail.com', 'active', 99999999999.00),
        ('050505050505', 'Miss Mary Bennet', '+7 703 703 03 03', 'MissMaryBennet@gmail.com', 'blocked', 1000000000.00),
        ('060606060606', 'Miss Catherine Bennet', '+704 704 04 04', 'MissCatherineBennet@gmail.com', 'blocked', 1000000000.00),
        ('070707070707' ,'Miss Lydia Bennet', '+705 705 05 05', 'MissLydiaBennet@gmail.com', 'active', 10000000000.00),
        ('080808080808', 'Miss Caroline Bingley', '+7 706 706 06 06', 'MissCarolineBingleyVIP@gmail.com', 'active', 99999999999.00 ),
        ('090909090909', 'Mr. William Collins', '+707 707 07 07', 'MrWilliamCollins@gmail.com', 'frozen', 1.00);

INSERT INTO account(customer_id, account_number, currency, balance, is_active)
VALUES
    (1, 'ACC0001', 'KZT', 5000000.00, TRUE),
    (2, 'ACC0002', 'USD', 10000.00, TRUE),
    (3, 'ACC0003', 'USD', 2500000.00, TRUE),
    (4, 'ACC0004', 'KZT', 2000000.00, TRUE),
    (5, 'ACC0005', 'EUR', 15000.00, TRUE),
    (6, 'ACC0006', 'RUB', 750000.00, TRUE),
    (7, 'ACC0007', 'KZT', 1000000.00, TRUE),
    (8, 'ACC0008', 'KZT', 8000000.00, TRUE),
    (9, 'ACC0009', 'USD', 500000.00, TRUE),
    (10,'ACC0010', 'KZT', 10000.00, TRUE),
    (1, 'ACC0011', 'USD', 50000.00, TRUE),
    (3, 'ACC0012', 'EUR', 120000.00, TRUE),
    (9, 'ACC0013', 'KZT', 750000.00, TRUE);

INSERT INTO exchange_rate (from_currency, to_currency, rate, valid_from, valid_to)
    VALUES
        ('USD', 'KZT', 520.19, CURRENT_TIMESTAMP, NULL),
        ('EUR', 'KZT', 609.59, CURRENT_TIMESTAMP, NULL),
        ('RUB', 'KZT', 6.47, CURRENT_TIMESTAMP, NULL),
        ('KZT', 'USD', 0.001921, CURRENT_TIMESTAMP, NULL),
        ('KZT', 'EUR', 0.001640, CURRENT_TIMESTAMP, NULL),
        ('KZT', 'RUB', 0.154560, CURRENT_TIMESTAMP, NULL);

--TASK 1
DROP PROCEDURE IF EXISTS process_transfer(character varying,character varying,numeric,character varying,text);

CREATE OR REPLACE PROCEDURE process_transfer(
    from_account_number VARCHAR,
    to_account_number   VARCHAR,
    p_amount            NUMERIC,
    p_currency          VARCHAR,
    p_description       TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_from_id INT;
    v_to_id INT;
    v_from_balance NUMERIC;
    v_currency_from VARCHAR(3);
    v_currency_to VARCHAR(3);
    v_rate NUMERIC := 1;
    v_amount_kzt NUMERIC;

    v_customer_id INT;
    v_customer_status VARCHAR(20);
    v_daily_limit NUMERIC;

    v_today_used NUMERIC;
BEGIN

-- 1. Validate accounts

    SELECT account_id, currency, balance, customer_id
    INTO v_from_id, v_currency_from, v_from_balance, v_customer_id
    FROM account
    WHERE account_number = from_account_number AND is_active = TRUE
    FOR UPDATE;

    IF v_from_id IS NULL THEN
        RAISE EXCEPTION 'ERR01: Sender account not found or inactive';
    END IF;

    SELECT account_id, currency
    INTO v_to_id, v_currency_to
    FROM account
    WHERE account_number = to_account_number AND is_active = TRUE
    FOR UPDATE;

    IF v_to_id IS NULL THEN
        RAISE EXCEPTION 'ERR02: Receiver account not found or inactive';
    END IF;


-- 2. Check customer status

    SELECT status, daily_limit_kzt
    INTO v_customer_status, v_daily_limit
    FROM customer
    WHERE customer_id = v_customer_id;

    IF v_customer_status <> 'active' THEN
        RAISE EXCEPTION 'ERR03: Sender customer is %', v_customer_status;
    END IF;

 -- 3. Check balance

    IF v_from_balance < p_amount THEN
        RAISE EXCEPTION 'ERR04: Insufficient funds';
    END IF;

-- 4. Currency conversion to KZT

    v_amount_kzt := p_amount * COALESCE(
        (SELECT rate FROM exchange_rate
         WHERE from_currency = v_currency_from AND to_currency = 'KZT'
         ORDER BY valid_from DESC LIMIT 1),
        1
    );

-- 5. Check daily limit

    SELECT COALESCE(SUM(amount_kzt), 0)
    INTO v_today_used
    FROM transaction_log
    WHERE from_account_id = v_from_id
      AND created_at::date = CURRENT_DATE
      AND status = 'completed';

    IF v_today_used + v_amount_kzt > v_daily_limit THEN
        RAISE EXCEPTION 'ERR05: Daily limit exceeded';
    END IF;

-- 6. Apply currency conversion for receiver

    IF v_currency_from = v_currency_to THEN
        v_rate := 1;
    ELSE
        v_rate := COALESCE(
            (SELECT rate FROM exchange_rate
             WHERE from_currency = v_currency_from AND to_currency = v_currency_to
             ORDER BY valid_from DESC LIMIT 1),
            1
        );
    END IF;

-- 7. Update balances (money movement)

    UPDATE account
    SET balance = balance - p_amount
    WHERE account_id = v_from_id;

    UPDATE account
    SET balance = balance + (p_amount * v_rate)
    WHERE account_id = v_to_id;

-- 8. Write transaction log

    INSERT INTO transaction_log(
        from_account_id, to_account_id, amount, currency,
        exchange_rate, amount_kzt, type, status, description
    ) VALUES (
        v_from_id, v_to_id, p_amount, v_currency_from,
        v_rate, v_amount_kzt, 'transfer', 'completed', p_description
    );

-- 9. Audit log (successful)

    INSERT INTO audit_log(table_name, record_id, action, new_values)
    VALUES ('transaction_log',
            currval('transaction_log_transaction_id_seq'),
            'INSERT',
            jsonb_build_object(
                'from', from_account_number,
                'to', to_account_number,
                'amount', p_amount,
                'currency', p_currency
            ));

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO audit_log(table_name, record_id, action, old_values, new_values)
        VALUES (
            'transaction_log',
            0,
            'INSERT',
            NULL,
            jsonb_build_object(
                'error', SQLERRM,
                'from', from_account_number,
                'to', to_account_number,
                'amount', p_amount
            )
        );
        RAISE;
END;
$$;

--ПРОВЕРКА ПЕРВОЙ ЗАДАЧИ:
--это код, который показывает баланс до перевода
SELECT account_number, balance, currency
FROM account
WHERE account_number IN ('ACC0001', 'ACC0008');

--этот код, чтобы проверить сколько отправлено сегодня, и какой еще лимит
    SELECT transaction_id, amount, amount_kzt, status, created_at
FROM transaction_log
WHERE from_account_id = (SELECT account_id FROM account WHERE account_number = 'ACC0001')
  AND created_at::date = CURRENT_DATE;
--вызов процедуры
CALL process_transfer('ACC0001', 'ACC0008', 10000, 'KZT', 'Test transfer');

--это код, который показывает баланс после перевода
SELECT account_number, balance, currency
FROM account
WHERE account_number IN ('ACC0001', 'ACC0008');

--Показывает, что транзакция зафиксирована, статус completed, правильная сумма и курс
SELECT *
FROM transaction_log
WHERE from_account_id = (SELECT account_id FROM account WHERE account_number='ACC0001')
   OR to_account_id = (SELECT account_id FROM account WHERE account_number='ACC0008')
ORDER BY created_at DESC;

--Показывает успешные или неудачные операции, включая описание ошибки, если что-то пошло не так
SELECT *
FROM audit_log
ORDER BY changed_at DESC
LIMIT 5;

--Проверить лимит отправителя после транзакции. Можно показать, что сумма всех транзакций за день не превышает daily_limit_kzt.
SELECT COALESCE(SUM(amount_kzt),0) AS today_used
FROM transaction_log
WHERE from_account_id = (SELECT account_id FROM account WHERE account_number='ACC0001')
  AND created_at::date = CURRENT_DATE
  AND status = 'completed';

--TASK 2
--View 1: customer_balance_summary
DROP VIEW IF EXISTS customer_balance_summary;

CREATE VIEW customer_balance_summary AS
WITH account_kzt AS (
    SELECT
        a.account_id,
        a.customer_id,
        a.account_number,
        a.currency,
        a.balance,
        -- конвертация в KZT
        CASE
            WHEN a.currency = 'KZT' THEN a.balance
            ELSE a.balance * (
                SELECT rate
                FROM exchange_rate
                WHERE from_currency = a.currency AND to_currency = 'KZT'
                ORDER BY valid_from DESC LIMIT 1
            )
        END AS balance_kzt
    FROM account a
    WHERE a.is_active = TRUE
),
customer_total AS (
    SELECT
        c.customer_id,
        c.full_name,
        c.daily_limit_kzt,
        SUM(a.balance_kzt) AS total_balance_kzt
    FROM customer c
    LEFT JOIN account_kzt a ON c.customer_id = a.customer_id
    GROUP BY c.customer_id, c.full_name, c.daily_limit_kzt
)
SELECT
    c.customer_id,
    c.full_name,
    a.account_number,
    a.currency,
    a.balance,
    a.balance_kzt,
    c.total_balance_kzt,
    ROUND((c.total_balance_kzt / c.daily_limit_kzt) * 100, 2) AS daily_limit_usage_pct,
    RANK() OVER (ORDER BY c.total_balance_kzt DESC) AS rank_by_balance
FROM customer_total c
LEFT JOIN account_kzt a ON c.customer_id = a.customer_id;

--View 2: daily_transaction_report
DROP VIEW IF EXISTS daily_transaction_report;

CREATE VIEW daily_transaction_report AS
WITH daily_agg AS (
    SELECT
        created_at::date AS tx_date,
        type,
        COUNT(*) AS tx_count,
        SUM(amount_kzt) AS total_amount_kzt,
        AVG(amount_kzt) AS avg_amount_kzt
    FROM transaction_log
    WHERE status = 'completed'
    GROUP BY created_at::date, type
),
daily_running AS (
    SELECT
        *,
        SUM(total_amount_kzt) OVER (PARTITION BY type ORDER BY tx_date) AS running_total_kzt,
        LAG(total_amount_kzt) OVER (PARTITION BY type ORDER BY tx_date) AS prev_day_total
    FROM daily_agg
)
SELECT
    tx_date,
    type,
    tx_count,
    total_amount_kzt,
    avg_amount_kzt,
    running_total_kzt,
    CASE
        WHEN prev_day_total IS NULL THEN NULL
        ELSE ROUND((total_amount_kzt - prev_day_total) / prev_day_total * 100, 2)
    END AS day_over_day_growth_pct
FROM daily_running;

--View 3: suspicious_activity_view (WITH SECURITY BARRIER)
DROP VIEW IF EXISTS suspicious_activity_view;

CREATE VIEW suspicious_activity_view
WITH (security_barrier = true) AS
WITH flagged AS (
    SELECT
        t.transaction_id,
        t.from_account_id,
        t.to_account_id,
        t.amount,
        t.amount_kzt,
        t.currency,
        t.created_at,
        CASE WHEN t.amount_kzt > 5000000 THEN TRUE ELSE FALSE END AS large_transfer_flag
    FROM transaction_log t
    WHERE t.status = 'completed'
),
freq_hour AS (
    SELECT
        from_account_id,
        date_trunc('hour', created_at) AS hour_block,
        COUNT(*) AS tx_count_hour
    FROM transaction_log
    WHERE status = 'completed'
    GROUP BY from_account_id, date_trunc('hour', created_at)
    HAVING COUNT(*) > 10
),
rapid_seq AS (
    SELECT
        from_account_id,
        created_at AS tx_time,
        LEAD(created_at) OVER (PARTITION BY from_account_id ORDER BY created_at) AS next_tx_time
    FROM transaction_log
    WHERE status = 'completed'
)
SELECT
    f.transaction_id,
    f.from_account_id,
    f.to_account_id,
    f.amount,
    f.amount_kzt,
    f.currency,
    f.created_at,
    f.large_transfer_flag,
    CASE WHEN h.tx_count_hour IS NOT NULL THEN TRUE ELSE FALSE END AS high_frequency_flag,
    CASE WHEN r.next_tx_time IS NOT NULL AND r.next_tx_time - r.tx_time < INTERVAL '1 minute' THEN TRUE ELSE FALSE END AS rapid_sequential_flag
FROM flagged f
LEFT JOIN freq_hour h ON f.from_account_id = h.from_account_id
LEFT JOIN rapid_seq r ON f.from_account_id = r.from_account_id AND f.created_at = r.tx_time;

--ПРОВЕРКА ВТОРОЙ ЗАДАЧИ:
--1)Проверка customer_balance_summary
--Посмотреть всех клиентов с их счетами и суммой в KZT
SELECT *
FROM customer_balance_summary
ORDER BY total_balance_kzt DESC;

-- Или конкретного клиента
SELECT *
FROM customer_balance_summary
WHERE full_name = 'Yernazar Altynbekov';

--Проверка daily_transaction_report
-- Все агрегированные транзакции по дате и типу
SELECT *
FROM daily_transaction_report
ORDER BY tx_date, type;

-- Конкретная дата
SELECT *
FROM daily_transaction_report
WHERE tx_date = CURRENT_DATE;

--Проверка suspicious_activity_view
-- Все подозрительные транзакции
SELECT *
FROM suspicious_activity_view
ORDER BY created_at DESC;

-- Только большие суммы
SELECT *
FROM suspicious_activity_view
WHERE large_transfer_flag = TRUE;

-- Частые транзакции за час
SELECT *
FROM suspicious_activity_view
WHERE high_frequency_flag = TRUE;

-- Быстрые последовательные переводы
SELECT *
FROM suspicious_activity_view
WHERE rapid_sequential_flag = TRUE;

--TASK 3
-- 1. До создания индексов
EXPLAIN ANALYZE SELECT * FROM account WHERE account_number='ACC0001';
EXPLAIN ANALYZE SELECT * FROM customer WHERE LOWER(email)='yernazar@gmail.com';
EXPLAIN ANALYZE SELECT * FROM transaction_log WHERE from_account_id=1;
EXPLAIN ANALYZE SELECT * FROM audit_log WHERE new_values @> '{"amount":10000}'::jsonb;

-- 2. Создание индексов
CREATE INDEX idx_account_number ON account(account_number); -- B-tree
CREATE INDEX idx_customer_email_lower ON customer(LOWER(email)); -- Expression index, case-insensitive search
CREATE INDEX idx_transaction_from_to ON transaction_log(from_account_id, to_account_id); -- Composite
CREATE INDEX idx_active_accounts_partial ON account(account_number) WHERE is_active=TRUE; -- Partial
CREATE INDEX idx_audit_log_gin ON audit_log USING GIN(new_values); -- GIN
CREATE INDEX idx_transaction_amount_hash ON transaction_log USING HASH(amount); -- Hash
CREATE INDEX idx_customer_status_balance ON customer(status, daily_limit_kzt); -- Composite/B-tree
CREATE INDEX idx_transaction_created_at ON transaction_log(created_at); -- For range queries

-- 3. После создания индексов
EXPLAIN ANALYZE SELECT * FROM account WHERE account_number='ACC0001';
EXPLAIN ANALYZE SELECT * FROM customer WHERE LOWER(email)='yernazar@gmail.com';
EXPLAIN ANALYZE SELECT * FROM transaction_log WHERE from_account_id=1;
EXPLAIN ANALYZE SELECT * FROM audit_log WHERE new_values @> '{"amount":10000}'::jsonb;

-- 4. Примеры использования частичных индексов
EXPLAIN ANALYZE SELECT * FROM account WHERE is_active=TRUE AND account_number='ACC0001';

--TASK 4
DROP PROCEDURE IF EXISTS process_salary_batch(VARCHAR, JSONB);

CREATE OR REPLACE PROCEDURE process_salary_batch(
    company_account_number VARCHAR,
    payments JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_company_id INT;
    v_company_balance NUMERIC;
    v_total_batch NUMERIC := 0;
    v_success_count INT := 0;
    v_failed_count INT := 0;
    v_failed_details JSONB := '[]'::JSONB;
    v_payment JSONB;
    v_iin VARCHAR;
    v_amount NUMERIC;
    v_description TEXT;
    v_employee_account INT;
BEGIN
    SELECT account_id, balance INTO v_company_id, v_company_balance
    FROM account
    WHERE account_number = company_account_number
    FOR UPDATE;

    IF v_company_id IS NULL THEN
        RAISE EXCEPTION 'Company account not found';
    END IF;

    FOR v_payment IN SELECT * FROM jsonb_array_elements(payments) LOOP
        v_iin := v_payment->>'iin';
        v_amount := (v_payment->>'amount')::NUMERIC;
        v_description := v_payment->>'description';
        v_total_batch := v_total_batch + v_amount;
    END LOOP;

    IF v_total_batch > v_company_balance THEN
        RAISE EXCEPTION 'Insufficient funds for salary batch';
    END IF;

    PERFORM pg_advisory_xact_lock(v_company_id);

    FOR v_payment IN SELECT * FROM jsonb_array_elements(payments) LOOP
        BEGIN
            v_iin := v_payment->>'iin';
            v_amount := (v_payment->>'amount')::NUMERIC;
            v_description := v_payment->>'description';

            SELECT account_id INTO v_employee_account
            FROM account
            WHERE customer_id = (SELECT customer_id FROM customer WHERE iin = v_iin)
              AND is_active = TRUE
            FOR UPDATE;

            IF v_employee_account IS NULL THEN
                v_failed_count := v_failed_count + 1;
                v_failed_details := v_failed_details || jsonb_build_object('iin', v_iin, 'reason', 'Employee account not found');
                CONTINUE;
            END IF;

            UPDATE account
            SET balance = balance + v_amount
            WHERE account_id = v_employee_account;

            INSERT INTO transaction_log(
                from_account_id, to_account_id, amount, currency, amount_kzt, type, status, description
            ) VALUES (
                v_company_id, v_employee_account, v_amount, 'KZT', v_amount, 'transfer', 'completed', v_description
            );

            v_success_count := v_success_count + 1;

        EXCEPTION WHEN OTHERS THEN
            v_failed_count := v_failed_count + 1;
            v_failed_details := v_failed_details || jsonb_build_object('iin', v_iin, 'reason', SQLERRM);
        END;
    END LOOP;

    UPDATE account
    SET balance = balance - v_total_batch
    WHERE account_id = v_company_id;

    RAISE NOTICE 'Batch completed: % successful, % failed', v_success_count, v_failed_count;
    RAISE NOTICE 'Failed details: %', v_failed_details;
END;
$$;

-- Пример вызова
CALL process_salary_batch(
    'ACC0001',
    '[{"iin":"020202020202","amount":5000,"description":"Salary Dec"},{"iin":"030303030303","amount":7000,"description":"Salary Dec"},{"iin":"010101010101","amount":1000,"description":"Salary Dec"}]'
);

-- Проверка итоговых балансов
SELECT account_number, balance FROM account WHERE account_number IN ('ACC0001','ACC0003','ACC0004','ACC0002');

-- Проверка логов транзакций
SELECT * FROM transaction_log ORDER BY created_at DESC LIMIT 10;

--ошибки:
-- Ошибка: перевод с несуществующего счета
DO $$
BEGIN
    PERFORM process_transfer('NONEXIST', 'ACC0008', 1000, 'KZT', 'Test invalid sender');
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Expected error: %', SQLERRM;
END $$;

-- Ошибка: перевод на неактивный счет
UPDATE account SET is_active = FALSE WHERE account_number = 'ACC0008';
DO $$
BEGIN
    PERFORM process_transfer('ACC0001', 'ACC0008', 1000, 'KZT', 'Test inactive receiver');
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Expected error: %', SQLERRM;
END $$;
UPDATE account SET is_active = TRUE WHERE account_number = 'ACC0008';

-- Ошибка: недостаточно средств
DO $$
BEGIN
    PERFORM process_transfer('ACC0010', 'ACC0001', 1000000, 'KZT', 'Test insufficient funds');
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Expected error: %', SQLERRM;
END $$;

-- Ошибка: клиент заблокирован
UPDATE customer SET status = 'blocked' WHERE customer_id = 1;
DO $$
BEGIN
    PERFORM process_transfer('ACC0001', 'ACC0008', 1000, 'KZT', 'Test blocked customer');
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Expected error: %', SQLERRM;
END $$;
UPDATE customer SET status = 'active' WHERE customer_id = 1;

-- Ошибка: превышение дневного лимита
UPDATE customer SET daily_limit_kzt = 1000 WHERE customer_id = 1;
DO $$
BEGIN
    PERFORM process_transfer('ACC0001', 'ACC0008', 5000, 'KZT', 'Test daily limit exceeded');
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Expected error: %', SQLERRM;
END $$;
UPDATE customer SET daily_limit_kzt = 777777777.00 WHERE customer_id = 1;

-- Ошибка в process_salary_batch: несуществующий IIN
DO $$
DECLARE
    result JSONB;
BEGIN
    PERFORM process_salary_batch(
        'ACC0001',
        '[{"iin":"000000000000","amount":1000,"description":"Salary"}]'::JSONB
    );
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Expected salary batch error: %', SQLERRM;
END $$;


--Brief Documentation
/*
--индексы
B-tree на account_number чтобы быстро найти счет
hash на iin чтобы быстро искать клиента
частичный индекс на is_active = TRUE чтобы быстрее брать только активные счета
composite индекс на customer_id и currency чтобы удобно суммировать балансы по валюте
expression индекс LOWER(email) чтобы искать email без учета регистра
GIN на audit_log.new_values чтобы фильтровать JSONB быстрее

--процедура process_transfer
проверяет есть ли счета и активен ли клиент
проверяет баланс и дневной лимит
SELECT FOR UPDATE блокирует строки чтобы никто не менял их одновременно
SAVEPOINT откатывает только неудачные переводы
в audit_log пишет и успешные и ошибки

--процедура process_salary_batch
берет массив выплат JSONB
проверяет хватает ли денег
SAVEPOINT позволяет продолжать если один перевод не прошел
advisory locks чтобы одна компания не могла запускать зарплату два раза
не учитывает дневной лимит для зарплаты

--ограничения
daily_limit_kzt не дает перевести больше лимита за день
status клиента блокирует если заблокирован или заморожен
CHECK и FOREIGN KEY чтобы данные были целыми

--конкурентный доступ
открыть две сессии psql
в первой сделать BEGIN и вызвать process_transfer не делать COMMIT сразу
во второй попытаться перевести с того же счета
вторая сессия будет ждать пока первая закончит
после COMMIT первой сессии вторая пройдет
так видно что race conditions нет
*/



