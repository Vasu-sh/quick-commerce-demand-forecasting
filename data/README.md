# Data setup

This project uses four files from the public [Blinkit Sales Dataset on Kaggle](https://www.kaggle.com/datasets/akxiit/blinkit-sales-dataset):

| CSV file | SQLite table | Key fields used |
|---|---|---|
| `blinkit_products.csv` | `blinkit_products` | `product_id`, `product_name`, `category`, `brand` |
| `blinkit_orders.csv` | `blinkit_orders` | `order_id`, `order_date` |
| `blinkit_order_items.csv` | `blinkit_order_items` | `order_id`, `product_id`, `quantity`, `unit_price` |
| `blinkit_inventory.csv` | `blinkit_inventory` | `product_id`, `date`, `stock_received`, `damaged_stock` |

Raw data is intentionally excluded from this repository. Download it from Kaggle and import the CSVs with headers as column names. Preserve the table names above so the SQL scripts run unchanged.

## Important field notes

- Order timestamps are in an ISO-style format and are converted with SQLite's `DATE()` function.
- Inventory dates use `DD-MM-YYYY` and are explicitly converted to `YYYY-MM-DD` in SQL.
- `quantity × unit_price` should be used for line-level sales analysis. `order_total` does not reconcile to the single order-item row for nearly all orders in this synthetic extract.
- Inventory records show receipts and damages, but no opening balance or authoritative stock-on-hand snapshot. Therefore cumulative net movement is only a proxy—not true current stock.
