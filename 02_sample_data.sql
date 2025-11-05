-- =====================================================
-- INVENTORY AND ORDER MANAGEMENT SYSTEM - SAMPLE DATA
-- =====================================================
-- This script populates the database with realistic sample data for testing and demonstration

-- Disable safe update mode temporarily
SET SQL_SAFE_UPDATES = 0;

-- =====================================================
-- 1. INSERT CATEGORIES
-- =====================================================
INSERT INTO categories (category_name, description) VALUES
('Electronics', 'Electronic devices and accessories'),
('Clothing', 'Apparel and fashion items'),
('Books', 'Books and educational materials'),
('Home & Garden', 'Home improvement and garden supplies'),
('Sports & Outdoors', 'Sports equipment and outdoor gear'),
('Beauty & Health', 'Personal care and health products'),
('Toys & Games', 'Children toys and gaming products'),
('Automotive', 'Car parts and automotive accessories');

-- =====================================================
-- 2. INSERT SUPPLIERS
-- =====================================================
INSERT INTO suppliers (supplier_name, contact_person, email, phone, address, city, country) VALUES
('TechSupply Co.', 'John Smith', 'john@techsupply.com', '+1-555-0101', '123 Tech Street', 'San Francisco', 'USA'),
('Fashion Forward Ltd.', 'Sarah Johnson', 'sarah@fashionforward.com', '+1-555-0102', '456 Fashion Ave', 'New York', 'USA'),
('BookWorld Distribution', 'Mike Wilson', 'mike@bookworld.com', '+1-555-0103', '789 Reading Blvd', 'Chicago', 'USA'),
('HomeStyle Suppliers', 'Emily Davis', 'emily@homestyle.com', '+1-555-0104', '321 Home Way', 'Los Angeles', 'USA'),
('SportMax Wholesale', 'David Brown', 'david@sportmax.com', '+1-555-0105', '654 Sports Lane', 'Denver', 'USA'),
('Beauty Essentials', 'Lisa Garcia', 'lisa@beautyessentials.com', '+1-555-0106', '987 Beauty Blvd', 'Miami', 'USA'),
('Global Electronics', 'Robert Chen', 'robert@globalelectronics.com', '+1-555-0107', '147 Circuit Road', 'Seattle', 'USA'),
('Quality Automotive', 'Jennifer Lee', 'jennifer@qualityauto.com', '+1-555-0108', '258 Motor Street', 'Detroit', 'USA');

-- =====================================================
-- 3. INSERT PRODUCTS
-- =====================================================

-- Electronics Products
INSERT INTO products (product_name, description, category_id, supplier_id, sku, price, cost_price, current_stock, reorder_level, max_stock_level, weight, dimensions) VALUES
('iPhone 15 Pro', 'Latest Apple smartphone with advanced features', 1, 1, 'ELEC-IPH15P-001', 999.99, 750.00, 45, 10, 100, 0.18, '6.3x3.1x0.3 inches'),
('Samsung Galaxy S24', 'Premium Android smartphone', 1, 7, 'ELEC-SGS24-002', 849.99, 650.00, 32, 15, 80, 0.17, '6.2x2.9x0.3 inches'),
('MacBook Air M2', '13-inch laptop with M2 chip', 1, 1, 'ELEC-MBA13-003', 1199.99, 900.00, 12, 5, 50, 1.24, '12x8.5x0.4 inches'),
('iPad Pro 12.9', 'Professional tablet for creative work', 1, 1, 'ELEC-IPADP-004', 1099.99, 850.00, 18, 8, 40, 0.68, '11x8.5x0.25 inches'),
('Sony WH-1000XM5', 'Wireless noise-canceling headphones', 1, 7, 'ELEC-SWHNC-005', 399.99, 280.00, 67, 20, 150, 0.25, '10x7x1.2 inches'),
('Dell XPS 13', 'Ultrabook laptop for professionals', 1, 7, 'ELEC-DXPS13-006', 999.99, 750.00, 8, 5, 30, 1.20, '11.6x7.8x0.6 inches'),
('AirPods Pro', 'Wireless earbuds with noise cancellation', 1, 1, 'ELEC-AIRPRO-007', 249.99, 180.00, 89, 30, 200, 0.05, '2.4x2.1x0.9 inches'),
('Nintendo Switch', 'Hybrid gaming console', 1, 7, 'ELEC-NSWITCH-008', 299.99, 220.00, 23, 10, 60, 0.66, '9.4x4.0x0.6 inches');

