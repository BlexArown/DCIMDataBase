
INSERT INTO datacenters (name, location, tier_level, total_power_kw, contact_email) VALUES
('DC-Alpha',  'Москва, ул. Складочная 1',   3, 2400.00, 'ops@dc-alpha.ru'),
('DC-Beta',   'Санкт-Петербург, Пулково',   4, 5000.00, 'ops@dc-beta.ru'),
('DC-Gamma',  'Новосибирск, Академгородок', 2,  800.00, 'ops@dc-gamma.ru');

INSERT INTO racks (datacenter_id, label, row_label, position, max_units, max_power_w) VALUES
(1, 'A-01', 'A', 1, 42, 8000),
(1, 'A-02', 'A', 2, 42, 8000),
(1, 'B-01', 'B', 1, 42, 10000),
(2, 'R-01', 'R', 1, 47, 12000),
(2, 'R-02', 'R', 2, 47, 12000),
(3, 'Z-01', 'Z', 1, 42, 6000);

INSERT INTO employees (full_name, email, phone, role) VALUES
('Алексей Петров',    'a.petrov@corp.ru',    '+74951110001', 'engineer'),
('Мария Соколова',    'm.sokolova@corp.ru',  '+74951110002', 'admin'),
('Дмитрий Иванов',   'd.ivanov@corp.ru',    '+74951110003', 'noc_operator'),
('Ольга Новикова',   'o.novikova@corp.ru',  '+74951110004', 'manager'),
('Сергей Кузнецов',  's.kuznetson@corp.ru', '+74951110005', 'engineer'),
('Татьяна Морозова', 't.morozova@corp.ru',  '+74951110006', 'noc_operator'),
('Виктор Волков',    'v.volkov@corp.ru',    '+74951110007', 'security'),
('Наталья Лебедева', 'n.lebedeva@corp.ru',  '+74951110008', 'engineer');

INSERT INTO vendors (name, support_email, support_phone) VALUES
('YADRO (КНС Групп)', 'support@yadro.ru', '+74957778899'),
('Элтекс (Eltex)', 'tech@eltex-co.ru', '+73833350000'),
('Булат', 'support@bulat.ru', '+74951234567'),
('Т-Ком', 'info@t-kom.ru', '+74959998877');

INSERT INTO contracts (vendor_id, contract_number, start_date, end_date, sla_hours) VALUES
(1, 'CTR-YADRO-2024-01', '2024-01-01', '2027-01-01', 4),
(2, 'CTR-ELTEX-2024-11', '2024-05-15', '2026-05-15', 8),
(3, 'CTR-BULAT-2025-09', '2025-01-10', '2026-01-10', 12);

INSERT INTO servers (rack_id, contract_id, serial_number, hostname, manufacturer, model,
                     status, cpu_cores, ram_gb, storage_tb, power_w,
                     rack_unit_position, rack_units_height, installed_at, assigned_engineer) VALUES
(1, 1,    'SN-DELL-001', 'srv-web-01',   'YADRO',    'VEGMAN S220',     'active',        32, 256,  3.84, 750,  1, 2, '2022-03-15', 1),
(1, 1,    'SN-DELL-002', 'srv-web-02',   'YADRO',    'VEGMAN S220',     'active',        32, 256,  3.84, 750,  3, 2, '2022-03-15', 1),
(1, NULL, 'SN-HP-001',   'srv-db-01',    'HPE',      'ProLiant DL380',  'active',        64, 512, 15.36, 1200, 5, 2, '2021-11-01', 5),
(2, NULL, 'SN-HP-002',   'srv-db-02',    'HPE',      'ProLiant DL380',  'active',        64, 512, 15.36, 1200, 1, 2, '2021-11-01', 5),
(2, 2,    'SN-SUP-001',  'srv-cache-01', 'Eltex',    'CSR-240G',        'active',        16, 128,  1.92, 500,  3, 1, '2023-01-20', 8),
(3, 1,    'SN-DELL-003', 'srv-api-01',   'YADRO',    'VEGMAN R120',     'active',        24, 192,  7.68, 600,  1, 2, '2023-06-10', 1),
(3, NULL, 'SN-DELL-004', 'srv-mon-01',   'Dell',     'PowerEdge R350',  'maintenance',   8,  64,  1.92, 300,  3, 1, '2020-09-05', 8),
(4, 3,    'SN-LEN-001',  'srv-vpn-01',   'Булат',    'БС-202',          'active',        16, 128,  3.84, 550,  1, 2, '2022-07-18', 5),
(4, 3,    'SN-LEN-002',  'srv-stor-01',  'Булат',    'БС-404',          'active',        64,1024, 92.16,1600,  3, 4, '2021-05-30', 5),
(5, 2,    'SN-HP-003',   'srv-dns-01',   'Eltex',    'CSR-100',         'active',         4,  32,  0.96, 200,  1, 1, '2023-09-01', 8),
(5, 1,    'SN-DELL-005', 'srv-bkp-01',   'YADRO',    'TATLIN.ARCHIVE',  'active',        16, 128, 48.00, 400,  2, 2, '2022-12-12', 1),
(6, NULL, 'SN-SUP-002',  'srv-test-01',  'Supermicro','SuperServer 220P','reserved',   32, 256,  7.68, 700,  1, 2, '2024-01-10', 8);

