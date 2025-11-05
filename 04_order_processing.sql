-- =====================================================
-- INVENTORY AND ORDER MANAGEMENT SYSTEM - ORDER PROCESSING
-- =====================================================
-- This script contains advanced order processing procedures with stock validation,
-- automatic inventory updates, and comprehensive order management

DELIMITER //

-- Drop existing procedures if they exist
DROP PROCEDURE IF EXISTS CreateOrder//
DROP PROCEDURE IF EXISTS AddItemToOrder//
DROP PROCEDURE IF EXISTS RemoveItemFromOrder//
DROP PROCEDURE IF EXISTS UpdateOrderTotals//
DROP PROCEDURE IF EXISTS ConfirmOrder//
DROP PROCEDURE IF EXISTS CancelOrder//
DROP PROCEDURE IF EXISTS UpdateOrderStatus//
DROP PROCEDURE IF EXISTS SearchOrders//

-- =====================================================
-- ORDER PLACEMENT AND PROCESSING
-- =====================================================

-- Create new order with validation
CREATE PROCEDURE CreateOrder(
    IN p_customer_id INT,
    IN p_payment_method ENUM('Credit Card', 'Debit Card', 'PayPal', 'Bank Transfer', 'Cash', 'Other'),
    IN p_shipping_address_line1 VARCHAR(200),
    IN p_shipping_address_line2 VARCHAR(200),
    IN p_shipping_city VARCHAR(50),
    IN p_shipping_state VARCHAR(50),
    IN p_shipping_postal_code VARCHAR(20),
    IN p_shipping_country VARCHAR(50),
    IN p_notes TEXT
)
BEGIN
    DECLARE v_order_id INT;
    DECLARE v_order_number VARCHAR(50);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Validate customer exists and is active
    IF NOT EXISTS (SELECT 1 FROM customers WHERE customer_id = p_customer_id AND is_active = TRUE) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Customer not found or inactive';
    END IF;
    
    -- Generate order number
    SET v_order_number = GenerateOrderNumber();
    
    -- Create the order
    INSERT INTO orders (
        customer_id, order_number, order_status, payment_status, payment_method,
        subtotal, tax_amount, shipping_cost, total_amount,
        shipping_address_line1, shipping_address_line2, shipping_city, 
        shipping_state, shipping_postal_code, shipping_country, notes
    ) VALUES (
        p_customer_id, v_order_number, 'Pending', 'Pending', p_payment_method,
        0.00, 0.00, 0.00, 0.00,
        p_shipping_address_line1, p_shipping_address_line2, p_shipping_city,
        p_shipping_state, p_shipping_postal_code, p_shipping_country, p_notes
    );
    
    SET v_order_id = LAST_INSERT_ID();
    
    COMMIT;
    
    SELECT v_order_id AS order_id, v_order_number AS order_number;
END//

-- Add item to order with stock validation
CREATE PROCEDURE AddItemToOrder(
    IN p_order_id INT,
    IN p_product_id INT,
    IN p_quantity INT,
    IN p_unit_price DECIMAL(10,2),
    IN p_discount_amount DECIMAL(10,2)
)
BEGIN
    DECLARE v_current_stock INT;
    DECLARE v_product_price DECIMAL(10,2);
    DECLARE v_total_price DECIMAL(12,2);
    DECLARE v_order_status VARCHAR(20);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Validate order exists and is in editable state
    SELECT order_status INTO v_order_status 
    FROM orders 
    WHERE order_id = p_order_id;
    
    IF v_order_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order not found';
    END IF;
    
    IF v_order_status NOT IN ('Pending', 'Confirmed') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order cannot be modified in current status';
    END IF;
    
    -- Validate product exists and is active
    SELECT current_stock, price INTO v_current_stock, v_product_price
    FROM products 
    WHERE product_id = p_product_id AND is_active = TRUE;
    
    IF v_current_stock IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product not found or inactive';
    END IF;
    
    -- Validate sufficient stock
    IF v_current_stock < p_quantity THEN
        SET @error_msg = CONCAT('Insufficient stock. Available: ', v_current_stock, ', Requested: ', p_quantity);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @error_msg;
    END IF;
    
    -- Use product price if unit_price is NULL or 0
    IF p_unit_price IS NULL OR p_unit_price = 0 THEN
        SET p_unit_price = v_product_price;
    END IF;
    
    -- Calculate total price
    IF p_discount_amount IS NULL THEN
        SET v_total_price = (p_unit_price * p_quantity);
    ELSE
        SET v_total_price = (p_unit_price * p_quantity) - p_discount_amount;
    END IF;
    
    -- Add item to order
    INSERT INTO order_items (
        order_id, product_id, quantity, unit_price, total_price, discount_amount
    ) VALUES (
        p_order_id, p_product_id, p_quantity, p_unit_price, v_total_price, 
        CASE WHEN p_discount_amount IS NULL THEN 0 ELSE p_discount_amount END
    );
    
    -- Update order totals
    CALL UpdateOrderTotals(p_order_id);
    
    COMMIT;
    
    SELECT LAST_INSERT_ID() AS order_item_id, v_total_price AS item_total;
