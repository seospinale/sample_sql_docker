-- Customers with some NULL phones
INSERT INTO customers (name, email, phone, signup_date) VALUES
('Alice', 'alice@mail.com', '3001234567', '2023-01-15'),
('Bob', 'bob@mail.com', NULL, '2023-02-20'),
('Charlie', 'charlie@mail.com', '3109876543', '2023-03-01'),
('Diana', 'diana@mail.com', NULL, '2023-03-15');

-- Products
INSERT INTO products (name, category, price) VALUES
('Laptop', 'Electronics', 1000.00),
('Headphones', 'Electronics', 150.00),
('Coffee', 'Grocery', 5.00);

-- Transactions
INSERT INTO transactions (customer_id, product_id, txn_date, quantity) VALUES
(1, 1, '2023-05-01', 1),
(1, 3, '2023-05-02', 5),
(2, 2, '2023-06-10', 2),
(3, 1, '2023-07-12', 1),
(4, 3, '2023-08-05', 10);

-- Addresses with messy country codes
INSERT INTO addresses (customer_id, country_code) VALUES
(1, 'COL'),
(2, 'USA'),
(3, 'COL'),
(4, 'col'); -- messy lowercase