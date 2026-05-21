# DCIM. Управление инфраструктурой дата-центра

Расчётно-графическая работа по дисциплине **«Базы данных»**  
СибГУТИ, кафедра ТС и ВС, 2026
Методические указания: К.И. Брагин

---

## Описание проекта

База данных реализует систему управления IT-инфраструктурой дата-центра (**DCIM - Data Center Infrastructure Management**).

Предметная область охватывает полный жизненный цикл серверного оборудования:

- Учёт **физических площадок** (дата-центры, стойки, позиции)
- Управление **серверным парком** с привязкой к договорам техподдержки отечественных вендоров (YADRO, Элтекс, Булат)
- Детальный инвентарь **компонентов** (CPU, RAM, HDD, SSD, PSU)
- **IPAM** - учёт IP-адресов с поддержкой типов `INET`/`CIDR` PostgreSQL
- Регистрация и разрешение **инцидентов** с контролем SLA
- **IoT-телеметрия** стоек: потребляемая мощность и температура
- Журнал **технического обслуживания** и Post-Mortem анализ

### Состав схемы

| Таблица | Назначение | Записей |
|---|---|:---:|
| `employees` | Сотрудники (инженеры, операторы NOC, менеджеры) | 8 |
| `datacenters` | Физические площадки | 3 |
| `racks` | Серверные стойки | 6 |
| `rack_climate_metrics` | IoT-метрики климата стоек | 5 |
| `vendors` | Отечественные вендоры | 4 |
| `contracts` | Контракты SLA | 3 |
| `servers` | Серверы | 12 |
| `server_components` | Компоненты серверов | 7 |
| `ip_addresses` | IP-адреса (IPAM) | 7 |
| `services` | Логические сервисы | 12 |
| `incidents` | Инциденты | 8 |
| `incident_updates` | Worklog к инцидентам | 2 |
| `incident_services` | Связь инцидент ↔ сервис (M:N) | 10 |
| `maintenance_logs` | Журнал обслуживания | 8 |
| **ИТОГО** | | **95** |

### Файлы проекта

```
.
├── docker-compose.yml   # Конфигурация контейнера PostgreSQL
├── schema.sql           # DDL: таблицы, ограничения, индексы
├── data.sql             # Тестовые данные (95 записей)
├── queries.sql          # 20 аналитических SQL-запросов
└── README.md            # Этот файл
```

---

## Запуск проекта

### Требования

