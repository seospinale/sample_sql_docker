-- 🔑 Connection Details
-- 	•	Host: localhost
-- 	•	Port: 5433
-- 	•	Database: playground
-- 	•	User: sqluser
-- 	•	Password: sqlpass


-- group by
-- Total spend per customer
SELECT c.customer_id, c.name,
       SUM(t.quantity * p.price) AS total_spent
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
JOIN products p ON t.product_id = p.product_id
GROUP BY c.customer_id, c.name
ORDER BY total_spent DESC;


-- Insert
-- Insert a new customer
INSERT INTO customers (name, email, signup_date)
VALUES ('Diana', 'diana@mail.com', CURRENT_DATE);






-- Delete

-- Delete a transaction (careful in real DE pipelines!)
DELETE FROM transactions
WHERE txn_id = 3;


-- UNION ALL
-- Combine customers and products names (for fun)
SELECT name FROM customers
UNION ALL
SELECT name FROM products;


-- Deduplication

-- Deduplicate transactions by keeping latest per txn_id
SELECT DISTINCT ON (txn_id) *
FROM transactions
ORDER BY txn_id, updated_at DESC;


-- Joins
 
-- Get customer purchases with product info [INNER]
SELECT c.name AS customer, p.name AS product, t.quantity, t.txn_date
FROM transactions t
INNER JOIN customers c ON t.customer_id = c.customer_id
INNER JOIN products p ON t.product_id = p.product_id;


-- Get customer purchases with product info [LEFT]
SELECT c.name AS customer, p.name AS product, t.quantity, t.txn_date
FROM transactions t
INNER JOIN customers c ON t.customer_id = c.customer_id
INNER JOIN products p ON t.product_id = p.product_id;


-- Show all transactions, with customer info (some customers may be missing) [RIGHT]
SELECT t.txn_id, t.txn_date, c.name
FROM customers c
RIGHT JOIN transactions t ON c.customer_id = t.customer_id;


-- Show all customers and transactions, even if no match [OUTER]
SELECT c.name, t.txn_id, t.txn_date
FROM customers c
FULL OUTER JOIN transactions t ON c.customer_id = t.customer_id;

-- ANTI JOIN
SELECT c.name
FROM customers c
LEFT JOIN transactions t ON c.customer_id = t.customer_id
WHERE t.txn_id IS NULL;


-- All possible pairs of customers and products (Cartesian product) [CROSS]
SELECT c.name AS customer, p.name AS product
FROM customers c
CROSS JOIN products p;


-- Rank transactions by amount spent [ORDER BY]
SELECT t.txn_id, c.name, (t.quantity * p.price) AS amount
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
JOIN products p ON t.product_id = p.product_id
ORDER BY amount DESC;


-- Window functions

-- Find first purchase per customer
SELECT customer_id, txn_date,
       ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY txn_date) AS purchase_rank
FROM transactions;


-- Keep only the latest transaction per txn_id
WITH ranked AS (
    SELECT
        txn_id,
        customer_id,
        product_id,
        txn_date,
        quantity,
        updated_at,
        ROW_NUMBER() OVER (
            PARTITION BY txn_id
            ORDER BY updated_at DESC
        ) AS rn
    FROM transactions
)
SELECT *
FROM ranked
WHERE rn = 1;


-- dedup by rank If you want to allow ties (e.g., two identical updated_at timestamps):

WITH ranked AS (
    SELECT
        txn_id,
        customer_id,
        product_id,
        txn_date,
        quantity,
        updated_at,
        RANK() OVER (
            PARTITION BY txn_id
            ORDER BY updated_at DESC
        ) AS rk
    FROM transactions
)
SELECT *
FROM ranked
WHERE rk = 1;


-- Dedup by bussiness rules For example, keep the first transaction per customer:

WITH ranked AS (
    SELECT
        customer_id,
        txn_id,
        txn_date,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY txn_date ASC
        ) AS rn
    FROM transactions
)
SELECT *
FROM ranked
WHERE rn = 1;


-- CTEs

-- Monthly revenue and growth
WITH monthly_revenue AS (
    SELECT DATE_TRUNC('month', txn_date) AS month,
           SUM(quantity * p.price) AS revenue
    FROM transactions t
    JOIN products p ON t.product_id = p.product_id
    GROUP BY 1
)
SELECT month, revenue,
       revenue - LAG(revenue) OVER(ORDER BY month) AS growth
FROM monthly_revenue;


-- Data cleaning

-- Standardize emails
SELECT LOWER(TRIM(email)) AS clean_email FROM customers;


-- Merge

-- Upsert transaction (simulate incremental load)
INSERT INTO transactions (txn_id, customer_id, product_id, txn_date, quantity, updated_at)
VALUES (1, 1, 1, '2023-05-01', 2, now())
ON CONFLICT (txn_id) DO UPDATE
SET quantity = EXCLUDED.quantity,
    updated_at = now();


-- SCD Type 2

-- Update dimension when customer email changes
INSERT INTO dim_customers (customer_id, name, email, valid_from, valid_to, is_current)
SELECT 1, 'Alice', 'alice_new@mail.com', CURRENT_DATE, '9999-12-31', TRUE
ON CONFLICT (customer_id, valid_from) DO NOTHING;

-- Close old record
UPDATE dim_customers
SET valid_to = CURRENT_DATE - 1, is_current = FALSE
WHERE customer_id = 1 AND is_current = TRUE AND email <> 'alice_new@mail.com';