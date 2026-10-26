# Cross-Border D2C Cohort & Customer LTV Engine

A retention and customer lifetime value (LTV) framework built for cross-border e-commerce brands to track cohort decay, repurchase intervals, and customer acquisition payback periods.

## Overview
Evaluating unit economics in direct-to-consumer e-commerce requires isolating repeat behavior from top-of-funnel ad spend. This project uses windowed SQL CTEs and cohort matrices to track customer retention curves and cumulative LTV across international target markets.

## Project Structure
- `cohort_retention_pipeline.sql`: Production SQL CTEs calculating cohort indices, repeat purchase day intervals, and running LTV aggregations.
- `ltv_cohort_engine.py`: Python script simulating 25k+ orders to generate retention tables and benchmark CAC payback horizons.
- `requirements.txt`: Python package dependencies.

## Key Logic & Metrics
1. **Cohort Normalization:** Mapping purchase sequences to relative index periods (`M0, M1, M2...`) from the customer's first completed order.
2. **Repurchase Lag:** Measuring day intervals between orders using windowed `LAG()` to identify repeat purchasing momentum.
3. **Cumulative LTV:** Tracking cumulative revenue contribution per acquired user to assess paid acquisition break-even timelines.

## How to Run
```bash
# Clone the repository
git clone [https://github.com/puneetgoswami1/cross-border-d2c-cohort-ltv-engine.git](https://github.com/puneetgoswami1/cross-border-d2c-cohort-ltv-engine.git)
cd cross-border-d2c-cohort-ltv-engine

# Install dependencies
pip install -r requirements.txt

# Run cohort analysis
python ltv_cohort_engine.py