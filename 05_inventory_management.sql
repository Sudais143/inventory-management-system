-- =====================================================
-- INVENTORY AND ORDER MANAGEMENT SYSTEM - INVENTORY MANAGEMENT
-- =====================================================
-- Advanced inventory management features including stock monitoring,
-- alerts, replenishment, and comprehensive tracking

DELIMITER //

-- Drop existing procedures if they exist
DROP PROCEDURE IF EXISTS GetStockStatusReport//
DROP PROCEDURE IF EXISTS GenerateStockAlerts//
DROP PROCEDURE IF EXISTS GetInventoryMovementHistory//
DROP PROCEDURE IF EXISTS CalculateInventoryTurnover//
DROP PROCEDURE IF EXISTS GeneratePurchaseRecommendations//
DROP PROCEDURE IF EXISTS ProcessStockReplenishment//
DROP PROCEDURE IF EXISTS PerformABCAnalysis//
DROP PROCEDURE IF EXISTS GetDeadStockAnalysis//

-- =====================================================
-- STOCK MONITORING AND ALERTS
-- =====================================================

-- Get comprehensive stock status report
CREATE PROCEDURE GetStockStatusReport(
    IN p_category_id INT,
    IN p_supplier_id INT,
    IN p_stock_level_filter ENUM('All', 'Low', 'Out', 'Overstocked', 'Normal')
)
BEGIN
    SELECT 
        p.product_id,
        p.product_name,
        p.sku,
        c.category_name,
        s.supplier_name,
        p.current_stock,
        p.reorder_level,
        p.max_stock_level,
        CASE 
            WHEN p.current_stock = 0 THEN 'Out of Stock'
            WHEN p.current_stock <= p.reorder_level THEN 'Low Stock'
            WHEN p.current_stock > p.max_stock_level THEN 'Overstocked'
            ELSE 'Normal'
        END AS stock_status,
        (p.reorder_level - p.current_stock) AS stock_deficit,
        (p.current_stock - p.max_stock_level) AS overstock_amount,
        p.price,
        p.cost_price,
        (p.current_stock * p.cost_price) AS inventory_value,
        -- Calculate suggested reorder quantity
        CASE 
            WHEN p.current_stock <= p.reorder_level 
            THEN p.max_stock_level - p.current_stock
            ELSE 0
        END AS suggested_reorder_qty,
        p.updated_at AS last_updated
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.category_id
    LEFT JOIN suppliers s ON p.supplier_id = s.supplier_id
    WHERE p.is_active = TRUE
    AND (p_category_id IS NULL OR p.category_id = p_category_id)
    AND (p_supplier_id IS NULL OR p.supplier_id = p_supplier_id)
    AND (
        p_stock_level_filter = 'All' OR
        (p_stock_level_filter = 'Low' AND p.current_stock <= p.reorder_level AND p.current_stock > 0) OR
        (p_stock_level_filter = 'Out' AND p.current_stock = 0) OR
        (p_stock_level_filter = 'Overstocked' AND p.current_stock > p.max_stock_level) OR
        (p_stock_level_filter = 'Normal' AND p.current_stock > p.reorder_level AND p.current_stock <= p.max_stock_level)
    )
    ORDER BY 
        CASE 
            WHEN p.current_stock = 0 THEN 1
            WHEN p.current_stock <= p.reorder_level THEN 2
            WHEN p.current_stock > p.max_stock_level THEN 3
            ELSE 4
        END,
        (p.reorder_level - p.current_stock) DESC;
END//

