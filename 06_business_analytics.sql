-- =====================================================
-- INVENTORY AND ORDER MANAGEMENT SYSTEM - BUSINESS ANALYTICS
-- =====================================================
-- Comprehensive business analytics for customer behavior, sales performance,
-- and strategic business insights

-- Drop existing procedures if they exist
DROP PROCEDURE IF EXISTS AnalyzeCustomerBehavior;
DROP PROCEDURE IF EXISTS CalculateCustomerLifetimeValue;
DROP PROCEDURE IF EXISTS PerformCustomerSegmentation;
DROP PROCEDURE IF EXISTS GetSalesPerformanceDashboard;
DROP PROCEDURE IF EXISTS AnalyzeProductPerformance;
DROP PROCEDURE IF EXISTS AnalyzeCategoryPerformance;
DROP PROCEDURE IF EXISTS GetMonthlyFinancialSummary;

DELIMITER //

-- =====================================================
-- CUSTOMER BEHAVIOR ANALYSIS
-- =====================================================

-- Customer purchase behavior analysis
CREATE PROCEDURE AnalyzeCustomerBehavior(
    IN p_customer_id INT,
    IN p_analysis_period_days INT
)
BEGIN
    DECLARE v_start_date DATE;
    SET v_start_date = DATE_SUB(CURRENT_DATE, INTERVAL p_analysis_period_days DAY);
    
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.email,
        c.customer_since,
        DATEDIFF(CURRENT_DATE, c.customer_since) AS days_as_customer,
        
        -- Order statistics
        c.total_orders AS lifetime_orders,
        COALESCE(recent.recent_orders, 0) AS recent_orders,
        c.total_spent AS lifetime_spent,
        COALESCE(recent.recent_spent, 0) AS recent_spent,
        c.average_order_value AS lifetime_aov,
        COALESCE(recent.recent_aov, 0) AS recent_aov,
        
        -- Purchase frequency
        CASE 
            WHEN c.total_orders > 0 THEN 
                ROUND(DATEDIFF(CURRENT_DATE, c.customer_since) / c.total_orders, 1)
            ELSE NULL
        END AS avg_days_between_orders,
        
        -- Recent activity
        COALESCE(DATEDIFF(CURRENT_DATE, c.last_order_date), 9999) AS days_since_last_order,
        
        -- Customer segmentation
        CASE 
            WHEN c.total_spent >= 5000 THEN 'VIP'
            WHEN c.total_spent >= 1000 THEN 'Premium'
            WHEN c.total_spent >= 200 THEN 'Regular'
            ELSE 'New'
        END AS customer_tier,
        
        -- Purchase behavior classification
        CASE 
            WHEN COALESCE(DATEDIFF(CURRENT_DATE, c.last_order_date), 9999) <= 30 THEN 'Active'
            WHEN COALESCE(DATEDIFF(CURRENT_DATE, c.last_order_date), 9999) <= 90 THEN 'At Risk'
            WHEN COALESCE(DATEDIFF(CURRENT_DATE, c.last_order_date), 9999) <= 180 THEN 'Inactive'
            ELSE 'Dormant'
        END AS activity_status,
        
        -- Favorite categories
        COALESCE(fav_category.favorite_category, 'N/A') AS favorite_category,
        COALESCE(fav_category.category_spend, 0) AS favorite_category_spend
        
    FROM customers c
    LEFT JOIN (
        SELECT 
            o.customer_id,
            COUNT(o.order_id) AS recent_orders,
            SUM(o.total_amount) AS recent_spent,
            AVG(o.total_amount) AS recent_aov
        FROM orders o
        WHERE o.order_date >= v_start_date
        AND o.order_status NOT IN ('Cancelled', 'Returned')
        GROUP BY o.customer_id
    ) recent ON c.customer_id = recent.customer_id
    LEFT JOIN (
        SELECT 
            o.customer_id,
            cat.category_name AS favorite_category,
            SUM(oi.total_price) AS category_spend,
            ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY SUM(oi.total_price) DESC) AS rn
        FROM orders o
        JOIN order_items oi ON o.order_id = oi.order_id
        JOIN products p ON oi.product_id = p.product_id
        JOIN categories cat ON p.category_id = cat.category_id
        WHERE o.order_status NOT IN ('Cancelled', 'Returned')
        GROUP BY o.customer_id, cat.category_id, cat.category_name
    ) fav_category ON c.customer_id = fav_category.customer_id AND fav_category.rn = 1
    
    WHERE (p_customer_id IS NULL OR c.customer_id = p_customer_id)
    AND c.is_active = TRUE
    
    ORDER BY c.total_spent DESC;