-- Clothing Products
INSERT INTO products (product_name, description, category_id, supplier_id, sku, price, cost_price, current_stock, reorder_level, max_stock_level, weight, dimensions) VALUES
('Levi\'s 501 Jeans', 'Classic straight-leg denim jeans', 2, 2, 'CLTH-LEVI501-009', 89.99, 45.00, 156, 50, 300, 0.68, 'Size varies'),
('Nike Air Max Sneakers', 'Popular athletic footwear', 2, 5, 'CLTH-NIKAIR-010', 129.99, 75.00, 89, 25, 150, 0.45, 'Size varies'),
('Adidas Hoodie', 'Comfortable cotton blend hoodie', 2, 5, 'CLTH-ADHOOD-011', 69.99, 35.00, 120, 30, 200, 0.55, 'Size varies'),
('Ray-Ban Sunglasses', 'Classic aviator sunglasses', 2, 2, 'CLTH-RBSUN-012', 179.99, 90.00, 45, 15, 100, 0.03, '5.5x2.1x1.4 inches'),
('Under Armour T-Shirt', 'Performance athletic shirt', 2, 5, 'CLTH-UATEE-013', 29.99, 15.00, 234, 50, 400, 0.18, 'Size varies');

-- Books
INSERT INTO products (product_name, description, category_id, supplier_id, sku, price, cost_price, current_stock, reorder_level, max_stock_level, weight, dimensions) VALUES
('Python Programming Guide', 'Comprehensive Python programming book', 3, 3, 'BOOK-PYTHON-014', 49.99, 25.00, 78, 20, 150, 0.65, '9x7x1.2 inches'),
('Data Science Handbook', 'Essential guide to data science', 3, 3, 'BOOK-DSCI-015', 59.99, 30.00, 45, 15, 100, 0.75, '9x7x1.4 inches'),
('The Great Gatsby', 'Classic American literature', 3, 3, 'BOOK-GATSBY-016', 14.99, 7.50, 123, 25, 200, 0.25, '8x5x0.8 inches'),
('SQL Cookbook', 'Database programming reference', 3, 3, 'BOOK-SQL-017', 44.99, 22.50, 67, 20, 120, 0.58, '9x7x1.1 inches');

-- Home & Garden
INSERT INTO products (product_name, description, category_id, supplier_id, sku, price, cost_price, current_stock, reorder_level, max_stock_level, weight, dimensions) VALUES
('Dyson V15 Vacuum', 'Cordless stick vacuum cleaner', 4, 4, 'HOME-DYSONV15-018', 749.99, 500.00, 15, 5, 40, 2.95, '49x10x8 inches'),
('KitchenAid Mixer', 'Stand mixer for baking', 4, 4, 'HOME-KAMIX-019', 379.99, 250.00, 22, 8, 50, 11.00, '14x9x14 inches'),
('Ninja Blender', 'High-speed blending system', 4, 4, 'HOME-NINBLEND-020', 99.99, 60.00, 67, 20, 120, 4.20, '16x8x8 inches'),
('Garden Tool Set', 'Complete gardening tool collection', 4, 4, 'HOME-GARDSET-021', 89.99, 45.00, 34, 10, 80, 3.50, '24x12x6 inches');

-- Sports & Outdoors
INSERT INTO products (product_name, description, category_id, supplier_id, sku, price, cost_price, current_stock, reorder_level, max_stock_level, weight, dimensions) VALUES
('Trek Mountain Bike', 'All-terrain mountain bicycle', 5, 5, 'SPORT-TREKBIKE-022', 899.99, 600.00, 8, 3, 20, 13.60, '68x24x42 inches'),
('Yoga Mat Premium', 'Non-slip exercise mat', 5, 5, 'SPORT-YOGAMAT-023', 49.99, 25.00, 89, 25, 150, 1.20, '72x24x0.25 inches'),
('Camping Tent 4-Person', 'Waterproof family camping tent', 5, 5, 'SPORT-TENT4P-024', 199.99, 120.00, 16, 5, 40, 4.50, '20x12x8 inches'),
('Running Shoes', 'Professional athletic footwear', 5, 5, 'SPORT-RUNSHOE-025', 139.99, 80.00, 78, 20, 120, 0.45, 'Size varies');