-- Generate stock alerts
CREATE PROCEDURE GenerateStockAlerts()
BEGIN
    -- Critical alerts (out of stock)
    SELECT 
        'CRITICAL' AS alert_level,
        p.product_id,
        p.product_name,
        p.sku,
        c.category_name,
        s.supplier_name,
        s.email AS supplier_email,
        s.phone AS supplier_phone,
        p.current_stock,
        p.reorder_level,
        'OUT OF STOCK - Immediate action required' AS alert_message,
        p.max_stock_level AS suggested_order_qty
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.category_id
    LEFT JOIN suppliers s ON p.supplier_id = s.supplier_id
    WHERE p.current_stock = 0 AND p.is_active = TRUE
    
    UNION ALL
    
    -- Warning alerts (low stock)
    SELECT 
        'WARNING' AS alert_level,
        p.product_id,
        p.product_name,
        p.sku,
        c.category_name,
        s.supplier_name,
        s.email AS supplier_email,
        s.phone AS supplier_phone,
        p.current_stock,
        p.reorder_level,
        CONCAT('LOW STOCK - ', p.current_stock, ' units remaining') AS alert_message,
        (p.max_stock_level - p.current_stock) AS suggested_order_qty
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.category_id
    LEFT JOIN suppliers s ON p.supplier_id = s.supplier_id
    WHERE p.current_stock > 0 AND p.current_stock <= p.reorder_level AND p.is_active = TRUE
    
    UNION ALL
    
    -- Info alerts (overstocked)
    SELECT 
        'INFO' AS alert_level,
        p.product_id,
        p.product_name,
        p.sku,
        c.category_name,
        s.supplier_name,
        s.email AS supplier_email,
        s.phone AS supplier_phone,
        p.current_stock,
        p.max_stock_level,
        CONCAT('OVERSTOCKED - ', (p.current_stock - p.max_stock_level), ' units over maximum') AS alert_message,
        0 AS suggested_order_qty
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.category_id
    LEFT JOIN suppliers s ON p.supplier_id = s.supplier_id
    WHERE p.current_stock > p.max_stock_level AND p.is_active = TRUE
    
    ORDER BY 
        FIELD(alert_level, 'CRITICAL', 'WARNING', 'INFO'),
        product_name;
END//

-- =====================================================
-- INVENTORY MOVEMENTS AND TRACKING
-- =====================================================

-- Get detailed inventory movement history
CREATE PROCEDURE GetInventoryMovementHistory(
    IN p_product_id INT,
    IN p_change_type VARCHAR(20),
    IN p_date_from DATE,
    IN p_date_to DATE,
    IN p_limit_results INT
)
BEGIN
    SELECT 
        ic.change_id,
        ic.created_at AS movement_date,
        p.product_name,
        p.sku,
        ic.change_type,
        ic.quantity_change,
        ic.previous_stock,
        ic.new_stock,
        ic.reference_type,
        ic.reference_id,
        ic.unit_cost,
        ic.total_cost,
        ic.reason,
        ic.performed_by,
        -- Add reference details based on reference_type
        CASE 
            WHEN ic.reference_type = 'Order' THEN 
                (SELECT CONCAT('Order #', o.order_number, ' - ', CONCAT(c.first_name, ' ', c.last_name))
                 FROM orders o 
                 JOIN customers c ON o.customer_id = c.customer_id 
                 WHERE o.order_id = ic.reference_id)
            ELSE CONCAT(ic.reference_type, ' ID: ', 
                CASE WHEN ic.reference_id IS NULL THEN 'N/A' ELSE ic.reference_id END)
        END AS reference_details
    FROM inventory_changes ic
    JOIN products p ON ic.product_id = p.product_id
    WHERE 
        (p_product_id IS NULL OR ic.product_id = p_product_id)
        AND (p_change_type IS NULL OR ic.change_type = p_change_type)
        AND (p_date_from IS NULL OR DATE(ic.created_at) >= p_date_from)
        AND (p_date_to IS NULL OR DATE(ic.created_at) <= p_date_to)
    ORDER BY ic.created_at DESC
    LIMIT 100;
END//

