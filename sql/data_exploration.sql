-- Shipping Operations Analytics | 01 Data Exploration
-- PostgreSQL | Assumes data imported into public.vessel_operations
-- Portfolio sample data only. Run each SELECT independently.

-- 1. Check record count and unique voyage identifiers.
SELECT COUNT(*) AS total_records,
       COUNT(DISTINCT vessel_id) AS unique_vessel_ids
FROM public.vessel_operations;

-- 2. Inspect ports and their record volumes.
SELECT port, COUNT(*) AS vessel_calls
FROM public.vessel_operations
GROUP BY port
ORDER BY vessel_calls DESC, port;

-- 3. Missing reasons: a blank reason is NOT necessarily a delay.
SELECT COUNT(*) AS total_records,
       COUNT(*) FILTER (WHERE delay_reason IS NULL OR BTRIM(delay_reason) = '') AS missing_delay_reason,
       COUNT(*) FILTER (WHERE departure_delay_hours > 0 AND
           (delay_reason IS NULL OR BTRIM(delay_reason) = '')) AS delayed_without_reason
FROM public.vessel_operations;

-- 4. Duplicate voyage IDs, if any.
SELECT vessel_id, COUNT(*) AS occurrences
FROM public.vessel_operations
GROUP BY vessel_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;

-- 5. Check impossible capacity/utilization and negative durations.
SELECT vessel_id, port, yard_capacity, yard_occupancy,
       equipment_available, equipment_used,
       arrival_delay_hours, berth_time_hours, departure_delay_hours
FROM public.vessel_operations
WHERE yard_occupancy > yard_capacity
   OR equipment_used > equipment_available
   OR yard_capacity <= 0 OR equipment_available <= 0
   OR berth_time_hours < 0;

-- 6. Summary distributions by port.
SELECT port,
       COUNT(*) AS vessel_calls,
       ROUND(AVG(arrival_delay_hours)::numeric, 2) AS avg_arrival_delay_hours,
       ROUND(AVG(berth_time_hours)::numeric, 2) AS avg_berth_time_hours,
       ROUND(AVG(departure_delay_hours)::numeric, 2) AS avg_departure_delay_hours
FROM public.vessel_operations
GROUP BY port
ORDER BY avg_departure_delay_hours DESC;