END//

-- Customer lifetime value calculation
CREATE PROCEDURE CalculateCustomerLifetimeValue(
    IN p_customer_id INT
)
BEGIN
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.customer_since,
        DATEDIFF(CURRENT_DATE, c.customer_since) AS customer_age_days,
        c.total_orders,
        c.total_spent,
        c.average_order_value,
        
        -- Calculate CLV metrics
        CASE 
            WHEN DATEDIFF(CURRENT_DATE, c.customer_since) > 0 THEN
                ROUND(c.total_orders / (DATEDIFF(CURRENT_DATE, c.customer_since) / 365.25), 2)
            ELSE 0
        END AS annual_order_frequency,
        
        -- Predicted CLV (simplified model)
        CASE 
            WHEN DATEDIFF(CURRENT_DATE, c.customer_since) > 365 THEN
                ROUND(
                    (c.total_orders / (DATEDIFF(CURRENT_DATE, c.customer_since) / 365.25)) * 
                    c.average_order_value * 3, 2
                ) -- 3 year prediction
            ELSE ROUND(c.average_order_value * 12, 2) -- First year estimate
        END AS predicted_clv_3_years,
        
        -- Customer profitability (assuming 30% gross margin)
        ROUND(c.total_spent * 0.30, 2) AS estimated_gross_profit,
        
        -- Risk assessment
        CASE 
            WHEN COALESCE(DATEDIFF(CURRENT_DATE, c.last_order_date), 9999) > 180 THEN 'High Churn Risk'
            WHEN COALESCE(DATEDIFF(CURRENT_DATE, c.last_order_date), 9999) > 90 THEN 'Medium Churn Risk'
            WHEN COALESCE(DATEDIFF(CURRENT_DATE, c.last_order_date), 9999) > 30 THEN 'Low Churn Risk'
            ELSE 'Active'
        END AS churn_risk
        
    FROM customers c
    WHERE (p_customer_id IS NULL OR c.customer_id = p_customer_id)
    AND c.is_active = TRUE
    ORDER BY predicted_clv_3_years DESC;
END//

-- Customer segmentation analysis
CREATE PROCEDURE PerformCustomerSegmentation()
BEGIN
    -- RFM Analysis (Recency, Frequency, Monetary)
    SELECT 
        customer_id,
        customer_name,
        email,
        recency_days,
        frequency_orders,
        monetary_value,
        
        -- RFM Scores (1-5 scale)
        CASE 
            WHEN recency_days <= 30 THEN 5
            WHEN recency_days <= 60 THEN 4
            WHEN recency_days <= 90 THEN 3
            WHEN recency_days <= 180 THEN 2
            ELSE 1
        END AS recency_score,
        
        CASE 
            WHEN frequency_orders >= 10 THEN 5
            WHEN frequency_orders >= 7 THEN 4
            WHEN frequency_orders >= 4 THEN 3
            WHEN frequency_orders >= 2 THEN 2
            ELSE 1
        END AS frequency_score,
        
        CASE 
            WHEN monetary_value >= 2000 THEN 5
            WHEN monetary_value >= 1000 THEN 4
            WHEN monetary_value >= 500 THEN 3
            WHEN monetary_value >= 200 THEN 2
            ELSE 1
        END AS monetary_score,
        
        -- Segment classification
        CASE 
            WHEN recency_days <= 30 AND frequency_orders >= 5 AND monetary_value >= 1000 THEN 'Champions'
            WHEN recency_days <= 60 AND frequency_orders >= 3 AND monetary_value >= 500 THEN 'Loyal Customers'
            WHEN recency_days <= 30 AND frequency_orders <= 2 AND monetary_value >= 500 THEN 'Potential Loyalists'
            WHEN recency_days <= 60 AND frequency_orders <= 2 THEN 'New Customers'
            WHEN recency_days <= 90 AND frequency_orders >= 3 THEN 'At Risk'
            WHEN recency_days <= 180 AND frequency_orders >= 2 THEN 'Cannot Lose Them'
            WHEN recency_days > 180 AND frequency_orders >= 2 THEN 'Hibernating'
            ELSE 'Lost'
        END AS customer_segment
        
    FROM (
        SELECT 
            c.customer_id,
            CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
            c.email,
            COALESCE(DATEDIFF(CURRENT_DATE, c.last_order_date), 9999) AS recency_days,
            c.total_orders AS frequency_orders,
            c.total_spent AS monetary_value
        FROM customers c
        WHERE c.is_active = TRUE
    ) customer_data
    ORDER BY monetary_value DESC, frequency_orders DESC, recency_days ASC;
