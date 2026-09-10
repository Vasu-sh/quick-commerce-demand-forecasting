-- Portfolio KPI summary
SELECT
    COUNT(*) AS sku_count,
    SUM(stockout_risk_status = 'High Risk') AS high_risk_skus,
    ROUND(100.0 * SUM(stockout_risk_status = 'High Risk') / COUNT(*), 1) AS high_risk_pct,
    SUM(avg_daily_demand > 0) AS skus_with_nonzero_forecast
FROM v_inventory_risk_model;

-- Review queue
SELECT
    product_id,
    product_name,
    category,
    current_stock,
    avg_daily_demand,
    sku_volatility_7d,
    reorder_point,
    stockout_risk_status
FROM v_inventory_risk_model
WHERE stockout_risk_status = 'High Risk'
ORDER BY current_stock ASC;

-- Category profile
SELECT
    category,
    COUNT(*) AS sku_count,
    SUM(stockout_risk_status = 'High Risk') AS high_risk_skus,
    ROUND(AVG(avg_daily_demand), 2) AS avg_latest_daily_demand,
    ROUND(AVG(sku_volatility_7d), 2) AS avg_latest_volatility,
    ROUND(MAX(reorder_point), 2) AS max_reorder_point
FROM v_inventory_risk_model
GROUP BY category
ORDER BY high_risk_skus DESC, max_reorder_point DESC;

-- Forecast backtest after the full seven-day warm-up.
SELECT
    ROUND(AVG(ABS(forecast_error)), 3) AS moving_average_mae,
    ROUND(
        SUM(ABS(forecast_error)) / NULLIF(SUM(units_sold), 0),
        3
    ) AS moving_average_wape,
    ROUND(AVG(ABS(units_sold - same_weekday_benchmark)), 3) AS same_weekday_mae
FROM v_demand_forecast_metrics
WHERE history_days = 7;

-- Highest reorder points for operational prioritization.
SELECT
    product_id,
    product_name,
    category,
    avg_daily_demand,
    sku_volatility_7d,
    safety_stock,
    reorder_point
FROM v_inventory_risk_model
ORDER BY reorder_point DESC
LIMIT 10;
