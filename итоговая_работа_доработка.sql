/* 1. В каких городах больше одного аэропорта? */

select distinct city as "Название города", count(airport_code) as "Количество аэропортов"
from airports
group by city
having count(*) > 1

/* Считаем количество аэропортов оператором count, группируем по городу
 * Так как в если в одном городе несколько аэропортов, то он в выдаче выведется столько раз, сколько в нем аэропортовБ
 * а нам это не надо - выводим только уникальные наименования
 * Ограничиваем выдачу только теми городами, где количестве аэропортов более одного */

/* 2. В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?
Обязательное условие - использовать подзапрос */

select a.model as "Модель самолета", f.departure_airport as "Название аэропорта", a.range as "Дальность полета"
from (select range, model, aircraft_code 
from aircrafts
order by "range" desc
limit 1
) as a
left join flights f on a.aircraft_code = f.aircraft_code
left join airports a2 on a2.airport_code = f.departure_airport 
group by f.departure_airport, a.model, a."range" 

/* С помощью подзапроса определяем, какая модель (название, код) имеет наибольшую дальность полета,
 * выведя весь список моделей, отсортировав по убыванию дальности и оставив только модель с наибольшей дальностью
 * Присоединяем список передетов и аэропортов. Используем левый джойн интереса ради, так как, как оказывается,
 * один из наших Эйрбусов никуда не летает. Тут это неважно, будет важно в запросе №6.
 * Для красоты выдачи формируем таблицу с моделью самолета, названием аэропорта и дальностью полета
 * Хотя просят только название аэропорта */

/* 3. Вывести 10 рейсов с максимальным временем задержки вылета
 Обязательное условие - использовать оператор limit */

select flight_id as "Номер рейса", (actual_departure - scheduled_departure) as "Задержка рейса"
from flights
where status in ('Delayed','Departed','Arrived') 
and actual_departure - scheduled_departure is not null
order by "Задержка рейса" desc
limit 10

/* Задержку рейса вычисляем через разницу между отправлением по расписанию и фактическим отправлением
 * Задержанные рейсы могут иметь статус "отложен", "вылетел" и "прилетел" - рейсы "по расписанию" и "отменен" не подходят
 * Ограничиваем выдачу ненулевыми (точнее, не null) значениями задержки
 * Сортируем по убыванию и ограничиваем выдачу 10 записями */

/* 4. Были ли брони, по которым не были получены посадочные талоны?
 Обязательное условие - использовать верный тип join */

select b.book_ref as "Номер бронирования", t.ticket_no as "Номер билета", 
bp.boarding_no as "Номер посадочного талона"
from bookings b
join tickets t on b.book_ref = t.book_ref 
left join boarding_passes bp on bp.ticket_no = t.ticket_no 
where bp.boarding_no is null

/* Брони, по которым не получены посадочные талоны - это если есть номер брони, номер билета, но нет 
 * номера посадочного талона
 * Поэтому в таблице с билетами (которые есть) присоединяем таблицу с посадочными талонами так, чтобы
 * не пропали строки в таблице с билетами 
 * С помощью is null ищем пустые записи в посадочных талонах */

/* 5. Найдите свободные места для каждого рейса, их % отношение к общему количеству мест в самолете.
Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров 
из каждого аэропорта на каждый день. Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек
уже вылетело из данного аэропорта на этом или более ранних рейсах за день.
Обязательное условие - использовать оконную функцию и подзапросы */

select t1.flight_id, (total - occupied) as free_seats, 
round(occupied::numeric/total::numeric, 4)*100 as percentage, 
	sum(occupied) over (partition by departure_airport, actual_departure order by occupied),
t2.departure_airport, t2.actual_departure
from (select count(ticket_no) as occupied, flight_id 
from boarding_passes bp 
group by flight_id
order by flight_id) as t1
join (select flight_id, count(seat_no) as total, f.actual_departure, f.departure_airport 
from seats s 
join aircrafts a on s.aircraft_code = a.aircraft_code 
join flights f on f.aircraft_code = a.aircraft_code
group by flight_id
order by flight_id) as t2 on t1.flight_id = t2.flight_id

