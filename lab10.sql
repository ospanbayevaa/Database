CREATE TABLE accounts (
id SERIAL PRIMARY KEY,
name VARCHAR(100) NOT NULL,
balance DECIMAL(10, 2) DEFAULT 0.00
);
CREATE TABLE products (
id SERIAL PRIMARY KEY,
shop VARCHAR(100) NOT NULL,
product VARCHAR(100) NOT NULL,
price DECIMAL(10, 2) NOT NULL
);
-- Insert test data
INSERT INTO accounts (name, balance) VALUES
('Alice', 1000.00),
('Bob', 500.00),
('Wally', 750.00);
INSERT INTO products (shop, product, price) VALUES
('Joe''s Shop', 'Coke', 2.50),
('Joe''s Shop', 'Pepsi', 3.00); и вот так выглядит мой вайл --Part 3
--task 3.1
CREATE TABLE accounts (
id SERIAL PRIMARY KEY,
name VARCHAR(100) NOT NULL,
balance DECIMAL(10, 2) DEFAULT 0.00
);
CREATE TABLE products (
id SERIAL PRIMARY KEY,
shop VARCHAR(100) NOT NULL,
product VARCHAR(100) NOT NULL,
price DECIMAL(10, 2) NOT NULL
);
-- Insert test data
INSERT INTO accounts (name, balance) VALUES
('Alice', 1000.00),
('Bob', 500.00),
('Wally', 750.00);
INSERT INTO products (shop, product, price) VALUES
('Joe''s Shop', 'Coke', 2.50),
('Joe''s Shop', 'Pepsi', 3.00);

--task3.2
BEGIN;
UPDATE accounts SET balance = balance - 100.00 WHERE name = 'Alice';
UPDATE accounts SET balance = balance + 100.00 WHERE name = 'Bob';
COMMIT;
/*
a)Alice: 1000.00 − 100.00 = 900.00
Bob: 500.00 + 100.00 = 600.00
b)Because a transfer is a logical unit: you either need to perform both 
UPDATEs (debit and credit), or neither.
c)If the system crashes between two UPDATE statements and there was no transaction, 
the state will become inconsistent: the money will be withdrawn from Alice but not transferred 
to Bob—data loss/error. With a transaction that crashes without a COMMIT, the DBMS will roll back 
or the changes will not be considered applied.
*/

--task 3.3
BEGIN;
UPDATE accounts SET balance = balance - 500.00 WHERE name = 'Alice';
SELECT * FROM accounts WHERE name = 'Alice';  -- покажет промежуточное значение в рамках транзакции
ROLLBACK;
SELECT * FROM accounts WHERE name = 'Alice';  -- покажет значение до транзакции
/*
a)After the UPDATE but before the ROLLBACK, within the same transaction, Alice will return a SELECT of 1000.00 − 500.00 = 500.00. 
If another session views the record (depending on isolation), it may not see these changes.
b)After ROLLBACK the balance returns to 1000.00 (transaction cancelled).
c)ROLLBACK is used in case of errors (e.g., validation, insufficient funds), constraint violations, or unexpected exceptions in applications—to 
roll back all intermediate changes and keep the database in a consistent state.
*/

--task 3.4
BEGIN;
UPDATE accounts SET balance = balance - 100.00 WHERE name = 'Alice';
SAVEPOINT my_savepoint;
UPDATE accounts SET balance = balance + 100.00 WHERE name = 'Bob';
-- Откат к savepoint, Bob не должен получить деньги
ROLLBACK TO my_savepoint;
UPDATE accounts SET balance = balance + 100.00 WHERE name = 'Wally';
COMMIT;
/*
a)After COMMIT:
Alice = 900.00
Bob = 500.00
Wally = 850.00
b)Briefly, yes, but then we rolled back to SAVEPOINT, so in the final state, Bob was not credited.
c)The advantage of SAVEPOINT is that you can partially roll back changes within a large transaction without losing all previous steps.
*/

--task 3.5
--terminal 1
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop';  -- видит начальные строки: Coke, Pepsi
-- ждёт
SELECT * FROM products WHERE shop = 'Joe''s Shop';  -- после коммита терминала 2 увидит уже изменённый набор
COMMIT;
--terminal 2
BEGIN;
DELETE FROM products WHERE shop = 'Joe''s Shop'; -- удаляет Coke и Pepsi
INSERT INTO products (shop, product, price) VALUES ('Joe''s Shop', 'Fanta', 3.50);
COMMIT;
/*
a)In Scenario A: Terminal 1 first saw Coke, Pepsi, and after the commit, Terminal 2 will see Fanta.
b)In Scenario B: Terminal 1 will see the state it had at the beginning of the transaction—usually Coke, Pepsi, and won't see Fanta. If there's a conflict, 
the DBMS may throw a serialization error on COMMIT.
c)Difference: READ COMMITTED gives the most current committed data for each SELECT
SERIALIZABLE attempts to provide behavior equivalent to serial execution of transactions - preventing concurrency anomalies
*/

