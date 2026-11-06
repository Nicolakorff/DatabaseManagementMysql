-- 01_schema.sql
-- Creates the `sales` database and its base tables.
-- Source data is a synthetic dataset (no real customers or cards).

CREATE DATABASE IF NOT EXISTS sales;
USE sales;

CREATE TABLE IF NOT EXISTS credit_cards (
    id            VARCHAR(20) PRIMARY KEY,
    user_id       INT NOT NULL,              -- dropped in 02_load_clean.sql (redundant with transactions.user_id)
    iban          VARCHAR(50) UNIQUE NOT NULL,
    pan           VARCHAR(50) UNIQUE NOT NULL,
    pin           VARCHAR(50) NOT NULL,
    cvv           INT NOT NULL,
    track1        VARCHAR(50),
    track2        VARCHAR(50),
    expiring_date VARCHAR(10) NOT NULL       -- text in the CSV, converted to DATE in 02_load_clean.sql
);

CREATE TABLE IF NOT EXISTS companies (
    company_id   VARCHAR(20) PRIMARY KEY,
    company_name VARCHAR(50) NOT NULL,
    phone        VARCHAR(20) UNIQUE,
    email        VARCHAR(50),
    country      VARCHAR(20),
    website      VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS users (
    id          INT PRIMARY KEY,
    name        VARCHAR(50),
    surname     VARCHAR(50),
    phone       VARCHAR(20),
    email       VARCHAR(255),
    birth_date  VARCHAR(100),                -- text in the CSV, converted to DATE in 02_load_clean.sql
    country     VARCHAR(100),
    city        VARCHAR(100),
    postal_code VARCHAR(50),
    address     VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS products (
    id           INT PRIMARY KEY,
    product_name VARCHAR(50) NOT NULL,
    price        VARCHAR(10) NOT NULL,       -- "$12.34" in the CSV, split into currency + price in 02_load_clean.sql
    color        VARCHAR(20),
    weight       FLOAT,
    warehouse_id VARCHAR(10)
);

CREATE TABLE IF NOT EXISTS transactions (
    id          VARCHAR(100) PRIMARY KEY,
    card_id     VARCHAR(20) NOT NULL,
    business_id VARCHAR(20) NOT NULL,
    timestamp   TIMESTAMP,
    amount      DECIMAL(10,2) NOT NULL,
    declined    BOOLEAN,
    product_ids VARCHAR(50) NOT NULL,        -- multivalued ("59, 71, 7"); normalized into `orders`
    user_id     INT NOT NULL,
    lat         FLOAT,
    longitude   FLOAT
);
