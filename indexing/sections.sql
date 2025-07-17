DROP TABLE IF EXISTS logs CASCADE;
CREATE TABLE logs
(
    username varchar(100) NOT NULL,
	action_type TEXT NOT NULL, 
	changed_table TEXT NOT NULL, 
    changes TEXT NOT NULL,
	changed_on TIMESTAMP(6) NOT NULL
);

DROP TABLE IF EXISTS logs_part CASCADE;
CREATE TABLE logs_part (
    username varchar(100) NOT NULL,
    action_type TEXT NOT NULL,
    changed_table TEXT NOT NULL,
    changes TEXT NOT NULL,
    changed_on TIMESTAMP(6) NOT NULL
) PARTITION BY RANGE (changed_on);

CREATE TABLE logs_2023 PARTITION OF logs_part
FOR VALUES FROM ('2023-01-01 00:00:00') TO ('2024-01-01 00:00:00');

CREATE TABLE logs_2024 PARTITION OF logs_part
FOR VALUES FROM ('2024-01-01 00:00:00') TO ('2025-01-01 00:00:00');
