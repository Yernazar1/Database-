-- 3.1
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS products CASCADE;

CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    balance DECIMAL(10,2) DEFAULT 0.00
);
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    shop VARCHAR(100) NOT NULL,
    product VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL
);
INSERT INTO accounts (name, balance) VALUES
    ('Alice', 1000.00),
    ('Bob', 500.00),
    ('Wally', 750.00);
INSERT INTO products (shop, product, price) VALUES
    ('Joes Shop', 'Coke', 2.50),
    ('Joes Shop', 'Pepsi', 3.00);

-- 3.2
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE name = 'Alice';
UPDATE accounts SET balance = balance + 100 WHERE name = 'Bob';
COMMIT;

SELECT * FROM accounts;

-- a) Final balances:
-- Alice: 1000 - 100 = 900
-- Bob: 500 + 100 = 600
-- b) Both UPDATEs need to be in a single transaction because a money transfer is one logical action. If one part succeeds and the other fails, the database would be inconsistent.
-- c) Without a transaction, if the system crashes between the two UPDATEs, Alice loses 100 but Bob doesn't get it, leaving incorrect data.

-- 3.3
BEGIN;
UPDATE accounts SET balance = balance - 500 WHERE name = 'Alice';
SELECT * FROM accounts WHERE name = 'Alice';   -- before rollback
ROLLBACK;

SELECT * FROM accounts WHERE name = 'Alice';   -- after rollback

-- a) After the UPDATE but before ROLLBACK, Alice's balance = 1000 - 500 = 500.
-- b) After ROLLBACK, Alice's balance goes back to 1000.
-- c) Use ROLLBACK when:
-- wrong data was updated,
-- the amount is incorrect,
-- a validation fails,
-- or an unexpected error occurs.
-- It safely reverts all temporary changes.

-- 3.4
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE name = 'Alice';
SAVEPOINT my_savepoint;
UPDATE accounts SET balance = balance + 100 WHERE name = 'Bob';
-- incorrect transfer → undo Bob
ROLLBACK TO my_savepoint;
-- correct transfer
UPDATE accounts SET balance = balance + 100 WHERE name = 'Wally';
COMMIT;

SELECT * FROM accounts;

-- a) Final balances:
-- Alice: 1000 - 100 = 900
-- Bob: 500 (unchanged)
-- Wally: 750 + 100 = 850
-- b) Bob was credited temporarily, but this change was undone with ROLLBACK TO SAVEPOINT. So Bob's balance remains the same.
-- c) SAVEPOINT allows rolling back only part of a transaction instead of the whole. Useful when one step fails but others are correct.

-- 3.5 TASK 4 – ISOLATION LEVEL DEMO (RUN IN 2 TERMINALS)
-- TERMINAL 1:
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT * FROM products WHERE shop='Joe''s Shop';
-- repeat SELECT after Terminal 2 COMMIT
COMMIT;

-- TERMINAL 2:
BEGIN;
DELETE FROM products WHERE shop='Joe''s Shop';
INSERT INTO products(shop,product,price)
VALUES ('Joe''s Shop','Fanta',3.50);
COMMIT;

-- Scenario A — READ COMMITTED:
-- a) Terminal 1 sees:
-- Before Terminal 2 commits → Coke, Pepsi
-- After Terminal 2 commits → Fanta
-- READ COMMITTED always returns the most recent committed data.
-- Scenario B — SERIALIZABLE:
-- b) Terminal 1 only sees Coke, Pepsi.
-- c) Difference:
-- READ COMMITTED: every SELECT sees the latest committed changes.
-- SERIALIZABLE: transaction behaves as if it runs alone; no other changes are visible.

-- 3.6
-- TERMINAL 1:
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT MAX(price), MIN(price) FROM products WHERE shop='Joe''s Shop';
-- repeat SELECT after Terminal 2 INSERT
COMMIT;

-- TERMINAL 2:
BEGIN;
INSERT INTO products(shop,product,price)
VALUES ('Joe''s Shop','Sprite',4.00);
COMMIT;

-- a) No, Terminal 1 does NOT see the new product from Terminal 2.
-- REPEATABLE READ locks the result set for the whole transaction.
-- b) Phantom read occurs when new rows appear in the result of the same query during a transaction.
-- c) Only SERIALIZABLE completely prevents phantom reads.

