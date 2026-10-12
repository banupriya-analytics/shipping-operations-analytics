-- Shipping Operations Analytics | 03 Advanced SQL Analysis
-- PostgreSQL | CTEs, ranking, window functions, trends

-- 1. Rank ports by average departure delay (CTE + DENSE_RANK).
WITH port_performance AS (
    SELECT port, COUNT(*) AS vessel_calls,
           ROUND(AVG(departure_delay_hours)::numeric, 2) AS avg_delay_hours
    FROM public.vessel_operations
    GROUP BY port
)
SELECT port, vessel_calls, avg_delay_hours,
       DENSE_RANK() OVER (ORDER BY avg_delay_hours DESC) AS delay_rank
FROM port_performance
ORDER BY delay_rank, port;

-- 2. Monthly departure delay trend and previous month's difference (LAG).
WITH monthly AS (
    SELECT DATE_TRUNC('month', actual_departure::timestamp)::date AS month,
           COUNT(*) AS vessel_calls,
           ROUND(AVG(departure_delay_hours)::numeric, 2) AS avg_delay_hours
    FROM public.vessel_operations
    GROUP BY 1
)
SELECT month, vessel_calls, avg_delay_hours,
       LAG(avg_delay_hours) OVER (ORDER BY month) AS previous_month_avg,
       ROUND(avg_delay_hours - LAG(avg_delay_hours) OVER (ORDER BY month), 2)
           AS change_vs_previous_month
FROM monthly
ORDER BY month;

-- 3. Top 3 highest-delay vessel calls within each port (ROW_NUMBER).
WITH ranked_calls AS (
    SELECT vessel_id, vessel_name, port, departure_delay_hours,
           ROW_NUMBER() OVER (
               PARTITION BY port ORDER BY departure_delay_hours DESC, vessel_id
           ) AS port_rank
    FROM public.vessel_operations
)
SELECT vessel_id, vessel_name, port, departure_delay_hours, port_rank
FROM ranked_calls
WHERE port_rank <= 3
ORDER BY port, port_rank;

-- 4. Documented delay reasons only (exclude unknown, not assume 'No delay').
SELECT delay_reason, COUNT(*) AS vessel_calls,
       ROUND(AVG(departure_delay_hours)::numeric, 2) AS avg_departure_delay_hours
FROM public.vessel_operations
WHERE NULLIF(BTRIM(delay_reason), '') IS NOT NULL
GROUP BY delay_reason
ORDER BY vessel_calls DESC, delay_reason;

-- 5. Compare high vs lower yard occupancy, exploratory association only.
WITH grouped AS (
    SELECT CASE WHEN yard_occupancy_pct >= 80 THEN '80% or higher'
                ELSE 'Below 80%' END AS occupancy_band,
           departure_delay_hours
    FROM public.vessel_operations
)
SELECT occupancy_band, COUNT(*) AS vessel_calls,
       ROUND(AVG(departure_delay_hours)::numeric, 2) AS avg_departure_delay_hours
FROM grouped
GROUP BY occupancy_band
ORDER BY occupancy_band;

-- 6. Identify ports above overall average departure delay (subquery).
SELECT port,
       ROUND(AVG(departure_delay_hours)::numeric, 2) AS port_avg_delay_hours
FROM public.vessel_operations
GROUP BY port
HAVING AVG(departure_delay_hours) > (
    SELECT AVG(departure_delay_hours) FROM public.vessel_operations
)
ORDER BY port_avg_delay_hours DESC;