END//

-- Remove item from order
CREATE PROCEDURE RemoveItemFromOrder(
    IN p_order_item_id INT
)
BEGIN
    DECLARE v_order_id INT;
    DECLARE v_order_status VARCHAR(20);
    DECLARE v_product_id INT;
    DECLARE v_quantity INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Get order info
    SELECT oi.order_id, o.order_status, oi.product_id, oi.quantity
    INTO v_order_id, v_order_status, v_product_id, v_quantity
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    WHERE oi.order_item_id = p_order_item_id;
    
    IF v_order_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order item not found';
    END IF;
    
    IF v_order_status NOT IN ('Pending', 'Confirmed') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order cannot be modified in current status';
    END IF;
    
    -- If order was already processed, restore stock
    IF v_order_status = 'Confirmed' THEN
        UPDATE products 
        SET current_stock = current_stock + v_quantity
        WHERE product_id = v_product_id;
        
        INSERT INTO inventory_changes (
            product_id, change_type, quantity_change, 
            previous_stock, new_stock, reference_type, reference_id,
            reason, performed_by
        ) VALUES (
            v_product_id, 'Stock_In', v_quantity,
            (SELECT current_stock - v_quantity FROM products WHERE product_id = v_product_id),
            (SELECT current_stock FROM products WHERE product_id = v_product_id),
            'Order', v_order_id,
            'Item removed from order', 'System'
        );
    END IF;
    
    -- Remove the item
    DELETE FROM order_items WHERE order_item_id = p_order_item_id;
    
    -- Update order totals
    CALL UpdateOrderTotals(v_order_id);
    
    COMMIT;
    
    SELECT ROW_COUNT() AS affected_rows;
END//

-- Update order totals
CREATE PROCEDURE UpdateOrderTotals(
    IN p_order_id INT
)
BEGIN
    DECLARE v_subtotal DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_tax_rate DECIMAL(5,4) DEFAULT 0.0875; -- 8.75% tax rate
    DECLARE v_shipping_cost DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_tax_amount DECIMAL(10,2);
    DECLARE v_total_amount DECIMAL(12,2);
    
    -- Calculate subtotal
    SELECT SUM(total_price) INTO v_subtotal
    FROM order_items 
    WHERE order_id = p_order_id;
    
    -- Handle NULL case
    IF v_subtotal IS NULL THEN
        SET v_subtotal = 0;
    END IF;
    
    -- Calculate shipping cost based on subtotal
    CASE
        WHEN v_subtotal >= 100 THEN SET v_shipping_cost = 0.00;  -- Free shipping over $100
        WHEN v_subtotal >= 50 THEN SET v_shipping_cost = 5.99;   -- Reduced shipping $50-$99
        ELSE SET v_shipping_cost = 9.99;                         -- Standard shipping under $50
    END CASE;
    
    -- Calculate tax
    SET v_tax_amount = v_subtotal * v_tax_rate;
    
    -- Calculate total
    SET v_total_amount = v_subtotal + v_tax_amount + v_shipping_cost;
    
    -- Update order
    UPDATE orders 
    SET subtotal = v_subtotal,
        tax_amount = v_tax_amount,
        shipping_cost = v_shipping_cost,
        total_amount = v_total_amount,
        updated_at = CURRENT_TIMESTAMP
    WHERE order_id = p_order_id;
END//