--task 3.6
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT MAX(price), MIN(price) FROM products WHERE shop = 'Joe''s Shop';
-- ждёт
SELECT MAX(price), MIN(price) FROM products WHERE shop = 'Joe''s Shop';
COMMIT;

BEGIN;
INSERT INTO products (shop, product, price) VALUES ('Joe''s Shop', 'Sprite', 4.00);
COMMIT;
/*
a)By the classic SQL definition, REPEATABLE READ guarantees that repeated reading of the same rows will return the same values, but REPEATABLE READ in 
the standard allows phantoms
b)Phantom read - a situation where a repeated request in a transaction returns a set of rows
c)SERIALIZABLE
*/

--task 3.7
BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- ждёт, чтобы Terminal 2 сделал UPDATE, но не COMMIT
SELECT * FROM products WHERE shop = 'Joe''s Shop';  -- может увидеть незакоммиченый price=99.99
-- ждёт, Terminal 2 делает ROLLBACK
SELECT * FROM products WHERE shop = 'Joe''s Shop';  -- теперь вернёт старую цену
COMMIT;


BEGIN;
UPDATE products SET price = 99.99 WHERE product = 'Fanta';
-- НЕ COMMIT, ждёт
-- затем ROLLBACK;
ROLLBACK;
/*
a)Yes, Terminal 1 can see the price of 99.99 before Terminal 2 rolls back the changes - this is a dirty read: reading uncommitted data from another transaction.
b) Dirty read - reading data that has been modified by another transaction but not yet committed; it can be rolled back.
c)READ UNCOMMITTED should be avoided in most applications because it allows dirty reads and can lead to incorrect decisions and inconsistencies.
*/

--Part 4: Independent Exercises
--Ex 1
BEGIN;
SELECT id, balance FROM accounts WHERE name = 'Bob' FOR UPDATE;

DO $$
DECLARE
  bob_balance numeric(10,2);
BEGIN
  SELECT balance INTO bob_balance FROM accounts WHERE name = 'Bob' FOR UPDATE;
  IF bob_balance < 200.00 THEN
    RAISE NOTICE 'Not enough funds: %', bob_balance;
    ROLLBACK;
    RETURN;
  END IF;

  UPDATE accounts SET balance = balance - 200.00 WHERE name = 'Bob';
  UPDATE accounts SET balance = balance + 200.00 WHERE name = 'Wally';
  COMMIT;
END;
$$;

--Ex 2
BEGIN;

INSERT INTO products (shop, product, price) VALUES ('Joe''s Shop', 'NewProduct', 5.00);
SAVEPOINT sp1;
UPDATE products SET price = 6.50 WHERE product = 'NewProduct';
SAVEPOINT sp2;
DELETE FROM products WHERE product = 'NewProduct';
ROLLBACK TO SAVEPOINT sp1;

COMMIT;

--Ex 3
BEGIN ISOLATION LEVEL READ COMMITTED;
UPDATE accounts SET balance = balance - 300 WHERE name = 'Alice';
COMMIT;

BEGIN ISOLATION LEVEL READ COMMITTED;
UPDATE accounts SET balance = balance - 300 WHERE name = 'Alice';
COMMIT;


BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT balance FROM accounts WHERE name = 'Alice' FOR UPDATE;
UPDATE accounts SET balance = balance - 300 WHERE name = 'Alice';
COMMIT;

BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT balance FROM accounts WHERE name = 'Alice' FOR UPDATE;
ROLLBACK;


BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT balance FROM accounts WHERE name = 'Alice';
UPDATE accounts SET balance = balance - 300 WHERE name = 'Alice';
COMMIT;

BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT balance FROM accounts WHERE name = 'Alice';
UPDATE accounts SET balance = balance - 300 WHERE name = 'Alice';
COMMIT;


--ex 4
BEGIN ISOLATION LEVEL REPEATABLE READ;

SELECT MAX(price) AS max_price, MIN(price) AS min_price
FROM products
WHERE shop = 'Joe''s Shop';

UPDATE products SET price = 10.00 WHERE product = 'Fanta';
UPDATE products SET price = 1.00  WHERE product = 'Sprite';
COMMIT;

SELECT MAX(price) AS max_price, MIN(price) AS min_price
FROM products
WHERE shop = 'Joe''s Shop';

COMMIT;