/* В первом подзапросе t1 находим количество занятых мест на каждом рейсе по числу посадочных талонов.
 * Во втором подзапросе t2 находим количество мест вообще на каждом рейсе в зависимости от типа воздушного судна
 * Джойним два подзапроса, причем сджойнятся они по количеству тех рейсов, на которые были выданы посадочные
 * талоны - то есть уже улетевшие, а рейсы, на которые посадочные не были выданы, отвалятся
 * С помощью математических операций находим разницу между общим числом мест и числом занятых мест - это
 * свободные места, делим занятые на общее - % занятых
 * Накоплением считаем занятые места по аэропорту отправления и по дате */

/* 6. Найдите процентное соотношение перелетов по типам самолетов от общего количества.
 Обязательное условие - использование подзапроса и оператора ROUND */

select t2.model as "Модель самолета", t2.cm as "Количество перелетов",
round(t2.cm/t2.summ, 4)*100 as "Процент перелетов"
from (select t1.model, t1.cm, sum(t1.cm) over () as summ
from (select a.model, f.aircraft_code, count(f.flight_id) as cm
from aircrafts a 
left outer join flights f on f.aircraft_code = a.aircraft_code 
group by a.model, f.aircraft_code
) as t1
group by t1.model, t1.cm
order by t1.cm) as t2

/* В первом подзапросе считаем, сколько перелетов совершила каждая модель (наименование модели и ее код)
 * Во втором подзапросе считаем суммарное количество совершенных перелетов для всех типов самолетов
 * В основном подзапросе делим количество перелетов, совершенных каждой моделью, на суммарное их число, 
 * округляем до второго знака (так красивее всего).
 * Видим, что Эйрбус А320, либо совсем новый, либо совсем сломанный - 0% перелетов)
 *  */

/* 7. Были ли города, в которые можно  добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета?
Обязательное условие - использование cte */

with cte as(
select a.city, tf.flight_id 
from airports a 
join flights f on a.airport_code = f.arrival_airport   
join ticket_flights tf on tf.flight_id = f.flight_id 
group by a.city, tf.flight_id),
cte2 as (select flight_id, min(amount) filter (where fare_conditions = 'Business') as min_business_cost,
max(amount) filter (where fare_conditions = 'Economy') as max_economy_cost
from ticket_flights
group by flight_id
order by flight_id)
select cte.city, cte.flight_id
from cte
join cte2 on cte2.flight_id = cte.flight_id
where cte2.min_business_cost is not null and cte2.max_economy_cost is not null 
and cte2.min_business_cost < cte2.max_economy_cost

/* С помощью cte получаем города, в которые можно добраться - нас интересует список по городу прилета.
 * С помощью cte2 находим минимальную стоимость билета в бизнес-класс и максимульную - в эконом-класс в рамках
 * отдельного перелета.
 * Объединяем обе временные таблицы и прописываем условия, что в рамках перелета должен быть и эконом-класс,
 * и бизнес-класс (если отдельно выполнить запрос cte2, видно, что для некоторых рейсов есть значения null,
 * то есть нет какого-то из классов), а также минимальная стоимость бизнеса должна быть меньше максимальной
 * стоимость эконома
 * Получаем пустую выдачу - то есть, таких городов не было */

/* 8. Между какими городами нет прямых рейсов?
Обязательное условие - декартово произведение в предложении FROM; самостоятельно созданные представления;
оператор EXCEPT */

create view routes_cities as
select f.flight_id,
  	f.departure_airport,
    dep.city as departure_city,
    f.arrival_airport,
    arr.city as arrival_city
    from flights f,
    airports dep,
    airports arr
  where f.departure_airport = dep.airport_code and f.arrival_airport = arr.airport_code
  
with cte as(
select dep.airport_code, arr.airport_code, 
dep.city as city_1, arr.city as city_2  
from airports dep 
cross join airports arr
where dep.airport_code != arr.airport_code
 ),