-- Calculate inventory turnover rate
CREATE PROCEDURE CalculateInventoryTurnover(
    IN p_product_id INT,
    IN p_days_period INT
)
BEGIN
    DECLARE v_start_date DATE;
    SET v_start_date = DATE_SUB(CURRENT_DATE, INTERVAL p_days_period DAY);
    
    SELECT 
        p.product_id,
        p.product_name,
        p.sku,
        p.current_stock,
        p.cost_price,
        (p.current_stock * p.cost_price) AS current_inventory_value,
        
        -- Calculate total units sold
        CASE WHEN sales.total_units_sold IS NULL THEN 0 ELSE sales.total_units_sold END AS total_units_sold,
        CASE WHEN sales.total_revenue IS NULL THEN 0 ELSE sales.total_revenue END AS total_revenue,
        CASE WHEN sales.total_cost_of_goods_sold IS NULL THEN 0 ELSE sales.total_cost_of_goods_sold END AS total_cost_of_goods_sold,
        
        -- Calculate average inventory (simplified as current stock)
        p.current_stock AS average_inventory,
        
        -- Calculate turnover ratios
        CASE 
            WHEN p.current_stock > 0 THEN 
                ROUND(CASE WHEN sales.total_units_sold IS NULL THEN 0 ELSE sales.total_units_sold END / p.current_stock, 2)
            ELSE 0
        END AS inventory_turnover_ratio,
        
        -- Calculate days sales in inventory
        CASE 
            WHEN (CASE WHEN sales.total_units_sold IS NULL THEN 0 ELSE sales.total_units_sold END) > 0 THEN 
                ROUND((p.current_stock / ((CASE WHEN sales.total_units_sold IS NULL THEN 0 ELSE sales.total_units_sold END) / p_days_period)), 1)
            ELSE 9999
        END AS days_sales_in_inventory,
        
        -- Performance metrics
        CASE 
            WHEN (CASE WHEN sales.total_units_sold IS NULL THEN 0 ELSE sales.total_units_sold END) = 0 THEN 'No Sales'
            WHEN ((CASE WHEN sales.total_units_sold IS NULL THEN 0 ELSE sales.total_units_sold END) / p_days_period) > (p.current_stock / 30) THEN 'Fast Moving'
            WHEN ((CASE WHEN sales.total_units_sold IS NULL THEN 0 ELSE sales.total_units_sold END) / p_days_period) < (p.current_stock / 90) THEN 'Slow Moving'
            ELSE 'Normal'
        END AS movement_category
        
    FROM products p
    LEFT JOIN (
        SELECT 
            oi.product_id,
            SUM(oi.quantity) AS total_units_sold,
            SUM(oi.total_price) AS total_revenue,
            SUM(oi.quantity * p.cost_price) AS total_cost_of_goods_sold
        FROM order_items oi
        JOIN orders o ON oi.order_id = o.order_id
        JOIN products p ON oi.product_id = p.product_id
        WHERE o.order_status NOT IN ('Cancelled', 'Returned')
        AND DATE(o.order_date) >= v_start_date
        GROUP BY oi.product_id
    ) sales ON p.product_id = sales.product_id
    WHERE 
        (p_product_id IS NULL OR p.product_id = p_product_id)
        AND p.is_active = TRUE
    ORDER BY inventory_turnover_ratio DESC;
END//

-- =====================================================
-- STOCK REPLENISHMENT SYSTEM
-- =====================================================

-- Generate purchase recommendations
CREATE PROCEDURE GeneratePurchaseRecommendations(
    IN p_supplier_id INT,
    IN p_category_id INT
)
BEGIN
    SELECT 
        p.product_id,
        p.product_name,
        p.sku,
        c.category_name,
        s.supplier_name,
        s.contact_person,
        s.email AS supplier_email,
        s.phone AS supplier_phone,
        p.current_stock,
        p.reorder_level,
        p.max_stock_level,
        
        -- Calculate recommended order quantity
        GREATEST(0, p.max_stock_level - p.current_stock) AS recommended_order_qty,
        
        p.cost_price AS unit_cost,
        (GREATEST(0, p.max_stock_level - p.current_stock) * p.cost_price) AS estimated_cost,
        
        -- Priority scoring
        CASE 
            WHEN p.current_stock = 0 THEN 'URGENT'
            WHEN p.current_stock <= (p.reorder_level * 0.5) THEN 'HIGH'
            WHEN p.current_stock <= p.reorder_level THEN 'MEDIUM'
            ELSE 'LOW'
        END AS priority,
        
        -- Sales velocity (last 30 days)
        CASE WHEN recent_sales.units_sold_30d IS NULL THEN 0 ELSE recent_sales.units_sold_30d END AS units_sold_last_30_days,
        
        -- Days until stockout (estimated)
        CASE 
            WHEN (CASE WHEN recent_sales.avg_daily_sales IS NULL THEN 0 ELSE recent_sales.avg_daily_sales END) > 0 THEN
                ROUND(p.current_stock / recent_sales.avg_daily_sales, 1)
            ELSE 9999
        END AS days_until_stockout
        
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.category_id
    LEFT JOIN suppliers s ON p.supplier_id = s.supplier_id
    LEFT JOIN (
        SELECT 
            oi.product_id,
            SUM(oi.quantity) AS units_sold_30d,
            SUM(oi.quantity) / 30.0 AS avg_daily_sales
        FROM order_items oi
        JOIN orders o ON oi.order_id = o.order_id
        WHERE o.order_status NOT IN ('Cancelled', 'Returned')
        AND o.order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)
        GROUP BY oi.product_id
    ) recent_sales ON p.product_id = recent_sales.product_id
    
    WHERE p.is_active = TRUE
    AND p.current_stock <= p.reorder_level
    AND (p_supplier_id IS NULL OR p.supplier_id = p_supplier_id)
    AND (p_category_id IS NULL OR p.category_id = p_category_id)
    
    ORDER BY 
        FIELD(priority, 'URGENT', 'HIGH', 'MEDIUM', 'LOW'),
        days_until_stockout ASC,
        estimated_cost DESC;
