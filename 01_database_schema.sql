-- =====================================================
-- INVENTORY AND ORDER MANAGEMENT SYSTEM - DATABASE SCHEMA
-- =====================================================
-- This schema supports a comprehensive e-commerce inventory and order management system
-- Features: Product management, Customer data, Order processing, Inventory tracking, Business analytics

-- Drop existing tables if they exist (for clean setup)
DROP TABLE IF EXISTS inventory_changes;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS suppliers;
DROP TABLE IF EXISTS categories;

-- =====================================================
-- 1. CATEGORIES TABLE
-- =====================================================
CREATE TABLE categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 2. SUPPLIERS TABLE
-- =====================================================
CREATE TABLE suppliers (
    supplier_id INT PRIMARY KEY AUTO_INCREMENT,
    supplier_name VARCHAR(200) NOT NULL,
    contact_person VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(50),
    country VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 3. PRODUCTS TABLE
-- =====================================================
CREATE TABLE products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    product_name VARCHAR(200) NOT NULL,
    description TEXT,
    category_id INT,
    supplier_id INT,
    sku VARCHAR(50) UNIQUE NOT NULL,
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    cost_price DECIMAL(10,2) CHECK (cost_price >= 0),
    current_stock INT NOT NULL DEFAULT 0 CHECK (current_stock >= 0),
    reorder_level INT DEFAULT 10 CHECK (reorder_level >= 0),
    max_stock_level INT DEFAULT 1000,
    is_active BOOLEAN DEFAULT TRUE,
    weight DECIMAL(8,2),
    dimensions VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Table-level constraints
    CONSTRAINT chk_max_stock_level CHECK (max_stock_level >= reorder_level),
    
    FOREIGN KEY (category_id) REFERENCES categories(category_id),
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id),
    INDEX idx_product_sku (sku),
    INDEX idx_product_category (category_id),
    INDEX idx_product_stock (current_stock),
    INDEX idx_product_active (is_active)
);

-- =====================================================
-- 4. CUSTOMERS TABLE
-- =====================================================
CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    date_of_birth DATE,
    gender ENUM('Male', 'Female', 'Other'),
    
    -- Address Information
    address_line1 VARCHAR(200),
    address_line2 VARCHAR(200),
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(50) DEFAULT 'USA',
    
    -- Customer Metrics
    total_orders INT DEFAULT 0,
    total_spent DECIMAL(12,2) DEFAULT 0.00,
    average_order_value DECIMAL(10,2) DEFAULT 0.00,
    last_order_date DATE,
    customer_since DATE DEFAULT (CURRENT_DATE),
    
    -- Status and Preferences
    is_active BOOLEAN DEFAULT TRUE,
    preferred_contact ENUM('Email', 'Phone', 'SMS') DEFAULT 'Email',
    marketing_consent BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_customer_email (email),
    INDEX idx_customer_name (last_name, first_name),
    INDEX idx_customer_city (city),
    INDEX idx_customer_active (is_active)
);

-- =====================================================
-- 5. ORDERS TABLE
-- =====================================================
CREATE TABLE orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Order Status and Processing
    order_status ENUM('Pending', 'Confirmed', 'Processing', 'Shipped', 'Delivered', 'Cancelled', 'Returned') DEFAULT 'Pending',
    payment_status ENUM('Pending', 'Paid', 'Failed', 'Refunded', 'Partial') DEFAULT 'Pending',
    payment_method ENUM('Credit Card', 'Debit Card', 'PayPal', 'Bank Transfer', 'Cash', 'Other'),
    
    -- Financial Information
    subtotal DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    tax_amount DECIMAL(10,2) DEFAULT 0.00,
    shipping_cost DECIMAL(10,2) DEFAULT 0.00,
    discount_amount DECIMAL(10,2) DEFAULT 0.00,
    total_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    
    -- Shipping Information
    shipping_address_line1 VARCHAR(200),
    shipping_address_line2 VARCHAR(200),
    shipping_city VARCHAR(50),
    shipping_state VARCHAR(50),
    shipping_postal_code VARCHAR(20),
    shipping_country VARCHAR(50),
    
    -- Tracking and Notes
    tracking_number VARCHAR(100),
    shipped_date TIMESTAMP NULL,
    delivered_date TIMESTAMP NULL,
    notes TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    INDEX idx_order_customer (customer_id),
    INDEX idx_order_date (order_date),
    INDEX idx_order_status (order_status),
    INDEX idx_order_number (order_number)
);

-- =====================================================
-- 6. ORDER_ITEMS TABLE
-- =====================================================
CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
    total_price DECIMAL(12,2) NOT NULL CHECK (total_price >= 0),
    discount_amount DECIMAL(10,2) DEFAULT 0.00,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    INDEX idx_order_items_order (order_id),
    INDEX idx_order_items_product (product_id)
);

