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

SELECT * FROM customers


-- Delete
-- Delete a transaction (careful in real DE pipelines!)
DELETE FROM transactions
WHERE txn_id in 3;


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

SELECT AVG(total_spent) AS avg_customer_spent
FROM (
    SELECT customer_id, SUM(quantity) AS total_spent
    FROM transactions
    GROUP BY customer_id
) sub;


WITH customer_totals AS (
    SELECT customer_id, SUM(quantity) AS total_spent
    FROM transactions
    GROUP BY customer_id
)
SELECT AVG(total_spent) AS avg_customer_spent
FROM customer_totals;



-- see table used in with

SELECT DATE_TRUNC('month', txn_date) AS month,
        SUM(quantity * p.price) AS revenue
FROM transactions t
JOIN products p ON t.product_id = p.product_id
GROUP BY 1;

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

-- Remove leading/trailing spaces from names
SELECT name, TRIM(name) AS clean_name
FROM customers;

-- Standardize emails to lowercase
SELECT email, LOWER(TRIM(email)) AS clean_email
FROM customers;

-- Replace NULL phones with default value
SELECT customer_id, COALESCE(phone, 'UNKNOWN') AS phone_number
FROM customers;

-- Standardize country codes
SELECT customer_id, UPPER(REPLACE(country_code, 'COL', 'CO')) AS clean_country_code
FROM addresses;

-- Extract domain from emails
SELECT email, SPLIT_PART(email, '@', 2) AS email_domain
FROM customers;

-- Normalize gender (if such column existed, example only)
-- SELECT gender,
--        CASE
--            WHEN gender IN ('M','Male','H') THEN 'Male'
--            WHEN gender IN ('F','Female','Mujer') THEN 'Female'
--            ELSE 'Other'
--        END AS clean_gender
-- FROM demographics;


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

-- Column must always have a value
CREATE TABLE products_n (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) CHECK (price > 0), -- must be positive
    category VARCHAR(50) DEFAULT 'General'
);

-- Primary Key ensures uniqueness
CREATE TABLE customers_n (
    customer_id SERIAL PRIMARY KEY,
    email VARCHAR(100) UNIQUE,
    signup_date DATE
);

-- Foreign Key ensures valid references
CREATE TABLE transactions_n (
    txn_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    product_id INT REFERENCES products(product_id),
    txn_date DATE
);

-- Index on customer_id for faster joins
CREATE INDEX idx_transactions_customer
ON transactions_n(customer_id);

-- Composite index for queries filtering by customer & date
CREATE INDEX idx_transactions_customer_date
ON transactions_n(customer_id, txn_date);