END//

-- Process stock replenishment (purchase order)
CREATE PROCEDURE ProcessStockReplenishment(
    IN p_product_id INT,
    IN p_quantity INT,
    IN p_unit_cost DECIMAL(10,2),
    IN p_supplier_reference VARCHAR(100),
    IN p_performed_by VARCHAR(100)
)
BEGIN
    DECLARE v_current_stock INT;
    DECLARE v_new_stock INT;
    DECLARE v_total_cost DECIMAL(12,2);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Validate product exists
    SELECT current_stock INTO v_current_stock
    FROM products 
    WHERE product_id = p_product_id AND is_active = TRUE;
    
    IF v_current_stock IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product not found or inactive';
    END IF;
    
    -- Calculate new stock and total cost
    SET v_new_stock = v_current_stock + p_quantity;
    SET v_total_cost = p_quantity * p_unit_cost;
    
    -- Update product stock
    UPDATE products 
    SET current_stock = v_new_stock,
        updated_at = CURRENT_TIMESTAMP
    WHERE product_id = p_product_id;
    
    -- Log inventory change
    INSERT INTO inventory_changes (
        product_id, change_type, quantity_change, 
        previous_stock, new_stock, reference_type, 
        unit_cost, total_cost, reason, performed_by
    ) VALUES (
        p_product_id, 'Stock_In', p_quantity,
        v_current_stock, v_new_stock, 'Purchase',
        p_unit_cost, v_total_cost,
        CONCAT('Stock replenishment - Supplier Ref: ', 
            CASE WHEN p_supplier_reference IS NULL THEN 'N/A' ELSE p_supplier_reference END),
        p_performed_by
    );
    
    COMMIT;
    
    SELECT 
        'Stock replenishment completed' AS message,
        p_product_id AS product_id,
        v_current_stock AS previous_stock,
        v_new_stock AS new_stock,
        p_quantity AS quantity_added,
        v_total_cost AS total_cost;
END//

-- =====================================================
-- INVENTORY VALUATION AND ANALYSIS
-- =====================================================

-- Calculate ABC analysis for inventory management
CREATE PROCEDURE PerformABCAnalysis(
    IN p_analysis_period_days INT
)
BEGIN
    -- Create temporary table for calculations
    DROP TEMPORARY TABLE IF EXISTS temp_abc_analysis;
    
    CREATE TEMPORARY TABLE temp_abc_analysis AS
    SELECT 
        p.product_id,
        p.product_name,
        p.sku,
        p.current_stock,
        p.cost_price,
        (p.current_stock * p.cost_price) AS inventory_value,
        CASE WHEN sales.total_revenue IS NULL THEN 0 ELSE sales.total_revenue END AS revenue_contribution,
        CASE WHEN sales.total_units_sold IS NULL THEN 0 ELSE sales.total_units_sold END AS units_sold
    FROM products p
    LEFT JOIN (
        SELECT 
            oi.product_id,
            SUM(oi.total_price) AS total_revenue,
            SUM(oi.quantity) AS total_units_sold
        FROM order_items oi
        JOIN orders o ON oi.order_id = o.order_id
        WHERE o.order_status NOT IN ('Cancelled', 'Returned')
        AND o.order_date >= DATE_SUB(CURRENT_DATE, INTERVAL p_analysis_period_days DAY)
        GROUP BY oi.product_id
    ) sales ON p.product_id = sales.product_id
    WHERE p.is_active = TRUE;
    
    -- Calculate percentiles and assign categories
    SELECT 
        product_id,
        product_name,
        sku,
        current_stock,
        inventory_value,
        revenue_contribution,
        units_sold,
        
        -- Calculate cumulative percentage
        ROUND(
            (SUM(revenue_contribution) OVER (ORDER BY revenue_contribution DESC) / 
             SUM(revenue_contribution) OVER ()) * 100, 2
        ) AS cumulative_revenue_percentage,
        
        -- Assign ABC category based on revenue contribution
        CASE 
            WHEN (SUM(revenue_contribution) OVER (ORDER BY revenue_contribution DESC) / 
                  SUM(revenue_contribution) OVER ()) <= 0.8 THEN 'A'
            WHEN (SUM(revenue_contribution) OVER (ORDER BY revenue_contribution DESC) / 
                  SUM(revenue_contribution) OVER ()) <= 0.95 THEN 'B'
            ELSE 'C'
        END AS abc_category,
        
        -- Management recommendations
        CASE 
            WHEN (SUM(revenue_contribution) OVER (ORDER BY revenue_contribution DESC) / 
                  SUM(revenue_contribution) OVER ()) <= 0.8 THEN 
                'High value - Monitor closely, ensure stock availability'
            WHEN (SUM(revenue_contribution) OVER (ORDER BY revenue_contribution DESC) / 
                  SUM(revenue_contribution) OVER ()) <= 0.95 THEN 
                'Medium value - Regular monitoring, standard controls'
            ELSE 'Low value - Simple controls, bulk ordering'
        END AS management_recommendation
        
    FROM temp_abc_analysis
    ORDER BY revenue_contribution DESC;
    
    DROP TEMPORARY TABLE temp_abc_analysis;
