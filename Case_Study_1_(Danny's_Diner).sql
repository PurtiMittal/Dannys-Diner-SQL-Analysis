-- DATABASE SCHEMA 
-- SALES TABLE CREATION

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

 -- MENU TABLE CREATION

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  
  
 -- MEMBERS TABLE CREATION 

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
select * from sales;
select * from menu;
select * from members;

--1. What is the total amount each customer spent at the restaurant?

SELECT s.customer_id, SUM(m.price) AS total_spent
FROM sales s
INNER JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- Analysis: Customer A & B are primary drivers of the revenue, representing highest total spendings while customer C's contribution to the revenue is quite low. 

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS days_visited
FROM sales
GROUP BY customer_id;

-- Analysis: Customers A & B are more frequent visitors compared to Customer C, who has visited only twice. This aligns with previous observation regarding contribution to revenue.


-- 3. What was the first item from the menu purchased by each customer?

WITH cte AS
(SELECT s.customer_id, m.product_name, DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY order_date) AS rn 
FROM sales s
INNER JOIN menu m ON s.product_id = m.product_id)

SELECT customer_id, product_name
FROM cte
WHERE rn = 1
GROUP BY customer_id, product_name;


/* Alternate Presentation */

WITH cte AS
(SELECT DISTINCT s.customer_id, m.product_name, DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY order_date) AS rn 
FROM sales s
INNER JOIN menu m ON s.product_id = m.product_id)

SELECT customer_id, STRING_AGG(product_name, ', ') as first_ordered_products
FROM cte
WHERE rn = 1
GROUP BY customer_id;

-- Analysis: Customer A ordered Curry and Sushi for their first order while Customer B ordered only curry and Customer C ordered Ramen.


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
WITH total_purchases AS
(SELECT m.product_name, COUNT(s.product_id) AS purchased_times, DENSE_RANK() OVER(ORDER BY COUNT(s.product_id) DESC) AS rn 
FROM sales s
INNER JOIN menu m ON s.product_id = m.product_id
GROUP BY m.product_name)

SELECT product_name, purchased_times
FROM total_purchases
WHERE rn=1;

/* Alternate Solution */

SELECT TOP 1 WITH TIES m.product_name, COUNT(s.product_id) AS purchased_times
FROM sales s
INNER JOIN menu m ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY 2 DESC;

-- Analysis: Ramen is the best-selling items among all the offerings on the menu.


-- 5. Which item was the most popular for each customer?

WITH ranked_items AS
(SELECT s.customer_id, m.product_name, COUNT(s.product_id) AS total_orders, DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS rn 
FROM sales s
INNER JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id, m.product_name)

SELECT customer_id, product_name, total_orders
FROM ranked_items
WHERE rn = 1;

-- Analysis: Ramen remains the most popular item for each customer individually while also being the best-selling item overall. Additionally, Customer B liked Sushi and Curry equally.


-- 6. Which item was purchased first by the customer after they became a member?

WITH cte AS
(SELECT s.customer_id, m.product_name, s.order_date, DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rn
FROM sales s
INNER JOIN menu m ON s.product_id = m.product_id
INNER JOIN members mr ON s.customer_id = mr.customer_id and s.order_date >= mr.join_date)

SELECT customer_id, product_name, order_date
FROM cte
WHERE rn = 1;

-- Analysis - Customer A ordered Curry and customer B ordered Sushi as their first item after joining the membership program. Customer C hasn't joined the program yet.


--7. Which item was purchased just before the customer became a member?

WITH cte AS
(SELECT s.customer_id, m.product_name, DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rn
FROM sales s
INNER JOIN menu m ON s.product_id = m.product_id
INNER JOIN members mr ON s.customer_id = mr.customer_id and s.order_date < mr.join_date)

SELECT customer_id, product_name
FROM cte
WHERE rn = 1;

/* Alternate Solution */

WITH cte AS
(SELECT s.customer_id, m.product_name, DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rn
FROM sales s
INNER JOIN menu m ON s.product_id = m.product_id
INNER JOIN members mr ON s.customer_id = mr.customer_id and s.order_date < mr.join_date)

SELECT customer_id, STRING_AGG(product_name, ', ') as products_ordered
FROM cte
WHERE rn = 1
GROUP BY customer_id;

-- Analysis: Before joining the membership program, Customer A ordered Sushi and Curry while customer B ordered Sushi. This indicates the consistent ordering patterns both before and after joining the membersip program.


-- 8. What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id, COUNT(s.product_id) AS total_items, SUM(m.price) as amount_spent_before_membership
FROM sales s
INNER JOIN menu m ON s.product_id = m.product_id
INNER JOIN members mr ON s.customer_id = mr.customer_id and s.order_date < mr.join_date
GROUP BY s.customer_id;

-- Analysis: Before becoming the member, Customer A ordered 2 items and Customer B ordered 3 items. Their total contribution to revenue were $25 and $40 respectively.


--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT s.customer_id, SUM(CASE WHEN LOWER(m.product_name) = 'sushi' THEN m.price*10*2 ELSE m.price*10 END) AS points
FROM sales s
INNER JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY 2 DESC;

-- Analysis: Customer B has collected the highest points followed by customer A, while Customer C has the fewest. 
-- Even though Customer A spent more total money than Customer B, Customer B wins the points race because Customer B ordered Sushi more often taking full advantage of 2x multiplier.


--10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT s.customer_id, 
SUM(CASE 
	WHEN LOWER(m.product_name) = 'sushi'  
 	OR s.order_date BETWEEN mr.join_date AND DATEADD(DAY, 6, mr.join_date) THEN m.price*10*2
	ELSE m.price*10 
END) AS points
FROM sales s
INNER JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members mr on s.customer_id = mr.customer_id 
WHERE mr.customer_id is not null and s.order_date <= '2021-01-31'
GROUP BY s.customer_id
ORDER BY 2 DESC;

-- Analysis: Given the conditions, Customer A earned the highest number of points, totalling 1370, while Customer B followed with 820 points. This indicates that Customer A made the maximum use of 'first week' 2x multiplier by ordering Ramen and Curry after joining the program, hence the most loyal customer.


-- BONUS QUESTIONS

--Join All The Things

SELECT s.customer_id, s.order_date, m.product_name, m.price, CASE WHEN s.order_date < mr.join_date OR mr.join_date IS NULL THEN 'N' else 'Y' END AS member
FROM sales s
INNER JOIN menu m ON m.product_id = s.product_id
LEFT JOIN members mr ON mr.customer_id = s.customer_id
ORDER BY 1,2,3;

-- Rank All The Things
WITH cte AS
(SELECT s.customer_id, s.order_date, m.product_name, m.price, CASE WHEN s.order_date < mr.join_date OR mr.join_date IS NULL THEN 'N' else 'Y' END AS member
FROM sales s
INNER JOIN menu m ON m.product_id = s.product_id
LEFT JOIN members mr ON mr.customer_id = s.customer_id)

SELECT *, CASE WHEN member = 'Y' THEN DENSE_RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date) END AS ranking
FROM CTE