END//

-- =====================================================
-- SALES PERFORMANCE ANALYSIS
-- =====================================================

-- Sales performance dashboard
CREATE PROCEDURE GetSalesPerformanceDashboard(
    IN p_period_days INT
)
BEGIN
    DECLARE v_start_date DATE;
    DECLARE v_prev_start_date DATE;
    SET v_start_date = DATE_SUB(CURRENT_DATE, INTERVAL p_period_days DAY);
    SET v_prev_start_date = DATE_SUB(v_start_date, INTERVAL p_period_days DAY);
    
    -- Overall performance metrics
    SELECT 
        'Current Period' AS period_label,
        COUNT(DISTINCT o.order_id) AS total_orders,
        COUNT(DISTINCT o.customer_id) AS unique_customers,
        SUM(o.total_amount) AS total_revenue,
        AVG(o.total_amount) AS average_order_value,
        SUM(oi.quantity) AS total_units_sold,
        
        -- Compare with previous period
        MAX(prev_period.prev_orders) AS prev_orders,
        MAX(prev_period.prev_revenue) AS prev_revenue,
        MAX(prev_period.prev_aov) AS prev_aov,
        
        -- Calculate growth rates
        CASE 
            WHEN MAX(prev_period.prev_orders) > 0 THEN
                ROUND(((COUNT(DISTINCT o.order_id) - MAX(prev_period.prev_orders)) / MAX(prev_period.prev_orders)) * 100, 2)
            ELSE 0
        END AS order_growth_percent,
        
        CASE 
            WHEN MAX(prev_period.prev_revenue) > 0 THEN
                ROUND(((SUM(o.total_amount) - MAX(prev_period.prev_revenue)) / MAX(prev_period.prev_revenue)) * 100, 2)
            ELSE 0
        END AS revenue_growth_percent,
        
        CASE 
            WHEN MAX(prev_period.prev_aov) > 0 THEN
                ROUND(((AVG(o.total_amount) - MAX(prev_period.prev_aov)) / MAX(prev_period.prev_aov)) * 100, 2)
            ELSE 0
        END AS aov_growth_percent
        
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    CROSS JOIN (
        SELECT 
            COUNT(DISTINCT ord.order_id) AS prev_orders,
            CASE WHEN SUM(ord.total_amount) IS NULL THEN 0 ELSE SUM(ord.total_amount) END AS prev_revenue,
            CASE WHEN AVG(ord.total_amount) IS NULL THEN 0 ELSE AVG(ord.total_amount) END AS prev_aov
        FROM orders ord
        WHERE ord.order_date >= v_prev_start_date 
        AND ord.order_date < v_start_date
        AND ord.order_status NOT IN ('Cancelled', 'Returned')
    ) prev_period
    WHERE o.order_date >= v_start_date
    AND o.order_status NOT IN ('Cancelled', 'Returned');
END//