-- Beauty & Health
INSERT INTO products (product_name, description, category_id, supplier_id, sku, price, cost_price, current_stock, reorder_level, max_stock_level, weight, dimensions) VALUES
('Vitamin D3 Supplements', 'Daily vitamin supplement', 6, 6, 'HEALTH-VITD3-026', 24.99, 12.00, 156, 40, 300, 0.12, '4x2x2 inches'),
('Skincare Set', 'Complete facial care routine', 6, 6, 'BEAUTY-SKINSET-027', 79.99, 40.00, 67, 20, 120, 0.35, '8x6x3 inches'),
('Electric Toothbrush', 'Rechargeable dental care', 6, 6, 'HEALTH-ETOOTHB-028', 89.99, 50.00, 45, 15, 80, 0.18, '10x1.5x1.5 inches');

-- Toys & Games
INSERT INTO products (product_name, description, category_id, supplier_id, sku, price, cost_price, current_stock, reorder_level, max_stock_level, weight, dimensions) VALUES
('LEGO Creator Set', 'Advanced building block set', 7, 7, 'TOY-LEGO-029', 129.99, 75.00, 45, 15, 100, 2.20, '15x12x8 inches'),
('Board Game Collection', 'Family strategy board games', 7, 7, 'TOY-BOARDG-030', 49.99, 25.00, 67, 20, 120, 1.80, '12x9x3 inches'),
('Remote Control Car', 'High-speed RC racing car', 7, 7, 'TOY-RCCAR-031', 89.99, 50.00, 23, 10, 60, 1.50, '18x10x8 inches');

-- Automotive
INSERT INTO products (product_name, description, category_id, supplier_id, sku, price, cost_price, current_stock, reorder_level, max_stock_level, weight, dimensions) VALUES
('Car Phone Mount', 'Universal smartphone car holder', 8, 8, 'AUTO-MOUNT-032', 19.99, 10.00, 89, 30, 200, 0.25, '6x4x3 inches'),
('Dash Cam HD', 'High definition dashboard camera', 8, 8, 'AUTO-DASHCAM-033', 149.99, 85.00, 34, 12, 80, 0.35, '4x2x2 inches'),
('Car Air Freshener', 'Long-lasting vehicle fragrance', 8, 8, 'AUTO-FRESH-034', 9.99, 4.00, 156, 50, 300, 0.08, '3x2x1 inches');

-- =====================================================
-- 4. INSERT CUSTOMERS
-- =====================================================
INSERT INTO customers (first_name, last_name, email, phone, date_of_birth, gender, address_line1, city, state, postal_code, country, preferred_contact, marketing_consent) VALUES
('John', 'Doe', 'john.doe@email.com', '+1-555-1001', '1985-03-15', 'Male', '123 Main Street', 'New York', 'NY', '10001', 'USA', 'Email', TRUE),
('Jane', 'Smith', 'jane.smith@email.com', '+1-555-1002', '1990-07-22', 'Female', '456 Oak Avenue', 'Los Angeles', 'CA', '90210', 'USA', 'Email', TRUE),
('Michael', 'Johnson', 'michael.j@email.com', '+1-555-1003', '1988-11-08', 'Male', '789 Pine Road', 'Chicago', 'IL', '60601', 'USA', 'Phone', FALSE),
('Sarah', 'Williams', 'sarah.w@email.com', '+1-555-1004', '1992-02-14', 'Female', '321 Elm Street', 'Houston', 'TX', '77001', 'USA', 'Email', TRUE),
('David', 'Brown', 'david.brown@email.com', '+1-555-1005', '1987-09-30', 'Male', '654 Maple Drive', 'Phoenix', 'AZ', '85001', 'USA', 'SMS', TRUE),
('Emily', 'Davis', 'emily.davis@email.com', '+1-555-1006', '1995-05-18', 'Female', '987 Cedar Lane', 'Philadelphia', 'PA', '19101', 'USA', 'Email', FALSE),
('Robert', 'Miller', 'robert.miller@email.com', '+1-555-1007', '1983-12-03', 'Male', '147 Birch Street', 'San Antonio', 'TX', '78201', 'USA', 'Phone', TRUE),
('Lisa', 'Wilson', 'lisa.wilson@email.com', '+1-555-1008', '1991-08-25', 'Female', '258 Walnut Avenue', 'San Diego', 'CA', '92101', 'USA', 'Email', TRUE),
('James', 'Garcia', 'james.garcia@email.com', '+1-555-1009', '1989-04-12', 'Male', '369 Cherry Road', 'Dallas', 'TX', '75201', 'USA', 'Email', FALSE),
('Amanda', 'Martinez', 'amanda.m@email.com', '+1-555-1010', '1993-10-07', 'Female', '741 Spruce Street', 'San Jose', 'CA', '95101', 'USA', 'SMS', TRUE),
('Christopher', 'Anderson', 'chris.anderson@email.com', '+1-555-1011', '1986-01-20', 'Male', '852 Ash Drive', 'Austin', 'TX', '73301', 'USA', 'Email', TRUE),
('Jennifer', 'Taylor', 'jennifer.t@email.com', '+1-555-1012', '1994-06-16', 'Female', '963 Poplar Lane', 'Jacksonville', 'FL', '32099', 'USA', 'Phone', FALSE),
('Matthew', 'Thomas', 'matthew.thomas@email.com', '+1-555-1013', '1990-03-28', 'Male', '159 Hickory Street', 'Fort Worth', 'TX', '76101', 'USA', 'Email', TRUE),
('Ashley', 'Jackson', 'ashley.jackson@email.com', '+1-555-1014', '1988-09-11', 'Female', '357 Sycamore Avenue', 'Columbus', 'OH', '43085', 'USA', 'Email', FALSE),
('Ryan', 'White', 'ryan.white@email.com', '+1-555-1015', '1992-12-05', 'Male', '486 Magnolia Road', 'Charlotte', 'NC', '28201', 'USA', 'SMS', TRUE);

