-- Run after importing the four source CSVs into SQLite.

-- Row counts
SELECT 'products' AS table_name, COUNT(*) AS row_count FROM blinkit_products
UNION ALL
SELECT 'orders', COUNT(*) FROM blinkit_orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM blinkit_order_items
UNION ALL
SELECT 'inventory', COUNT(*) FROM blinkit_inventory;

-- Date coverage
SELECT
    MIN(DATE(order_date)) AS first_order_date,
    MAX(DATE(order_date)) AS last_order_date,
    CAST(JULIANDAY(MAX(DATE(order_date))) - JULIANDAY(MIN(DATE(order_date))) + 1 AS INTEGER) AS calendar_days
FROM blinkit_orders;

-- Primary-key and relationship checks
SELECT COUNT(*) - COUNT(DISTINCT product_id) AS duplicate_product_ids
FROM blinkit_products;

SELECT COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_order_ids
FROM blinkit_orders;

SELECT COUNT(*) AS orphan_order_items
FROM blinkit_order_items oi
LEFT JOIN blinkit_orders o ON o.order_id = oi.order_id
LEFT JOIN blinkit_products p ON p.product_id = oi.product_id
WHERE o.order_id IS NULL OR p.product_id IS NULL;

-- Inventory caveat: negative cumulative movement suggests opening stock is missing.
WITH inventory_movement AS (
    SELECT
        product_id,
        SUM(stock_received - damaged_stock) AS cumulative_net_movement
    FROM blinkit_inventory
    GROUP BY product_id
)
SELECT COUNT(*) AS products_with_negative_net_movement
FROM inventory_movement
WHERE cumulative_net_movement < 0;