-- Product performance analysis
CREATE PROCEDURE AnalyzeProductPerformance(
    IN p_period_days INT,
    IN p_category_id INT
)
BEGIN
    DECLARE v_start_date DATE;
    SET v_start_date = DATE_SUB(CURRENT_DATE, INTERVAL p_period_days DAY);
    
    SELECT 
        p.product_id,
        p.product_name,
        p.sku,
        c.category_name,
        s.supplier_name,
        p.price AS current_price,
        p.cost_price,
        (p.price - p.cost_price) AS profit_per_unit,
        
        -- Sales metrics
        COALESCE(sales.total_units_sold, 0) AS units_sold,
        COALESCE(sales.total_revenue, 0) AS revenue,
        COALESCE(sales.total_orders, 0) AS number_of_orders,
        COALESCE(sales.avg_selling_price, p.price) AS avg_selling_price,
        
        -- Profitability
        COALESCE(sales.total_revenue, 0) - (COALESCE(sales.total_units_sold, 0) * p.cost_price) AS total_profit,
        CASE 
            WHEN COALESCE(sales.total_revenue, 0) > 0 THEN
                ROUND(((COALESCE(sales.total_revenue, 0) - (COALESCE(sales.total_units_sold, 0) * p.cost_price)) / 
                       COALESCE(sales.total_revenue, 0)) * 100, 2)
            ELSE 0
        END AS profit_margin_percent,
        
        -- Inventory metrics
        p.current_stock,
        CASE 
            WHEN COALESCE(sales.total_units_sold, 0) > 0 AND p_period_days > 0 THEN
                ROUND(p.current_stock / (COALESCE(sales.total_units_sold, 0) / p_period_days), 1)
            ELSE 9999
        END AS days_of_inventory,
        
        -- Performance classification
        CASE 
            WHEN COALESCE(sales.total_revenue, 0) = 0 THEN 'No Sales'
            WHEN COALESCE(sales.total_revenue, 0) >= 5000 THEN 'Star Performer'
            WHEN COALESCE(sales.total_revenue, 0) >= 1000 THEN 'Good Performer'
            WHEN COALESCE(sales.total_revenue, 0) >= 200 THEN 'Average Performer'
            ELSE 'Poor Performer'
        END AS performance_category
        
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.category_id
    LEFT JOIN suppliers s ON p.supplier_id = s.supplier_id
    LEFT JOIN (
        SELECT 
            oi.product_id,
            SUM(oi.quantity) AS total_units_sold,
            SUM(oi.total_price) AS total_revenue,
            COUNT(DISTINCT oi.order_id) AS total_orders,
            AVG(oi.unit_price) AS avg_selling_price
        FROM order_items oi
        JOIN orders o ON oi.order_id = o.order_id
        WHERE o.order_date >= v_start_date
        AND o.order_status NOT IN ('Cancelled', 'Returned')
        GROUP BY oi.product_id
    ) sales ON p.product_id = sales.product_id
    
    WHERE p.is_active = TRUE
    AND (p_category_id IS NULL OR p.category_id = p_category_id)
    
    ORDER BY COALESCE(sales.total_revenue, 0) DESC;
END//

-- Category performance analysis
CREATE PROCEDURE AnalyzeCategoryPerformance(
    IN p_period_days INT
)
BEGIN
    DECLARE v_start_date DATE;
    SET v_start_date = DATE_SUB(CURRENT_DATE, INTERVAL p_period_days DAY);
    
    SELECT 
        c.category_id,
        c.category_name,
        
        -- Product metrics
        COUNT(DISTINCT p.product_id) AS total_products,
        SUM(p.current_stock) AS total_inventory_units,
        SUM(p.current_stock * p.cost_price) AS inventory_value,
        
        -- Sales metrics
        COALESCE(sales.total_units_sold, 0) AS units_sold,
        COALESCE(sales.total_revenue, 0) AS revenue,
        COALESCE(sales.total_orders, 0) AS number_of_orders,
        COALESCE(sales.avg_order_value, 0) AS avg_order_value,
        
        -- Market share (within our product mix)
        ROUND(
            (COALESCE(sales.total_revenue, 0) / 
             (SELECT SUM(oi2.total_price) 
              FROM order_items oi2 
              JOIN orders o2 ON oi2.order_id = o2.order_id 
              WHERE o2.order_date >= v_start_date 
              AND o2.order_status NOT IN ('Cancelled', 'Returned'))) * 100, 2
        ) AS revenue_share_percent,
        
        -- Profitability
        COALESCE(sales.total_profit, 0) AS total_profit,
        CASE 
            WHEN COALESCE(sales.total_revenue, 0) > 0 THEN
                ROUND((COALESCE(sales.total_profit, 0) / COALESCE(sales.total_revenue, 0)) * 100, 2)
            ELSE 0
        END AS profit_margin_percent,
        
        -- Growth metrics (compare with previous period)
        prev_sales.prev_revenue,
        CASE 
            WHEN prev_sales.prev_revenue > 0 THEN
                ROUND(((COALESCE(sales.total_revenue, 0) - prev_sales.prev_revenue) / prev_sales.prev_revenue) * 100, 2)
            ELSE 0
        END AS revenue_growth_percent
        
    FROM categories c
    LEFT JOIN products p ON c.category_id = p.category_id AND p.is_active = TRUE
    LEFT JOIN (
        SELECT 
            cat.category_id,
            SUM(oi.quantity) AS total_units_sold,
            SUM(oi.total_price) AS total_revenue,
            COUNT(DISTINCT oi.order_id) AS total_orders,
            AVG(o.total_amount) AS avg_order_value,
            SUM(oi.total_price - (oi.quantity * prod.cost_price)) AS total_profit
        FROM order_items oi
        JOIN orders o ON oi.order_id = o.order_id
        JOIN products prod ON oi.product_id = prod.product_id
        JOIN categories cat ON prod.category_id = cat.category_id
        WHERE o.order_date >= v_start_date
        AND o.order_status NOT IN ('Cancelled', 'Returned')
        GROUP BY cat.category_id
    ) sales ON c.category_id = sales.category_id
    LEFT JOIN (
        SELECT 
            cat.category_id,
            SUM(oi.total_price) AS prev_revenue
        FROM order_items oi
        JOIN orders o ON oi.order_id = o.order_id
        JOIN products prod ON oi.product_id = prod.product_id
        JOIN categories cat ON prod.category_id = cat.category_id
        WHERE o.order_date >= DATE_SUB(v_start_date, INTERVAL p_period_days DAY)
        AND o.order_date < v_start_date
        AND o.order_status NOT IN ('Cancelled', 'Returned')
        GROUP BY cat.category_id
    ) prev_sales ON c.category_id = prev_sales.category_id
    
    ORDER BY COALESCE(sales.total_revenue, 0) DESC;
