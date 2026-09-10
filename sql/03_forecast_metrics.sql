DROP VIEW IF EXISTS v_demand_forecast_metrics;

CREATE VIEW v_demand_forecast_metrics AS
WITH base_metrics AS (
    SELECT
        demand_date,
        product_id,
        product_name,
        category,
        brand,
        units_sold,

        -- Because v_daily_demand has a complete date spine, this is exactly 7 days ago.
        LAG(units_sold, 7) OVER (
            PARTITION BY product_id
            ORDER BY demand_date
        ) AS same_weekday_benchmark,

        -- Previous seven days only: current-day demand is excluded to prevent leakage.
        SUM(units_sold) OVER window_7d AS sum_units_7d,
        SUM(units_sold * units_sold) OVER window_7d AS sum_sq_units_7d,
        COUNT(units_sold) OVER window_7d AS count_7d
    FROM v_daily_demand
    WINDOW window_7d AS (
        PARTITION BY product_id
        ORDER BY demand_date
        ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING
    )
)
SELECT
    demand_date,
    product_id,
    product_name,
    category,
    brand,
    units_sold,
    same_weekday_benchmark,
    count_7d AS history_days,

    ROUND(CAST(sum_units_7d AS REAL) / NULLIF(count_7d, 0), 2) AS forecast_7d,
    ROUND(units_sold - (CAST(sum_units_7d AS REAL) / NULLIF(count_7d, 0)), 2) AS forecast_error,

    CASE
        WHEN count_7d > 1 THEN
            ROUND(
                SQRT(
                    MAX(
                        0,
                        (sum_sq_units_7d - (CAST(sum_units_7d * sum_units_7d AS REAL) / count_7d))
                        / (count_7d - 1)
                    )
                ),
                2
            )
        ELSE 0
    END AS sku_volatility_7d
FROM base_metrics;

-- Sample check
SELECT *
FROM v_demand_forecast_metrics
WHERE history_days = 7
ORDER BY demand_date, product_id
LIMIT 20;
