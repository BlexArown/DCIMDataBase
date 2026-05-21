
SELECT
    dc.name                            AS datacenter,
    r.label                            AS rack,
    s.hostname,
    s.manufacturer || ' ' || s.model   AS hardware,
    s.cpu_cores,
    s.ram_gb,
    s.storage_tb,
    s.status,
    s.installed_at
FROM servers s
JOIN racks r        ON r.id = s.rack_id
JOIN datacenters dc ON dc.id = r.datacenter_id
ORDER BY dc.name, r.label, s.rack_unit_position;

SELECT
    s.hostname,
    s.status,
    s.manufacturer || ' ' || s.model AS hardware,
    e.full_name                      AS responsible_engineer
FROM servers s
LEFT JOIN employees e ON e.id = s.assigned_engineer
WHERE s.status IN ('maintenance', 'reserved')
ORDER BY s.status, s.hostname;

SELECT
    i.id,
    i.severity,
    i.title,
    s.hostname                         AS affected_server,
    rep.full_name                      AS reported_by,
    COALESCE(asgn.full_name, '—')      AS assigned_to,
    i.created_at
FROM incidents i
JOIN servers   s    ON s.id = i.server_id
JOIN employees rep  ON rep.id = i.reported_by
LEFT JOIN employees asgn ON asgn.id = i.assigned_to
WHERE i.status IN ('open', 'in_progress')
ORDER BY
    CASE i.severity
        WHEN 'critical' THEN 1
        WHEN 'high'     THEN 2
        WHEN 'medium'   THEN 3
        ELSE 4
    END,
    i.created_at;

SELECT
    dc.name          AS datacenter,
    s.status,
    COUNT(*)         AS server_count
FROM servers s
JOIN racks r        ON r.id = s.rack_id
JOIN datacenters dc ON dc.id = r.datacenter_id
GROUP BY dc.name, s.status
ORDER BY dc.name, s.status;

SELECT
    dc.name                       AS datacenter,
    r.label                       AS rack,
    r.max_power_w                 AS rack_limit_w,
    SUM(s.power_w)                AS used_power_w,
    ROUND(SUM(s.power_w)::NUMERIC / r.max_power_w * 100, 1) AS load_pct
FROM servers s
JOIN racks r        ON r.id = s.rack_id
JOIN datacenters dc ON dc.id = r.datacenter_id
WHERE s.status = 'active'
GROUP BY dc.name, r.label, r.max_power_w
HAVING SUM(s.power_w) > 1500
ORDER BY load_pct DESC;

SELECT
    severity,
    COUNT(*)                                      AS total_incidents,
    ROUND(AVG(EXTRACT(EPOCH FROM (resolved_at - created_at))/3600)::NUMERIC, 2)
                                                  AS avg_resolution_hours
FROM incidents
WHERE status IN ('resolved', 'closed')
  AND resolved_at IS NOT NULL
GROUP BY severity
ORDER BY
    CASE severity
        WHEN 'critical' THEN 1
        WHEN 'high'     THEN 2
        WHEN 'medium'   THEN 3
        ELSE 4
    END;

WITH incident_counts AS (
    SELECT
        s.id,
        s.hostname,
        s.manufacturer || ' ' || s.model AS hardware,
        COUNT(i.id)                       AS incident_count,
        SUM(CASE WHEN i.severity = 'critical' THEN 1 ELSE 0 END) AS critical_count
    FROM servers s
    LEFT JOIN incidents i ON i.server_id = s.id
    GROUP BY s.id, s.hostname, s.manufacturer, s.model
)
SELECT
    hostname,
    hardware,
    incident_count,
    critical_count
FROM incident_counts
ORDER BY incident_count DESC, critical_count DESC
LIMIT 3;

SELECT DISTINCT
    svc.name             AS service,
    svc.service_type,
    svc.status,
    srv.hostname         AS host
FROM services svc
JOIN servers srv ON srv.id = svc.server_id
WHERE svc.id IN (
    SELECT is2.service_id
    FROM incident_services is2
    JOIN incidents i ON i.id = is2.incident_id
    WHERE i.severity IN ('critical', 'high')
)
ORDER BY svc.service_type, svc.name;

SELECT
    ml.performed_at,
    s.hostname,
    e.full_name  AS technician,
    ml.action,
    ml.notes