END//

-- =====================================================
-- FINANCIAL REPORTING
-- =====================================================

-- Monthly financial summary
CREATE PROCEDURE GetMonthlyFinancialSummary(
    IN p_year INT,
    IN p_month INT
)
BEGIN
    DECLARE v_start_date DATE;
    DECLARE v_end_date DATE;
    
    SET v_start_date = DATE(CONCAT(p_year, '-', LPAD(p_month, 2, '0'), '-01'));
    SET v_end_date = LAST_DAY(v_start_date);
    
    SELECT 
        p_year AS report_year,
        p_month AS report_month,
        MONTHNAME(v_start_date) AS month_name,
        
        -- Order metrics
        COUNT(DISTINCT o.order_id) AS total_orders,
        COUNT(DISTINCT o.customer_id) AS unique_customers,
        
        -- Revenue breakdown
        SUM(o.subtotal) AS gross_revenue,
        SUM(o.discount_amount) AS total_discounts,
        SUM(o.tax_amount) AS total_tax,
        SUM(o.shipping_cost) AS total_shipping,
        SUM(o.total_amount) AS net_revenue,
        
        -- Product metrics
        SUM(oi.quantity) AS total_units_sold,
        AVG(o.total_amount) AS average_order_value,
        
        -- Cost and profit analysis
        SUM(oi.quantity * p.cost_price) AS cost_of_goods_sold,
        SUM(o.total_amount) - SUM(oi.quantity * p.cost_price) AS gross_profit,
        
        CASE 
            WHEN SUM(o.total_amount) > 0 THEN
                ROUND(((SUM(o.total_amount) - SUM(oi.quantity * p.cost_price)) / SUM(o.total_amount)) * 100, 2)
            ELSE 0
        END AS gross_profit_margin_percent,
        
        -- Daily averages
        ROUND(COUNT(DISTINCT o.order_id) / DAY(v_end_date), 1) AS avg_orders_per_day,
        ROUND(SUM(o.total_amount) / DAY(v_end_date), 2) AS avg_revenue_per_day
        
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE DATE(o.order_date) BETWEEN v_start_date AND v_end_date
    AND o.order_status NOT IN ('Cancelled', 'Returned');
END//

DELIMITER ;

-- =====================================================
-- SAMPLE USAGE EXAMPLES
-- =====================================================

/*
-- Analyze customer behavior for all customers (last 90 days)
CALL AnalyzeCustomerBehavior(NULL, 90);

-- Calculate CLV for all customers
CALL CalculateCustomerLifetimeValue(NULL);

-- Perform customer segmentation
CALL PerformCustomerSegmentation();

-- Get sales performance dashboard (last 30 days)
CALL GetSalesPerformanceDashboard(30);

-- Analyze product performance (last 60 days)
CALL AnalyzeProductPerformance(60, NULL);

-- Analyze category performance (last 90 days)
CALL AnalyzeCategoryPerformance(90);

-- Get monthly financial summary for current month
CALL GetMonthlyFinancialSummary(YEAR(CURRENT_DATE), MONTH(CURRENT_DATE));
*/