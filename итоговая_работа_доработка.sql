/* 1. � ����� ������� ������ ������ ���������? */

select distinct city as "�������� ������", count(airport_code) as "���������� ����������"
from airports
group by city
having count(*) > 1

/* ������� ���������� ���������� ���������� count, ���������� �� ������
 * ��� ��� � ���� � ����� ������ ��������� ����������, �� �� � ������ ��������� ������� ���, ������� � ��� �����������
 * � ��� ��� �� ���� - ������� ������ ���������� ������������
 * ������������ ������ ������ ���� ��������, ��� ���������� ���������� ����� ������ */

/* 2. � ����� ���������� ���� �����, ����������� ��������� � ������������ ���������� ��������?
������������ ������� - ������������ ��������� */

select a.model as "������ ��������", f.departure_airport as "�������� ���������", a.range as "��������� ������"
from (select range, model, aircraft_code 
from aircrafts
order by "range" desc
limit 1
) as a
left join flights f on a.aircraft_code = f.aircraft_code
left join airports a2 on a2.airport_code = f.departure_airport 
group by f.departure_airport, a.model, a."range" 

/* � ������� ���������� ����������, ����� ������ (��������, ���) ����� ���������� ��������� ������,
 * ������ ���� ������ �������, ������������ �� �������� ��������� � ������� ������ ������ � ���������� ����������
 * ������������ ������ ��������� � ����������. ���������� ����� ����� �������� ����, ��� ���, ��� �����������,
 * ���� �� ����� �������� ������ �� ������. ��� ��� �������, ����� ����� � ������� �6.
 * ��� ������� ������ ��������� ������� � ������� ��������, ��������� ��������� � ���������� ������
 * ���� ������ ������ �������� ��������� */

/* 3. ������� 10 ������ � ������������ �������� �������� ������
 ������������ ������� - ������������ �������� limit */

select flight_id as "����� �����", (actual_departure - scheduled_departure) as "�������� �����"
from flights
where status in ('Delayed','Departed','Arrived') 
and actual_departure - scheduled_departure is not null
order by "�������� �����" desc
limit 10

/* �������� ����� ��������� ����� ������� ����� ������������ �� ���������� � ����������� ������������
 * ����������� ����� ����� ����� ������ "�������", "�������" � "��������" - ����� "�� ����������" � "�������" �� ��������
 * ������������ ������ ���������� (������, �� null) ���������� ��������
 * ��������� �� �������� � ������������ ������ 10 �������� */

/* 4. ���� �� �����, �� ������� �� ���� �������� ���������� ������?
 ������������ ������� - ������������ ������ ��� join */

select b.book_ref as "����� ������������", t.ticket_no as "����� ������", 
bp.boarding_no as "����� ����������� ������"
from bookings b
join tickets t on b.book_ref = t.book_ref 
left join boarding_passes bp on bp.ticket_no = t.ticket_no 
where bp.boarding_no is null

/* �����, �� ������� �� �������� ���������� ������ - ��� ���� ���� ����� �����, ����� ������, �� ��� 
 * ������ ����������� ������
 * ������� � ������� � �������� (������� ����) ������������ ������� � ����������� �������� ���, �����
 * �� ������� ������ � ������� � �������� 
 * � ������� is null ���� ������ ������ � ���������� ������� */

/* 5. ������� ��������� ����� ��� ������� �����, �� % ��������� � ������ ���������� ���� � ��������.
�������� ������� � ������������� ������ - ��������� ���������� ���������� ���������� ���������� 
�� ������� ��������� �� ������ ����. �.�. � ���� ������� ������ ���������� ������������� ����� - ������� �������
��� �������� �� ������� ��������� �� ���� ��� ����� ������ ������ �� ����.
������������ ������� - ������������ ������� ������� � ���������� */

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

/* � ������ ���������� t1 ������� ���������� ������� ���� �� ������ ����� �� ����� ���������� �������.
 * �� ������ ���������� t2 ������� ���������� ���� ������ �� ������ ����� � ����������� �� ���� ���������� �����
 * ������� ��� ����������, ������ ���������� ��� �� ���������� ��� ������, �� ������� ���� ������ ����������
 * ������ - �� ���� ��� ���������, � �����, �� ������� ���������� �� ���� ������, ���������
 * � ������� �������������� �������� ������� ������� ����� ����� ������ ���� � ������ ������� ���� - ���
 * ��������� �����, ����� ������� �� ����� - % �������
 * ����������� ������� ������� ����� �� ��������� ����������� � �� ���� */

/* 6. ������� ���������� ����������� ��������� �� ����� ��������� �� ������ ����������.
 ������������ ������� - ������������� ���������� � ��������� ROUND */

