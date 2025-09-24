# 🐳 SQL Playground for Data Engineering

This repository contains a **Dockerized PostgreSQL environment** with preloaded schemas and datasets designed for learning **SQL with a Data Engineering focus**.  
You’ll practice everything from **basic queries** to **advanced concepts** like **window functions, CTEs, MERGE/UPSERTs, Slowly Changing Dimensions (SCDs), data cleaning, deduplication, and performance patterns**.

---

## 🚀 Getting Started

### 1. Clone the repository

```bash
git clone <your-repo-url>
cd sql-playground
```

### 2. Start the environment

```bash
docker-compose up -d
```

This will:

- Spin up a PostgreSQL 15 container.
- Expose it on `localhost:5433`.
- Load initial schema + seed data into a database called `playground`.

### 3. Connect to the database

**Connection details:**

- **Host:** `localhost`
- **Port:** `5433`
- **Database:** `playground`
- **User:** `sqluser`
- **Password:** `sqlpass`

---

## 💻 How to Connect

### Option A: Using `psql`

```bash
psql -h localhost -p 5433 -U sqluser -d playground
```

### Option B: Using a GUI

- [DBeaver](https://dbeaver.io/download/)
- [pgAdmin](https://www.pgadmin.org/download/)
- JetBrains DataGrip

Fill in the credentials above to connect.

### Option C: From Python

```python
import psycopg2

conn = psycopg2.connect(
    host="localhost",
    port=5433,
    dbname="playground",
    user="sqluser",
    password="sqlpass"
)
cur = conn.cursor()
cur.execute("SELECT COUNT(*) FROM customers;")
print(cur.fetchone())
```

---

## 📂 Project Structure

```
sql-playground/
├── docker-compose.yml        # Container definition
├── init/
│   ├── 01_schema.sql         # Database schema (customers, products, transactions, etc.)
│   ├── 02_data.sql           # Seed data with some dirty values
│   ├── 03_exercises.sql      # Core exercises (joins, aggregations, window functions)
│   ├── 04_more_examples.sql  # Extra examples (dedup, unions, advanced joins)
│   ├── 05_data_cleaning.sql  # Data cleaning transformations
└── README.md                 # This guide
```

---

## 📘 Example Queries

### 1. Aggregations

```sql
SELECT c.name, SUM(t.quantity * p.price) AS total_spent
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
JOIN products p ON t.product_id = p.product_id
GROUP BY c.name
ORDER BY total_spent DESC;
```

### 2. Window Functions

```sql
SELECT customer_id, txn_date,
       ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY txn_date) AS purchase_rank
FROM transactions;
```

### 3. Data Cleaning

```sql
-- Standardize emails
SELECT LOWER(TRIM(email)) AS clean_email
FROM customers;

-- Replace NULL phones
SELECT COALESCE(phone, 'UNKNOWN') AS phone_number
FROM customers;

-- Fix country codes
SELECT UPPER(REPLACE(country_code, 'COL', 'CO')) AS clean_country_code
FROM addresses;
```

---

## 🛠️ Resetting the Environment

If you want to **rebuild from scratch** (drop old data and reload everything):

```bash
docker-compose down -v
docker-compose up --build -d
```

---

## 🏗️ Learning Path

1. **Basic SQL** → `SELECT`, `WHERE`, `ORDER BY`, `GROUP BY`.
2. **Joins** → `INNER`, `LEFT`, `RIGHT`, `FULL OUTER`, `CROSS`, `ANTI-JOIN`.
3. **CTEs** → Simplify queries, step-by-step transformations.
4. **Window Functions** → `ROW_NUMBER`, `RANK`, `LAG`, `LEAD`, running totals.
5. **Data Cleaning** → `TRIM`, `LOWER`, `COALESCE`, `CASE`, `REPLACE`.
6. **Deduplication** → `ROW_NUMBER()` + filtering.
7. **Advanced DE Patterns** → Incremental loads, `MERGE`, Slowly Changing Dimensions (SCD Type 1 & 2).

---
