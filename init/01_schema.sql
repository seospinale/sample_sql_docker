-- Customers table with phone
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),       -- new column
    signup_date DATE
);

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10,2)
);

CREATE TABLE transactions (
    txn_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    product_id INT REFERENCES products(product_id),
    txn_date DATE,
    quantity INT,
    updated_at TIMESTAMP DEFAULT now()
);

-- For Slowly Changing Dimensions (Type 2)
CREATE TABLE dim_customers (
    customer_id INT,
    name VARCHAR(100),
    email VARCHAR(100),
    valid_from DATE,
    valid_to DATE,
    is_current BOOLEAN,
    PRIMARY KEY(customer_id, valid_from)
);

-- Addresses table for cleaning examples
CREATE TABLE addresses (
    address_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    country_code VARCHAR(10)
);