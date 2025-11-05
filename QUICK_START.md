# Quick Start Guide - Inventory and Order Management System

## Overview
This quick start guide will help you get the Inventory and Order Management System up and running in minutes.

## Prerequisites
- MySQL 8.0 or higher
- Database user with CREATE, INSERT, UPDATE, DELETE privileges

## Installation (5 minutes)

### Step 1: Create Database
```sql
CREATE DATABASE inventory_management;
USE inventory_management;
```

### Step 2: Execute Scripts in Order
```bash
# Run these files in sequence:
mysql -u your_username -p inventory_management < 01_database_schema.sql
mysql -u your_username -p inventory_management < 02_sample_data.sql
mysql -u your_username -p inventory_management < 03_core_operations.sql
mysql -u your_username -p inventory_management < 04_order_processing.sql
mysql -u your_username -p inventory_management < 05_inventory_management.sql
mysql -u your_username -p inventory_management < 06_business_analytics.sql
mysql -u your_username -p inventory_management < 07_advanced_features.sql
```

### Step 3: Verify Installation
```sql
-- Check if tables were created
SHOW TABLES;

-- Verify sample data
SELECT COUNT(*) as product_count FROM products;
SELECT COUNT(*) as customer_count FROM customers;
SELECT COUNT(*) as order_count FROM orders;
```

## Quick Demo (2 minutes)

### Run the Complete Demo
```sql
SOURCE 08_demo_script.sql;
```

## Essential Operations

### 1. Check Current Inventory Status
```sql
-- View all low stock products
SELECT * FROM low_stock_products;

-- Get stock alerts
CALL GenerateStockAlerts();
```

### 2. Process a New Order
```sql
-- Create order for customer ID 1
CALL CreateOrder(1, 'Credit Card', '123 Main St', NULL, 'City', 'State', '12345', 'USA', 'Rush order');

-- Add items (replace 11 with actual order_id returned above)
CALL AddItemToOrder(11, 1, 2, 999.99, 0.00);  -- 2 iPhones
CALL AddItemToOrder(11, 7, 1, 249.99, 0.00);  -- 1 AirPods

-- Confirm the order
CALL ConfirmOrder(11, 'Credit Card');
```

### 3. View Business Analytics
```sql
-- Sales performance (last 30 days)
CALL GetSalesPerformanceDashboard(30);

-- Customer segments
CALL PerformCustomerSegmentation();

-- Top products
SELECT * FROM product_performance ORDER BY total_revenue DESC LIMIT 10;
```

### 4. Inventory Management
```sql
-- Restock products
CALL ProcessStockReplenishment(1, 50, 750.00, 'PO-001', 'Manager');

-- Get purchase recommendations
CALL GeneratePurchaseRecommendations(NULL, NULL);
```

## Key Features at a Glance

| Feature | SQL Command | Description |
|---------|-------------|-------------|
| **Product Search** | `CALL SearchProducts('iPhone', NULL, TRUE, TRUE)` | Find products by name |
| **Customer Analysis** | `CALL AnalyzeCustomerBehavior(NULL, 90)` | Analyze customer behavior |
| **Order Processing** | `CALL CreateOrder(...)` | Create new orders |
| **Stock Alerts** | `CALL GenerateStockAlerts()` | Get low stock alerts |
| **Sales Report** | `CALL GetSalesPerformanceDashboard(30)` | 30-day sales performance |
| **Forecasting** | `CALL ForecastDemand(1, 6)` | 6-month demand forecast |

## Useful Views

```sql
-- Pre-built views for common queries
SELECT * FROM low_stock_products;           -- Products needing reorder
SELECT * FROM customer_order_summary;       -- Customer purchase summary
SELECT * FROM product_performance;          -- Product sales performance
```

## Troubleshooting

### Common Issues

1. **"Table doesn't exist" error**
   - Ensure scripts were run in the correct order
   - Check database connection

2. **"Insufficient stock" error**
   - Check current stock: `SELECT current_stock FROM products WHERE product_id = X`
   - Replenish stock: `CALL ProcessStockReplenishment(...)`

3. **Performance issues**
   - Run: `ANALYZE TABLE products, customers, orders, order_items;`

## Next Steps

1. **Customize the system**: Modify categories, suppliers, and products for your business
2. **Set up automated reports**: Use the analytics procedures for regular reporting
3. **Implement alerts**: Set up monitoring for low stock and order processing
4. **Scale the system**: Add more products, customers, and suppliers

## Support Files

- **README.md**: Complete documentation
- **08_demo_script.sql**: Comprehensive system demonstration
- **SQL files**: All system components and features

## Quick Reference

### Core Tables
- `products`: Product catalog and inventory
- `customers`: Customer information
- `orders`: Order headers
- `order_items`: Order line items
- `inventory_changes`: Stock movement audit trail

### Key Procedures
- **Product Management**: `AddProduct`, `SearchProducts`, `AdjustProductStock`
- **Order Processing**: `CreateOrder`, `AddItemToOrder`, `ConfirmOrder`
- **Analytics**: `GetSalesPerformanceDashboard`, `AnalyzeCustomerBehavior`
- **Inventory**: `GenerateStockAlerts`, `ProcessStockReplenishment`

You're now ready to start using the Inventory and Order Management System!