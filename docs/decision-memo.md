# Decision memo: replenishment risk prototype

## Decision

Use the model as a **daily review queue prototype**, not an automated replenishment engine.

## Evidence

- 3 of 268 SKUs were flagged in the supplied export; all three are Household Care products.
- Those flags were caused by negative cumulative net inventory movement, not by high recent demand.
- Only 52 SKUs had a non-zero forecast on the final analysis date, showing that the seven-day series is highly intermittent.

## Recommendation

1. Investigate the three negative-balance records and repair the inventory ledger logic.
2. Add opening inventory and daily closing-stock snapshots before treating the flag as stockout risk.
3. Backtest the seven-day moving average against the same-weekday benchmark using MAE and WAPE.
4. Test a 28-day horizon or an intermittent-demand method for sparse SKUs.
5. Automate only after defining category-specific lead times, service levels, and review ownership.

## Why this matters for an APM

The central program decision is not whether the SQL runs; it is whether the output is trustworthy enough to drive an operational action. The prototype exposes both a candidate prioritization rule and the data contracts required before scaling it.