cte_2 as(
select distinct departure_city as city_1, arrival_city as city_2
from routes_cities
)
select cte.city_1, cte.city_2
from cte
except select cte_2.city_1, cte_2.city_2
from cte_2
 
 /* Создаем представление routes_cities с названием города отлета и прилета, кодами аэропортов вылета и прилета, 
 * чтобы связать кодовые значения с наименованиями городов, применение этого представления через использование 
 * временной таблицы CTE_2 позволяет узнать, какие города связаны рейсами (получатся пары городов вылета и прилета).
 * Чтобы исключить дублирование городов, в которых несколько аэропортов, применяем оператор distinct.
 * Создаем с помощью CTE временную таблицу, в которой используя декартово произведение включаем вообще все 
 * возможные пары городов вылета и прилета вне зависимости от наличия между ними перелетов. 
 * Удаляем дубли и "нулевые" перелеты (когда город вылета и прилета одинаковые) с помощью условия where. 
 * Чтобы оставить только пары, между которыми нет прямых рейсов, вычитаем оператором EXCEPT
 * из общей таблицы с вообще всеми возможными парами (CTE) таблицу с парами, где есть прямые перелеты (CTE_2).  */

/* 9. Вычислите расстояние между аэропортами, связанными прямыми рейсами, 
сравните с допустимой максимальной дальностью перелетов в самолетах, обслуживающих эти рейсы.
Обязательное условие - оператор RADIANS или использование sind/cosd */

--запрос по формуле расстояния из интернета
with cte as(
select f.flight_id, f.departure_airport, f.arrival_airport, dep.longitude, dep.latitude,
arr.longitude, arr.latitude,
6371*asin(sqrt(power((sin(radians((arr.latitude - dep.latitude)/2))), 2) 
+ cos(radians(dep.latitude)*cos(radians(arr.latitude)*power((sin(radians((arr.longitude - dep.longitude)/2))), 2))))) as distance
from flights f,
airports dep,
airports arr 
where f.departure_airport = dep.airport_code and f.arrival_airport = arr.airport_code),
cte_2 as (select f.departure_airport, f.arrival_airport, f.flight_id, a2.aircraft_code, a2.range 
from airports a 
join flights f on a.airport_code = f.arrival_airport    
join aircrafts a2 on a2.aircraft_code = f.aircraft_code)
select cte.flight_id, cte.distance, cte_2.range
from cte
join cte_2 on cte.flight_id = cte_2.flight_id
where cte_2.range < cte.distance
order by cte.flight_id

--запрос по формуле расстояния из формулировки итоговой работы
with cte as(
select f.flight_id, f.departure_airport, f.arrival_airport, dep.longitude, dep.latitude,
arr.longitude, arr.latitude,
6371*acos(sin(radians(dep.latitude))*sin(radians(arr.latitude)) 
+ cos(radians(dep.latitude))*cos(radians(arr.latitude))*cos(radians(dep.longitude - arr.longitude))) as distance
from flights f,
airports dep,
airports arr 
where f.departure_airport = dep.airport_code and f.arrival_airport = arr.airport_code),
cte_2 as (select f.departure_airport, f.arrival_airport, f.flight_id, a2.aircraft_code, a2.range 
from airports a 
join flights f on a.airport_code = f.arrival_airport    
join aircrafts a2 on a2.aircraft_code = f.aircraft_code)
select cte.flight_id, cte.distance, cte_2.range
from cte
join cte_2 on cte.flight_id = cte_2.flight_id
where cte_2.range < cte.distance
order by cte.flight_id

/* Логика обоих запросов одинаковая, просто в одном для рассчета расстояния по широте и долготе использую формулу,
 * найденную в интернете, во втором - формулу, приведенную в задании к итоговой работе. Результаты разные :)
 * В первом cte создаем таблицу, в которой к коду аэропорта вылета и прилета привязываем их широту и долготу,
 * находим по формуле(формулам) расстояние в километрах между ними. 
 * Во втором cte_2 цепляем к идентификаторам рейсов модель самолета, выполняющую рейс, и ее паспортную дальность
 * полета.
 * Далее соединяем временные таблицы по идентификатору полета и выбираем те строки, где максимальная дальность
 * меньше расстояния между аэропортами. 
 * По формуле из задания к итоговой работе все самолеты долетели, а Вы вроде бы говорили, что один самолет
 * должен быть разбиться :) Хотя по формуле из итоговой расстояния distance больше похожи на правду, например,
 * между Москвой и Питером получается 667 км, что близко к истине. */