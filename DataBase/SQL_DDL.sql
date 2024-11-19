--CREATE DATABASE healthcare;  --create database for our healthcare data 

CREATE SCHEMA IF NOT EXISTS healthcare;  --CREATE NEW SCHEMA

SET search_path TO 'healthcare'; --AFTER this command ALL queries IN this file would be proceeded within healthcare SCHEMA

CREATE TABLE IF NOT EXISTS country (  --CREATE TABLE TO store country's name 
	country_id SERIAL PRIMARY KEY,  --use SERIAL TYPE since we don't have too much countries IN the wotld, it's NOT NULL AND UNIQUE BY DEFAULT 
	country text NOT NULL
);

CREATE TABLE IF NOT EXISTS city ( --CREATE TABLE TO store cities 
	city_id BIGSERIAL PRIMARY KEY,
	city text NOT NULL,
	country_id int NOT NULL REFERENCES country (country_id) --FK country_id FROM country TABLE, TYPE int since the KEY already qenerated AND UNIQUE
);

CREATE TABLE IF NOT EXISTS address ( --CREATE TABLE TO store address 
	address_id BIGSERIAL PRIMARY KEY,
	address text NOT NULL,
	district text,
	city_id int NOT NULL REFERENCES city (city_id), --refer TO сity table
	postal_code text NULL
);

CREATE TABLE IF NOT EXISTS institution( --TABLE TO store institutions 
	institution_id BIGSERIAL PRIMARY KEY,
	title CHAR (150) NOT NULL,
	institution_type CHAR (150) NOT NULL, -- we have different TYPES OF institutions, they ARE named IN CHECK constraint
	phone CHAR (50) NOT NULL,
	email CHAR (50),
	website CHAR (255),
	address_id INT NOT NULL REFERENCES address (address_id), 
	CONSTRAINT check_intitution_type CHECK (institution_type IN ('rehub', 'clinic', 'hospital', 'institution','specializes hospital')) --constaint TO CHECK TYPE OF institution
);

CREATE TABLE IF NOT EXISTS room(  --store information about rooms IN the health institution
	room_id BIGSERIAL PRIMARY KEY,
	room_type CHAR(150), --we have different room TYPES IN institutions 
	capacity INT, --capacity means number OF beds IN the room
	institution_id INT NOT NULL REFERENCES institution(institution_id), --refer TO institution TO CONNECT TABLE AND be able TO cout how many patients EACH intitution can have AT the same time
	CONSTRAINT check_room_type CHECK (room_type IN ('single', 'double', 'ward', 'operating','recovery','isolation'))
);

CREATE TABLE IF NOT EXISTS patient(
	patient_id BIGSERIAL PRIMARY KEY,
	firstname CHAR(100) NOT NULL,
	surname CHAR(100) NOT NULL,
	id_number CHAR (30) NOT NULL UNIQUE, --person's id OR passport number
	insurance_number CHAR (100) UNIQUE,
	phone CHAR(50),
	email CHAR (50),
	address_id INT NOT NULL REFERENCES address(address_id)
);

CREATE TABLE IF NOT EXISTS staff( --IN this TABLE we store information about ALL staff members, we don't have institution id here because one doctor can WORK IN several clinics 
	staff_id BIGSERIAL PRIMARY KEY,
	firstname CHAR(100) NOT NULL,
	surname CHAR(100) NOT NULL,
	phone CHAR(50),
	email CHAR (50),
	job_title CHAR(255)	
);

CREATE TABLE IF NOT EXISTS service(  -- TABLE WITH ALL services IN EACH institution AND their description
	service_id BIGSERIAL PRIMARY KEY,
	title char(255) NOT NULL,
	description TEXT, --IN description we use TYPE TEXT since it can be long 
	institution_id INT REFERENCES institution (institution_id)
);

CREATE TABLE IF NOT EXISTS staffservice( --here we connct OUT staff AND services, AND since we connected services AND institution, this TABLE CONNECTs ALSO doctor AND clinic AND allow one doctor WORK IN several clinics 
	service_id INT NOT NULL REFERENCES service (service_id),
	staff_id INT NOT NULL REFERENCES staff (staff_id),
	PRIMARY KEY (service_id, staff_id) 
);

