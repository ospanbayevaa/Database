-- bonus_lab.sql
SET client_min_messages = WARNING;

-- DROP existing
DROP MATERIALIZED VIEW IF EXISTS salary_batch_summary;
DROP VIEW IF EXISTS suspicious_activity_view;
DROP VIEW IF EXISTS daily_transaction_report;
DROP VIEW IF EXISTS customer_balance_summary;
DROP PROCEDURE IF EXISTS process_transfer(TEXT, TEXT, NUMERIC, CHAR(3), TEXT);
DROP PROCEDURE IF EXISTS process_salary_batch(TEXT, JSONB);
DROP FUNCTION IF EXISTS fn_audit_log();
DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS exchange_rates CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

-- DDL
CREATE TABLE customers (
  customer_id SERIAL PRIMARY KEY,
  iin CHAR(12) UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  status TEXT NOT NULL CHECK (status IN ('active','blocked','frozen')),
  created_at TIMESTAMPTZ DEFAULT now(),
  daily_limit_kzt NUMERIC(24,2) NOT NULL DEFAULT 1000000
);

CREATE TABLE accounts (
  account_id SERIAL PRIMARY KEY,
  customer_id INT NOT NULL REFERENCES customers(customer_id),
  account_number TEXT UNIQUE NOT NULL,
  currency CHAR(3) NOT NULL CHECK (currency IN ('KZT','USD','EUR','RUB')),
  balance NUMERIC(24,2) NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  opened_at TIMESTAMPTZ DEFAULT now(),
  closed_at TIMESTAMPTZ
);

CREATE TABLE exchange_rates (
  rate_id SERIAL PRIMARY KEY,
  from_currency CHAR(3) NOT NULL,
  to_currency CHAR(3) NOT NULL,
  rate NUMERIC(24,8) NOT NULL CHECK (rate > 0),
  valid_from TIMESTAMPTZ DEFAULT now(),
  valid_to TIMESTAMPTZ
);

CREATE TABLE transactions (
  transaction_id BIGSERIAL PRIMARY KEY,
  from_account_id INT REFERENCES accounts(account_id),
  to_account_id INT REFERENCES accounts(account_id),
  amount NUMERIC(24,2) NOT NULL CHECK (amount >= 0),
  currency CHAR(3) NOT NULL,
  exchange_rate NUMERIC(24,8),
  amount_kzt NUMERIC(28,2),
  type TEXT NOT NULL CHECK (type IN ('transfer','deposit','withdrawal','salary')),
  status TEXT NOT NULL CHECK (status IN ('pending','completed','failed','reversed')),
  created_at TIMESTAMPTZ DEFAULT now(),
  completed_at TIMESTAMPTZ,
  description TEXT
);

CREATE TABLE audit_log (
  log_id BIGSERIAL PRIMARY KEY,
  table_name TEXT NOT NULL,
  record_id TEXT,
  action TEXT NOT NULL CHECK (action IN ('INSERT','UPDATE','DELETE')),
  old_values JSONB,
  new_values JSONB,
  changed_by TEXT,
  changed_at TIMESTAMPTZ DEFAULT now(),
  ip_address TEXT
);

-- sample data customers (10)
INSERT INTO customers(iin, full_name, phone, email, status, daily_limit_kzt) VALUES
('860123456789','Aida Bek','+77011234567','aida@example.com','active',2000000),
('870987654321','Nurzhan K.','+77019876543','nurzhan@example.com','active',5000000),
('870111222333','Aliya S','+77013332211','aliya@example.com','blocked',1000000),
('880444555666','Murat T','+77014445566','murat@example.com','active',2000000),
('890999888777','Zhanar B','+77019998877','zhanar@example.com','frozen',500000),
('860222333444','Ermek K','+77012223344','ermek@example.com','active',1500000),
('870333444555','Dana I','+77013334455','dana@example.com','active',800000),
('880666777888','Sultan A','+77016667788','sultan@example.com','active',3000000),
('890123890123','Oksana P','+77018901231','oksana@example.com','active',1200000),
('860777888999','Bulat S','+77017778889','bulat@example.com','active',1000000);

