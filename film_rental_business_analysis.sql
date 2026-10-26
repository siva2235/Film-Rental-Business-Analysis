/*
PROJECT:Film Rental Business Analysis Using MySQL
DATASET:film_rental
NOTES:
- Run schema.sql first, then data.sql, in MySQL.
- This file contains answers to the 15 questions from the project brief.
- Uses MySQL queries without CTEs or window functions.
- Question 9: the actor table has no gender field, so SQL cannot reliably identify
  actresses specifically. The query returns all actors in films whose description
  contains "Wrestler".
*/

use film_rental;

-- Q1. Total revenue generated from all rentals.
select round(sum(amount), 2) as total_revenue
from payment;


-- Q2. Number of rentals made in each month name.
-- Groups by month name across all years in the dataset.
select monthname(rental_date) as month_name,count(*) as total_rentals from rental
group by month(rental_date), MONTHNAME(rental_date)
order by month(rental_date);

-- Q3. Rental rate of the film with the longest title.
select title,char_length(title) as title_length,rental_rate from film
order by char_length(title) desc,title
limit 1;

-- Q4. Average rental rate of films rented in the 30 days before
-- 2005-05-05 22:04:30.
select round(avg(f.rental_rate), 2) as average_rental_rate from rental r
join inventory i on r.inventory_id = i.inventory_id
join film f on i.film_id = f.film_id
where r.rental_date between date_sub('2005-05-05 22:04:30', interval 30 day) and '2005-05-05 22:04:30';

-- Q5. Most popular film category by number of rentals.
select c.name as category_name,count(*) as total_rentals from rental r
join inventory i on r.inventory_id = i.inventory_id
join film_category fc on i.film_id = fc.film_id
join category c on fc.category_id = c.category_id
group by c.category_id, c.name
order by total_rentals desc
limit 1;

-- Q6. Longest film that has never been rented.
select f.title,f.length as movie_duration_minutes from film f
where not exists (select 1 from inventory i join rental r on r.inventory_id = i.inventory_id
where i.film_id = f.film_id)
order by f.length desc
limit 1;

-- Q7. Average rental rate by film category.
select c.name as category_name,round(avg(f.rental_rate), 2) as average_rental_rate from category c
join film_category fc on c.category_id = fc.category_id
join film f on fc.film_id = f.film_id
group by c.category_id, c.name
order by average_rental_rate desc;

-- Q8. Total rental-payment revenue associated with each actor.
-- Each payment is attributed to every actor appearing in the rented film.
select a.actor_id,concat(a.first_name, ' ', a.last_name) as actor_name,
round(coalesce(sum(p.amount), 0), 2) as total_revenue from actor a
left join film_actor fa on a.actor_id = fa.actor_id
left join inventory i on fa.film_id = i.film_id
left join rental r on i.inventory_id = r.inventory_id
left join payment p on r.rental_id = p.rental_id
group by a.actor_id, a.first_name, a.last_name
order by total_revenue desc, actor_name;


-- Q9. Actors in films whose description contains "Wrestler".
-- The dataset has no gender column, so actresses cannot be isolated reliably.
select distinct a.actor_id,concat(a.first_name, ' ', a.last_name) as actor_name,
f.title as film_title,f.description from actor a
join film_actor fa on a.actor_id = fa.actor_id
join film f on fa.film_id = f.film_id
where f.description like '%Wrestler%'
order by actor_name, film_title;

-- Q10. Customers who rented the same film more than once.
select cu.customer_id,concat(cu.first_name, ' ', cu.last_name) as customer_name,
f.film_id,f.title as film_title,count(*) as times_rented from customer cu
join rental r on cu.customer_id = r.customer_id
join inventory i on r.inventory_id = i.inventory_id
join film f on i.film_id = f.film_id
group by cu.customer_id, cu.first_name, cu.last_name, f.film_id, f.title
having count(*) > 1
order by times_rented desc, customer_name;

-- Q11. Comedy films whose rental rate is above the overall average film rental rate.
select f.film_id,f.title,f.rental_rate
from film f
join film_category fc on f.film_id = fc.film_id
join category c on fc.category_id = c.category_id
where c.name = 'Comedy' and f.rental_rate > (select avg(rental_rate) from film)
order by f.rental_rate desc, f.title;

-- Q12. Most-rented film(s) for each city based on customers' home city.
-- Returns ties if multiple films share the highest rental count in a city.
select c.city,f.title AS film_title,city_film.total_rentals
from (select a.city_id,i.film_id,
count(*) as total_rentals from rental r
join customer cu on r.customer_id = cu.customer_id
join address a on cu.address_id = a.address_id
join inventory i on r.inventory_id = i.inventory_id
group by a.city_id, i.film_id) as city_film
join city c on city_film.city_id = c.city_id
join film f ON city_film.film_id = f.film_id
where not exists (select 1 from (select a2.city_id,i2.film_id,
count(*) as total_rentals from rental r2
join customer cu2 on r2.customer_id = cu2.customer_id
join address a2 on cu2.address_id = a2.address_id
join inventory i2 on r2.inventory_id = i2.inventory_id
group by a2.city_id, i2.film_id) as other_city_film
where other_city_film.city_id = city_film.city_id
and other_city_film.total_rentals > city_film.total_rentals)
order by c.city, f.title;


-- Q13. Total amount spent by customers whose total payments exceed $200.
select cu.customer_id,concat(cu.first_name, ' ', cu.last_name) as customer_name,
round(sum(p.amount), 2) as total_spent from customer cu
join payment p on cu.customer_id = p.customer_id
group by cu.customer_id, cu.first_name, cu.last_name
having sum(p.amount) > 200
order by total_spent desc;

-- Q14. View: revenue per staff member, with store city and country.
create or replace view vw_staff_revenue_by_store_location as
select s.staff_id,concat(s.first_name, ' ', s.last_name) as staff_name,
st.store_id,ci.city as store_city,co.country as store_country,
round(coalesce(sum(p.amount), 0), 2) as total_revenue from staff s
join store st on s.store_id = st.store_id
join address ad on st.address_id = ad.address_id
join city ci on ad.city_id = ci.city_id
join country co on ci.country_id = co.country_id
left join payment p on s.staff_id = p.staff_id
group by s.staff_id, s.first_name, s.last_name,st.store_id, ci.city, co.country;

-- View results:
select * from vw_staff_revenue_by_store_location
order by total_revenue desc;