CREATE TABLE IF NOT EXISTS appointment( --we store appointments FOR EACH patient AND their date 
	appointment_id BIGSERIAL PRIMARY KEY,
	staff_id INT NOT NULL,
    service_id INT NOT NULL,
    FOREIGN KEY (staff_id, service_id) REFERENCES staffservice(staff_id, service_id),
    appointment_date DATE,
    patient_id INT NOT NULL REFERENCES patient(patient_id)
);

--inserting data into the tables 
--below i create cte for each table before insert, it helps to make check easier to avoid duplicates  

WITH cte_country AS  --creating CTE TO INSERT it INTO the TABLE country 
( SELECT 'Serbia' AS country
UNION ALL SELECT'Russia'
UNION ALL SELECT 'Georgia'
UNION ALL SELECT 'Belarus'
UNION ALL SELECT 'Egypt')

INSERT INTO country (country)
SELECT country FROM cte_country
WHERE NOT EXISTS (SELECT country FROM country WHERE upper(country)=upper(cte_country.country)); --CHECK IF we already have such DATA INTO the table

WITH cte_city AS
(SELECT 'Belgrade' AS city 
UNION ALL SELECT 'Novi Sad'
UNION ALL SELECT 'Nis'
UNION ALL SELECT 'Kraljevo'
UNION ALL SELECT 'Subotica')

INSERT INTO city (city, country_id)
SELECT city,
		(SELECT country_id  --SELECT TO GET 'Serbia' id IN country table
		FROM country
		WHERE upper(country) = 'SERBIA')
FROM cte_city
WHERE NOT EXISTS (SELECT city FROM city WHERE upper(city)=upper(cte_city.city)); --CHECK IF we already have such DATA INTO the TABLE, preventing inseting duplicates 

WITH cte_address AS
(SELECT '1 Ismeta Mujezinovica' AS address, '11000' AS postal_code
UNION ALL SELECT '14 Patrijarha Dimitrija', '11000'
UNION ALL SELECT '74 Pregrevica', '11000'
UNION ALL SELECT '53 Liberation Boulevard', '11060'
UNION ALL SELECT '51b Ljubise Miodragovica', '11050'
UNION ALL SELECT '47 Radnicka', '11070'
UNION ALL SELECT '4 Cucuk Stanina', '11050'
UNION ALL SELECT '147 Dimitrija Tucovica', '11050'
UNION ALL SELECT '26 Hadzi-Melentijeva', '11030'
UNION ALL SELECT '9 Vojvode Stepe', '11040')

INSERT INTO address (address, city_id, postal_code)
SELECT address,
		(SELECT city_id  --SELECT TO GET 'Belgrade' id IN city table
		FROM city
		WHERE upper(city) = 'BELGRADE'),
		postal_code 
FROM cte_address
WHERE NOT EXISTS (SELECT address 
					FROM address
					WHERE upper(address)=upper(cte_address.address) AND upper(postal_code)=upper(cte_address.postal_code)); --CHECK IF we didn't have this address IN the TABLE 

WITH cte_institution AS (
SELECT 'Institute of Infectious and Tropical Diseases' AS title, 
		'institution' AS institution_type, '683366' AS phone, 
		(SELECT address_id FROM address a WHERE lower(address)='1 ismeta mujezinovica') AS address_id
UNION ALL SELECT 'Clinic for Neurology and Psychiatry for Children and Youth', 'clinic', '2658355', (SELECT address_id FROM address a WHERE lower(address)='14 patrijarha dimitrija')
UNION ALL SELECT 'Special Hospital for Cerebral Palsy and Developmental Neurology', 'specializes hospital', '2667755', (SELECT address_id FROM address a WHERE lower(address)='74 pregrevica')
UNION ALL SELECT 'Mosaic Health & Rehab', 'rehub', '3884988', (SELECT address_id FROM address a WHERE lower(address)='53 liberation boulevard')
UNION ALL SELECT 'Special Hospital for Cerebrovascular Diseases „Saint Sava“', 'hospital', '2066800', (SELECT address_id FROM address a WHERE lower(address)='51b ljubise miodragovica'))