INSERT INTO server_components (server_id, component_type, model, serial_number, capacity_gb, status) VALUES
(1, 'CPU', 'Intel Xeon Gold 6330', 'CPU-YAD-001', NULL, 'healthy'),
(1, 'RAM', 'Samsung DDR4 ECC', 'RAM-SAM-101', 64, 'healthy'),
(1, 'RAM', 'Samsung DDR4 ECC', 'RAM-SAM-102', 64, 'healthy'),
(1, 'PSU', 'Delta Electronics 800W', 'PSU-DEL-011', NULL, 'healthy'),
(1, 'PSU', 'Delta Electronics 800W', 'PSU-DEL-012', NULL, 'failed'), 
(3, 'HDD', 'Seagate Enterprise SAS', 'HDD-SEA-091', 8000, 'healthy'),
(9, 'SSD', 'Crucial NVMe Gen4', 'SSD-CRU-882', 2000, 'healthy');

INSERT INTO ip_addresses (server_id, ip_address, subnet, ip_type, is_vip) VALUES
(1, '10.100.1.11', '10.100.1.0/24', 'production', false),
(1, '192.168.50.11', '192.168.50.0/24', 'management', false),
(2, '10.100.1.12', '10.100.1.0/24', 'production', false),
(3, '10.100.2.21', '10.100.2.0/24', 'production', false),
(4, '10.100.2.22', '10.100.2.0/24', 'production', false),
(9, '85.249.10.45', '85.249.10.0/28', 'public', false),
(9, '85.249.10.50', '85.249.10.0/28', 'public', true); 

INSERT INTO rack_climate_metrics (rack_id, recorded_at, power_w, temperature_c) VALUES
(1, NOW() - INTERVAL '30 minutes', 1400, 21.2),
(1, NOW(), 1500, 22.0),
(4, NOW() - INTERVAL '15 minutes', 3800, 24.5),
(4, NOW(), 4100, 25.1),
(5, NOW(), 600, 19.8);

INSERT INTO services (server_id, owner_id, name, service_type, port, status, created_at) VALUES
(1,  2, 'Nginx Frontend',       'web',        80,   'running',  '2022-03-20 09:00:00+03'),
(1,  2, 'Nginx SSL',            'web',        443,  'running',  '2022-03-20 09:00:00+03'),
(3,  5, 'PostgreSQL Primary',   'database',   5432, 'running',  '2021-11-05 10:00:00+03'),
(4,  5, 'PostgreSQL Replica',   'database',   5432, 'running',  '2021-11-05 10:30:00+03'),
(5,  8, 'Redis Cluster',        'cache',      6379, 'running',  '2023-01-25 14:00:00+03'),
(6,  1, 'REST API Gateway',     'api',        8080, 'running',  '2023-06-15 11:00:00+03'),
(7,  8, 'Prometheus',           'monitoring', 9090, 'stopped',  '2020-09-10 08:00:00+03'),
(7,  8, 'Grafana',              'monitoring', 3000, 'stopped',  '2020-09-10 08:30:00+03'),
(8,  1, 'OpenVPN',              'vpn',        1194, 'running',  '2022-07-20 16:00:00+03'),
(10, 8, 'BIND9 DNS',            'dns',        53,   'running',  '2023-09-05 07:00:00+03'),
(9,  5, 'MinIO Object Storage', 'storage',    9000, 'running',  '2021-06-01 10:00:00+03'),
(6,  1, 'Internal Admin API',   'api',        8443, 'degraded', '2023-07-01 09:00:00+03');

