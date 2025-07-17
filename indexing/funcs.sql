-- генерация логов
CREATE OR REPLACE FUNCTION generate_logs(num_rows INT, target_table TEXT)
RETURNS VOID AS $$
DECLARE
  i INT := 1;
  username_prefix VARCHAR(50) := 'user_';
  action_types TEXT[] := ARRAY['Insert', 'Update', 'Delete', 'Select'];
  table_names TEXT[] := ARRAY['Employee', 'Department', 'Product', 'Customer', 'Orders'];
BEGIN
  WHILE i <= num_rows LOOP
	  
    EXECUTE FORMAT('INSERT INTO %I (username, action_type, changed_table, changes, changed_on) VALUES ($1, $2, $3, $4, $5)', target_table)
	USING
      username_prefix || i,
      action_types[1 + (i % array_length(action_types, 1))],
      table_names[1 + (i % array_length(table_names, 1))],
      'Generated log entry ' || i,
	  make_date((random()*1+2023)::int, (random()*11+1)::int, (random()*27+1)::int) + 
	  	make_time((random()*22+1)::int, (random()*58+1)::int, (random()*58+1)::int);
    i := i + 1;
  END LOOP;
END;
$$ LANGUAGE plpgsql;


-- рандомный селект
CREATE OR REPLACE FUNCTION random_select(target_table TEXT)
RETURNS VOID AS $$
DECLARE
  record_counts int[] := ARRAY[10, 100, 1000, 10000, 100000, 1000000];
  records int;
  start_time timestamp;
  end_time interval;
  random_log TIMESTAMP(6);
BEGIN
  FOREACH records IN ARRAY record_counts LOOP
    PERFORM generate_logs(records, target_table);

	FOR i IN 1..6 LOOP
	    EXECUTE FORMAT('SELECT changed_on FROM %I ORDER BY RANDOM() LIMIT 1', target_table) INTO random_log;
	    
		start_time := clock_timestamp();
	    EXECUTE FORMAT('SELECT * FROM %I WHERE changed_on = $1', target_table) USING random_log;
	    end_time := clock_timestamp() - start_time;
	
	    INSERT INTO results (execution_time, target_table, records)
	    VALUES (extract(milliseconds FROM end_time), target_table, records);
	END LOOP;

	EXECUTE FORMAT('TRUNCATE TABLE %I', target_table);
  END LOOP;
END;
$$ LANGUAGE plpgsql;


-- random insert
CREATE OR REPLACE FUNCTION random_insert(target_table TEXT)
RETURNS VOID AS $$
DECLARE
  record_counts int[] := ARRAY[10, 100, 1000, 10000, 100000, 1000000];
  records int;
  start_time timestamp;
  end_time interval;
  action_types TEXT[] := ARRAY['Insert', 'Update', 'Delete', 'Select'];
  table_names TEXT[] := ARRAY['Employee', 'Department', 'Product', 'Customer', 'Orders'];
  username_prefix VARCHAR(50) := 'insert_';
BEGIN
  FOREACH records IN ARRAY record_counts LOOP
    PERFORM generate_logs(records, target_table);

	FOR i IN 1..6 LOOP
		start_time := clock_timestamp();
		
	    EXECUTE FORMAT('INSERT INTO %I (username, action_type, changed_table, changes, changed_on) VALUES ($1, $2, $3, $4, $5)', target_table)
		USING
	      username_prefix || i,
	      action_types[1 + (i % array_length(action_types, 1))],
	      table_names[1 + (i % array_length(table_names, 1))],
	      'Generated log entry ' || i,
		  make_date((random()*24+2000)::int, (random()*11+1)::int, (random()*27+1)::int) + 
		  	make_time((random()*22+1)::int, (random()*58+1)::int, (random()*58+1)::int);
	    
		end_time := clock_timestamp() - start_time;
	
	    INSERT INTO results (execution_time, target_table, records)
	    VALUES (extract(milliseconds FROM end_time), target_table, records);
	END LOOP;

	EXECUTE FORMAT('TRUNCATE TABLE %I', target_table);
  END LOOP;
END;
$$ LANGUAGE plpgsql;


-- random update
CREATE OR REPLACE FUNCTION random_update(target_table TEXT)
RETURNS VOID AS $$
DECLARE
  record_counts int[] := ARRAY[10, 100, 1000, 10000, 100000, 1000000];
  records int;
  start_time timestamp;
  end_time interval;
  action_types TEXT[] := ARRAY['Insert', 'Update', 'Delete', 'Select'];
  random_log TEXT;
  new_act TEXT;
BEGIN
  FOREACH records IN ARRAY record_counts LOOP
    PERFORM generate_logs(records, target_table);

	FOR i IN 1..6 LOOP
	 	EXECUTE FORMAT('SELECT changes FROM %I ORDER BY RANDOM() LIMIT 1', target_table) INTO random_log;
		new_act := action_types[1 + (i % array_length(action_types, 1))];
		
		start_time := clock_timestamp();
	    EXECUTE FORMAT('UPDATE %I SET action_type = $1 WHERE changes = $2', target_table) USING new_act, random_log;
		end_time := clock_timestamp() - start_time;
	
	    INSERT INTO results (execution_time, target_table, records)
	    VALUES (extract(milliseconds FROM end_time), target_table, records);
	END LOOP;

	EXECUTE FORMAT('TRUNCATE TABLE %I', target_table);
  END LOOP;
END;
$$ LANGUAGE plpgsql;

