-- Table 1: regions (lookup table)
CREATE TABLE regions (
    region_id      SERIAL PRIMARY KEY,
    region_name    VARCHAR(20) UNIQUE NOT NULL,
    region_manager VARCHAR(100) NOT NULL
);

-- Table 2: customers
CREATE TABLE customers (
    customer_id  SERIAL PRIMARY KEY,
    first_name   VARCHAR(50) NOT NULL,
    last_name    VARCHAR(50) NOT NULL,
    email        VARCHAR(100) UNIQUE NOT NULL,
    region       VARCHAR(20) NOT NULL REFERENCES regions(region_name),
    join_date    DATE NOT NULL DEFAULT CURRENT_DATE
);

-- Table 3: products
CREATE TABLE products (
    product_id     SERIAL PRIMARY KEY,
    product_name   VARCHAR(100) NOT NULL,
    category       VARCHAR(50) NOT NULL,
    unit_price     DECIMAL(10,2) NOT NULL CHECK (unit_price > 0),
    stock_quantity INTEGER DEFAULT 0
);

-- Table 4: transactions (fact table)
CREATE TABLE transactions (
    transaction_id   SERIAL PRIMARY KEY,
    customer_id      INTEGER NOT NULL REFERENCES customers(customer_id),
    product_id       INTEGER NOT NULL REFERENCES products(product_id),
    quantity         INTEGER NOT NULL CHECK (quantity > 0),
    total_amount     DECIMAL(12,2) NOT NULL,
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE
);

-- Performance indexes
CREATE INDEX idx_tx_customer ON transactions(customer_id);
CREATE INDEX idx_tx_product  ON transactions(product_id);
CREATE INDEX idx_tx_date     ON transactions(transaction_date);
CREATE INDEX idx_cust_region ON customers(region);