INSERT INTO institution(title, phone,institution_type,address_id) 
SELECT title, phone,institution_type,address_id
FROM cte_institution
WHERE NOT EXISTS (SELECT institution_id  
					FROM institution 
					WHERE upper(title)=upper(cte_institution.title));


WITH cte_staff AS 
(SELECT 'Abigail' AS firstname, 'Anderson' AS surname, '1234567' AS phone, 'anderson.abigail@gmail.com' AS email, 'Medical Assistant' AS job_title
UNION ALL SELECT 'Joshua','Campbell', '9876543', 'jcampbell_md@hotmail.com', 'Cardiologist'
UNION ALL SELECT 'Sophia', 'Patel', '5551212', 'sophia.patel@medgroup.com', 'Pediatrician'
UNION ALL SELECT 'Ethan', 'Lee',  '5552424', 'ethan.lee@healthcare.net', 'Emergency Medicine'
UNION ALL SELECT 'Madison', 'Nguyen', '5551313', 'madison.nguyen@docmail.com', 'Nurse Practitioner')

INSERT INTO staff (firstname, surname, phone, email, job_title)
SELECT firstname, surname, phone, email, job_title
FROM cte_staff
WHERE NOT EXISTS (SELECT * FROM staff WHERE lower(firstname)=lower(cte_staff.firstname) AND lower(surname)=lower(cte_staff.surname) AND phone=cte_staff.phone);

WITH cte_service AS
(SELECT 'Annual check-up' AS title, 'A yearly physical examination to evaluate overall health, including blood tests, blood pressure measurements, and other routine health screenings.' AS description
UNION ALL SELECT 'Allergy testing', 'A test to determine if a patient has any allergies and the extent of the allergy, which helps develop a treatment plan to alleviate symptoms.'
UNION ALL SELECT 'Dermatology consultation', 'A consultation with a dermatologist to evaluate and treat skin conditions such as acne, eczema, psoriasis, and rashes'
UNION ALL SELECT 'Gynecology exam', ' An exam to assess womens reproductive health, including pap smear, pelvic exam, breast exam, and screening for sexually transmitted diseases.'
UNION ALL SELECT 'Cardiology consultation', 'A consultation with a cardiologist to assess and treat cardiovascular diseases such as hypertension, heart failure, and arrhythmia.'
UNION ALL SELECT 'Physical therapy', 'A treatment program that aims to restore mobility and function after an injury, surgery, or illness.'
UNION ALL SELECT 'Diabetes management', 'A personalized care plan for patients with diabetes, including medication management, dietary guidance, and lifestyle changes to manage blood sugar levels.'
UNION ALL SELECT 'Pain management', 'reatment options for chronic pain, including medication management, physical therapy, and non-pharmacological therapies such as acupuncture and massage.'
UNION ALL SELECT 'Nutrition counseling', 'A consultation with a registered dietician to develop a personalized nutrition plan for patients with various dietary needs, including weight loss or management of chronic conditions.'
UNION ALL SELECT 'Sleep study', 'A diagnostic test to evaluate sleep patterns, identify the presence of sleep disorders such as sleep apnea, and develop a treatment plan to improve sleep quality.')

INSERT INTO service (title, description, institution_id)
SELECT title, description, (SELECT institution_id FROM institution WHERE lower(title)='clinic for neurology and psychiatry for children and youth')
FROM cte_service
WHERE NOT EXISTS (SELECT * 
					FROM service
					WHERE lower(title) = lower(cte_service.title) AND 
						(SELECT institution_id FROM institution WHERE lower(title)='clinic for neurology and psychiatry for children and youth') = (SELECT institution_id FROM Service WHERE lower(title) = lower(cte_service.title)));
						--to check duplicates in this case we check if there is no combination service+institution
					