INSERT INTO incidents (server_id, reported_by, assigned_to, title, severity, status,
                       created_at, resolved_at, description) VALUES
(3, 3, 1, 'PostgreSQL Primary — high CPU load', 'high',     'resolved',
    '2024-10-01 02:15:00+03', '2024-10-01 04:45:00+03',
    'Резкий рост CPU до 95% из-за VACUUM FULL на большой таблице.'),

(1, 3, 5, 'Nginx — 502 Bad Gateway', 'medium', 'resolved',
    '2024-10-15 11:00:00+03', '2024-10-15 11:35:00+03',
    'Бэкенд API не отвечал из-за перегрузки пула соединений.'),

(7, 6, 8, 'srv-mon-01 — плановое обслуживание', 'low', 'closed',
    '2024-11-01 08:00:00+03', '2024-11-01 18:00:00+03',
    'Замена HDD, обновление прошивки BIOS.'),

(9, 3, 5, 'MinIO — потеря диска в пуле', 'critical', 'resolved',
    '2024-11-20 03:00:00+03', '2024-11-20 07:30:00+03',
    'Выход из строя одного диска в erasure-кодированном пуле.'),

(6, 6, 1, 'Admin API — деградация производительности', 'medium', 'in_progress',
    '2024-12-01 14:00:00+03', NULL,
    'Увеличение времени ответа API до 8 секунд.'),

(8, 3, 5, 'OpenVPN — разрыв соединений', 'high', 'resolved',
    '2024-12-05 09:30:00+03', '2024-12-05 11:00:00+03',
    'MTU mismatch после обновления конфигурации фаервола.'),

(1, 3, 1, 'srv-web-01 — kernel panic', 'critical', 'resolved',
    '2025-01-10 01:00:00+03', '2025-01-10 03:15:00+03',
    'OOM killer завершил процессы ядра. Требовалась перезагрузка.'),

(5, 6, 8, 'Redis — eviction storm', 'high', 'open',
    '2025-02-14 22:00:00+03', NULL,
    'maxmemory достигнут, агрессивный eviction мешает кэшированию.');

INSERT INTO incident_updates (incident_id, author_id, update_text, status_state, created_at) VALUES
(5, 1, 'Обнаружен медленный метод в котроллере AdminAPI, изучаю логи базы данных.', 'in_progress', '2024-12-01 14:30:00+03'),
(5, 1, 'Запросил оптимизацию индексов у администратора СУБД.', 'in_progress', '2024-12-01 16:00:00+03');

INSERT INTO incident_services (incident_id, service_id) VALUES
(1, 3), (1, 4), (2, 1), (2, 6), (3, 7), (3, 8), (4,11), (5, 6), (5,12), (6, 9);

INSERT INTO maintenance_logs (server_id, performed_by, action, notes, performed_at) VALUES
(7, 8, 'Замена HDD 2TB SAS', 'Заменён диск slot-2, RAID перестроен за 4ч.', '2024-11-01 09:00:00+03'),
(7, 8, 'Обновление BIOS до v2.8.1', 'Устранены уязвимости CVE-2024-XXXX.', '2024-11-01 13:00:00+03'),
(3, 1, 'Анализ производительности PostgreSQL', 'Добавлен индекс на таблицу events(created_at). CPU нормализовался.', '2024-10-01 04:30:00+03'),
(9, 5, 'Замена диска MinIO pool (disk-5)', 'Диск заменён, heal-операция завершена успешно.', '2024-11-20 06:00:00+03'),
(1, 1, 'Перезагрузка после kernel panic', 'Ядро обновлено до 6.1.72-lts.', '2025-01-10 03:00:00+03'),
(8, 5, 'Корректировка MTU OpenVPN', 'MTU снижен с 1500 до 1400 на tun-интерфейсе.', '2024-12-05 10:45:00+03'),
(4, 5, 'Апгрейд RAM: 512 GB → 768 GB', 'Добавлено 8 × 32 GB DDR4 RDIMM.', '2024-09-15 06:00:00+03'),
(11, 1, 'Расширение дискового пула', 'Добавлено 2 × 12 TB NL-SAS для резервного копирования.', '2024-08-20 10:00:00+03');