-- =====================================================
-- 7. INVENTORY_CHANGES TABLE
-- =====================================================
CREATE TABLE inventory_changes (
    change_id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT NOT NULL,
    change_type ENUM('Stock_In', 'Stock_Out', 'Adjustment', 'Return', 'Damage', 'Transfer') NOT NULL,
    quantity_change INT NOT NULL, -- Positive for increases, negative for decreases
    previous_stock INT NOT NULL,
    new_stock INT NOT NULL,
    
    -- Reference Information
    reference_type ENUM('Order', 'Purchase', 'Manual', 'System', 'Return', 'Damage') NOT NULL,
    reference_id INT, -- Could reference order_id, purchase_id, etc.
    
    -- Additional Information
    unit_cost DECIMAL(10,2),
    total_cost DECIMAL(12,2),
    reason TEXT,
    performed_by VARCHAR(100) DEFAULT 'System',
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    INDEX idx_inventory_product (product_id),
    INDEX idx_inventory_date (created_at),
    INDEX idx_inventory_type (change_type)
);

-- =====================================================
-- INDEXES FOR PERFORMANCE OPTIMIZATION
-- =====================================================

-- Additional composite indexes for common queries
CREATE INDEX idx_products_category_active ON products(category_id, is_active);
CREATE INDEX idx_products_stock_reorder ON products(current_stock, reorder_level);
CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date);
CREATE INDEX idx_orders_status_date ON orders(order_status, order_date);
CREATE INDEX idx_inventory_product_date ON inventory_changes(product_id, created_at);

-- =====================================================
-- TRIGGERS FOR AUTOMATED OPERATIONS
-- =====================================================

-- Trigger to automatically update product stock when order items are inserted
DELIMITER //
CREATE TRIGGER update_stock_on_order 
AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
    -- Update product stock
    UPDATE products 
    SET current_stock = current_stock - NEW.quantity,
        updated_at = CURRENT_TIMESTAMP
    WHERE product_id = NEW.product_id;
    
    -- Log inventory change
    INSERT INTO inventory_changes (
        product_id, change_type, quantity_change, 
        previous_stock, new_stock, reference_type, reference_id,
        unit_cost, total_cost, reason
    ) VALUES (
        NEW.product_id, 'Stock_Out', -NEW.quantity,
        (SELECT current_stock + NEW.quantity FROM products WHERE product_id = NEW.product_id),
        (SELECT current_stock FROM products WHERE product_id = NEW.product_id),
        'Order', NEW.order_id,
        NEW.unit_price, NEW.total_price,
        CONCAT('Stock reduction for Order #', NEW.order_id)
    );
END//

-- Trigger to update customer statistics when orders are placed
CREATE TRIGGER update_customer_stats 
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
    UPDATE customers 
    SET total_orders = total_orders + 1,
        total_spent = total_spent + NEW.total_amount,
        last_order_date = NEW.order_date,
        average_order_value = (total_spent + NEW.total_amount) / (total_orders + 1),
        updated_at = CURRENT_TIMESTAMP
    WHERE customer_id = NEW.customer_id;
END//

DELIMITER ;

-- =====================================================
-- VIEWS FOR COMMON BUSINESS QUERIES
-- =====================================================

-- =====================================================
-- VIEWS FOR EASY DATA ACCESS
-- =====================================================

-- Drop existing views if they exist (for clean setup)
DROP VIEW IF EXISTS low_stock_products;
DROP VIEW IF EXISTS customer_order_summary;
DROP VIEW IF EXISTS product_performance;

-- Simple view to show products that need restocking
-- Shows products where current stock is less than or equal to reorder level
CREATE VIEW low_stock_products AS
SELECT 
    p.product_id,
    p.product_name,
    p.sku,
    c.category_name,
    s.supplier_name,
    p.current_stock,
    p.reorder_level,
    (p.reorder_level - p.current_stock) AS how_many_needed,  -- simpler name
    p.price
FROM products p
JOIN categories c ON p.category_id = c.category_id  -- using JOIN instead of LEFT JOIN for simplicity
JOIN suppliers s ON p.supplier_id = s.supplier_id
WHERE p.current_stock <= p.reorder_level 
AND p.is_active = 1  -- using 1 instead of TRUE for MySQL compatibility
ORDER BY how_many_needed DESC;

-- Simple view to show customer information with their order history
-- This makes it easy to see customer details and spending
CREATE VIEW customer_order_summary AS
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    c.total_orders,
    c.total_spent,
    c.average_order_value,
    c.last_order_date,
    c.customer_since,
    -- Simple customer classification based on spending
    CASE 
        WHEN c.total_spent >= 1000 THEN 'VIP Customer'
        WHEN c.total_spent >= 500 THEN 'Good Customer'
        WHEN c.total_spent >= 100 THEN 'Regular Customer'
        ELSE 'New Customer'
    END AS customer_type
FROM customers c
WHERE c.is_active = 1;

-- Simple view to show how well products are selling
-- Shows basic sales information for each product
CREATE VIEW product_performance AS
SELECT 
    p.product_id,
    p.product_name,
    p.sku,
    c.category_name,
    p.price,
    p.cost_price,
    p.current_stock,
    -- Calculate profit per item sold
    (p.price - p.cost_price) AS profit_per_unit,
    -- Calculate total value of current stock
    (p.current_stock * p.cost_price) AS stock_value,
    -- Show if product is profitable
    CASE 
        WHEN (p.price - p.cost_price) > 0 THEN 'Profitable'
        ELSE 'Check Pricing'
    END AS profit_status
FROM products p
JOIN categories c ON p.category_id = c.category_id
WHERE p.is_active = 1;

-- =====================================================
-- SCHEMA CREATION COMPLETE
-- =====================================================