WITH cte_staffservice AS 
(SELECT (SELECT staff_id FROM staff WHERE lower(email)='anderson.abigail@gmail.com') AS staff_id, 
		(SELECT service_id FROM service WHERE lower(title)='gynecology exam') AS service_id
UNION ALL SELECT (SELECT staff_id FROM staff WHERE lower(email)='anderson.abigail@gmail.com'), 
					(SELECT service_id FROM service WHERE lower(title)='cardiology consultation')
UNION ALL SELECT (SELECT staff_id FROM staff WHERE lower(email)='anderson.abigail@gmail.com'), 
					(SELECT service_id FROM service WHERE lower(title)='sleep study')
UNION ALL SELECT (SELECT staff_id FROM staff WHERE lower(email)='jcampbell_md@hotmail.com'), 
					(SELECT service_id FROM service WHERE lower(title)='cardiology consultation')
UNION ALL SELECT (SELECT staff_id FROM staff WHERE lower(email)='jcampbell_md@hotmail.com'), 
					(SELECT service_id FROM service WHERE lower(title)='sleep study')
UNION ALL SELECT (SELECT staff_id FROM staff WHERE lower(email)='madison.nguyen@docmail.com'), 
					(SELECT service_id FROM service WHERE lower(title)='sleep study'))
					
INSERT INTO staffservice(service_id, staff_id) 
SELECT service_id, staff_id
FROM cte_staffservice
WHERE NOT EXISTS (SELECT * FROM staffservice  WHERE staff_id=cte_staffservice.staff_id AND  service_id = cte_staffservice.service_id);

WITH cte_patient AS
(SELECT 'Emma' AS firstname, 'Johnson' AS surname, '82042650333' AS id_number, '20000102229000' AS insurance_number, '1234567' AS phone, 'emma.johnson@gmail.com' AS email, 
		(SELECT address_id FROM address a WHERE lower(address)='47 radnicka') AS address_id
UNION ALL SELECT 'Benjamin', 'Lee', '90031770129', '19960917141200', '9876543', 'benjamin.lee@hotmail.com', (SELECT address_id FROM address a WHERE lower(address)='4 cucuk stanina')
UNION ALL SELECT 'Ava', 'Martinez', '85091310261', '20040507230901', '5551212', 'ava.martinez@healthcaregroup.com', (SELECT address_id FROM address a WHERE lower(address)='147 dimitrija tucovica')
UNION ALL SELECT 'William', 'Davis', '92020240156', '19930303142100', '5552424', 'william.davis@medgroup.net', (SELECT address_id FROM address a WHERE lower(address)='26 hadzi-melentijeva')
UNION ALL SELECT 'Mia', 'Smith', '99060280101', '20031023150101', '5551313', 'mia.smith@docmail.com', (SELECT address_id FROM address a WHERE lower(address)='9 vojvode stepe'))

INSERT INTO patient(firstname, surname, id_number, insurance_number, phone, email, address_id)
SELECT firstname, surname, id_number, insurance_number, phone, email, address_id
FROM cte_patient 
WHERE NOT EXISTS (SELECT * FROM patient WHERE id_number = cte_patient.id_number);

