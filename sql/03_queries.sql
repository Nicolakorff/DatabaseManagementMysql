-- 03_queries.sql
-- Analytical queries on the `sales` database.
USE sales;

-- Q1. Users with more than 30 transactions (subquery across two tables)
SELECT u.id AS user_id, CONCAT(u.name, ' ', u.surname) AS user_name
FROM users u
WHERE u.id IN (SELECT user_id
               FROM transactions
               GROUP BY user_id
               HAVING COUNT(id) > 30);

-- Q2a. Average amount per card IBAN for company "Donec Ltd", all transactions
SELECT cc.iban, ROUND(AVG(t.amount), 2) AS avg_amount
FROM transactions t
JOIN credit_cards cc ON t.card_id = cc.id
JOIN companies c     ON t.business_id = c.company_id
WHERE c.company_name = 'Donec Ltd'
GROUP BY cc.iban;

-- Q2b. Same, excluding declined payments
SELECT cc.iban, ROUND(AVG(t.amount), 2) AS avg_amount
FROM transactions t
JOIN credit_cards cc ON t.card_id = cc.id
JOIN companies c     ON t.business_id = c.company_id
WHERE c.company_name = 'Donec Ltd' AND t.declined = 0
GROUP BY cc.iban;

-- Q3. Number of active cards
SELECT COUNT(*) AS active_cards
FROM credit_status
WHERE status = 'active';

-- Q4. Times each product was sold (non-declined transactions), via the bridge table
SELECT o.product_id, p.product_name, COUNT(*) AS units_sold
FROM orders o
JOIN transactions t ON t.id = o.transaction_id
JOIN products p     ON p.id = o.product_id
WHERE t.declined = 0
GROUP BY o.product_id, p.product_name
ORDER BY units_sold DESC;