-- 3.7
-- TERMINAL 1:
BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * FROM products WHERE shop='Joe''s Shop';
-- repeat SELECT while Terminal 2 UPDATED but NOT committed
-- repeat SELECT after Terminal 2 ROLLBACK
COMMIT;

-- TERMINAL 2:
BEGIN;
UPDATE products SET price=99.99 WHERE product='Fanta';
ROLLBACK;

-- a) Terminal 1 sees 99.99. This is a dirty read because Terminal 2 has not committed, and the change is later rolled back.
-- b) Dirty read means reading uncommitted changes from another transaction.
-- c) READ UNCOMMITTED should be avoided since it can show temporary or inconsistent data, leading to incorrect results.

-- 4. INDEPENDENT EXERCISE 1
-- Transfer $200 from Bob to Wally IF Bob has enough balance
DO $$
BEGIN
    IF (SELECT balance FROM accounts WHERE name='Bob') >= 200 THEN
        BEGIN
            UPDATE accounts SET balance = balance - 200 WHERE name='Bob';
            UPDATE accounts SET balance = balance + 200 WHERE name='Wally';
            RAISE NOTICE 'Transfer successful';
        END;
    ELSE
        RAISE NOTICE 'Transfer failed: insufficient funds';
    END IF;
END $$;
SELECT * FROM accounts;

-- 4. INDEPENDENT EXERCISE 2
-- SAVEPOINT DEMO with INSERT → UPDATE → DELETE → ROLLBACK
BEGIN;
INSERT INTO products(shop,product,price)
VALUES ('Demo Shop','Tea',1.00);
SAVEPOINT sp1;
UPDATE products SET price=2.50 WHERE product='Tea';
SAVEPOINT sp2;
DELETE FROM products WHERE product='Tea';
ROLLBACK TO sp1;
COMMIT;
SELECT * FROM products;

-- 4. INDEPENDENT EXERCISE 3
-- Simultaneous withdrawals (conceptual example)
-- TERMINAL 1:
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
UPDATE accounts SET balance = balance - 300 WHERE name='Alice';
COMMIT;

-- TERMINAL 2:
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
UPDATE accounts SET balance = balance - 300 WHERE name='Alice';
COMMIT;

-- Under SERIALIZABLE, the second transaction would fail.

-- 4. INDEPENDENT EXERCISE 4
-- Demonstrate MAX < MIN problem without transactions
-- BAD SESSION 1:
SELECT MAX(price) FROM products WHERE shop='Joe''s Shop';

-- Meanwhile SESSION 2 deletes rows

-- BAD RESULT: MAX < MIN is possible

-- GOOD (WITH TRANSACTION):
BEGIN;
SELECT MAX(price), MIN(price) FROM products WHERE shop='Joe''s Shop';
COMMIT;

-- 5.
 /*
1. ACID Properties:
   Atomic – everything happens together or not at all (bank transfer example).
   Consistent – database stays valid (constraints enforced).
   Isolated – transactions do not see each other's intermediate results.
   Durable – committed changes persist even after crash.

2. COMMIT saves changes permanently,
   ROLLBACK cancels all changes.

3. SAVEPOINT is used to undo part of a transaction if needed.

4. Isolation levels:
   • Read Uncommitted – allows dirty reads
   • Read Committed – prevents dirty reads
   • Repeatable Read – prevents non-repeatable reads
   • Serializable – full isolation

5. Dirty read = reading uncommitted changes (READ UNCOMMITTED).

6. Non-repeatable read:
   You read the same row twice and it changes in between.

7. Phantom read:
   A query returns new rows added by another transaction.
   Only SERIALIZABLE completely prevents this.

8. READ COMMITTED is faster and commonly used in high-load systems.

9. Transactions keep data consistent when many users access the database simultaneously.

10. Uncommitted changes are lost if the system crashes.
*/

 /*
Conclusion

In this lab I learned how SQL transactions keep a database safe,
correct, and reliable when multiple operations occur simultaneously.
I understood ACID properties and how each protects data:
atomicity ensures all steps execute together,
consistency maintains valid database state,
isolation prevents concurrency problems,
and durability guarantees committed changes are permanent.

I also practiced using main transaction commands — BEGIN, COMMIT, ROLLBACK, and SAVEPOINT.
*/