WITH cte_appointment AS 
(SELECT (SELECT patient_id FROM patient WHERE id_number = '90031770129') AS patient_id,
		(SELECT staff_id FROM staff WHERE lower(email)='anderson.abigail@gmail.com') AS staff_id, 
		(SELECT service_id FROM service WHERE lower(title)='gynecology exam') AS service_id,
		date '2023-04-01' AS appointment_date
UNION ALL SELECT (SELECT patient_id FROM patient WHERE id_number = '90031770129') AS patient_id,
				(SELECT staff_id FROM staff WHERE lower(email)='anderson.abigail@gmail.com') AS staff_id, 
				(SELECT service_id FROM service WHERE lower(title)='cardiology consultation') AS service_id,
				date '2023-04-01'
UNION ALL SELECT (SELECT patient_id FROM patient WHERE id_number = '90031770129') AS patient_id,
				(SELECT staff_id FROM staff WHERE lower(email)='anderson.abigail@gmail.com') AS staff_id, 
				(SELECT service_id FROM service WHERE lower(title)='cardiology consultation') AS service_id,
				date '2023-03-01'
UNION ALL SELECT (SELECT patient_id FROM patient WHERE id_number = '90031770129') AS patient_id,
				(SELECT staff_id FROM staff WHERE lower(email)='anderson.abigail@gmail.com') AS staff_id, 
				(SELECT service_id FROM service WHERE lower(title)='cardiology consultation') AS service_id,
				date '2023-03-09'
UNION ALL SELECT (SELECT patient_id FROM patient WHERE id_number = '90031770129') AS patient_id,
				(SELECT staff_id FROM staff WHERE lower(email)='anderson.abigail@gmail.com') AS staff_id, 
				(SELECT service_id FROM service WHERE lower(title)='cardiology consultation') AS service_id,
				date '2023-03-08'
UNION ALL SELECT (SELECT patient_id FROM patient WHERE id_number = '90031770129') AS patient_id,
				(SELECT staff_id FROM staff WHERE lower(email)='anderson.abigail@gmail.com') AS staff_id, 
				(SELECT service_id FROM service WHERE lower(title)='cardiology consultation') AS service_id,
				date '2023-03-07'
UNION ALL SELECT (SELECT patient_id FROM patient WHERE id_number = '90031770129') AS patient_id,
				(SELECT staff_id FROM staff WHERE lower(email)='anderson.abigail@gmail.com') AS staff_id, 
				(SELECT service_id FROM service WHERE lower(title)='cardiology consultation') AS service_id,
				date '2023-03-06'
UNION ALL SELECT (SELECT patient_id FROM patient WHERE id_number = '90031770129') AS patient_id,
				(SELECT staff_id FROM staff WHERE lower(email)='anderson.abigail@gmail.com') AS staff_id, 
				(SELECT service_id FROM service WHERE lower(title)='cardiology consultation') AS service_id,
				date '2023-03-05'
UNION ALL SELECT (SELECT patient_id FROM patient WHERE id_number = '90031770129') AS patient_id,
				(SELECT staff_id FROM staff WHERE lower(email)='anderson.abigail@gmail.com') AS staff_id, 
				(SELECT service_id FROM service WHERE lower(title)='cardiology consultation') AS service_id,
				date '2023-03-04'
UNION ALL SELECT (SELECT patient_id FROM patient WHERE id_number = '90031770129') AS patient_id,
				(SELECT staff_id FROM staff WHERE lower(email)='anderson.abigail@gmail.com') AS staff_id, 
				(SELECT service_id FROM service WHERE lower(title)='cardiology consultation') AS service_id,
				date '2023-04-03'
UNION ALL SELECT (SELECT patient_id FROM patient WHERE id_number = '90031770129') AS patient_id,
				(SELECT staff_id FROM staff WHERE lower(email)='anderson.abigail@gmail.com') AS staff_id, 
				(SELECT service_id FROM service WHERE lower(title)='cardiology consultation') AS service_id,
				date '2023-03-02'
UNION ALL SELECT (SELECT patient_id FROM patient WHERE id_number = '90031770129') AS patient_id,
				(SELECT staff_id FROM staff WHERE lower(email)='anderson.abigail@gmail.com') AS staff_id, 
				(SELECT service_id FROM service WHERE lower(title)='cardiology consultation') AS service_id,
				date '2023-03-01'
UNION ALL SELECT (SELECT patient_id FROM patient WHERE id_number = '90031770129') AS patient_id,
				(SELECT staff_id FROM staff WHERE lower(email)='jcampbell_md@hotmail.com') AS staff_id, 
				(SELECT service_id FROM service WHERE lower(title)='sleep study') AS service_id,
				date '2023-03-08'
UNION ALL SELECT (SELECT patient_id FROM patient WHERE id_number = '90031770129') AS patient_id,
				(SELECT staff_id FROM staff WHERE lower(email)='jcampbell_md@hotmail.com') AS staff_id, 
				(SELECT service_id FROM service WHERE lower(title)='sleep study') AS service_id,
				date '2023-03-07'
UNION ALL SELECT (SELECT patient_id FROM patient WHERE id_number = '90031770129') AS patient_id,
				(SELECT staff_id FROM staff WHERE lower(email)='jcampbell_md@hotmail.com') AS staff_id, 
				(SELECT service_id FROM service WHERE lower(title)='sleep study') AS service_id,
				date '2023-03-06'
UNION ALL SELECT (SELECT patient_id FROM patient WHERE id_number = '90031770129') AS patient_id,
				(SELECT staff_id FROM staff WHERE lower(email)='madison.nguyen@docmail.com') AS staff_id, 
				(SELECT service_id FROM service WHERE lower(title)='sleep study') AS service_id,
				date '2023-03-05'
UNION ALL SELECT (SELECT patient_id FROM patient WHERE id_number = '90031770129') AS patient_id,
				(SELECT staff_id FROM staff WHERE lower(email)='madison.nguyen@docmail.com') AS staff_id, 
				(SELECT service_id FROM service WHERE lower(title)='sleep study') AS service_id,
				date '2023-03-04'
UNION ALL SELECT (SELECT patient_id FROM patient WHERE id_number = '90031770129') AS patient_id,
				(SELECT staff_id FROM staff WHERE lower(email)='madison.nguyen@docmail.com') AS staff_id, 
				(SELECT service_id FROM service WHERE lower(title)='sleep study') AS service_id,
				date '2023-04-03'
UNION ALL SELECT (SELECT patient_id FROM patient WHERE id_number = '90031770129') AS patient_id,
				(SELECT staff_id FROM staff WHERE lower(email)='madison.nguyen@docmail.com') AS staff_id, 
				(SELECT service_id FROM service WHERE lower(title)='sleep study') AS service_id,
				date '2023-03-02'
UNION ALL SELECT (SELECT patient_id FROM patient WHERE id_number = '90031770129') AS patient_id,
				(SELECT staff_id FROM staff WHERE lower(email)='madison.nguyen@docmail.com') AS staff_id, 
				(SELECT service_id FROM service WHERE lower(title)='sleep study') AS service_id,
				date '2023-03-01'
UNION ALL SELECT (SELECT patient_id FROM patient WHERE id_number = '90031770129') AS patient_id,
				(SELECT staff_id FROM staff WHERE lower(email)='madison.nguyen@docmail.com') AS staff_id, 
				(SELECT service_id FROM service WHERE lower(title)='sleep study') AS service_id,
				date '2022-03-01')
				
