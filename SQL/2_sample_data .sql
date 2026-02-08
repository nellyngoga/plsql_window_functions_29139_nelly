
-- Regions (4 records)
INSERT INTO regions (region_name, region_manager) VALUES
('North', 'Alice Mukamana'),
('South', 'Jean Habimana'),
('East',  'Grace Uwimana'),
('West',  'Patrick Niyonzima');

-- Customers (12 records, 3 per region, including 2 with no transactions)
INSERT INTO customers (first_name, last_name, email, region, join_date) VALUES
('Marie',   'Uwase',        'marie.uwase@email.com',         'North', '2025-03-15'),
('Jean',    'Mugabo',       'jean.mugabo@email.com',          'North', '2025-04-20'),
('Claude',  'Iriza',        'claude.iriza@email.com',         'North', '2025-06-10'),
('Diane',   'Ingabire',     'diane.ingabire@email.com',       'South', '2025-03-01'),
('Eric',    'Nshuti',       'eric.nshuti@email.com',           'South', '2025-05-15'),
('Flora',   'Mutesi',       'flora.mutesi@email.com',          'South', '2025-07-22'),
('Grace',   'Tumukunde',    'grace.tumukunde@email.com',       'East',  '2025-02-28'),
('Henri',   'Bizimana',     'henri.bizimana@email.com',        'East',  '2025-05-12'),
('Irene',   'Umutoni',      'irene.umutoni@email.com',         'East',  '2025-08-05'),
('Jules',   'Habiyaremye',  'jules.habiyaremye@email.com',     'West',  '2025-04-28'),
('Kevin',   'Ndayisaba',    'kevin.ndayisaba@email.com',       'West',  '2025-09-01'),  -- No transactions
('Liliane', 'Mukeshimana',  'liliane.mukeshimana@email.com',   'West',  '2025-10-15');  -- No transactions

-- Products (8 records, including 2 with no sales)
INSERT INTO products (product_name, category, unit_price, stock_quantity) VALUES
('Organic Honey 500g',  'Honey',       8500.00,  150),
('Green Tea Pack',      'Beverages',   3200.00,  300),
('Dried Mango 250g',    'Snacks',      4500.00,  200),
('Moringa Powder 100g', 'Supplements', 6000.00,  100),
('Avocado Oil 250ml',   'Oils',        12000.00,  80),
('Raw Cashews 500g',    'Nuts',        9500.00,  120),
('Baobab Powder 200g',  'Supplements', 7500.00,    0),  -- No sales yet
('Shea Butter 100g',    'Skincare',    5500.00,    0);  -- No sales yet

-- Transactions (26 records: Nov 2025 - Jan 2026)
INSERT INTO transactions (customer_id, product_id, quantity, total_amount, transaction_date) VALUES
-- November 2025 (9 transactions)
(1,  1, 2, 17000.00,  '2025-11-02'),
(2,  2, 5, 16000.00,  '2025-11-05'),
(7,  1, 4, 34000.00,  '2025-11-08'),
(4,  6, 2, 19000.00,  '2025-11-11'),
(1,  3, 3, 13500.00,  '2025-11-14'),
(5,  2, 10, 32000.00, '2025-11-17'),
(3,  5, 1, 12000.00,  '2025-11-20'),
(6,  4, 2, 12000.00,  '2025-11-23'),
(10, 1, 5, 42500.00,  '2025-11-27'),

-- December 2025 (9 transactions)
(2,  4, 1, 6000.00,   '2025-12-01'),
(4,  3, 4, 18000.00,  '2025-12-04'),
(7,  6, 3, 28500.00,  '2025-12-07'),
(3,  1, 3, 25500.00,  '2025-12-10'),
(5,  1, 1, 8500.00,   '2025-12-13'),
(8,  3, 2, 9000.00,   '2025-12-16'),
(9,  5, 2, 24000.00,  '2025-12-19'),
(6,  5, 1, 12000.00,  '2025-12-22'),
(10, 6, 2, 19000.00,  '2025-12-28'),

-- January 2026 (8 transactions)
(8,  2, 6, 19200.00,  '2026-01-03'),
(9,  4, 3, 18000.00,  '2026-01-07'),
(1,  2, 4, 12800.00,  '2026-01-10'),
(2,  3, 2, 9000.00,   '2026-01-14'),
(4,  1, 3, 25500.00,  '2026-01-18'),
(7,  2, 8, 25600.00,  '2026-01-22'),
(5,  6, 1, 9500.00,   '2026-01-26'),
(3,  4, 2, 12000.00,  '2026-01-30');