- [Docker](https://docs.docker.com/get-docker/) и [Docker Compose](https://docs.docker.com/compose/) (v2+)

### Шаг 1 - Запуск контейнера

```bash
docker compose up -d
```

PostgreSQL поднимется на порту `5432`. При **первом** запуске автоматически выполнятся скрипты инициализации:

```
/docker-entrypoint-initdb.d/01_schema.sql  →  создание таблиц и индексов
/docker-entrypoint-initdb.d/02_data.sql    →  загрузка тестовых данных
```

### Шаг 2 - Проверка готовности

```bash
docker compose ps
```

Дождитесь статуса `healthy` в колонке `STATUS`. Healthcheck выполняет `pg_isready` каждые 10 секунд.

### Шаг 3 - Остановка

```bash
# Остановить контейнер (данные в томе сохраняются)
docker compose down

# Запустить снова - данные уже на месте, инициализация не повторяется
docker compose up -d
```

---

## 🔌 Подключение к базе данных

### Параметры подключения

| Параметр | Значение |
|---|---|
| Host | `localhost` |
| Port | `5432` |
| Database | `datacenter` |
| User | `dcadmin` |
| Password | `dcpass123` |

### Через psql (терминал)

**Вариант А - через Docker exec (не требует локального psql):**

```bash
docker compose exec postgres psql -U dcadmin -d datacenter
```

**Вариант Б - локальный psql:**

```bash
psql -h localhost -p 5432 -U dcadmin -d datacenter
```

Полезные команды внутри psql:

```sql
\dt                   -- список всех таблиц
\d servers            -- структура таблицы servers
\di                   -- список всех индексов
SELECT COUNT(*) FROM servers;
\q                    -- выход
```

### Через DBeaver

1. **New Connection → PostgreSQL**
2. Заполнить поля: Host `localhost`, Port `5432`, Database `datacenter`, Username `dcadmin`, Password `dcpass123`
3. Нажать **Test Connection** - должен появиться статус `Connected`
4. ER-диаграмму можно открыть: ПКМ по базе → **View Diagram**

---

## Проверка работоспособности

### Запуск аналитических запросов

```bash
# Все 20 запросов из queries.sql
docker compose exec postgres psql -U dcadmin -d datacenter -f /docker-entrypoint-initdb.d/../queries.sql
```

Или скопировать нужные запросы вручную в psql / DBeaver.

### Быстрая проверка наполненности базы

```sql
SELECT 'employees' AS tbl, COUNT(*) FROM employees
UNION ALL SELECT 'datacenters', COUNT(*) FROM datacenters
UNION ALL SELECT 'racks', COUNT(*) FROM racks
UNION ALL SELECT 'servers', COUNT(*) FROM servers
UNION ALL SELECT 'services', COUNT(*) FROM services
UNION ALL SELECT 'incidents', COUNT(*) FROM incidents
UNION ALL SELECT 'maintenance_logs', COUNT(*) FROM maintenance_logs;
```

### Проверка ограничений целостности

```sql
-- Попытка вставить сервер с недопустимым статусом - должна завершиться ошибкой
INSERT INTO servers (rack_id, serial_number, hostname, manufacturer, model,
    status, cpu_cores, ram_gb, storage_tb, power_w, rack_unit_position)
VALUES (1, 'TEST-001', 'test-host', 'Test', 'Model X',
    'broken', 4, 32, 1.0, 300, 10);
-- ERROR: new row for relation "servers" violates check constraint

-- Попытка поставить два сервера в один юнит стойки - должна завершиться ошибкой
INSERT INTO servers (rack_id, serial_number, hostname, manufacturer, model,
    status, cpu_cores, ram_gb, storage_tb, power_w, rack_unit_position)
VALUES (1, 'TEST-002', 'test-host-2', 'Test', 'Model Y',
    'active', 4, 32, 1.0, 300, 1);
-- ERROR: duplicate key value violates unique constraint
```

---

## Полная очистка данных

```bash
# Остановить контейнер И удалить том pgdata (все данные будут уничтожены)
docker compose down -v
```

После этой команды при следующем `docker compose up -d` база будет создана заново с нуля - скрипты инициализации выполнятся повторно.

> Команда `down -v` необратимо удаляет все данные. Используйте только если хотите пересоздать БД с "чистого листа".

---

## Обоснование ограничений целостности

### Ограничения CHECK

Ограничения `CHECK` кодируют бизнес-правила прямо в схеме, не позволяя попасть в базу заведомо некорректным данным.

| Ограничение | Поле | Обоснование |
|---|---|---|
| `tier_level BETWEEN 1 AND 4` | `datacenters` | Международная классификация надёжности ЦОД имеет ровно 4 уровня. Значения 0 или 5 физически не существуют. |
| `total_power_kw > 0` | `datacenters` | Мощность - физическая величина, не может быть нулевой или отрицательной. |
| `temperature_c BETWEEN 10.0 AND 45.0` | `rack_climate_metrics` | Допустимый диапазон температур для работы серверного оборудования по стандарту ASHRAE. Значения вне диапазона означают неисправность датчика. |
| `status IN ('active','maintenance',...)` | `servers`, `services` | Фиксированный набор бизнес-состояний. Произвольные строки нарушили бы логику фильтрации в мониторинге. |
| `component_type IN ('CPU','RAM',...)` | `server_components` | Закрытый перечень типов компонентов обеспечивает возможность агрегации и построения дефектных ведомостей. |
| `cpu_cores > 0`, `ram_gb > 0` | `servers` | Сервер без процессоров или памяти невозможен физически. |
| `port BETWEEN 1 AND 65535` | `services` | Стандарт TCP/UDP: порт 0 зарезервирован, значения выше 65535 не существуют. |
| `end_date >= start_date` | `contracts` | Договор не может заканчиваться раньше, чем начался. |
| `resolved_at >= created_at` | `incidents` | Инцидент не может быть закрыт раньше, чем был зарегистрирован. |
| `email LIKE '%@%.%'` | `employees`, `vendors` | Минимальная валидация формата e-mail без усложнённых регулярных выражений. |

### Ограничения UNIQUE

Ограничения `UNIQUE` защищают бизнес-ключи - поля, по которым в реальном мире объекты идентифицируются уникально.

| Ограничение | Поле | Обоснование |
|---|---|---|
| `email UNIQUE` | `employees` | Два сотрудника не могут иметь одинаковый корпоративный e-mail - он является логином. |
| `phone UNIQUE` | `employees` | Мобильный номер привязан к конкретному человеку, дублирование - ошибка ввода. |
| `hostname UNIQUE` | `servers` | В сети дата-центра имя хоста должно быть уникальным - иначе возникает конфликт DNS. |
| `serial_number UNIQUE` | `servers` | Серийный номер - заводской идентификатор конкретного экземпляра оборудования. |
| `ip_address UNIQUE` | `ip_addresses` | Два устройства с одним IP вызывают конфликт в сети (IP collision). |
| `UNIQUE (rack_id, rack_unit_position)` | `servers` | Составной ключ: в одну физическую позицию стойки нельзя установить два сервера. Защита от ошибок при планировании размещения. |
| `contract_number UNIQUE` | `contracts` | Номер договора - уникальный юридический идентификатор. |

### Стратегии ON DELETE для внешних ключей

| Стратегия | Где применена | Логика |
|---|---|---|
| `ON DELETE RESTRICT` | `racks → datacenters`, `servers → racks`, `incidents → servers` | Запрет удаления родителя, пока есть дочерние записи. Нельзя «потерять» стойку с серверами или сервер с открытым инцидентом. |
| `ON DELETE CASCADE` | `server_components`, `services`, `incident_updates`, `rack_climate_metrics` | Дочерние записи являются неотъемлемой частью родителя. Удаление сервера автоматически удаляет его компоненты и сервисы - нет смысла хранить сироток. |
| `ON DELETE SET NULL` | `servers.contract_id`, `servers.assigned_engineer`, `services.owner_id` | Дочерняя запись продолжает существовать, теряя лишь ссылку. Сервер остаётся в инвентаре даже если договор расторгнут или инженер уволен. |

---

## Обоснование стратегии индексации

Индексы созданы по принципу **«индексируй то, что фильтруешь и джойнишь»**. Каждый индекс решает конкретную задачу из набора аналитических запросов.

| Индекс | Таблица / Поле | Обоснование |
|---|---|---|
| `idx_servers_status` | `servers(status)` | Поле `status` - наиболее частый фильтр (`WHERE status = 'active'`). Используется в Q-02, Q-05, Q-10. Без индекса - полный перебор всех серверов при каждом запросе. |
| `idx_servers_rack` | `servers(rack_id)` | Внешний ключ, по которому выполняется JOIN с таблицей `racks` в большинстве запросов (Q-01, Q-04, Q-05). PostgreSQL не создаёт индексы на FK автоматически. |
| `idx_incidents_composite` | `incidents(status, severity)` | **Составной индекс** покрывает одновременно фильтрацию по статусу и критичности (Q-03, Q-07, Q-08). Порядок полей: сначала `status` (равенство), затем `severity` (IN-список). |
| `idx_services_server` | `services(server_id)` | JOIN сервисов с серверами (Q-08, Q-16). Частый запрос: «какие сервисы запущены на этом сервере». |
| `idx_ip_addresses_search` | `ip_addresses(ip_address)` | Тип `INET` в PostgreSQL требует отдельного индекса для эффективного поиска. Используется в Q-13 и при поиске по IP в мониторинге. |
| `idx_components_server` | `server_components(server_id)` | JOIN компонентов с серверами при построении дефектных ведомостей (Q-14, Q-17). |
| `idx_climate_rack_time` | `rack_climate_metrics(rack_id, recorded_at DESC)` | **Составной индекс по убыванию времени** - оптимизирует запросы «последние N метрик для стойки X» (Q-15). Убывающий порядок соответствует типичной выборке «от новых к старым». |
| `idx_incident_updates_inc` | `incident_updates(incident_id)` | Выборка всего worklog по конкретному инциденту (Q-20). Без индекса при большом количестве записей - полный перебор. |
| `idx_maintenance_server` | `maintenance_logs(server_id)` | JOIN журнала обслуживания с таблицей серверов. |
| `idx_maintenance_performed` | `maintenance_logs(performed_at DESC)` | Сортировка по дате убывания для выборки последних записей (Q-09). Индекс по убыванию устраняет сортировку при выполнении запроса. |
