-- =====================================================
-- INVENTORY AND ORDER MANAGEMENT SYSTEM - TESTING & DEMO SCRIPT
-- =====================================================
-- This script demonstrates all major features of the system with practical examples
-- Note: This script handles duplicate entries gracefully - it can be run multiple times safely

-- Select the database
USE inventory_management;

-- =====================================================
-- PART 1: BASIC SYSTEM TESTING
-- =====================================================

-- 1. Verify system setup
SELECT 'System Setup Verification' AS test_section;
SELECT 'Categories' AS table_name, COUNT(*) AS record_count FROM categories
UNION ALL
SELECT 'Suppliers', COUNT(*) FROM suppliers
UNION ALL
SELECT 'Products', COUNT(*) FROM products
UNION ALL
SELECT 'Customers', COUNT(*) FROM customers
UNION ALL
SELECT 'Orders', COUNT(*) FROM orders;

-- =====================================================
-- PART 2: PRODUCT MANAGEMENT DEMO
-- =====================================================

SELECT '\n=== PRODUCT MANAGEMENT DEMO ===' AS demo_section;

-- Add a new product (only if it doesn't exist)
SET @product_exists = 0;
SELECT COUNT(*) INTO @product_exists FROM products WHERE sku = 'ELEC-WATCH10-101';

SELECT 
    CASE 
        WHEN @product_exists > 0 THEN 'Product with SKU ELEC-WATCH10-101 already exists - skipping creation'
        ELSE 'Adding new Apple Watch Series 10...'
    END AS product_creation_status;

-- Only add if it doesn't exist
SET @sql = CASE 
    WHEN @product_exists = 0 THEN 
        "CALL AddProduct('Apple Watch Series 10', 'Latest smartwatch with health monitoring features', 1, 1, 'ELEC-WATCH10-101', 399.99, 250.00, 25, 5, 75, 0.35, '1.7x1.5x0.4 inches')"
    ELSE 
        "SELECT 'Product creation skipped - already exists' AS result"
END;

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Search for products
SELECT '\nProduct Search Results:' AS info;
CALL SearchProducts('Apple', NULL, TRUE, TRUE);

-- Check low stock products
SELECT '\nLow Stock Alert:' AS info;
CALL GetLowStockReport();

-- =====================================================
-- PART 3: CUSTOMER MANAGEMENT DEMO
-- =====================================================

SELECT '\n=== CUSTOMER MANAGEMENT DEMO ===' AS demo_section;

-- Add a new customer (only if email doesn't exist)
SET @customer_exists = 0;
SELECT COUNT(*) INTO @customer_exists FROM customers WHERE email = 'maria.rodriguez@email.com';

SELECT 
    CASE 
        WHEN @customer_exists > 0 THEN 'Customer with email maria.rodriguez@email.com already exists - skipping creation'
        ELSE 'Adding new customer Maria Rodriguez...'
    END AS customer_creation_status;

-- Only add if customer doesn't exist
SET @sql_customer = CASE 
    WHEN @customer_exists = 0 THEN 
        "CALL AddCustomer('Maria', 'Rodriguez', 'maria.rodriguez@email.com', '+1-555-2020', '1992-08-15', 'Female', '456 Tech Boulevard', 'Suite 201', 'San Francisco', 'CA', '94105', 'USA', 'Email', TRUE)"
    ELSE 
        "SELECT 'Customer creation skipped - email already exists' AS result"
END;

PREPARE stmt2 FROM @sql_customer;
EXECUTE stmt2;
DEALLOCATE PREPARE stmt2;

-- Analyze customer behavior
SELECT '\nCustomer Behavior Analysis:' AS info;
CALL AnalyzeCustomerBehavior(NULL, 90);

-- =====================================================
-- PART 4: ORDER PROCESSING DEMO
-- =====================================================

SELECT '\n=== ORDER PROCESSING DEMO ===' AS demo_section;

-- Create a new order and capture the order_id
SELECT 'Creating new order...' AS status;

-- Create order for customer 1
CALL CreateOrder(
    1, 'Credit Card', '123 Main Street', NULL, 
    'New York', 'NY', '10001', 'USA', 'Express shipping requested'
);

-- Get the most recent order_id for this customer (safer approach)
SELECT MAX(order_id) INTO @new_order_id 
FROM orders 
WHERE customer_id = 1 AND order_status = 'Pending';

SELECT CONCAT('Working with order ID: ', @new_order_id) AS order_info;

-- Add items to the order
CALL AddItemToOrder(@new_order_id, 1, 1, 999.99, 50.00);  -- iPhone with discount
CALL AddItemToOrder(@new_order_id, 7, 1, 249.99, 0.00);   -- AirPods Pro

-- Update order totals
CALL UpdateOrderTotals(@new_order_id);

-- Get order details
SELECT '\nOrder Details:' AS info;
SELECT 
    o.order_id, o.order_number, o.order_status, o.total_amount,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name
FROM orders o 
JOIN customers c ON o.customer_id = c.customer_id 
WHERE o.order_id = @new_order_id;

-- Confirm the order
CALL ConfirmOrder(@new_order_id, 'Credit Card');

-- Update order status
CALL UpdateOrderStatus(@new_order_id, 'Processing', NULL, 'Order being prepared for shipment');

-- =====================================================
-- PART 5: INVENTORY MANAGEMENT DEMO
-- =====================================================

SELECT '\n=== INVENTORY MANAGEMENT DEMO ===' AS demo_section;

-- Generate stock status report
SELECT '\nStock Status Report:' AS info;
CALL GetStockStatusReport(NULL, NULL, 'All');

-- Process stock replenishment
SELECT '\nStock Replenishment:' AS info;
CALL ProcessStockReplenishment(1, 30, 750.00, 'PO-2024-DEMO-001', 'Demo User');

-- Get inventory movement history
SELECT '\nInventory Movement History:' AS info;
CALL GetInventoryMovementHistory(1, NULL, NULL, NULL, 10);

-- Generate purchase recommendations
SELECT '\nPurchase Recommendations:' AS info;
CALL GeneratePurchaseRecommendations(NULL, NULL);

-- =====================================================
-- PART 6: BUSINESS ANALYTICS DEMO
-- =====================================================

SELECT '\n=== BUSINESS ANALYTICS DEMO ===' AS demo_section;

-- Sales performance dashboard
SELECT '\nSales Performance Dashboard:' AS info;
CALL GetSalesPerformanceDashboard(30);

-- Product performance analysis
SELECT '\nProduct Performance Analysis:' AS info;
CALL AnalyzeProductPerformance(60, NULL);

-- Customer segmentation
SELECT '\nCustomer Segmentation:' AS info;
CALL PerformCustomerSegmentation();

-- Calculate customer lifetime value
SELECT '\nCustomer Lifetime Value:' AS info;
CALL CalculateCustomerLifetimeValue(NULL);

-- Monthly financial summary
SELECT '\nFinancial Summary:' AS info;
CALL GetMonthlyFinancialSummary(YEAR(CURRENT_DATE), MONTH(CURRENT_DATE));

-- =====================================================
-- PART 7: ADVANCED FEATURES DEMO
-- =====================================================

SELECT '\n=== ADVANCED FEATURES DEMO ===' AS demo_section;

-- Purchase recommendations (automated reorder suggestions)
SELECT '\nPurchase Recommendations:' AS info;
CALL GeneratePurchaseRecommendations(NULL, NULL);

-- ABC analysis
SELECT '\nABC Analysis:' AS info;
CALL PerformABCAnalysis(180);

-- Inventory turnover analysis
SELECT '\nInventory Turnover Analysis:' AS info;
CALL CalculateInventoryTurnover(NULL, 90);

-- Dead stock analysis
SELECT '\nDead Stock Analysis:' AS info;
CALL GetDeadStockAnalysis(60);

-- Note: Advanced features like seasonal analysis, demand forecasting, 
-- and advanced segmentation are available in 07_advanced_features.sql
-- but not included in this basic demo for simplicity

-- =====================================================
-- PART 8: REPORTING AND VIEWS DEMO
-- =====================================================

SELECT '\n=== REPORTING AND VIEWS DEMO ===' AS demo_section;

-- Low stock products view
SELECT '\nLow Stock Products:' AS info;
SELECT * FROM low_stock_products LIMIT 5;

-- Customer order summary view
SELECT '\nTop Customers:' AS info;
SELECT * FROM customer_order_summary ORDER BY total_spent DESC LIMIT 5;

-- Product performance view
SELECT '\nTop Performing Products:' AS info;
SELECT * FROM product_performance ORDER BY total_revenue DESC LIMIT 5;

-- =====================================================
-- PART 9: SYSTEM PERFORMANCE METRICS
-- =====================================================

SELECT '\n=== SYSTEM PERFORMANCE METRICS ===' AS demo_section;

-- Show current system status
SELECT 
    'Database Size' AS metric,
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS value_mb
FROM information_schema.tables 
WHERE table_schema = DATABASE();

-- Show table sizes
SELECT 
    table_name,
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS size_mb
FROM information_schema.TABLES 
WHERE table_schema = DATABASE()
ORDER BY size_mb DESC;

-- Show index usage
SELECT 
    DISTINCT table_name,
    COUNT(*) AS index_count
FROM information_schema.statistics 
WHERE table_schema = DATABASE()
GROUP BY table_name
ORDER BY index_count DESC;

-- =====================================================
-- PART 10: DATA QUALITY CHECKS
-- =====================================================

SELECT '\n=== DATA QUALITY CHECKS ===' AS demo_section;

-- Check for data consistency
SELECT 'Data Consistency Checks' AS check_type;

-- Verify order totals match item totals
SELECT 
    'Order Total Consistency' AS check_name,
    COUNT(*) AS issues_found
FROM orders o
WHERE ABS(o.subtotal - (
    SELECT SUM(oi.total_price) 
    FROM order_items oi 
    WHERE oi.order_id = o.order_id
)) > 0.01;

-- Check for negative stock
SELECT 
    'Negative Stock Check' AS check_name,
    COUNT(*) AS issues_found
FROM products 
WHERE current_stock < 0;

-- Check customer statistics consistency
SELECT 
    'Customer Stats Consistency' AS check_name,
    COUNT(*) AS issues_found
FROM customers c
WHERE c.total_orders != (
    SELECT COUNT(*) 
    FROM orders o 
    WHERE o.customer_id = c.customer_id 
    AND o.order_status NOT IN ('Cancelled')
);

-- =====================================================
-- PART 11: SAMPLE BUSINESS SCENARIOS
-- =====================================================

SELECT '\n=== BUSINESS SCENARIO SIMULATIONS ===' AS demo_section;

-- Scenario 1: Holiday rush preparation
SELECT '\nScenario 1: Holiday Rush Preparation' AS scenario;
SELECT 
    p.product_name,
    p.current_stock,
    COALESCE(summer_sales.projected_holiday_demand, 0) AS projected_demand,
    CASE 
        WHEN p.current_stock < COALESCE(summer_sales.projected_holiday_demand, 0) 
        THEN 'INCREASE STOCK'
        ELSE 'SUFFICIENT STOCK'
    END AS recommendation
FROM products p
LEFT JOIN (
    SELECT 
        oi.product_id,
        SUM(oi.quantity) * 2 AS projected_holiday_demand  -- Assume 2x summer demand
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    WHERE MONTH(o.order_date) IN (6,7,8)  -- Summer months
    AND o.order_status NOT IN ('Cancelled', 'Returned')
    GROUP BY oi.product_id
) summer_sales ON p.product_id = summer_sales.product_id
WHERE p.is_active = TRUE
ORDER BY projected_demand DESC
LIMIT 10;

-- Scenario 2: Customer retention analysis
SELECT '\nScenario 2: Customer Retention Analysis' AS scenario;
SELECT 
    CASE 
        WHEN days_since_last_order <= 30 THEN 'Active (0-30 days)'
        WHEN days_since_last_order <= 90 THEN 'At Risk (31-90 days)'
        WHEN days_since_last_order <= 180 THEN 'Inactive (91-180 days)'
        ELSE 'Lost (>180 days)'
    END AS customer_status,
    COUNT(*) AS customer_count,
    ROUND(AVG(total_spent), 2) AS avg_lifetime_value
FROM (
    SELECT 
        customer_id,
        total_spent,
        COALESCE(DATEDIFF(CURRENT_DATE, last_order_date), 9999) AS days_since_last_order
    FROM customers
    WHERE is_active = TRUE
) customer_data
GROUP BY customer_status
ORDER BY customer_count DESC;

-- =====================================================
-- DEMO COMPLETION SUMMARY
-- =====================================================

SELECT '\n=== DEMO COMPLETION SUMMARY ===' AS demo_section;

SELECT 
    'Demo Completed Successfully' AS status,
    NOW() AS completion_time,
    'All system features tested and validated' AS message;

-- Final system health check
SELECT '\nFinal System Health Check:' AS info;
SELECT 
    'Total Products' AS metric, COUNT(*) AS value FROM products WHERE is_active = TRUE
UNION ALL
SELECT 'Total Customers', COUNT(*) FROM customers WHERE is_active = TRUE
UNION ALL
SELECT 'Total Orders', COUNT(*) FROM orders
UNION ALL
SELECT 'Products Low Stock', COUNT(*) FROM products WHERE current_stock <= reorder_level AND is_active = TRUE
UNION ALL
SELECT 'Orders Pending', COUNT(*) FROM orders WHERE order_status = 'Pending';

-- =====================================================
-- END OF DEMO SCRIPT
-- =====================================================