-- Confirm order (process payment and reserve stock)
CREATE PROCEDURE ConfirmOrder(
    IN p_order_id INT,
    IN p_payment_method ENUM('Credit Card', 'Debit Card', 'PayPal', 'Bank Transfer', 'Cash', 'Other')
)
BEGIN
    DECLARE v_order_status VARCHAR(20);
    DECLARE v_total_amount DECIMAL(12,2);
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_product_id INT;
    DECLARE v_quantity INT;
    DECLARE v_current_stock INT;
    
    -- Cursor for order items
    DECLARE item_cursor CURSOR FOR 
        SELECT product_id, quantity 
        FROM order_items 
        WHERE order_id = p_order_id;
    
    DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = TRUE;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Validate order
    SELECT order_status, total_amount INTO v_order_status, v_total_amount
    FROM orders 
    WHERE order_id = p_order_id;
    
    IF v_order_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order not found';
    END IF;
    
    IF v_order_status != 'Pending' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order is not in pending status';
    END IF;
    
    IF v_total_amount <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order has no items or invalid total';
    END IF;
    
    -- Validate stock availability for all items
    OPEN item_cursor;
    read_loop: LOOP
        FETCH item_cursor INTO v_product_id, v_quantity;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        SELECT current_stock INTO v_current_stock
        FROM products 
        WHERE product_id = v_product_id;
        
        IF v_current_stock < v_quantity THEN
            SET @error_msg = CONCAT('Insufficient stock for product ID: ', v_product_id);
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @error_msg;
        END IF;
    END LOOP;
    CLOSE item_cursor;
    
    -- Stock validation passed, now process the order
    -- Note: Stock is automatically reduced by the trigger when order_items were inserted
    -- So we just need to update the order status
    
    UPDATE orders 
    SET order_status = 'Confirmed',
        payment_status = 'Paid',
        payment_method = p_payment_method,
        updated_at = CURRENT_TIMESTAMP
    WHERE order_id = p_order_id;
    
    COMMIT;
    
    SELECT 'Order confirmed successfully' AS message, p_order_id AS order_id;
END//

-- Cancel order
CREATE PROCEDURE CancelOrder(
    IN p_order_id INT,
    IN p_cancel_reason TEXT
)
BEGIN
    DECLARE v_order_status VARCHAR(20);
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_product_id INT;
    DECLARE v_quantity INT;
    
    -- Cursor for order items to restore stock
    DECLARE item_cursor CURSOR FOR 
        SELECT product_id, quantity 
        FROM order_items 
        WHERE order_id = p_order_id;
    
    DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = TRUE;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Validate order
    SELECT order_status INTO v_order_status
    FROM orders 
    WHERE order_id = p_order_id;
    
    IF v_order_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order not found';
    END IF;
    
    IF v_order_status IN ('Shipped', 'Delivered', 'Cancelled') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order cannot be cancelled in current status';
    END IF;
    
    -- Restore stock for confirmed orders
    IF v_order_status IN ('Confirmed', 'Processing') THEN
        SET done = FALSE;
        OPEN item_cursor;
        read_loop: LOOP
            FETCH item_cursor INTO v_product_id, v_quantity;
            IF done THEN
                LEAVE read_loop;
            END IF;
            
            -- Restore stock
            UPDATE products 
            SET current_stock = current_stock + v_quantity
            WHERE product_id = v_product_id;
            
            -- Log inventory change
            INSERT INTO inventory_changes (
                product_id, change_type, quantity_change, 
                previous_stock, new_stock, reference_type, reference_id,
                reason, performed_by
            ) VALUES (
                v_product_id, 'Stock_In', v_quantity,
                (SELECT current_stock - v_quantity FROM products WHERE product_id = v_product_id),
                (SELECT current_stock FROM products WHERE product_id = v_product_id),
                'Order', p_order_id,
                CASE 
                    WHEN p_cancel_reason IS NULL THEN 'Order cancelled: No reason provided'
                    ELSE CONCAT('Order cancelled: ', p_cancel_reason)
                END, 'System'
            );
        END LOOP;
        CLOSE item_cursor;
    END IF;
    
    -- Update order status
    UPDATE orders 
    SET order_status = 'Cancelled',
        payment_status = CASE 
            WHEN payment_status = 'Paid' THEN 'Refunded'
            ELSE payment_status
        END,
        notes = CASE 
            WHEN notes IS NULL AND p_cancel_reason IS NULL THEN '\nCancelled: No reason provided'
            WHEN notes IS NULL THEN CONCAT('\nCancelled: ', p_cancel_reason)
            WHEN p_cancel_reason IS NULL THEN CONCAT(notes, '\nCancelled: No reason provided')
            ELSE CONCAT(notes, '\nCancelled: ', p_cancel_reason)
        END,
        updated_at = CURRENT_TIMESTAMP
    WHERE order_id = p_order_id;
    
    COMMIT;
    
    SELECT 'Order cancelled successfully' AS message, p_order_id AS order_id;
END//

