--> Q1. What is the total amount each customer spent at the restaurant?
select s.customer_id, sum(m.price) as Total_AmountSpent from sales s left join menu m on s.product_id = m.product_id
group by s.customer_id;

-->	Q2. How many days has each customer visited the restaurant?
select count(distinct order_date) as days_visited from sales group by customer_id;

--> Q3. What was the first item from the menu purchased by each customer?
select s.customer_id, group_concat(m.product_name) from sales s left join menu m on s.product_id = m.product_id 
where s.order_date = (select min(order_date) from sales)
group by customer_id;

--> Q4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT m.product_name, count(s.product_id) AS product_count
FROM sales s JOIN menu m on s.product_id = m.product_id
GROUP BY product_name
ORDER BY product_count DESC
LIMIT 1;

--> Q5. Which item was the most popular for each customer?
WITH popular_products AS
(
    SELECT customer_id, product_id,
    DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY COUNT(*) DESC) AS popularity
    FROM sales
    GROUP BY customer_id, product_id
)
SELECT pp.customer_id, 
group_concat(m.product_name ORDER BY m.product_name) AS popular_products_per_customer
FROM popular_products pp JOIN menu m on pp.product_id = m.product_id
WHERE pp.popularity = 1
GROUP BY pp.customer_id;

--> Q6. Which item was purchased first by the customer after they became a member?
with PId as
 (select s.product_id, s.order_date, s.customer_id, dense_rank() over (partition by s.customer_id order by s.order_date) as rnk from sales s inner join members mm on s.customer_id = mm.customer_id
 where s.order_date >= mm.join_date
 )
select p.customer_id, m.product_name from PId p left join menu m on p.product_id = m.product_id
where rnk = 1;

--> Q7. Which item was purchased just before the customer became a member?
with PId as
 (select s.product_id, s.order_date, s.customer_id, dense_rank() over (partition by s.customer_id order by s.order_date desc) as rnk from sales s inner join members mm on s.customer_id = mm.customer_id
 where s.order_date < mm.join_date
 )
select p.customer_id, m.product_name from PId p left join menu m on p.product_id = m.product_id
where rnk = 1;

--> Q8. What is the total items and amount spent for each member before they became a member?
with CTE as
(
 select m.price, s.customer_id, m.product_name, s.order_date from sales s left join menu m 
 on s.product_id = m.product_id 
 )
select c.customer_id, count(distinct c.product_name), sum(c.price) from CTE c inner join members m on c.customer_id = m.customer_id 
where c.order_date < m.join_date
group by c.customer_id;

--> Q9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with CTE as
(select product_id,
case
 when product_name = 'sushi' then 20*price
 else 10*price 
 end as pnts from menu)
select s.customer_id, sum(c.pnts) as points from sales s left join CTE c on s.product_id = c.product_id
group by s.customer_id;

--> Q10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi 
- how many points do customer A and B have at the end of January?
WITH cte AS 
(
 SELECT *, 
  ADDDATE(join_date, 6) AS valid_date, 
  '2021-01-31' AS last_date
 FROM members AS m
)
SELECT c.customer_id, s.order_date, c.join_date, 
 c.valid_date, c.last_date, m.product_name, m.price,
 SUM(CASE
  WHEN m.product_name = 'sushi' THEN 2 * 10 * m.price
  WHEN s.order_date BETWEEN c.join_date AND c.valid_date THEN 2 * 10 * m.price
  ELSE 10 * m.price
  END) AS points
FROM cte AS c
JOIN sales AS s
 ON c.customer_id = s.customer_id
JOIN menu AS m
 ON s.product_id = m.product_id
WHERE s.order_date < c.last_date
GROUP BY c.customer_id, s.order_date, c.join_date, c.valid_date, c.last_date, m.product_name, m.price



