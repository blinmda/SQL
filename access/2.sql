DROP TABLE IF EXISTS Employee CASCADE;
CREATE TABLE Employee(   
	full_name varchar(100) primary key not null,
	document_number int unique not null,
	phone_number varchar(12) unique not null,
	birth_date date not null,
	children_count int not null,
	family_status varchar(50) not null,
	education_level varchar(50) not null,
	work_experience int not null,
	qualification text
);

DROP TABLE IF EXISTS EmployeePosition  CASCADE;
CREATE TABLE EmployeePosition (   
	full_name varchar(100) not null,
	appointment_date date not null,
	department varchar(50) not null,
	termination_date date,
	position_name varchar(50) not null,
	primary key (full_name, appointment_date),
	foreign key (full_name) references Employee(full_name)    
	on delete cascade on update cascade
);


-- контроль целостности
CREATE OR REPLACE FUNCTION check_education_level(ed_level varchar)
RETURNS int AS $$
DECLARE
  levels varchar[] := ARRAY['Среднее', 'Среднее специальное', 'Высшее', 'Доктор наук'];
  ed_index int;
BEGIN
  ed_index := array_position(levels, ed_level);
  IF ed_index is NULL THEN
    RAISE EXCEPTION 'Недопустимый уровень образования';
  END IF;
  RETURN ed_index;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION check_employee_update()
RETURNS TRIGGER AS $$
BEGIN
	IF check_education_level(NEW.education_level) < check_education_level(OLD.education_level) THEN
    	RAISE EXCEPTION 'Уровень образования не может быть понижен';
  	END IF;
	IF NEW.work_experience < OLD.work_experience THEN
    	RAISE EXCEPTION 'Общий стаж не может быть уменьшен';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER employee_update_trigger 
BEFORE UPDATE ON Employee 
FOR EACH ROW EXECUTE PROCEDURE check_employee_update();

CREATE OR REPLACE FUNCTION check_employee_education()
RETURNS TRIGGER AS $$
BEGIN
	PERFORM check_education_level(NEW.education_level);
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER employee_education_trigger 
BEFORE INSERT ON Employee 
FOR EACH ROW EXECUTE PROCEDURE check_employee_education();

-- создание пользователей
DO $$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'employee') THEN
      CREATE ROLE employee;
   END IF;
END$$;

DROP USER IF EXISTS "Ivan";
CREATE USER "Ivan" WITH PASSWORD '123';
GRANT employee TO "Ivan";

DROP USER IF EXISTS "Masha";
CREATE USER "Masha" WITH PASSWORD '123';
GRANT employee TO "Masha";

DROP USER IF EXISTS "Alex";
CREATE USER "Alex" WITH PASSWORD '123';
GRANT employee TO "Alex";

-- контроль доступа (свои данные)
CREATE OR REPLACE VIEW EmployeeSelf AS
SELECT
    e.*,
	ep.department,
    ep.appointment_date,
    ep.termination_date,
    ep.position_name
FROM
    Employee e
JOIN
    EmployeePosition ep ON e.full_name = ep.full_name
WHERE
    e.full_name = current_user;

GRANT SELECT ON EmployeeSelf TO employee;

-- контроль доступа (чужие данные)
CREATE VIEW EmployeeContacts AS
SELECT
    e.full_name,
    e.phone_number
FROM
    Employee e
JOIN
    EmployeePosition ep ON e.full_name = ep.full_name
WHERE
    ep.department = (SELECT department FROM EmployeePosition WHERE full_name = current_user 
	AND termination_date is NULL) AND termination_date is NULL;

GRANT SELECT ON EmployeeContacts TO employee;

-- обновление представления
CREATE OR REPLACE FUNCTION update_info()
RETURNS TRIGGER 
SECURITY DEFINER
AS $$
BEGIN
	IF (OLD.qualification != NEW.qualification) THEN 
		UPDATE Employee SET qualification = NEW.qualification WHERE full_name = OLD.full_name;
	ELSIF (OLD.family_status != NEW.family_status)  THEN 
		UPDATE Employee SET family_status = NEW.family_status WHERE full_name = OLD.full_name;
	ELSIF (OLD.children_count != NEW.children_count)  THEN 
		UPDATE Employee SET children_count = NEW.children_count WHERE full_name = OLD.full_name;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_update_info
INSTEAD OF UPDATE ON EmployeeSelf
FOR EACH ROW EXECUTE PROCEDURE update_info();

GRANT UPDATE (children_count, family_status, qualification) ON EmployeeSelf TO employee;