-- =====================================================
-- 5. INSERT SAMPLE ORDERS
-- =====================================================
INSERT INTO orders (customer_id, order_number, order_status, payment_status, payment_method, subtotal, tax_amount, shipping_cost, total_amount, shipping_address_line1, shipping_city, shipping_state, shipping_postal_code, shipping_country) VALUES
(1, 'ORD-2024-001', 'Delivered', 'Paid', 'Credit Card', 1249.98, 100.00, 15.99, 1365.97, '123 Main Street', 'New York', 'NY', '10001', 'USA'),
(2, 'ORD-2024-002', 'Shipped', 'Paid', 'PayPal', 219.98, 17.60, 9.99, 247.57, '456 Oak Avenue', 'Los Angeles', 'CA', '90210', 'USA'),
(3, 'ORD-2024-003', 'Processing', 'Paid', 'Credit Card', 89.99, 7.20, 5.99, 103.18, '789 Pine Road', 'Chicago', 'IL', '60601', 'USA'),
(4, 'ORD-2024-004', 'Delivered', 'Paid', 'Debit Card', 759.99, 60.80, 12.99, 833.78, '321 Elm Street', 'Houston', 'TX', '77001', 'USA'),
(5, 'ORD-2024-005', 'Confirmed', 'Paid', 'Credit Card', 399.99, 32.00, 8.99, 440.98, '654 Maple Drive', 'Phoenix', 'AZ', '85001', 'USA'),
(6, 'ORD-2024-006', 'Delivered', 'Paid', 'PayPal', 129.98, 10.40, 7.99, 148.37, '987 Cedar Lane', 'Philadelphia', 'PA', '19101', 'USA'),
(1, 'ORD-2024-007', 'Delivered', 'Paid', 'Credit Card', 649.98, 52.00, 11.99, 713.97, '123 Main Street', 'New York', 'NY', '10001', 'USA'),
(7, 'ORD-2024-008', 'Shipped', 'Paid', 'Credit Card', 179.99, 14.40, 6.99, 201.38, '147 Birch Street', 'San Antonio', 'TX', '78201', 'USA'),
(8, 'ORD-2024-009', 'Processing', 'Paid', 'Bank Transfer', 299.99, 24.00, 8.99, 332.98, '258 Walnut Avenue', 'San Diego', 'CA', '92101', 'USA'),
(2, 'ORD-2024-010', 'Delivered', 'Paid', 'Credit Card', 159.97, 12.80, 7.99, 180.76, '456 Oak Avenue', 'Los Angeles', 'CA', '90210', 'USA');

-- =====================================================
-- 6. INSERT ORDER ITEMS
-- =====================================================
INSERT INTO order_items (order_id, product_id, quantity, unit_price, total_price) VALUES
-- Order 1: John Doe - Electronics
(1, 1, 1, 999.99, 999.99),  -- iPhone 15 Pro
(1, 7, 1, 249.99, 249.99),  -- AirPods Pro

-- Order 2: Jane Smith - Mixed items
(2, 10, 1, 129.99, 129.99), -- Nike Air Max Sneakers
(2, 13, 3, 29.99, 89.97),   -- Under Armour T-Shirts

-- Order 3: Michael Johnson - Clothing
(3, 9, 1, 89.99, 89.99),    -- Levi's 501 Jeans

-- Order 4: Sarah Williams - Home appliance
(4, 18, 1, 749.99, 749.99), -- Dyson V15 Vacuum
(4, 26, 2, 24.99, 49.98),   -- Vitamin D3 Supplements (2 bottles)

