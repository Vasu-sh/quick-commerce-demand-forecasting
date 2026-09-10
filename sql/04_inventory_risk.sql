DROP VIEW IF EXISTS v_inventory_risk_model;

CREATE VIEW v_inventory_risk_model AS
WITH inventory_proxy AS (
    -- This reproduces the supplied project result. It is cumulative net movement,
    -- not authoritative stock on hand, because opening inventory is unavailable.
    SELECT
        product_id,
        SUM(net_stock_added) AS current_stock
    FROM v_daily_inventory
    GROUP BY product_id
),
latest_demand AS (
    SELECT *
    FROM (
        SELECT
            demand_date,
            product_id,
            product_name,
            category,
            brand,
            forecast_7d AS avg_daily_demand,
            sku_volatility_7d,
            ROW_NUMBER() OVER (
                PARTITION BY product_id
                ORDER BY demand_date DESC
            ) AS rn
        FROM v_demand_forecast_metrics
        WHERE history_days = 7
    )
    WHERE rn = 1
),
policy AS (
    SELECT
        d.*,
        COALESCE(i.current_stock, 0) AS current_stock,
        2 AS lead_time_days,
        1.65 AS service_level_z
    FROM latest_demand d
    LEFT JOIN inventory_proxy i
        ON i.product_id = d.product_id
)
SELECT
    demand_date AS analysis_date,
    product_id,
    product_name,
    category,
    brand,
    current_stock,
    avg_daily_demand,
    sku_volatility_7d,
    lead_time_days,
    ROUND(service_level_z * sku_volatility_7d * SQRT(lead_time_days), 2) AS safety_stock,
    ROUND(
        (avg_daily_demand * lead_time_days)
        + (service_level_z * sku_volatility_7d * SQRT(lead_time_days)),
        2
    ) AS reorder_point,
    CASE
        WHEN current_stock <= ROUND(
            (avg_daily_demand * lead_time_days)
            + (service_level_z * sku_volatility_7d * SQRT(lead_time_days)),
            2
        ) THEN 'High Risk'
        ELSE 'Healthy'
    END AS stockout_risk_status
FROM policy;

SELECT *
FROM v_inventory_risk_model
ORDER BY stockout_risk_status DESC, reorder_point DESC;