FROM maintenance_logs ml
JOIN servers   s ON s.id = ml.server_id
JOIN employees e ON e.id = ml.performed_by
ORDER BY ml.performed_at DESC
LIMIT 5;

SELECT
    dc.name                       AS datacenter,
    dc.tier_level,
    COUNT(s.id)                   AS active_servers,
    SUM(s.ram_gb)                 AS total_ram_gb,
    ROUND(AVG(s.ram_gb)::NUMERIC, 1) AS avg_ram_gb,
    SUM(s.cpu_cores)              AS total_cpu_cores
FROM servers s
JOIN racks r        ON r.id = s.rack_id
JOIN datacenters dc ON dc.id = r.datacenter_id
WHERE s.status = 'active'
GROUP BY dc.name, dc.tier_level
ORDER BY total_ram_gb DESC;

SELECT 
    dc.name AS dc_name, 
    s.hostname, 
    s.ram_gb,
    DENSE_RANK() OVER (PARTITION BY dc.id ORDER BY s.ram_gb DESC) as ram_rank
FROM servers s
JOIN racks r ON r.id = s.rack_id
JOIN datacenters dc ON dc.id = r.datacenter_id;

WITH incident_duration AS (
    SELECT 
        id, 
        server_id, 
        EXTRACT(EPOCH FROM (resolved_at - created_at))/3600 AS actual_hours
    FROM incidents 
    WHERE status = 'resolved' AND resolved_at IS NOT NULL
)
SELECT 
    s.hostname, 
    v.name AS vendor_name, 
    c.contract_number, 
    ROUND(idr.actual_hours::NUMERIC, 1) AS hours_taken, 
    c.sla_hours AS promised_sla
FROM incident_duration idr
JOIN servers s ON s.id = idr.server_id
JOIN contracts c ON c.id = s.contract_id
JOIN vendors v ON v.id = c.vendor_id
WHERE idr.actual_hours > c.sla_hours;

SELECT s.hostname, ip.ip_address, ip.subnet, ip.ip_type, ip.is_vip
FROM ip_addresses ip
JOIN servers s ON s.id = ip.server_id
WHERE ip.ip_type = 'public' OR ip.is_vip = TRUE;

SELECT s.hostname, sc.component_type, sc.model, sc.serial_number, sc.status
FROM server_components sc
JOIN servers s ON s.id = sc.server_id
WHERE sc.status = 'failed';

SELECT 
    r.label AS rack_label, 
    cl.recorded_at, 
    cl.temperature_c,
    ROUND(AVG(cl.temperature_c) OVER (
        PARTITION BY cl.rack_id 
        ORDER BY cl.recorded_at 
        ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
    ), 2) AS sliding_avg_temperature
FROM rack_climate_metrics cl
JOIN racks r ON r.id = cl.rack_id;

SELECT 
    service_type,
    COUNT(*) FILTER (WHERE status = 'running')  AS running_count,
    COUNT(*) FILTER (WHERE status = 'degraded') AS degraded_count,
    COUNT(*) FILTER (WHERE status = 'stopped')  AS stopped_count
FROM services
GROUP BY service_type;

SELECT s.hostname, COUNT(sc.id) AS active_psu_count
FROM servers s
LEFT JOIN server_components sc ON s.id = sc.server_id AND sc.component_type = 'PSU' AND sc.status = 'healthy'
GROUP BY s.id, s.hostname
HAVING COUNT(sc.id) < 2;

SELECT e.full_name, e.role, COUNT(i.id) AS resolved_incidents_count
FROM employees e
JOIN incidents i ON e.id = i.assigned_to
WHERE i.status IN ('resolved', 'closed')
GROUP BY e.id, e.full_name, e.role
ORDER BY resolved_incidents_count DESC
LIMIT 1;

SELECT v.name AS vendor, c.contract_number, c.end_date, 
       (c.end_date - CURRENT_DATE) AS days_until_expiration
FROM contracts c
JOIN vendors v ON v.id = c.vendor_id
WHERE c.end_date - CURRENT_DATE < 365;

SELECT up.created_at, e.full_name AS technical_author, up.update_text, up.status_state
FROM incident_updates up
JOIN employees e ON e.id = up.author_id
WHERE up.incident_id = 5
ORDER BY up.created_at ASC;
