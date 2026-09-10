# Quick-Commerce Demand Forecasting & Inventory Risk Analysis

An end-to-end SQLite portfolio project inspired by Blinkit's quick-commerce operating model. It converts order, product, and inventory movement data into daily SKU demand, a seven-day demand forecast, safety stock, reorder points, and a replenishment-risk flag.

> **Portfolio disclaimer:** This is an independent analysis of a public synthetic dataset. It is not affiliated with, endorsed by, or based on internal data from Blinkit or Eternal Limited.

## Business question

Which SKUs need replenishment attention, and how can a simple, explainable policy separate demand risk from inventory noise?

## Headline results

| Metric | Result |
|---|---:|
| Analysis period | 16 Mar 2023–4 Nov 2024 (600 days) |
| Products analyzed | 268 SKUs across 11 categories |
| SKUs flagged for review | 3 (1.1%) |
| Category containing all flags | Household Care |
| SKUs with non-zero latest 7-day forecast | 52 (19.4%) |
| Highest calculated reorder point | 5.38 units |

The three flags are **review signals, not confirmed live stockouts**. Each was driven by a negative cumulative inventory-movement proxy. The source lacks opening inventory balances and point-in-time stock snapshots, so operational stock-on-hand cannot be reconstructed reliably.

## Method

1. Join orders to order items and products, then aggregate quantity into daily SKU demand.
2. Build a complete product-date grid so zero-sale days are retained. Without this step, `LAG(..., 7)` would mean seven observations ago—not necessarily seven calendar days ago.
3. Forecast demand with the mean of the prior seven calendar days, excluding the current day.
4. Estimate rolling demand volatility using the seven-day sample standard deviation.
5. Apply an illustrative inventory policy:

   `Safety stock = 1.65 × demand volatility × √lead time`

   `Reorder point = average daily demand × lead time + safety stock`

6. Flag an SKU when its inventory proxy is at or below the reorder point.

The policy assumes a two-day lead time and an approximately 95% one-sided service level. Both are scenario inputs because supplier lead times and target service levels are absent from the dataset.

## Repository structure

```text
.
├── data/
│   └── README.md
├── docs/
│   └── decision-memo.md
├── results/
│   └── inventory_risk_results.csv
└── sql/
    ├── 01_data_audit.sql
    ├── 02_daily_views.sql
    ├── 03_forecast_metrics.sql
    ├── 04_inventory_risk.sql
    └── 05_analysis_queries.sql
```

## How to run

1. Download the source files listed in [`data/README.md`](data/README.md).
2. Import the four CSVs into SQLite using the exact table names shown there.
3. Run the SQL files in numerical order.
4. Export the final view:

```sql
SELECT *
FROM v_inventory_risk_model
ORDER BY stockout_risk_status DESC, reorder_point DESC;
```

The project uses SQLite window functions and math functions. A recent SQLite build is recommended.

## What the result says—and does not say

- The final export contains three risk flags, all in Household Care.
- The latest seven-day window is sparse: 216 of 268 SKUs have a zero forecast. This makes a short moving average easy to explain but weak for intermittent demand.
- The model is useful as a prototype for prioritization. It should not be deployed until actual opening stock, stock snapshots, supplier lead times, and lost-sales/cancellation signals are available.
- A production next step would compare this model against a same-weekday baseline on a holdout period using MAE/WAPE, then test a longer horizon or an intermittent-demand method.

## Tools and skills demonstrated

- **SQL:** joins, CTEs, recursive date spine, aggregation, window functions, rolling statistics, conditional logic
- **Inventory analytics:** safety stock, reorder point, service-level assumptions, replenishment prioritization
- **Program management:** problem framing, assumption management, decision rules, and operational recommendations

## Resume bullet

> Analyzed 600 days of quick-commerce data across 268 SKUs in SQLite; built a zero-filled daily demand spine, seven-day rolling forecast, volatility-based safety stock, and reorder-point model, identifying 3 replenishment review signals while documenting inventory-data limitations.

## License

The SQL and documentation in this repository are released under the MIT License. The source dataset is not redistributed here and remains subject to its publisher's terms.