-- Order 5: David Brown - Electronics
(5, 5, 1, 399.99, 399.99),  -- Sony WH-1000XM5 headphones

-- Order 6: Emily Davis - Books and health
(6, 14, 1, 49.99, 49.99),   -- Python Programming Guide
(6, 26, 1, 24.99, 24.99),   -- Vitamin D3 Supplements
(6, 17, 1, 44.99, 44.99),   -- SQL Cookbook

-- Order 7: John Doe (repeat customer) - More electronics
(7, 3, 1, 1199.99, 1199.99), -- MacBook Air M2
(7, 5, 1, 399.99, 399.99),   -- Sony WH-1000XM5

-- Order 8: Robert Miller - Accessories
(8, 12, 1, 179.99, 179.99),  -- Ray-Ban Sunglasses

-- Order 9: Lisa Wilson - Gaming
(9, 8, 1, 299.99, 299.99),   -- Nintendo Switch

-- Order 10: Jane Smith (repeat customer) - Sports
(10, 23, 1, 49.99, 49.99),   -- Yoga Mat Premium
(10, 25, 1, 139.99, 139.99), -- Running Shoes
(10, 26, 1, 24.99, 24.99);   -- Vitamin D3 Supplements

-- =====================================================
-- 7. INSERT ADDITIONAL INVENTORY CHANGES
-- =====================================================
-- Simulate stock replenishments and adjustments
INSERT INTO inventory_changes (product_id, change_type, quantity_change, previous_stock, new_stock, reference_type, reason, performed_by) VALUES
(1, 'Stock_In', 50, 0, 50, 'Purchase', 'Initial stock purchase from supplier', 'Admin'),
(2, 'Stock_In', 50, 0, 50, 'Purchase', 'Initial stock purchase from supplier', 'Admin'),
(3, 'Stock_In', 20, 0, 20, 'Purchase', 'Initial stock purchase from supplier', 'Admin'),
(5, 'Stock_In', 100, 0, 100, 'Purchase', 'Initial stock purchase from supplier', 'Admin'),
(9, 'Stock_In', 200, 0, 200, 'Purchase', 'Initial stock purchase from supplier', 'Admin'),
(10, 'Stock_In', 120, 0, 120, 'Purchase', 'Initial stock purchase from supplier', 'Admin'),
(26, 'Stock_In', 200, 0, 200, 'Purchase', 'Initial stock purchase from supplier', 'Admin'),

-- Some adjustments and damages
(1, 'Adjustment', -3, 48, 45, 'Manual', 'Damaged units found during quality check', 'Warehouse Manager'),
(2, 'Damage', -1, 33, 32, 'Manual', 'Customer return - damaged item', 'Customer Service'),
(10, 'Return', 1, 88, 89, 'Return', 'Customer return - wrong size', 'Customer Service');

-- =====================================================
-- DATA INSERTION COMPLETE
-- =====================================================

-- Update order dates to be more realistic (recent orders)
UPDATE orders SET order_date = DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 30) DAY) WHERE order_id <= 10;
UPDATE orders SET shipped_date = DATE_ADD(order_date, INTERVAL 2 DAY) WHERE order_status IN ('Shipped', 'Delivered');
UPDATE orders SET delivered_date = DATE_ADD(shipped_date, INTERVAL 3 DAY) WHERE order_status = 'Delivered';

-- Update customer statistics based on their orders
UPDATE customers c SET 
    total_orders = (SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.customer_id),
    total_spent = (SELECT COALESCE(SUM(total_amount), 0) FROM orders o WHERE o.customer_id = c.customer_id),
    last_order_date = (SELECT MAX(order_date) FROM orders o WHERE o.customer_id = c.customer_id);

UPDATE customers SET average_order_value = total_spent / total_orders WHERE total_orders > 0;

-- Show summary of inserted data
SELECT 'Categories' AS table_name, COUNT(*) AS record_count FROM categories
UNION ALL
SELECT 'Suppliers', COUNT(*) FROM suppliers
UNION ALL
SELECT 'Products', COUNT(*) FROM products
UNION ALL
SELECT 'Customers', COUNT(*) FROM customers
UNION ALL
SELECT 'Orders', COUNT(*) FROM orders
UNION ALL
SELECT 'Order Items', COUNT(*) FROM order_items
UNION ALL
SELECT 'Inventory Changes', COUNT(*) FROM inventory_changes;

-- Re-enable safe update mode
SET SQL_SAFE_UPDATES = 1;