select t2.model as "������ ��������", t2.cm as "���������� ���������",
round(t2.cm/t2.summ, 4)*100 as "������� ���������"
from (select t1.model, t1.cm, sum(t1.cm) over () as summ
from (select a.model, f.aircraft_code, count(f.flight_id) as cm
from aircrafts a 
left outer join flights f on f.aircraft_code = a.aircraft_code 
group by a.model, f.aircraft_code
) as t1
group by t1.model, t1.cm
order by t1.cm) as t2

/* � ������ ���������� �������, ������� ��������� ��������� ������ ������ (������������ ������ � �� ���)
 * �� ������ ���������� ������� ��������� ���������� ����������� ��������� ��� ���� ����� ���������
 * � �������� ���������� ����� ���������� ���������, ����������� ������ �������, �� ��������� �� �����, 
 * ��������� �� ������� ����� (��� �������� �����).
 * �����, ��� ������ �320, ���� ������ �����, ���� ������ ��������� - 0% ���������)
 *  */

/* 7. ���� �� ������, � ������� �����  ��������� ������ - ������� �������, ��� ������-������� � ������ ��������?
������������ ������� - ������������� cte */

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

/* � ������� cte �������� ������, � ������� ����� ��������� - ��� ���������� ������ �� ������ �������.
 * � ������� cte2 ������� ����������� ��������� ������ � ������-����� � ������������ - � ������-����� � ������
 * ���������� ��������.
 * ���������� ��� ��������� ������� � ����������� �������, ��� � ������ �������� ������ ���� � ������-�����,
 * � ������-����� (���� �������� ��������� ������ cte2, �����, ��� ��� ��������� ������ ���� �������� null,
 * �� ���� ��� ������-�� �� �������), � ����� ����������� ��������� ������� ������ ���� ������ ������������
 * ��������� �������
 * �������� ������ ������ - �� ����, ����� ������� �� ���� */

/* 8. ����� ������ �������� ��� ������ ������?
������������ ������� - ��������� ������������ � ����������� FROM; �������������� ��������� �������������;
�������� EXCEPT */

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
 
 /* ������� ������������� routes_cities � ��������� ������ ������ � �������, ������ ���������� ������ � �������, 
 * ����� ������� ������� �������� � �������������� �������, ���������� ����� ������������� ����� ������������� 
 * ��������� ������� CTE_2 ��������� ������, ����� ������ ������� ������� (��������� ���� ������� ������ � �������).
 * ����� ��������� ������������ �������, � ������� ��������� ����������, ��������� �������� distinct.
 * ������� � ������� CTE ��������� �������, � ������� ��������� ��������� ������������ �������� ������ ��� 
 * ��������� ���� ������� ������ � ������� ��� ����������� �� ������� ����� ���� ���������. 
 * ������� ����� � "�������" �������� (����� ����� ������ � ������� ����������) � ������� ������� where. 
 * ����� �������� ������ ����, ����� �������� ��� ������ ������, �������� ���������� EXCEPT
 * �� ����� ������� � ������ ����� ���������� ������ (CTE) ������� � ������, ��� ���� ������ �������� (CTE_2).  */

/* 9. ��������� ���������� ����� �����������, ���������� ������� �������, 
�������� � ���������� ������������ ���������� ��������� � ���������, ������������� ��� �����.
������������ ������� - �������� RADIANS ��� ������������� sind/cosd */

--������ �� ������� ���������� �� ���������
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

--������ �� ������� ���������� �� ������������ �������� ������
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

/* ������ ����� �������� ����������, ������ � ����� ��� �������� ���������� �� ������ � ������� ��������� �������,
 * ��������� � ���������, �� ������ - �������, ����������� � ������� � �������� ������. ���������� ������ :)
 * � ������ cte ������� �������, � ������� � ���� ��������� ������ � ������� ����������� �� ������ � �������,
 * ������� �� �������(��������) ���������� � ���������� ����� ����. 
 * �� ������ cte_2 ������� � ��������������� ������ ������ ��������, ����������� ����, � �� ���������� ���������
 * ������.
 * ����� ��������� ��������� ������� �� �������������� ������ � �������� �� ������, ��� ������������ ���������
 * ������ ���������� ����� �����������. 
 * �� ������� �� ������� � �������� ������ ��� �������� ��������, � �� ����� �� ��������, ��� ���� �������
 * ������ ���� ��������� :) ���� �� ������� �� �������� ���������� distance ������ ������ �� ������, ��������,
 * ����� ������� � ������� ���������� 667 ��, ��� ������ � ������. */