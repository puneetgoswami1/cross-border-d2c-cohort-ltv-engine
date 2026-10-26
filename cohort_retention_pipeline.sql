-- Cross-Border D2C Cohort Retention & Repurchase Cycle Pipeline
-- Computes customer acquisition cohorts, repurchase intervals, and cumulative gross revenue.

WITH customer_first_orders AS (
    SELECT 
        customer_id,
        MIN(order_date) AS first_order_date,
        DATE_TRUNC('month', MIN(order_date)) AS cohort_month,
        MIN(destination_country) AS acquisition_market
    FROM international_store.orders
    WHERE order_status = 'DELIVERED'
    GROUP BY customer_id
),

order_sequence_with_intervals AS (
    SELECT 
        o.order_id,
        o.customer_id,
        o.order_date,
        o.net_sales_usd,
        o.destination_country,
        c.cohort_month,
        c.acquisition_market,
        
        -- Days elapsed between consecutive purchases
        EXTRACT(DAY FROM (o.order_date - LAG(o.order_date, 1) OVER (
            PARTITION BY o.customer_id 
            ORDER BY o.order_date
        ))) AS days_since_last_order,

        -- Cohort Index (0 = acquisition month, 1 = month 1, etc.)
        (EXTRACT(YEAR FROM o.order_date) - EXTRACT(YEAR FROM c.cohort_month)) * 12 +
        (EXTRACT(MONTH FROM o.order_date) - EXTRACT(MONTH FROM c.cohort_month)) AS cohort_index
    FROM international_store.orders o
    JOIN customer_first_orders c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'DELIVERED'
),

cohort_matrix_aggregates AS (
    SELECT 
        cohort_month,
        acquisition_market,
        cohort_index,
        COUNT(DISTINCT customer_id) AS retained_customers,
        SUM(net_sales_usd) AS cohort_monthly_revenue,
        ROUND(AVG(net_sales_usd), 2) AS avg_order_value_usd,
        ROUND(AVG(days_since_last_order), 1) AS avg_repurchase_cycle_days
    FROM order_sequence_with_intervals
    GROUP BY cohort_month, acquisition_market, cohort_index
)

SELECT 
    cohort_month,
    acquisition_market,
    cohort_index,
    retained_customers,
    cohort_monthly_revenue,
    avg_order_value_usd,
    avg_repurchase_cycle_days,
    -- Retention percentage relative to Month 0 base size
    ROUND(
        (retained_customers * 100.0) / 
        FIRST_VALUE(retained_customers) OVER (
            PARTITION BY cohort_month, acquisition_market 
            ORDER BY cohort_index
        ), 2
    ) AS retention_rate_pct,
    -- Running cumulative revenue (Customer LTV trajectory)
    SUM(cohort_monthly_revenue) OVER (
        PARTITION BY cohort_month, acquisition_market 
        ORDER BY cohort_index 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_ltv_revenue_usd
FROM cohort_matrix_aggregates
ORDER BY cohort_month DESC, acquisition_market, cohort_index;