END//

-- Get dead stock analysis
CREATE PROCEDURE GetDeadStockAnalysis(
    IN p_no_sales_days INT
)
BEGIN
    SELECT 
        p.product_id,
        p.product_name,
        p.sku,
        c.category_name,
        p.current_stock,
        p.cost_price,
        (p.current_stock * p.cost_price) AS tied_up_capital,
        p.updated_at AS last_stock_update,
        CASE WHEN last_sale.last_sale_date IS NULL THEN 'Never' ELSE last_sale.last_sale_date END AS last_sale_date,
        CASE WHEN DATEDIFF(CURRENT_DATE, last_sale.last_sale_date) IS NULL THEN 9999 ELSE DATEDIFF(CURRENT_DATE, last_sale.last_sale_date) END AS days_since_last_sale,
        
        -- Age category
        CASE 
            WHEN last_sale.last_sale_date IS NULL THEN 'Never Sold'
            WHEN DATEDIFF(CURRENT_DATE, last_sale.last_sale_date) > (p_no_sales_days * 2) THEN 'Dead Stock'
            WHEN DATEDIFF(CURRENT_DATE, last_sale.last_sale_date) > p_no_sales_days THEN 'Slow Moving'
            ELSE 'Active'
        END AS stock_category,
        
        -- Recommendations
        CASE 
            WHEN last_sale.last_sale_date IS NULL THEN 'Consider discontinuing or promoting'
            WHEN DATEDIFF(CURRENT_DATE, last_sale.last_sale_date) > (p_no_sales_days * 2) THEN 'Liquidate or return to supplier'
            WHEN DATEDIFF(CURRENT_DATE, last_sale.last_sale_date) > p_no_sales_days THEN 'Reduce price or promote'
            ELSE 'Normal stock management'
        END AS recommendation
        
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.category_id
    LEFT JOIN (
        SELECT 
            oi.product_id,
            MAX(o.order_date) AS last_sale_date
        FROM order_items oi
        JOIN orders o ON oi.order_id = o.order_id
        WHERE o.order_status NOT IN ('Cancelled', 'Returned')
        GROUP BY oi.product_id
    ) last_sale ON p.product_id = last_sale.product_id
    
    WHERE p.is_active = TRUE
    AND p.current_stock > 0
    AND (
        last_sale.last_sale_date IS NULL OR 
        DATEDIFF(CURRENT_DATE, last_sale.last_sale_date) >= p_no_sales_days
    )
    
    ORDER BY 
        CASE 
            WHEN last_sale.last_sale_date IS NULL THEN 1
            ELSE 2
        END,
        CASE WHEN DATEDIFF(CURRENT_DATE, last_sale.last_sale_date) IS NULL THEN 9999 ELSE DATEDIFF(CURRENT_DATE, last_sale.last_sale_date) END DESC,
        tied_up_capital DESC;
END//

DELIMITER ;

-- =====================================================
-- SAMPLE USAGE EXAMPLES
-- =====================================================

/*
-- Get stock status for all products
CALL GetStockStatusReport(NULL, NULL, 'All');

-- Get only low stock items
CALL GetStockStatusReport(NULL, NULL, 'Low');

-- Generate stock alerts
CALL GenerateStockAlerts();

-- Get inventory movement history for a specific product
CALL GetInventoryMovementHistory(1, NULL, NULL, NULL, 50);

-- Calculate inventory turnover for last 90 days
CALL CalculateInventoryTurnover(NULL, 90);

-- Generate purchase recommendations
CALL GeneratePurchaseRecommendations(NULL, NULL);

-- Process stock replenishment
CALL ProcessStockReplenishment(1, 50, 750.00, 'PO-2024-001', 'Inventory Manager');

-- Perform ABC analysis for last 180 days
CALL PerformABCAnalysis(180);

-- Get dead stock analysis (no sales in 60 days)
CALL GetDeadStockAnalysis(60);
*/