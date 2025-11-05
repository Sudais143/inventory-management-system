-- =====================================================
-- INVENTORY AND ORDER MANAGEMENT SYSTEM - CORE OPERATIONS
-- =====================================================
-- This script contains stored procedures and functions for basic CRUD operations

-- Drop existing procedures and functions if they exist
DROP PROCEDURE IF EXISTS AddProduct;
DROP PROCEDURE IF EXISTS UpdateProduct;
DROP PROCEDURE IF EXISTS AdjustProductStock;
DROP PROCEDURE IF EXISTS AddCustomer;
DROP PROCEDURE IF EXISTS UpdateCustomer;
DROP PROCEDURE IF EXISTS SearchProducts;
DROP PROCEDURE IF EXISTS GetCustomerOrderHistory;
DROP PROCEDURE IF EXISTS GetOrderDetails;
DROP PROCEDURE IF EXISTS GetLowStockReport;
DROP PROCEDURE IF EXISTS GetInventoryValueReport;
DROP PROCEDURE IF EXISTS GetProductSalesSummary;
DROP FUNCTION IF EXISTS GenerateOrderNumber;

DELIMITER //

-- =====================================================
-- PRODUCT MANAGEMENT PROCEDURES
-- =====================================================

-- Add new product
CREATE PROCEDURE AddProduct(
    IN p_product_name VARCHAR(200),
    IN p_description TEXT,
    IN p_category_id INT,
    IN p_supplier_id INT,
    IN p_sku VARCHAR(50),
    IN p_price DECIMAL(10,2),
    IN p_cost_price DECIMAL(10,2),
    IN p_initial_stock INT,
    IN p_reorder_level INT,
    IN p_max_stock_level INT,
    IN p_weight DECIMAL(8,2),
    IN p_dimensions VARCHAR(50)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Insert the product
    INSERT INTO products (
        product_name, description, category_id, supplier_id, sku, 
        price, cost_price, current_stock, reorder_level, max_stock_level,
        weight, dimensions
    ) VALUES (
        p_product_name, p_description, p_category_id, p_supplier_id, p_sku,
        p_price, p_cost_price, p_initial_stock, p_reorder_level, p_max_stock_level,
        p_weight, p_dimensions
    );
    
    -- Log initial inventory if stock > 0
    IF p_initial_stock > 0 THEN
        INSERT INTO inventory_changes (
            product_id, change_type, quantity_change, previous_stock, new_stock,
            reference_type, reason, performed_by
        ) VALUES (
            LAST_INSERT_ID(), 'Stock_In', p_initial_stock, 0, p_initial_stock,
            'Manual', 'Initial stock entry', 'System'
        );
    END IF;
    
    COMMIT;
    SELECT LAST_INSERT_ID() AS product_id;
END//

-- Update product information
CREATE PROCEDURE UpdateProduct(
    IN p_product_id INT,
    IN p_product_name VARCHAR(200),
    IN p_description TEXT,
    IN p_price DECIMAL(10,2),
    IN p_cost_price DECIMAL(10,2),
    IN p_reorder_level INT,
    IN p_max_stock_level INT,
    IN p_is_active BOOLEAN
)
BEGIN
    UPDATE products 
    SET product_name = p_product_name,
        description = p_description,
        price = p_price,
        cost_price = p_cost_price,
        reorder_level = p_reorder_level,
        max_stock_level = p_max_stock_level,
        is_active = p_is_active,
        updated_at = CURRENT_TIMESTAMP
    WHERE product_id = p_product_id;
    
    SELECT ROW_COUNT() AS affected_rows;
END//

-- Adjust product stock
CREATE PROCEDURE AdjustProductStock(
    IN p_product_id INT,
    IN p_quantity_change INT,
    IN p_change_type ENUM('Stock_In', 'Stock_Out', 'Adjustment', 'Return', 'Damage', 'Transfer'),
    IN p_reason TEXT,
    IN p_performed_by VARCHAR(100)
)
BEGIN
    DECLARE v_current_stock INT;
    DECLARE v_new_stock INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Get current stock
    SELECT current_stock INTO v_current_stock 
    FROM products 
    WHERE product_id = p_product_id;
    
    -- Calculate new stock
    SET v_new_stock = v_current_stock + p_quantity_change;
    
    -- Validate new stock is not negative
    IF v_new_stock < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock cannot be negative';
    END IF;
    
    -- Update product stock
    UPDATE products 
    SET current_stock = v_new_stock,
        updated_at = CURRENT_TIMESTAMP
    WHERE product_id = p_product_id;
    
    -- Log inventory change
    INSERT INTO inventory_changes (
        product_id, change_type, quantity_change, previous_stock, new_stock,
        reference_type, reason, performed_by
    ) VALUES (
        p_product_id, p_change_type, p_quantity_change, v_current_stock, v_new_stock,
        'Manual', p_reason, p_performed_by
    );
    
    COMMIT;
    SELECT v_new_stock AS new_stock_level;
END//

-- =====================================================
-- CUSTOMER MANAGEMENT PROCEDURES
-- =====================================================

-- Add new customer
CREATE PROCEDURE AddCustomer(
    IN p_first_name VARCHAR(50),
    IN p_last_name VARCHAR(50),
    IN p_email VARCHAR(100),
    IN p_phone VARCHAR(20),
    IN p_date_of_birth DATE,
    IN p_gender ENUM('Male', 'Female', 'Other'),
    IN p_address_line1 VARCHAR(200),
    IN p_address_line2 VARCHAR(200),
    IN p_city VARCHAR(50),
    IN p_state VARCHAR(50),
    IN p_postal_code VARCHAR(20),
    IN p_country VARCHAR(50),
    IN p_preferred_contact ENUM('Email', 'Phone', 'SMS'),
    IN p_marketing_consent BOOLEAN
)
BEGIN
    INSERT INTO customers (
        first_name, last_name, email, phone, date_of_birth, gender,
        address_line1, address_line2, city, state, postal_code, country,
        preferred_contact, marketing_consent
    ) VALUES (
        p_first_name, p_last_name, p_email, p_phone, p_date_of_birth, p_gender,
        p_address_line1, p_address_line2, p_city, p_state, p_postal_code, p_country,
        p_preferred_contact, p_marketing_consent
    );
    
    SELECT LAST_INSERT_ID() AS customer_id;
END//

-- Update customer information
CREATE PROCEDURE UpdateCustomer(
    IN p_customer_id INT,
    IN p_first_name VARCHAR(50),
    IN p_last_name VARCHAR(50),
    IN p_email VARCHAR(100),
    IN p_phone VARCHAR(20),
    IN p_address_line1 VARCHAR(200),
    IN p_address_line2 VARCHAR(200),
    IN p_city VARCHAR(50),
    IN p_state VARCHAR(50),
    IN p_postal_code VARCHAR(20),
    IN p_country VARCHAR(50),
    IN p_preferred_contact ENUM('Email', 'Phone', 'SMS'),
    IN p_marketing_consent BOOLEAN,
    IN p_is_active BOOLEAN
)
BEGIN
    UPDATE customers 
    SET first_name = p_first_name,
        last_name = p_last_name,
        email = p_email,
        phone = p_phone,
        address_line1 = p_address_line1,
        address_line2 = p_address_line2,
        city = p_city,
        state = p_state,
        postal_code = p_postal_code,
        country = p_country,
        preferred_contact = p_preferred_contact,
        marketing_consent = p_marketing_consent,
        is_active = p_is_active,
        updated_at = CURRENT_TIMESTAMP
    WHERE customer_id = p_customer_id;
    
    SELECT ROW_COUNT() AS affected_rows;
END//

-- =====================================================
-- SEARCH AND RETRIEVAL FUNCTIONS
-- =====================================================

-- Search products by name or SKU
CREATE PROCEDURE SearchProducts(
    IN p_search_term VARCHAR(200),
    IN p_category_id INT,
    IN p_active_only BOOLEAN,
    IN p_in_stock_only BOOLEAN
)
BEGIN
    SELECT 
        p.product_id,
        p.product_name,
        p.sku,
        p.description,
        c.category_name,
        s.supplier_name,
        p.price,
        p.cost_price,
        p.current_stock,
        p.reorder_level,
        p.is_active,
        CASE 
            WHEN p.current_stock <= p.reorder_level THEN 'Low Stock'
            WHEN p.current_stock = 0 THEN 'Out of Stock'
            ELSE 'In Stock'
        END AS stock_status
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.category_id
    LEFT JOIN suppliers s ON p.supplier_id = s.supplier_id
    WHERE 
        (p_search_term IS NULL OR 
         p.product_name LIKE CONCAT('%', p_search_term, '%') OR 
         p.sku LIKE CONCAT('%', p_search_term, '%') OR
         p.description LIKE CONCAT('%', p_search_term, '%'))
        AND (p_category_id IS NULL OR p.category_id = p_category_id)
        AND (p_active_only = FALSE OR p.is_active = TRUE)
        AND (p_in_stock_only = FALSE OR p.current_stock > 0)
    ORDER BY p.product_name;
END//

-- Get customer order history
CREATE PROCEDURE GetCustomerOrderHistory(
    IN p_customer_id INT,
    IN p_limit_orders INT
)
BEGIN
    SELECT 
        o.order_id,
        o.order_number,
        o.order_date,
        o.order_status,
        o.payment_status,
        o.total_amount,
        COUNT(oi.order_item_id) AS total_items,
        o.shipped_date,
        o.delivered_date
    FROM orders o
    LEFT JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.customer_id = p_customer_id
    GROUP BY o.order_id
    ORDER BY o.order_date DESC
    LIMIT p_limit_orders;
END//

-- Get order details with items
CREATE PROCEDURE GetOrderDetails(
    IN p_order_id INT
)
BEGIN
    -- Order information
    SELECT 
        o.order_id,
        o.order_number,
        o.order_date,
        o.order_status,
        o.payment_status,
        o.payment_method,
        o.subtotal,
        o.tax_amount,
        o.shipping_cost,
        o.discount_amount,
        o.total_amount,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.email AS customer_email,
        c.phone AS customer_phone,
        o.shipping_address_line1,
        o.shipping_city,
        o.shipping_state,
        o.shipping_postal_code,
        o.tracking_number,
        o.notes
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_id = p_order_id;
    
    -- Order items
    SELECT 
        oi.order_item_id,
        p.product_name,
        p.sku,
        oi.quantity,
        oi.unit_price,
        oi.total_price,
        oi.discount_amount,
        p.current_stock
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    WHERE oi.order_id = p_order_id
    ORDER BY oi.order_item_id;
END//

-- =====================================================
-- INVENTORY REPORTING FUNCTIONS
-- =====================================================

-- Get low stock report
CREATE PROCEDURE GetLowStockReport()
BEGIN
    SELECT 
        p.product_id,
        p.product_name,
        p.sku,
        c.category_name,
        s.supplier_name,
        p.current_stock,
        p.reorder_level,
        (p.reorder_level - p.current_stock) AS stock_deficit,
        p.price,
        p.cost_price,
        (p.current_stock * p.cost_price) AS inventory_value,
        s.email AS supplier_email,
        s.phone AS supplier_phone
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.category_id
    LEFT JOIN suppliers s ON p.supplier_id = s.supplier_id
    WHERE p.current_stock <= p.reorder_level 
    AND p.is_active = TRUE
    ORDER BY (p.reorder_level - p.current_stock) DESC;
END//

-- Get inventory value report
CREATE PROCEDURE GetInventoryValueReport(
    IN p_category_id INT
)
BEGIN
    SELECT 
        c.category_name,
        COUNT(p.product_id) AS product_count,
        SUM(p.current_stock) AS total_units,
        SUM(p.current_stock * p.cost_price) AS total_cost_value,
        SUM(p.current_stock * p.price) AS total_retail_value,
        SUM(p.current_stock * (p.price - p.cost_price)) AS potential_profit
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.category_id
    WHERE (p_category_id IS NULL OR p.category_id = p_category_id)
    AND p.is_active = TRUE
    GROUP BY c.category_id, c.category_name
    ORDER BY total_retail_value DESC;
END//

-- Get product sales summary
CREATE PROCEDURE GetProductSalesSummary(
    IN p_product_id INT,
    IN p_days_back INT
)
BEGIN
    SELECT 
        p.product_id,
        p.product_name,
        p.sku,
        p.current_stock,
        COALESCE(sales.total_sold, 0) AS total_units_sold,
        COALESCE(sales.total_revenue, 0) AS total_revenue,
        COALESCE(sales.order_count, 0) AS number_of_orders,
        COALESCE(sales.avg_price, p.price) AS average_selling_price,
        p.cost_price,
        (COALESCE(sales.avg_price, p.price) - p.cost_price) AS profit_per_unit,
        COALESCE(sales.total_revenue, 0) - (COALESCE(sales.total_sold, 0) * p.cost_price) AS total_profit
    FROM products p
    LEFT JOIN (
        SELECT 
            oi.product_id,
            SUM(oi.quantity) AS total_sold,
            SUM(oi.total_price) AS total_revenue,
            COUNT(DISTINCT oi.order_id) AS order_count,
            AVG(oi.unit_price) AS avg_price
        FROM order_items oi
        JOIN orders o ON oi.order_id = o.order_id
        WHERE o.order_status NOT IN ('Cancelled', 'Returned')
        AND (p_days_back IS NULL OR o.order_date >= DATE_SUB(CURRENT_DATE, INTERVAL p_days_back DAY))
        GROUP BY oi.product_id
    ) sales ON p.product_id = sales.product_id
    WHERE (p_product_id IS NULL OR p.product_id = p_product_id)
    AND p.is_active = TRUE
    ORDER BY total_revenue DESC;
END//

DELIMITER ;

-- =====================================================
-- UTILITY FUNCTIONS
-- =====================================================

-- Function to generate order number
DELIMITER //
CREATE FUNCTION GenerateOrderNumber() 
RETURNS VARCHAR(50)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE order_count INT;
    DECLARE order_number VARCHAR(50);
    
    SELECT COUNT(*) + 1 INTO order_count FROM orders;
    SET order_number = CONCAT('ORD-', YEAR(CURRENT_DATE), '-', LPAD(order_count, 4, '0'));
    
    RETURN order_number;
END//
DELIMITER ;

-- =====================================================
-- SAMPLE PROCEDURE CALLS FOR TESTING
-- =====================================================

/*
-- Test adding a new product
CALL AddProduct(
    'Test Product', 
    'This is a test product description', 
    1, 1, 'TEST-001', 
    99.99, 60.00, 50, 10, 100, 
    0.5, '10x5x2 inches'
);

-- Test searching products
CALL SearchProducts('iPhone', NULL, TRUE, TRUE);

-- Test getting low stock report
CALL GetLowStockReport();

-- Test getting customer order history
CALL GetCustomerOrderHistory(1, 10);

-- Test getting order details
CALL GetOrderDetails(1);

-- Test inventory value report
CALL GetInventoryValueReport(NULL);

-- Test product sales summary
CALL GetProductSalesSummary(NULL, 30);
*/