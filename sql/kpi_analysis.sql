-- Shipping Operations Analytics | 02 Operational KPI Analysis
-- PostgreSQL | Assumes data imported into public.vessel_operations
-- Timestamp fields should be imported as timestamp, or castable timestamp text.

-- 1. Executive summary KPIs.
SELECT COUNT(*) AS total_vessel_calls,
       SUM(container_count) AS total_containers,
       ROUND(AVG(arrival_delay_hours)::numeric, 2) AS avg_arrival_delay_hours,
       ROUND(AVG(berth_time_hours)::numeric, 2) AS avg_berth_time_hours,
       ROUND(AVG(departure_delay_hours)::numeric, 2) AS avg_departure_delay_hours,
       ROUND(AVG(equipment_utilization_pct)::numeric, 2) AS avg_equipment_utilization_pct,
       ROUND(AVG(yard_occupancy_pct)::numeric, 2) AS avg_yard_occupancy_pct
FROM public.vessel_operations;

-- 2. Waiting time from actual arrival to berth start.
-- This is calculated from timestamps; berth_time_hours is time at berth, not waiting time.
SELECT port,
       COUNT(*) AS vessel_calls,
       ROUND(AVG(EXTRACT(EPOCH FROM
           (berth_start::timestamp - actual_arrival::timestamp)) / 3600)::numeric, 2)
           AS avg_pre_berth_wait_hours
FROM public.vessel_operations
WHERE berth_start::timestamp >= actual_arrival::timestamp
GROUP BY port
ORDER BY avg_pre_berth_wait_hours DESC;

-- 3. Port departure delay ranking.
SELECT port,
       COUNT(*) AS vessel_calls,
       ROUND(AVG(departure_delay_hours)::numeric, 2) AS avg_departure_delay_hours,
       ROUND(100.0 * COUNT(*) FILTER (WHERE departure_delay_hours > 0)
           / NULLIF(COUNT(*), 0), 2) AS pct_departures_delayed
FROM public.vessel_operations
GROUP BY port
ORDER BY avg_departure_delay_hours DESC;

-- 4. Departure schedule reliability.
SELECT COUNT(*) FILTER (WHERE actual_departure::timestamp <= scheduled_departure::timestamp)
           AS on_time_or_early,
       COUNT(*) FILTER (WHERE actual_departure::timestamp > scheduled_departure::timestamp)
           AS late_departures,
       ROUND(100.0 * COUNT(*) FILTER
           (WHERE actual_departure::timestamp <= scheduled_departure::timestamp)
           / NULLIF(COUNT(*), 0), 2) AS on_time_pct
FROM public.vessel_operations;

-- 5. Yard occupancy by port.
SELECT port,
       ROUND(AVG(yard_occupancy_pct)::numeric, 2) AS avg_yard_occupancy_pct,
       ROUND(MAX(yard_occupancy_pct)::numeric, 2) AS peak_yard_occupancy_pct
FROM public.vessel_operations
GROUP BY port
ORDER BY avg_yard_occupancy_pct DESC;

-- 6. Customs clearance turnaround time (hours).
SELECT port,
       ROUND(AVG(EXTRACT(EPOCH FROM
           (customs_clearance::timestamp - customs_submission::timestamp)) / 3600)::numeric, 2)
           AS avg_customs_clearance_hours
FROM public.vessel_operations
WHERE customs_clearance::timestamp >= customs_submission::timestamp
GROUP BY port
ORDER BY avg_customs_clearance_hours DESC;
