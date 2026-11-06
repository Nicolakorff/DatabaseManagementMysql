-- 02_load_clean.sql
-- Loads the CSV files, fixes data types, adds foreign keys, normalizes
-- transactions.product_ids into the bridge table `orders` and derives `credit_status`.
--
-- Run from the repository root so the relative paths in LOAD DATA resolve:
--   mysql --local-infile=1 -u <user> -p sales < sql/02_load_clean.sql
-- Place the CSV files in data/ first (they are not included in this repository).
-- If rows load as a single column or with a trailing \r, change LINES TERMINATED BY
-- between '\n' (Unix files) and '\r\n' (Windows files).

USE sales;
SET GLOBAL local_infile = TRUE;

-- 1. Load ----------------------------------------------------------------
LOAD DATA LOCAL INFILE 'data/credit_cards.csv' INTO TABLE credit_cards
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'data/companies.csv' INTO TABLE companies
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

-- users come in three regional files
LOAD DATA LOCAL INFILE 'data/users_ca.csv' INTO TABLE users
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'data/users_uk.csv' INTO TABLE users
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'data/users_usa.csv' INTO TABLE users
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'data/products.csv' INTO TABLE products
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

-- transactions.csv is semicolon-separated
LOAD DATA LOCAL INFILE 'data/transactions.csv' INTO TABLE transactions
FIELDS TERMINATED BY ';' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

-- 2. Fix data types ------------------------------------------------------
-- user_id on credit_cards duplicates transactions.user_id
ALTER TABLE credit_cards DROP COLUMN user_id;

-- expiring_date: text 'MM/DD/YY' -> DATE
ALTER TABLE credit_cards ADD COLUMN expiring_date_temp DATE;
UPDATE credit_cards SET expiring_date_temp = STR_TO_DATE(expiring_date, '%m/%d/%y');
ALTER TABLE credit_cards DROP COLUMN expiring_date;
ALTER TABLE credit_cards CHANGE expiring_date_temp expiring_date DATE NOT NULL;

-- birth_date: text 'Mon DD, YYYY' -> DATE
ALTER TABLE users ADD COLUMN birth_date_temp DATE;
UPDATE users SET birth_date_temp = STR_TO_DATE(birth_date, '%b %d, %Y');
ALTER TABLE users DROP COLUMN birth_date;
ALTER TABLE users CHANGE birth_date_temp birth_date DATE NOT NULL;

-- price: "$12.34" -> currency symbol + numeric price
ALTER TABLE products ADD COLUMN currency VARCHAR(1);
UPDATE products
SET currency = LEFT(price, 1),
    price    = CAST(SUBSTRING(price, 2) AS DECIMAL(10,2));
ALTER TABLE products MODIFY price DECIMAL(10,2) NOT NULL;

-- 3. Foreign keys (star schema) -------------------------------------------
ALTER TABLE transactions
    ADD CONSTRAINT fk_transactions_credit_cards FOREIGN KEY (card_id)     REFERENCES credit_cards (id),
    ADD CONSTRAINT fk_transactions_companies    FOREIGN KEY (business_id) REFERENCES companies (company_id),
    ADD CONSTRAINT fk_transactions_users        FOREIGN KEY (user_id)     REFERENCES users (id);

-- 4. Bridge table orders (transaction <-> product, N:M) ---------------------
-- transactions.product_ids holds several ids in one cell ("59, 71, 7"), which
-- violates first normal form. One row per (transaction, product) pair instead.
CREATE TABLE orders (
    transaction_id VARCHAR(100) NOT NULL,
    product_id     INT NOT NULL,
    PRIMARY KEY (transaction_id, product_id),
    CONSTRAINT fk_orders_transactions FOREIGN KEY (transaction_id) REFERENCES transactions (id),
    CONSTRAINT fk_orders_products     FOREIGN KEY (product_id)     REFERENCES products (id)
);

INSERT INTO orders (transaction_id, product_id)
SELECT t.id, p.id
FROM transactions t
JOIN products p ON FIND_IN_SET(p.id, REPLACE(t.product_ids, ' ', '')) > 0;

-- 5. credit_status: a card is 'blocked' when its last 3 transactions were all declined
CREATE TABLE credit_status (
    card_id VARCHAR(20) PRIMARY KEY,
    status  ENUM('active', 'blocked') NOT NULL,
    CONSTRAINT fk_credit_status_credit_cards FOREIGN KEY (card_id) REFERENCES credit_cards (id)
);

INSERT INTO credit_status (card_id, status)
SELECT card_id,
       CASE WHEN SUM(declined) < 3 THEN 'active' ELSE 'blocked' END AS status
FROM (
    SELECT card_id, declined,
           DENSE_RANK() OVER (PARTITION BY card_id ORDER BY timestamp DESC) AS recency
    FROM transactions
) AS ranked
WHERE recency <= 3
GROUP BY card_id;
