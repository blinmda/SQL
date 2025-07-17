DROP TABLE IF EXISTS logs CASCADE;
CREATE TABLE logs
(
    username varchar(100) NOT NULL,
	action_type TEXT NOT NULL, 
	changed_table TEXT NOT NULL, 
    changes TEXT NOT NULL,
	changed_on TIMESTAMP(6) NOT NULL
);

DROP TABLE IF EXISTS logs_index CASCADE;
CREATE TABLE logs_index (
    username varchar(100) NOT NULL,
    action_type TEXT NOT NULL,
    changed_table TEXT NOT NULL,
    changes TEXT NOT NULL,
    changed_on TIMESTAMP(6) NOT NULL
);
CREATE INDEX idx_changed_on ON logs_index (changed_on);

DROP TABLE IF EXISTS results CASCADE;
CREATE TABLE results (
  execution_time numeric,
  target_table text,
  records int
);