-- Update order status
CREATE PROCEDURE UpdateOrderStatus(
    IN p_order_id INT,
    IN p_new_status ENUM('Pending', 'Confirmed', 'Processing', 'Shipped', 'Delivered', 'Cancelled', 'Returned'),
    IN p_tracking_number VARCHAR(100),
    IN p_notes TEXT
)
BEGIN
    DECLARE v_current_status VARCHAR(20);
    
    -- Get current status
    SELECT order_status INTO v_current_status
    FROM orders 
    WHERE order_id = p_order_id;
    
    IF v_current_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order not found';
    END IF;
    
    -- Validate status transition
    CASE v_current_status
        WHEN 'Pending' THEN
            IF p_new_status NOT IN ('Confirmed', 'Cancelled') THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid status transition from Pending';
            END IF;
        WHEN 'Confirmed' THEN
            IF p_new_status NOT IN ('Processing', 'Cancelled') THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid status transition from Confirmed';
            END IF;
        WHEN 'Processing' THEN
            IF p_new_status NOT IN ('Shipped', 'Cancelled') THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid status transition from Processing';
            END IF;
        WHEN 'Shipped' THEN
            IF p_new_status NOT IN ('Delivered', 'Returned') THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid status transition from Shipped';
            END IF;
        WHEN 'Delivered' THEN
            IF p_new_status NOT IN ('Returned') THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid status transition from Delivered';
            END IF;
        ELSE
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order cannot be modified in current status';
    END CASE;
    
    -- Update order
    UPDATE orders 
    SET order_status = p_new_status,
        tracking_number = CASE WHEN p_tracking_number IS NULL THEN tracking_number ELSE p_tracking_number END,
        shipped_date = CASE WHEN p_new_status = 'Shipped' THEN CURRENT_TIMESTAMP ELSE shipped_date END,
        delivered_date = CASE WHEN p_new_status = 'Delivered' THEN CURRENT_TIMESTAMP ELSE delivered_date END,
        notes = CASE 
            WHEN p_notes IS NOT NULL AND notes IS NULL THEN CONCAT('\n', p_notes)
            WHEN p_notes IS NOT NULL AND notes IS NOT NULL THEN CONCAT(notes, '\n', p_notes)
            ELSE notes
        END,
        updated_at = CURRENT_TIMESTAMP
    WHERE order_id = p_order_id;
    
    SELECT 'Order status updated successfully' AS message, 
           p_order_id AS order_id, 
           p_new_status AS new_status;
END//

-- =====================================================
-- ORDER SEARCH AND REPORTING
-- =====================================================

-- Search orders with filters
CREATE PROCEDURE SearchOrders(
    IN p_customer_id INT,
    IN p_order_status VARCHAR(20),
    IN p_payment_status VARCHAR(20),
    IN p_date_from DATE,
    IN p_date_to DATE,
    IN p_min_amount DECIMAL(12,2),
    IN p_max_amount DECIMAL(12,2),
    IN p_limit_results INT
)
BEGIN
    SELECT 
        o.order_id,
        o.order_number,
        o.order_date,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.email AS customer_email,
        o.order_status,
        o.payment_status,
        o.payment_method,
        o.total_amount,
        COUNT(oi.order_item_id) AS total_items,
        o.tracking_number,
        o.shipped_date,
        o.delivered_date
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    LEFT JOIN order_items oi ON o.order_id = oi.order_id
    WHERE 
        (p_customer_id IS NULL OR o.customer_id = p_customer_id)
        AND (p_order_status IS NULL OR o.order_status = p_order_status)
        AND (p_payment_status IS NULL OR o.payment_status = p_payment_status)
        AND (p_date_from IS NULL OR DATE(o.order_date) >= p_date_from)
        AND (p_date_to IS NULL OR DATE(o.order_date) <= p_date_to)
        AND (p_min_amount IS NULL OR o.total_amount >= p_min_amount)
        AND (p_max_amount IS NULL OR o.total_amount <= p_max_amount)
    GROUP BY o.order_id
    ORDER BY o.order_date DESC
    LIMIT 100;
END//

DELIMITER ;

-- =====================================================
-- SAMPLE USAGE EXAMPLES
-- =====================================================

/*
-- Create a new order
CALL CreateOrder(1, 'Credit Card', '123 Main St', NULL, 'New York', 'NY', '10001', 'USA', 'Rush delivery');

-- Add items to order
CALL AddItemToOrder(11, 1, 1, 999.99, 0.00);  -- iPhone 15 Pro
CALL AddItemToOrder(11, 7, 1, 249.99, 10.00); -- AirPods Pro with $10 discount

-- Confirm the order
CALL ConfirmOrder(11, 'Credit Card');

-- Update order status
CALL UpdateOrderStatus(11, 'Processing', NULL, 'Order is being prepared');

-- Search orders
CALL SearchOrders(NULL, 'Confirmed', NULL, NULL, NULL, NULL, NULL, 50);
*/