-- sample data accounts (>=10)
INSERT INTO accounts(customer_id, account_number, currency, balance, is_active) VALUES
(1,'KZ100000000000000001','KZT',5000000,TRUE),
(1,'US100000000000000001','USD',2000,TRUE),
(2,'KZ200000000000000002','KZT',15000000,TRUE),
(3,'KZ300000000000000003','KZT',100000,TRUE),
(4,'EU400000000000000004','EUR',5000,TRUE),
(5,'RU500000000000000005','RUB',300000,TRUE),
(6,'KZ600000000000000006','KZT',700000,TRUE),
(7,'US700000000000000007','USD',500,TRUE),
(8,'KZ800000000000000008','KZT',2000000,TRUE),
(9,'KZ900000000000000009','KZT',0,TRUE),
(10,'EU100000000000000010','EUR',1000,TRUE);

-- sample exchange rates
INSERT INTO exchange_rates(from_currency,to_currency,rate,valid_from) VALUES
('USD','KZT',470,now()-interval '1 day'),
('EUR','KZT',510,now()-interval '1 day'),
('RUB','KZT',5.5,now()-interval '1 day'),
('KZT','USD',1/470.0,now()-interval '1 day'),
('KZT','EUR',1/510.0,now()-interval '1 day'),
('KZT','RUB',1/5.5,now()-interval '1 day'),
('USD','EUR',0.92,now()-interval '1 day'),
('EUR','USD',1.087,now()-interval '1 day');

-- sample transactions (>=10)
INSERT INTO transactions(from_account_id,to_account_id,amount,currency,exchange_rate,amount_kzt,type,status,created_at,completed_at,description) VALUES
(1,3,100000,'KZT',1,100000,'transfer','completed',now()-interval '5 day',now()-interval '5 day','t1'),
(2,7,50,'USD',470,23500,'transfer','completed',now()-interval '4 day',now()-interval '4 day','t2'),
(4,5,100,'EUR',510,51000,'transfer','completed',now()-interval '3 day',now()-interval '3 day','t3'),
(8,9,20000,'KZT',1,20000,'transfer','completed',now()-interval '2 day',now()-interval '2 day','t4'),
(NULL,1,500000,'KZT',1,500000,'deposit','completed',now()-interval '10 day',now()-interval '10 day','t5'),
(6,9,10000,'KZT',1,10000,'transfer','failed',now()-interval '1 day',NULL,'t6'),
(2,8,100,'USD',470,47000,'transfer','completed',now()-interval '6 hour',now()-interval '5 hour','t7'),
(2,8,200,'USD',470,94000,'transfer','completed',now()-interval '30 minute',now()-interval '29 minute','t8'),
(1,4,10,'USD',470,4700,'transfer','completed',now()-interval '15 minute',now()-interval '14 minute','t9'),
(8,1,1000,'KZT',1,1000,'transfer','completed',now()-interval '1 minute',now(),'t10');

-- audit trigger function and triggers
CREATE OR REPLACE FUNCTION fn_audit_log() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_by, ip_address)
    VALUES (TG_TABLE_NAME, COALESCE(NEW::text,''), 'INSERT', NULL, to_jsonb(NEW), current_user, inet_client_addr()::text);
    RETURN NEW;
  ELSIF TG_OP = 'UPDATE' THEN
    INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_by, ip_address)
    VALUES (TG_TABLE_NAME, COALESCE(NEW::text,''), 'UPDATE', to_jsonb(OLD), to_jsonb(NEW), current_user, inet_client_addr()::text);
    RETURN NEW;
  ELSE
    INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_by, ip_address)
    VALUES (TG_TABLE_NAME, COALESCE(OLD::text,''), 'DELETE', to_jsonb(OLD), NULL, current_user, inet_client_addr()::text);
    RETURN OLD;
  END IF;
END;
$$;

CREATE TRIGGER trg_audit_customers AFTER INSERT OR UPDATE OR DELETE ON customers FOR EACH ROW EXECUTE FUNCTION fn_audit_log();
CREATE TRIGGER trg_audit_accounts AFTER INSERT OR UPDATE OR DELETE ON accounts FOR EACH ROW EXECUTE FUNCTION fn_audit_log();
CREATE TRIGGER trg_audit_transactions AFTER INSERT OR UPDATE OR DELETE ON transactions FOR EACH ROW EXECUTE FUNCTION fn_audit_log();

