--Вывести к каждому самолету класс обслуживания и количество мест этого класса
SELECT model AS Самолет,
       fare_conditions AS Клас_обслуживания,
       count(seat_no) AS Количество_мест
FROM aircrafts_data
         LEFT JOIN seats
                   ON(aircrafts_data.aircraft_code = seats.aircraft_code)
GROUP BY Самолет,
         Клас_обслуживания
ORDER BY model;

--Найти 3 самых вместительных самолета (модель + кол-во мест)
SELECT  model AS Самолет, count(seat_no) AS Количество_мест
FROM aircrafts_data
         LEFT JOIN seats
                   ON(aircrafts_data.aircraft_code = seats.aircraft_code)
GROUP BY Самолет
ORDER BY Количество_мест DESC
    LIMIT 3;

--Найти все рейсы, которые задерживались более 2 часов
SELECT *
FROM flights
WHERE actual_departure IS NOT NULL
  AND actual_arrival IS NOT NULL
  AND (actual_arrival - actual_departure) > interval '2 hours';

--Найти последние 10 билетов, купленные в бизнес-классе (fare_conditions = 'Business'), с указанием имени пассажира и контактных данных
SELECT tickets.passenger_name, tickets.contact_data
FROM tickets
         JOIN ticket_flights ON tickets.ticket_no = ticket_flights.ticket_no
WHERE ticket_flights.fare_conditions = 'Business'
ORDER BY tickets.book_ref DESC
LIMIT 10;


--Найти все рейсы, у которых нет забронированных мест в бизнес-классе (fare_conditions = 'Business')
SELECT *
FROM flights
WHERE NOT EXISTS (
    SELECT *
    FROM seats
    WHERE seats.aircraft_code = flights.aircraft_code
      AND seats.fare_conditions = 'Business'
);


--Получить список аэропортов (airport_name) и городов (city), в которых есть рейсы с задержкой по вылету
SELECT DISTINCT airports_data.airport_name, airports_data.city
FROM airports_data
         JOIN flights ON airports_data.airport_code = flights.departure_airport
WHERE flights.actual_departure IS NOT NULL
  AND flights.actual_arrival IS NOT NULL
  AND flights.actual_departure > flights.scheduled_departure;


--Получить список аэропортов (airport_name) и количество рейсов, вылетающих из каждого аэропорта, отсортированный по убыванию количества рейсов
SELECT airports_data.airport_name, COUNT(*) AS flight_count
FROM airports_data
         JOIN flights ON airports_data.airport_code = flights.departure_airport
GROUP BY airports_data.airport_name
ORDER BY flight_count DESC;

--Найти все рейсы, у которых запланированное время прибытия (scheduled_arrival) было изменено и новое время прибытия (actual_arrival) не совпадает с запланированным
SELECT *
FROM flights
WHERE actual_arrival IS NOT NULL
  AND scheduled_arrival <> actual_arrival;


--Вывести код, модель самолета и места не эконом класса для самолета "Аэробус A321-200" с сортировкой по местам
SELECT aircrafts_data.aircraft_code,
       aircrafts_data.model,
       seats.seat_no,
       seats.fare_conditions
FROM aircrafts_data
         LEFT JOIN seats
                   ON(aircrafts_data.aircraft_code = seats.aircraft_code)
WHERE seats.fare_conditions !='Economy'
AND aircrafts_data.model = '{"en": "Airbus A321-200", "ru": "Аэробус A321-200"}'::jsonb
ORDER BY seats.seat_no ASC;

--Вывести города, в которых больше 1 аэропорта (код аэропорта, аэропорт, город)
SELECT airport_code AS Код_аэропорта,
       airport_name AS Аэропорт,
       city AS Город
FROM airports_data
         INNER JOIN (
    SELECT city AS city_duplicate
    FROM airports_data
    GROUP BY city
    HAVING COUNT(*) > 1
) duplicate_city ON (airports_data.city  = duplicate_city.city_duplicate);

--Найти пассажиров, у которых суммарная стоимость бронирований превышает среднюю сумму всех бронирований
SELECT passenger_id, SUM(total_amount) AS total_booking_amount
FROM tickets
         JOIN bookings ON tickets.book_ref = bookings.book_ref
GROUP BY passenger_id
HAVING SUM(total_amount) > (
    SELECT AVG(total_amount) FROM bookings
);

--Найти ближайший вылетающий рейс из Екатеринбурга в Москву, на который еще не завершилась регистрация
SELECT *
FROM flights
         INNER JOIN (
    SELECT city AS Отправление, airport_code FROM airports_data
    WHERE city = '{"en": "Yekaterinburg","ru": "Екатеринбург"}'::jsonb) airports_a
                    ON (flights.departure_airport =  airports_a.airport_code)
         INNER JOIN (
    SELECT city AS Прибытие, airport_code  FROM airports_data
    WHERE city = '{"en": "Moscow","ru": "Москва"}'::jsonb) airports_b
                    ON (flights.arrival_airport = airports_b.airport_code)
WHERE flights.status IN ('On Time' )
ORDER BY flights.scheduled_departure DESC
    LIMIT 1;

--Вывести самый дешевый и дорогой билет и стоимость (в одном результирующем ответе)
SELECT DISTINCT * FROM tickets
                           LEFT JOIN (
    SELECT book_ref, total_amount AS price
    FROM bookings
    GROUP BY book_ref
    ORDER BY price DESC
    LIMIT 1
) max_sum ON tickets.book_ref = max_sum.book_ref
WHERE max_sum IS NOT NULL
UNION ALL
SELECT * FROM tickets
                  LEFT JOIN (
    SELECT book_ref, total_amount AS price
    FROM bookings
    GROUP BY book_ref
    ORDER BY price ASC
    LIMIT 1
) min_sum ON tickets.book_ref = min_sum.book_ref
WHERE min_sum IS NOT NULL;

-- Написать DDL таблицы Customers , должны быть поля id , firstName, LastName, email , phone. Добавить ограничения на
--     поля ( constraints).
CREATE TABLE Customers (
                           id SERIAL PRIMARY KEY,
                           firstName CHARACTER VARYING(20) NOT NULL,
                           LastName CHARACTER VARYING(20) NOT NULL,
                           email CHARACTER VARYING(30) CONSTRAINT Customers_email_key UNIQUE,
                           phone CHARACTER VARYING(20) CONSTRAINT customers_phone_key UNIQUE);

-- Написать DDL таблицы Orders , должен быть id, customerId, quantity. Должен быть внешний ключ на таблицу customers +
-- ограничения
CREATE TABLE Orders (
                        id SERIAL PRIMARY KEY,
                        customerId INTEGER,
                        quantity INTEGER,
                        FOREIGN KEY (customerId) REFERENCES Customers (id) ON DELETE CASCADE,
                        CHECK(quantity>0 AND quantity<100)
);

-- Написать 5 insert в эти таблицы
INSERT INTO Customers (firstName,  LastName, email, phone)
VALUES
    ('Artsem', 'Averkov', 'temaaak@mail.ru', +37544505187),
    ('Ivan', 'Ivanov', 'ivan@mail.ru', +3754411111),
    ('Pavel', 'Pavlov', 'pavel@mail.ru', +3754422222),
    ('Petr', 'Petrov', 'petr@mail.ru', +3754433333),
    ('Semen', 'Semenov', 'semen@mail.ru', +3754444444);

INSERT INTO Orders (customerId,  quantity)
VALUES
    (8,1),
    (9,2),
    (10,3),
    (11,4),
    (12,5);

-- удалить таблицы
DROP TABLE Orders, Customers;