-- логирование
DROP TABLE IF EXISTS logs CASCADE;
CREATE TABLE logs
(
    username varchar(100) NOT NULL,
	act TEXT NOT NULL, 
	ch_table TEXT NOT NULL, 
	changed_on TIMESTAMP(6) NOT NULL,
    change text NOT NULL
);
	
CREATE OR REPLACE FUNCTION audit() 
RETURNS TRIGGER 
AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
		INSERT INTO logs(username, act, ch_table, changed_on, change) 
		VALUES(current_user, 'delete', TG_TABLE_NAME, now(),
			format('full_name: ''%s''; 
					document_number: ''%s''; 
					phone_number: ''%s''; 
					birth_date: ''%s'';
					children_count: ''%s'';
					family_status: ''%s'';
					education_level: ''%s'';
					work_experience: ''%s'';
					qualification: ''%s''', 
					OLD.full_name,
					OLD.document_number,
					OLD.phone_number,
					OLD.birth_date,
					OLD.children_count,
					OLD.family_status,
					OLD.education_level,
					OLD.work_experience,
					OLD.qualification));
					
		RETURN OLD;
	ELSIF (TG_OP = 'UPDATE') THEN
		INSERT INTO logs(username, act, ch_table, changed_on, change) 
		VALUES(current_user, 'update', TG_TABLE_NAME, now(),
		format('full_name: ''%s'' -> ''%s''; 
				document_number: ''%s'' -> ''%s''; 
				phone_number: ''%s'' -> ''%s''; 
				birth_date: ''%s'' -> ''%s'';
				children_count: ''%s'' -> ''%s''
				family_status: ''%s'' -> ''%s''
				education_level: ''%s'' -> ''%s''
				work_experience: ''%s'' -> ''%s''
				qualification: ''%s'' -> ''%s''', 
				OLD.full_name, NEW.full_name,
				OLD.document_number, NEW.document_number,
				OLD.phone_number, NEW.phone_number,
				OLD.birth_date, NEW.birth_date,
				OLD.children_count, NEW.children_count,
				OLD.family_status, NEW.family_status,
				OLD.education_level, NEW.education_level,
				OLD.work_experience, NEW.work_experience,
				OLD.qualification, NEW.qualification));
		RETURN NEW;
	ELSIF (TG_OP = 'INSERT') THEN
		INSERT INTO logs(username, act, ch_table, changed_on, change) 
		VALUES(current_user, 'insert', TG_TABLE_NAME, now(),
		format('full_name: ''%s''; 
				document_number: ''%s''; 
				phone_number: ''%s''; 
				birth_date: ''%s'';
				children_count: ''%s'';
				family_status: ''%s'';
				education_level: ''%s'';
				work_experience: ''%s'';
				qualification: ''%s''', 
				NEW.full_name,
				NEW.document_number,
				NEW.phone_number,
				NEW.birth_date,
				NEW.children_count,
				NEW.family_status,
				NEW.education_level,
				NEW.work_experience,
				NEW.qualification));
		RETURN NEW;
	END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER audit_logs 
AFTER INSERT OR UPDATE OR DELETE ON Employee
FOR EACH ROW EXECUTE PROCEDURE audit();

CREATE OR REPLACE TRIGGER audit_logs_view 
INSTEAD OF UPDATE ON EmployeeSelf
FOR EACH ROW EXECUTE PROCEDURE audit();

GRANT INSERT ON logs TO employee;

-- заполнение
INSERT INTO Employee (full_name, document_number, phone_number, birth_date, children_count, family_status, education_level, work_experience, qualification)
VALUES ('Ivan', 123456789, '89123456789', '1990-06-10', 2, 'Женат', 'Высшее', 10, 'Инженер-программист'),
       ('Masha', 987654321, '89234567890', '2000-11-20', 0, 'Не замужем', 'Высшее', 3, 'Бухгалтер');
INSERT INTO Employee (full_name, document_number, phone_number, birth_date, children_count, family_status, education_level, work_experience)
VALUES ('Alex', 555555555, '89345678901', '1980-03-01', 1, 'Разведен', 'Среднее', 15);

INSERT INTO EmployeePosition (full_name, appointment_date, department, termination_date, position_name)
VALUES  ('Ivan', '2020-06-15', 'IT', '2021-08-25', 'Разработчик'),
		('Masha', '2021-09-01', 'Финансы', '2022-07-31', 'Стажер');
INSERT INTO EmployeePosition (full_name, appointment_date, department, position_name)
VALUES  ('Ivan', '2021-08-25', 'IT', 'Старший разработчик'),
 		('Masha', '2022-07-31', 'Финансы', 'Бухгалтер'),
		('Alex', '2010-04-05', 'IT', 'Системный администратор');

SELECT * FROM logs