-- Indexes: B-tree, composite, Hash, partial, expression, GIN
CREATE INDEX idx_accounts_account_number ON accounts(account_number);
CREATE INDEX idx_transactions_from_created_cover ON transactions (from_account_id, created_at) INCLUDE (amount, status);
CREATE INDEX idx_customers_phone_hash ON customers USING hash (phone);
CREATE INDEX idx_accounts_active_partial ON accounts(account_number) WHERE is_active = true;
CREATE INDEX idx_customers_email_lower ON customers (LOWER(email));
CREATE INDEX idx_audit_newvals_gin ON audit_log USING GIN (new_values);

-- process_transfer procedure
CREATE OR REPLACE PROCEDURE process_transfer(
  from_account_number TEXT,
  to_account_number TEXT,
  in_amount NUMERIC,
  in_currency CHAR(3),
  in_description TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_from accounts%ROWTYPE;
  v_to accounts%ROWTYPE;
  v_from_cust customers%ROWTYPE;
  v_rate NUMERIC;
  v_amount_kzt NUMERIC;
  v_today_total NUMERIC;
  v_trans_id BIGINT;
  v_amount_in_src NUMERIC;
  v_rate_in_to NUMERIC;
BEGIN
  IF in_amount <= 0 THEN RAISE EXCEPTION 'AMOUNT_INVALID' USING ERRCODE='P0001'; END IF;

  SELECT * INTO v_from FROM accounts WHERE account_number = from_account_number FOR UPDATE;
  IF NOT FOUND THEN
    INSERT INTO audit_log(table_name, record_id, action, new_values, changed_by) VALUES ('accounts', from_account_number, 'UPDATE', jsonb_build_object('error','from_not_found','attempt',in_amount), current_user);
    RAISE EXCEPTION 'FROM_ACCOUNT_NOT_FOUND' USING ERRCODE='P0002';
  END IF;

  SELECT * INTO v_to FROM accounts WHERE account_number = to_account_number FOR UPDATE;
  IF NOT FOUND THEN
    INSERT INTO audit_log(table_name, record_id, action, new_values, changed_by) VALUES ('accounts', to_account_number, 'UPDATE', jsonb_build_object('error','to_not_found','attempt',in_amount), current_user);
    RAISE EXCEPTION 'TO_ACCOUNT_NOT_FOUND' USING ERRCODE='P0003';
  END IF;

  IF NOT v_from.is_active THEN RAISE EXCEPTION 'FROM_ACCOUNT_INACTIVE' USING ERRCODE='P0004'; END IF;
  IF NOT v_to.is_active THEN RAISE EXCEPTION 'TO_ACCOUNT_INACTIVE' USING ERRCODE='P0005'; END IF;

  SELECT * INTO v_from_cust FROM customers WHERE customer_id = v_from.customer_id;
  IF v_from_cust.status <> 'active' THEN RAISE EXCEPTION 'SENDER_NOT_ACTIVE' USING ERRCODE='P0006'; END IF;

  SELECT rate INTO v_rate FROM exchange_rates WHERE from_currency = in_currency AND to_currency = 'KZT' AND (valid_to IS NULL OR valid_to > now()) ORDER BY valid_from DESC LIMIT 1;
  IF NOT FOUND THEN RAISE EXCEPTION 'NO_EXCHANGE_RATE' USING ERRCODE='P0010'; END IF;
  v_amount_kzt := in_amount * v_rate;

  SELECT COALESCE(SUM(t.amount_kzt),0) INTO v_today_total
  FROM transactions t JOIN accounts a ON t.from_account_id = a.account_id
  WHERE a.customer_id = v_from.customer_id AND t.created_at::date = now()::date AND t.status IN ('pending','completed','salary');

  IF v_today_total + v_amount_kzt > v_from_cust.daily_limit_kzt THEN
    INSERT INTO audit_log(table_name, record_id, action, new_values, changed_by) VALUES ('transactions', NULL, 'INSERT', jsonb_build_object('error','DAILY_LIMIT','attempt_kzt',v_amount_kzt,'today',v_today_total,'limit',v_from_cust.daily_limit_kzt), current_user);
    RAISE EXCEPTION 'DAILY_LIMIT_EXCEEDED' USING ERRCODE='P0011';
  END IF;

  IF in_currency = v_from.currency THEN
    v_amount_in_src := in_amount;
  ELSE
    SELECT rate INTO v_rate FROM exchange_rates WHERE from_currency = in_currency AND to_currency = 'KZT' ORDER BY valid_from DESC LIMIT 1;
    SELECT rate INTO v_rate_in_to FROM exchange_rates WHERE from_currency = 'KZT' AND to_currency = v_from.currency ORDER BY valid_from DESC LIMIT 1;
    IF v_rate IS NULL OR v_rate_in_to IS NULL THEN RAISE EXCEPTION 'NO_EXCHANGE_RATE' USING ERRCODE='P0010'; END IF;
    v_amount_in_src := in_amount * v_rate * v_rate_in_to;
  END IF;

  IF v_from.balance < v_amount_in_src THEN
    INSERT INTO audit_log(table_name, record_id, action, new_values, changed_by) VALUES ('transactions', NULL, 'INSERT', jsonb_build_object('error','INSUFFICIENT_FUNDS','avail',v_from.balance,'need',v_amount_in_src), current_user);
    RAISE EXCEPTION 'INSUFFICIENT_FUNDS' USING ERRCODE='P0012';
  END IF;

  SAVEPOINT sp_before_transfer;
  BEGIN
    INSERT INTO transactions(from_account_id,to_account_id,amount,currency,exchange_rate,amount_kzt,type,status,created_at,description)
    VALUES (v_from.account_id, v_to.account_id, in_amount, in_currency, v_rate, v_amount_kzt, 'transfer', 'pending', now(), in_description)
    RETURNING transaction_id INTO v_trans_id;

    UPDATE accounts SET balance = balance - v_amount_in_src WHERE account_id = v_from.account_id;

    IF v_to.currency = in_currency THEN
      UPDATE accounts SET balance = balance + in_amount WHERE account_id = v_to.account_id;
    ELSE
      SELECT rate INTO v_rate_in_to FROM exchange_rates WHERE from_currency = in_currency AND to_currency = v_to.currency ORDER BY valid_from DESC LIMIT 1;
      IF v_rate_in_to IS NULL THEN
        -- try via KZT
        SELECT rate INTO v_rate_in_to FROM exchange_rates WHERE from_currency = in_currency AND to_currency = 'KZT' ORDER BY valid_from DESC LIMIT 1;
        SELECT rate INTO v_rate_in_to FROM exchange_rates WHERE from_currency = 'KZT' AND to_currency = v_to.currency ORDER BY valid_from DESC LIMIT 1;
      END IF;
      IF v_rate_in_to IS NULL THEN
        ROLLBACK TO SAVEPOINT sp_before_transfer;
        UPDATE transactions SET status='failed', completed_at = now() WHERE transaction_id = v_trans_id;
        RAISE EXCEPTION 'NO_EXCHANGE_RATE_TO_DEST' USING ERRCODE='P0013';
      END IF;
      UPDATE accounts SET balance = balance + (in_amount * v_rate_in_to) WHERE account_id = v_to.account_id;
    END IF;

    UPDATE transactions SET status='completed', exchange_rate=v_rate, amount_kzt=v_amount_kzt, completed_at=now() WHERE transaction_id = v_trans_id;
    INSERT INTO audit_log(table_name, record_id, action, new_values, changed_by) VALUES ('transactions', v_trans_id::text, 'INSERT', (SELECT to_jsonb(t) FROM transactions t WHERE t.transaction_id = v_trans_id), current_user);
    RELEASE SAVEPOINT sp_before_transfer;
  EXCEPTION WHEN OTHERS THEN
    ROLLBACK TO SAVEPOINT sp_before_transfer;
    UPDATE transactions SET status='failed', completed_at = now() WHERE transaction_id = v_trans_id;
    INSERT INTO audit_log(table_name, record_id, action, new_values, changed_by) VALUES ('transactions', v_trans_id::text, 'UPDATE', jsonb_build_object('error',SQLERRM), current_user);
    RAISE;
  END;
END;
$$;

-- Views
CREATE OR REPLACE VIEW customer_balance_summary AS
SELECT
  c.customer_id,
  c.full_name,
  c.iin,
  a.account_id,
  a.account_number,
  a.currency,
  a.balance,
  SUM(CASE WHEN a.currency='KZT' THEN a.balance ELSE a.balance *
    COALESCE((SELECT rate FROM exchange_rates er WHERE er.from_currency=a.currency AND er.to_currency='KZT' AND (er.valid_to IS NULL OR er.valid_to>now()) ORDER BY er.valid_from DESC LIMIT 1),0) END
  ) OVER (PARTITION BY c.customer_id) AS total_balance_kzt,
  c.daily_limit_kzt,
  (SUM(CASE WHEN a.currency='KZT' THEN a.balance ELSE a.balance *
    COALESCE((SELECT rate FROM exchange_rates er WHERE er.from_currency=a.currency AND er.to_currency='KZT' ORDER BY er.valid_from DESC LIMIT 1),0) END
  ) OVER (PARTITION BY c.customer_id) / NULLIF(c.daily_limit_kzt,0)) * 100 AS daily_limit_util_pct,
  RANK() OVER (ORDER BY SUM(CASE WHEN a.currency='KZT' THEN a.balance ELSE a.balance *
    COALESCE((SELECT rate FROM exchange_rates er WHERE er.from_currency=a.currency AND er.to_currency='KZT' ORDER BY er.valid_from DESC LIMIT 1),0) END) OVER (PARTITION BY c.customer_id) DESC) AS rank_by_total
FROM customers c
LEFT JOIN accounts a ON a.customer_id = c.customer_id;

CREATE OR REPLACE VIEW daily_transaction_report AS
SELECT
  date_trunc('day', created_at) AS day,
  type,
  COUNT(*) AS count,
  SUM(amount_kzt) AS total_kzt,
  AVG(amount_kzt) AS avg_kzt,
  SUM(SUM(amount_kzt)) OVER (ORDER BY date_trunc('day', created_at) ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_kzt,
  LAG(SUM(amount_kzt)) OVER (ORDER BY date_trunc('day', created_at)) AS prev_day_total_kzt,
  CASE WHEN LAG(SUM(amount_kzt)) OVER (ORDER BY date_trunc('day', created_at)) IS NULL THEN NULL
       ELSE (SUM(amount_kzt) - LAG(SUM(amount_kzt)) OVER (ORDER BY date_trunc('day', created_at))) / NULLIF(LAG(SUM(amount_kzt)) OVER (ORDER BY date_trunc('day', created_at)),0) * 100 END AS day_over_day_pct
FROM transactions
GROUP BY date_trunc('day', created_at), type
ORDER BY day;

CREATE OR REPLACE VIEW suspicious_activity_view WITH (security_barrier=true) AS
SELECT t.*,
  (t.amount_kzt > 5000000) AS flag_large_tx,
  counts.tx_per_hour,
  seq.seq_count
FROM transactions t
LEFT JOIN (
  SELECT from_account_id, date_trunc('hour', created_at) AS hr, COUNT(*) AS tx_per_hour
  FROM transactions
  GROUP BY from_account_id, date_trunc('hour', created_at)
  HAVING COUNT(*) > 10
) counts ON counts.from_account_id = t.from_account_id AND date_trunc('hour', t.created_at) = counts.hr
LEFT JOIN (
  SELECT t1.transaction_id, t1.from_account_id,
    COUNT(*) OVER (PARTITION BY t1.from_account_id ORDER BY t1.created_at RANGE BETWEEN INTERVAL '1 minute' PRECEDING AND CURRENT ROW) AS seq_count
  FROM transactions t1
) seq ON seq.transaction_id = t.transaction_id
WHERE (t.amount_kzt > 5000000) OR (counts.tx_per_hour IS NOT NULL) OR (seq.seq_count > 1);

-- materialized view for salary summary
CREATE MATERIALIZED VIEW salary_batch_summary AS
SELECT now()::date AS snapshot_date, COUNT(*) FILTER (WHERE type='salary') AS salary_count, SUM(amount_kzt) FILTER (WHERE type='salary') AS salary_total_kzt
FROM transactions
WITH NO DATA;

-- process_salary_batch procedure
CREATE OR REPLACE PROCEDURE process_salary_batch(company_account_number TEXT, payments JSONB)
LANGUAGE plpgsql
AS $$
DECLARE
  v_company accounts%ROWTYPE;
  v_total NUMERIC := 0;
  v_elem JSONB;
  v_iin TEXT;
  v_amount NUMERIC;
  v_desc TEXT;
  v_target_account INT;
  v_failed JSONB := '[]'::jsonb;
  v_success INT := 0;
  v_failed_count INT := 0;
  v_lock_key BIGINT;
BEGIN
  v_lock_key := hashtext(company_account_number)::bigint;
  PERFORM pg_advisory_lock(v_lock_key);

  SELECT * INTO v_company FROM accounts WHERE account_number = company_account_number FOR UPDATE;
  IF NOT FOUND THEN PERFORM pg_advisory_unlock(v_lock_key); RAISE EXCEPTION 'COMPANY_ACCOUNT_NOT_FOUND' USING ERRCODE='P0020'; END IF;
  IF NOT v_company.is_active THEN PERFORM pg_advisory_unlock(v_lock_key); RAISE EXCEPTION 'COMPANY_ACCOUNT_INACTIVE' USING ERRCODE='P0021'; END IF;

  FOR v_elem IN SELECT * FROM jsonb_array_elements(payments) LOOP
    v_amount := (v_elem->>'amount')::numeric;
    v_total := v_total + COALESCE(v_amount,0);
  END LOOP;

  IF v_company.balance < v_total THEN PERFORM pg_advisory_unlock(v_lock_key); RAISE EXCEPTION 'INSUFFICIENT_COMPANY_FUNDS' USING ERRCODE='P0022'; END IF;

  CREATE TEMP TABLE IF NOT EXISTS tmp_salary_updates(account_id INT PRIMARY KEY, delta NUMERIC) ON COMMIT DROP;

  FOR v_elem IN SELECT * FROM jsonb_array_elements(payments) LOOP
    v_iin := v_elem->>'iin';
    v_amount := (v_elem->>'amount')::numeric;
    v_desc := COALESCE(v_elem->>'description','salary');
    BEGIN
      SELECT a.account_id INTO v_target_account FROM accounts a JOIN customers c ON a.customer_id = c.customer_id WHERE c.iin = v_iin AND a.is_active = TRUE LIMIT 1;
      IF NOT FOUND THEN
        v_failed := v_failed || jsonb_build_object('iin', v_iin, 'amount', v_amount, 'error','NO_ACCOUNT');
        v_failed_count := v_failed_count + 1;
        CONTINUE;
      END IF;
      INSERT INTO tmp_salary_updates(account_id, delta) VALUES (v_target_account, v_amount)
        ON CONFLICT (account_id) DO UPDATE SET delta = tmp_salary_updates.delta + EXCLUDED.delta;
      INSERT INTO transactions(from_account_id,to_account_id,amount,currency,exchange_rate,amount_kzt,type,status,created_at,description)
        VALUES (v_company.account_id, v_target_account, v_amount, v_company.currency, 1, v_amount, 'salary', 'pending', now(), v_desc);
      v_success := v_success + 1;
    EXCEPTION WHEN OTHERS THEN
      v_failed := v_failed || jsonb_build_object('iin', v_iin, 'amount', v_amount, 'error', SQLERRM);
      v_failed_count := v_failed_count + 1;
      CONTINUE;
    END;
  END LOOP;

  SAVEPOINT sp_batch;
  BEGIN
    UPDATE accounts SET balance = balance - v_total WHERE account_id = v_company.account_id;
    FOR v_elem IN SELECT account_id, delta FROM tmp_salary_updates LOOP
      UPDATE accounts SET balance = balance + v_elem.delta WHERE account_id = v_elem.account_id;
    END LOOP;
    UPDATE transactions SET status='completed', completed_at = now() WHERE type='salary' AND status='pending' AND from_account_id = v_company.account_id;
    INSERT INTO audit_log(table_name, record_id, action, new_values, changed_by) VALUES ('salary_batch', company_account_number, 'INSERT', jsonb_build_object('total', v_total, 'success', v_success, 'failed', v_failed), current_user);
    RELEASE SAVEPOINT sp_batch;
  EXCEPTION WHEN OTHERS THEN
    ROLLBACK TO SAVEPOINT sp_batch;
    UPDATE transactions SET status='failed', completed_at = now() WHERE type='salary' AND status='pending' AND from_account_id = v_company.account_id;
    PERFORM pg_advisory_unlock(v_lock_key);
    RAISE;
  END;

  REFRESH MATERIALIZED VIEW salary_batch_summary;
  PERFORM pg_advisory_unlock(v_lock_key);

  RAISE NOTICE 'SALARY_BATCH_RESULT success=% failed=% details=%', v_success, v_failed_count, v_failed;
END;
$$;

/*
-- Test Transfer
CALL process_transfer('KZ010101', 'KZ020201', 500, 'KZT', 'Lunch');

-- Test Batch
DO $$
DECLARE res JSONB;
BEGIN
    CALL process_salary_batch('KZ060601', '[{"iin":"111111111111", "amount":50000, "description":"Bonus"}]', res);
    RAISE NOTICE '%', res;
END $$;
*/
