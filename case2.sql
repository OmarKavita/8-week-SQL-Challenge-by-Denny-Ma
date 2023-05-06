use pizza_runner;

-- DATA CLEANING (Customer_orders table) -->
create table customer_orders1 as 
(select order_id, customer_id, pizza_id, exclusions, extras, order_time from customer_orders);
select * from customer_orders1;
update customer_orders1 set 
exclusions = case exclusions when 'null' then null else exclusions end, 
extras = case extras when 'null' then null else extras end; 

-- DATA CLEANING (runner_orders table) -->
create table runner_orders1 as 
(select order_id, runner_id, pickup_time,
case when distance like '%km' then trim('km' from distance) else distance end as distance,
case when duration like '%minutes' then trim('minutes' from duration)
when duration like '%mins' then trim('mins' from duration)
when duration like '%minute' then trim('minute' from duration)
else duration end as duration, cancellation from runner_orders);

update runner_orders1 set
pickup_time = case pickup_time when 'null' then null else pickup_time end,
distance= case distance when 'null' then null else distance end,
duration = case duration when 'null' then null else duration end,
cancellation = case cancellation when 'null' then null else cancellation end; 

-- UPDATING DATATYPE
alter table runner_orders1 modify column pickup_time datetime null,
modify column distance dec(4,1) null,
modify column duration int null;

use pizza_runner;

-- QUESTION SET A- PIZZA METRICS =>
-- Q1.How many pizzas were ordered?
select count( order_id) as Orders from customer_orders1;

#(14 pizzas were ordered)

-- Q2. How many unique customer orders were made?
Select count(distinct order_id) as unique_orders from customer_orders1;

#(total 10 unique cusomer orders were made)

-- Q3. How many successful orders were delivered by each runner?
select runner_id, count(duration) from runner_orders1 where duration is not null
group by runner_id;

#( runner ID 1 delivered most pizzas)

-- Q4. How many of each type of pizza was delivered?
select c.pizza_id, count(r.duration) from customer_orders1 c 
left join runner_orders1 r on c.order_id = r.order_id
where r.duration is not null
group by c.pizza_id;

#(meatlover pizza is definately liked by most of the customers)

-- Q5. How many Vegetarian and Meatlovers were ordered by each customer?
select c.customer_id, n.pizza_name, count(c.pizza_id) as total_orders from customer_orders1 c 
left join pizza_names n on c.pizza_id = n.pizza_id 
group by c.customer_id, n.pizza_name order by c.customer_id;

#(all the custumer like meatlovers pizza except customer 105) 

-- Q6. What was the maximum number of pizzas delivered in a single order?
select c.order_id, count(r.runner_id) as pizza_delivered from customer_orders1 c 
left join runner_orders1 r on c.order_id = r. order_id
where r.pickup_time is not null
group by c.order_id order by pizza_delivered desc
limit 1;

# (Maximum 3 pizzas were ordered in single order)

-- Q7. For each customer, how many delivered pizzas had at least 1 change, and how many had no changes?
select customer_id, sum(case 
	when (exclusions is not null and exclusions <>0) or ( extras is not null and extras <>0) then 1 
	else 0 end) as `at least one change`,
sum(case 
	when (exclusions is null or exclusions = 0) and (extras is null or extras = 0) then 1 
    else 0 end) as `no change`
from customer_orders1 c left join runner_orders1 r on c.order_id = r.order_id
where r.pickup_time is not null
group by c.customer_id order by c.customer_id;

#(customer 103 made most number  of changes ans 101 and 102 made no changes)

-- Q8. How many pizzas were delivered that had both exclusions and extras?
select count(c.order_id) from customer_orders c left join runner_orders r on c.order_id = r.order_id 
where  (c.exclusions is not null and c.exclusions <>0) and (c.extras is not null and c.extras<> 0) and r.pickup_time <> 0 ;

#(only 1 pizza delivered having bo exclusions and extras)

-- Q9. What was the total volume of pizzas ordered for each hour of the day?
select hour( order_time) as hour_of_day, count(order_id) as pizza_count from customer_orders1 
group by hour_of_day order by hour_of_day;

#(we get most orders at afternoon and night time)

-- Q10. What was the volume of orders for each day of the week?
select dayname(order_time) as WeekDay, count(order_id) as order_count from customer_orders1 
group by WeekDay order by order_count desc;

#(we get most orders on wednesday and saturday)

-- QUESTION SET-B - RUNNER AND CUSTOMER EXPERIENCE =>
-- Q1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
select week(adddate(registration_date,3)) as week_number, count(runner_id) from runners
group by week_number;

-- Q2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pick up the order?
select runner_id, avg(timestampdiff(minute, order_time, pickup_time)) from customer_orders1 c
left join runner_orders r on c.order_id = r.order_id where r.pickup_time is not null
group by r.runner_id ;

#(runner 2 took the maximum avg time to arrive.)

-- Q3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
with cte as (
	select c.order_id, count(c.order_id) as pizzas, 
    max(timestampdiff(minute, c.order_time, r.pickup_time)) as prep_time 
    from customer_orders1 c left join runner_orders1 r on c.order_id = r.order_id 
    where r.pickup_time is not null
	group by c.order_id)
select pizzas, avg(prep_time) as preparation_time from cte 
group by pizzas;

#( it takes around 10 minutes to prepare one pizza)

-- Q4. What was the average distance traveled for each customer?
select c.customer_id, avg(r.distance) from customer_orders1 c
left join runner_orders1 r on c.order_id = r.order_id
group by customer_id;

-- Q5. What was the difference between the longest and shortest delivery times for all orders?
with cte as(
	select c.order_id, 
    timestampdiff(minute, order_time, pickup_time) as time from customer_orders1 as c 
    left join runner_orders1 r on c.order_id = r.order_id where distance is not null)
select max(time)-min(time) as time_diff from cte;

-- Q6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
select runner_id, order_id, avg(distance/(duration/60)) from runner_orders1
where duration is not null
group by runner_id, order_id order by runner_id;

#(the average speed of runner 2 is very high.)

-- 7. What is the successful delivery percentage for each runner?
select runner_id, round((count(pickup_time)*100)/count(order_id)) from runner_orders1
group by runner_id;

#(runner1 made 100% successful deliveies, 2 made 75% and 3 made only 50 % successful deliveries)
