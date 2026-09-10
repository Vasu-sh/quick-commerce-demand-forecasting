DROP VIEW IF EXISTS v_daily_demand;
DROP VIEW IF EXISTS v_daily_demand_observed;
DROP VIEW IF EXISTS v_daily_inventory;

-- Observed demand at product-day grain.
CREATE VIEW v_daily_demand_observed AS
SELECT
    DATE(o.order_date) AS demand_date,
    oi.product_id,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS gross_item_value
FROM blinkit_orders o
JOIN blinkit_order_items oi
    ON oi.order_id = o.order_id
GROUP BY DATE(o.order_date), oi.product_id;

-- Complete product-date spine. Zero-sale days must exist before using ROWS-based
-- window frames; otherwise seven preceding rows are not seven calendar days.
CREATE VIEW v_daily_demand AS
WITH RECURSIVE
date_bounds AS (
    SELECT
        MIN(DATE(order_date)) AS min_date,
        MAX(DATE(order_date)) AS max_date
    FROM blinkit_orders
),
calendar(demand_date) AS (
    SELECT min_date FROM date_bounds
    UNION ALL
    SELECT DATE(demand_date, '+1 day')
    FROM calendar, date_bounds
    WHERE demand_date < max_date
),
product_calendar AS (
    SELECT
        c.demand_date,
        p.product_id,
        p.product_name,
        p.category,
        p.brand
    FROM calendar c
    CROSS JOIN blinkit_products p
)
SELECT
    pc.demand_date,
    pc.product_id,
    pc.product_name,
    pc.category,
    pc.brand,
    COALESCE(dd.units_sold, 0) AS units_sold,
    COALESCE(dd.gross_item_value, 0.0) AS gross_item_value
FROM product_calendar pc
LEFT JOIN v_daily_demand_observed dd
    ON dd.demand_date = pc.demand_date
   AND dd.product_id = pc.product_id;

-- Daily receipts and damages. Net stock added is an inventory-movement measure;
-- it is not stock on hand without an opening balance and sales depletion ledger.
CREATE VIEW v_daily_inventory AS
SELECT
    product_id,
    DATE(SUBSTR(date, 7, 4) || '-' || SUBSTR(date, 4, 2) || '-' || SUBSTR(date, 1, 2)) AS inventory_date,
    SUM(stock_received) AS stock_received,
    SUM(damaged_stock) AS damaged_stock,
    SUM(stock_received - damaged_stock) AS net_stock_added
FROM blinkit_inventory
GROUP BY product_id, inventory_date;
