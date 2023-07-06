CREATE DATABASE IF NOT EXISTS homework5_db;
USE homework5_db;

CREATE TABLE cars
(
	id INT NOT NULL PRIMARY KEY,
    name VARCHAR(45),
    cost INT
);

INSERT cars
VALUES
	(1, "Audi", 52642),
    (2, "Mercedes", 57127 ),
    (3, "Skoda", 9000 ),
    (4, "Volvo", 29000),
	(5, "Bentley", 350000),
    (6, "Citroen ", 21000 ), 
    (7, "Hummer", 41400), 
    (8, "Volkswagen ", 21600);

SELECT * FROM cars;

/*
1.	Создайте представление, в которое попадут автомобили стоимостью  до 25 000 долларов
*/
CREATE VIEW cost_25
AS
SELECT
	name,
    cost
FROM cars
WHERE cost < 25000
ORDER BY cost; 

SELECT * FROM cost_25;

/*
2.	Изменить в существующем представлении порог для стоимости: пусть цена будет до 30 000 долларов (используя оператор OR REPLACE) 
*/
-- если представление существует, то заменим его
CREATE OR REPLACE VIEW cost_25
AS
SELECT
name,
    cost
FROM cars
WHERE cost < 30000
ORDER BY cost; 

-- покажем обновленное представление
SELECT * FROM cost_25;

-- представление нам больше не потребуется, можно удалить
DROP VIEW cost_25;

/*
3. 	Создайте представление, в котором будут только автомобили марки “Шкода” и “Ауди”
*/

CREATE VIEW select_brands
AS
SELECT
	name,
    cost
FROM cars
WHERE name IN("Skoda", "Audi")
ORDER BY name; 

SELECT * FROM select_brands;

/*
Добавьте новый столбец под названием «время до следующей станции». 
Чтобы получить это значение, мы вычитаем время станций для пар смежных станций.
 Мы можем вычислить это значение  без использования оконной функции SQL, но это может быть очень сложно. 
 Проще это сделать с помощью оконной функции LEAD . 
 Эта функция сравнивает значения из одной строки со следующей строкой, чтобы получить результат.
 В этом случае функция сравнивает значения в столбце «время» для станции со станцией сразу после нее.
*/

DROP TABLE IF EXISTS train_shedule;
CREATE TABLE train_shedule
(
train_id INT,
station VARCHAR(20),
station_time TIME(0)
);

INSERT INTO train_shedule
  (train_id, station, station_time)
VALUES 
  (110, 'San Francisco', '10:00:00'),
        (110, 'Redwood City', '10:54:00'),
        (110, 'Paolo Alto', '11:02:00'),
        (110, 'San Jose', '12:35:00'),
        (120, 'San Francisco', '11:00:00'),
        (120, 'Paolo Alto', '12:49:00'),
        (120, 'San Jose', '13:30:00');
        
SELECT *
FROM train_shedule;

-- добавляем к таблице столбец
ALTER TABLE train_shedule
ADD COLUMN time_to_next_station TIME(0);

-- вычисляем разницу во времени и заносим значения из нашей выборки в созданный столбец (обновление таблицы)
UPDATE train_shedule ts1
JOIN(
SELECT 
	train_id,
    station_time,
    TIMEDIFF(
    LEAD(station_time) OVER (PARTITION BY train_id ORDER BY station_time), station_time
    ) AS time_to_next_station       
FROM train_shedule) ts2
ON ts1.train_id = ts2.train_id
AND ts1.station_time = ts2.station_time
SET ts1.time_to_next_station = ts2.time_to_next_station;


/*
Для скрипта, поставленного в прошлом уроке (vk_db только с расширенными данными).
*/
USE vk;
-- Получите друзей пользователя с id=1
-- (решение задачи с помощью представления “друзья”)
CREATE OR REPLACE VIEW friends
AS
SELECT DISTINCT u.id, u.firstname, u.lastname
FROM users u
JOIN (
    SELECT initiator_user_id, target_user_id
    FROM friend_requests
    WHERE (initiator_user_id = 1 OR target_user_id = 1) AND status = 'approved'
) fr ON u.id = 
	CASE
		WHEN fr.initiator_user_id = 1 
			THEN fr.target_user_id
		ELSE fr.initiator_user_id
	END
WHERE u.id != 1
ORDER BY u.id;

SELECT * FROM friends;

-- Создайте представление, в котором будут выводится все сообщения, в которых принимал
-- участие пользователь с id = 1.
CREATE OR REPLACE VIEW all_messages
AS
SELECT 
	m.id,
    m.from_user_id,
    m.to_user_id,
    m.body,
    m.created_at
FROM messages m
WHERE m.from_user_id = 1 OR m.to_user_id = 1;

SELECT * FROM all_messages;

-- Получите список медиафайлов пользователя с количеством лайков(media m, likes l ,users u)
SELECT
	m.id,
	u.firstname,    
    u.lastname,
    m.filename AS media_name,
    COUNT(l.id) AS total_likes
FROM media m
JOIN users u ON u.id = m.user_id
JOIN likes l ON l.media_id = m.id
GROUP BY u.firstname
ORDER BY total_likes;

-- Получите количество групп у пользователей
SELECT 
	user_id,
    firstname,
    lastname,
    MAX(group_number) AS group_count
FROM (
    SELECT 
    u.id AS user_id,
    u.firstname,
    u.lastname,
    uc.community_id,
    ROW_NUMBER() OVER (PARTITION BY u.id ORDER BY uc.community_id) AS group_number
    FROM users AS u
    LEFT JOIN users_communities AS uc ON u.id = uc.user_id
) AS subquery
GROUP BY user_id, firstname, lastname;

/* 
	1. Создайте представление, в которое попадет информация о пользователях (имя, фамилия, город и пол), которые не старше 20 лет.
*/

CREATE OR REPLACE VIEW adults
AS
SELECT
	CONCAT(u.firstname, ' ', u.lastname) AS full_name,	
    p.gender,
    p.hometown AS city
FROM users u
JOIN `profiles` p ON u.id = p.user_id 
WHERE DATEDIFF(CURRENT_DATE(), p.birthday) <= 20*365 
GROUP BY full_name
ORDER BY city;

SELECT * FROM adults;

/* 
	2. Найдите кол-во, отправленных сообщений каждым пользователем и выведите ранжированный список пользователей, указав имя и фамилию пользователя,
 количество отправленных сообщений и место в рейтинге (первое место у пользователя с максимальным количеством сообщений) . (используйте DENSE_RANK)
 */ 
SELECT 
	firstname,
    lastname,
    message_count,
    DENSE_RANK() OVER (ORDER BY message_count DESC) AS ranking
FROM (
    SELECT
    u.firstname,
    u.lastname,
    COUNT(*) AS message_count
    FROM users u
    JOIN messages m ON u.id = m.from_user_id
    GROUP BY u.firstname, u.lastname
) AS subquery
ORDER BY ranking;

/*
	3. Выберите все сообщения, отсортируйте сообщения по возрастанию даты отправления (created_at) и найдите разницу
 дат отправления между соседними сообщениями, получившегося списка. (используйте LEAD или LAG)
 */

SELECT id,
	   body,
	   created_at,	  
       DATEDIFF(created_at, LAG(created_at) OVER (ORDER BY created_at)) AS days_diff
FROM messages
ORDER BY created_at;