DROP TABLE IF EXISTS results CASCADE;
CREATE TABLE results (
  execution_time numeric,
  target_table text,
  records int
);

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


DROP TABLE IF EXISTS logs_unique CASCADE;
CREATE TABLE logs_unique
(
    username varchar(100) NOT NULL UNIQUE,
	action_type TEXT NOT NULL, 
	changed_table TEXT NOT NULL, 
    changes TEXT NOT NULL,
	changed_on TIMESTAMP(6) NOT NULL 
);
CREATE UNIQUE INDEX idx_unique ON logs_unique (username);


DROP TABLE IF EXISTS logs_expr CASCADE;
CREATE TABLE logs_expr
(
    username varchar(100) NOT NULL,
	action_type TEXT NOT NULL, 
	changed_table TEXT NOT NULL, 
    changes TEXT NOT NULL,
	changed_on TIMESTAMP(6) NOT NULL 
);
CREATE INDEX idx_expr ON logs_expr (username, changed_on);


DROP TABLE IF EXISTS logs_func CASCADE;
CREATE TABLE logs_func
(
    username varchar(100) NOT NULL,
	action_type TEXT NOT NULL, 
	changed_table TEXT NOT NULL, 
    changes TEXT NOT NULL,
	changed_on TIMESTAMP(6) NOT NULL 
);
CREATE INDEX idx_func ON logs_func (DATE(changed_on));