INSERT INTO appointment (staff_id, service_id,patient_id,appointment_date)
SELECT staff_id, service_id,patient_id,appointment_date
FROM cte_appointment
WHERE NOT EXISTS (SELECT * 
					FROM appointment 
					WHERE staff_id = cte_appointment.staff_id AND service_id=cte_appointment.service_id 
					AND patient_id=cte_appointment.patient_id AND appointment_date = cte_appointment.appointment_date);

/*we'll insert data in room table but there's a lot of opportunities for scaling DB here and adding functionality 
for example we can add table to connect room and patient and his/her dates of staying in the hospital 
it'll help to count available beds and so on
also I will not check duplicates here sinse we can have a lot of similar rooms of one type and one capacity in the same institution

WITH cte_room AS 				
(SELECT 'single' AS room_type, 1 AS capacity
UNION ALL SELECT 'double', 3
UNION ALL SELECT 'recovery', 6
UNION ALL SELECT 'ward', 10
UNION ALL SELECT 'isolation', 5
UNION ALL SELECT 'ward', 10
UNION ALL SELECT 'operating', 3)

INSERT INTO room (institution_id, room_type, capacity)
SELECT (SELECT institution_id FROM institution WHERE lower(title) = 'mosaic health & rehab'),
		room_type , capacity 
FROM cte_room
*/
				

--retreiving doctors with insuficcient workload
				
--CTE RESULT TABLE - id, YEAR, MONTH AND we count number OF patients FOR EACH MONTH OF the YEAR FOR EACH staff member
WITH cte_workload AS(
SELECT appointment.staff_id , 
		EXTRACT (YEAR FROM appointment_date), 
		EXTRACT (MONTH FROM appointment_date), 
		COUNT(*) AS workload  
FROM appointment
WHERE appointment_date >= current_date - INTERVAL '3 month' --identified 'few months' FROM the task AS 3 months 
GROUP BY 1,2,3 --GROUP bi staff_id, YEAR AND MONTH TO count appointments FOR EACH month
ORDER BY 1,2,3)

SELECT DISTINCT staff.staff_id, staff.surname , staff.firstname  
FROM cte_workload
RIGHT  JOIN staff --JOIN staff TO GET names, use RIGHT JOIN so we can see staff even IF there IS NO appointment WITH him/her 
ON staff.staff_id = cte_workload.staff_id
WHERE staff.staff_id NOT IN (SELECT staff_id FROM cte_workload WHERE workload>5); --we remove ALL staff_id wehere AT LEAST IN one MONTH workload > 5 