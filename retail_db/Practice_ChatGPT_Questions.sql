--Basics

--1 
SELECT *
FROM customers;

--2
SELECT product_name, product_price
FROM products;

--3
SELECT order_id
FROM orders
WHERE order_customer_id = 2533;

--4
SELECT p.product_id,p.product_name
FROM order_items oi
	JOIN products p ON
		oi.order_item_product_id = p.product_id
WHERE order_item_order_id = 42;

--5
SELECT COUNT(*)
FROM customers;

--6
SELECT *
FROM products
WHERE product_category_id = 44;

--7
SELECT order_id, order_status
FROM orders;

--8
SELECT customer_fname, customer_lname, customer_email
FROM customers
WHERE customer_city = 'New York';

--9
SELECT order_item_subtotal
FROM order_items
WHERE order_item_id = 531;

--10
SELECT category_name, department_name
FROM categories c
	INNER JOIN departments d
		ON c.category_department_id = d.department_id;
	

--Intermediate

--1

SELECT c.customer_id,
	   c.customer_fname,
	   c.customer_lname, 
	   count(o.order_id) as total_orders
FROM customers as c
	LEFT OUTER JOIN orders as o
		ON c.customer_id = o.order_customer_id
GROUP BY c.customer_id,c.customer_fname,c.customer_lname
ORDER BY total_orders DESC;

--2

SELECT product_id,
	   product_price
FROM products
ORDER BY product_price DESC
LIMIT 5;

--3
SELECT sum(order_item_subtotal)
FROM order_items;

--4
SELECT c.*
FROM customers as c
	LEFT OUTER JOIN orders as o
		ON c.customer_id = o.order_customer_id
WHERE o.order_customer_id is NULL;

--5
SELECT category_id, 
	   category_name,
	   count(product_id) as total_products
FROM categories as c
	 LEFT OUTER JOIN products p
	 	ON c.category_id = p.product_category_id
GROUP BY 1,2
ORDER BY total_products DESC;

--6
SELECT order_item_order_id, 
		SUM(order_item_quantity) as total_quantity
FROM order_items
GROUP BY 1
ORDER BY 1;

--7
SELECT AVG(total_order_value)
FROM
   (SELECT order_item_order_id,
			SUM(order_item_subtotal) as total_order_value
	FROM order_items
	GROUP BY 1)
;
SELECT SUM(order_item_subtotal) / COUNT(DISTINCT order_item_order_id) AS avg_order_value
FROM order_items;
--8
SELECT c.category_name,
	   p.product_price
FROM categories AS c
		INNER JOIN products AS p
			ON c.category_id = p.product_category_id
ORDER BY p.product_price DESC
LIMIT 1

--9
SELECT order_item_order_id, 
	   COUNT(DISTINCT order_item_product_id) as unique_products
FROM order_items 
GROUP BY order_item_order_id
	HAVING COUNT(DISTINCT order_item_product_id) >2
ORDER BY order_item_order_id;

--10

SELECT p.product_id,
	   p.product_name,
	   count(oi.order_item_id) AS total_times
FROM products AS p
	  INNER JOIN order_items AS oi 
	  		ON p.product_id = oi.order_item_product_id
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 1;


--ADVANCED
--1

WITH cust_spend
AS
(SELECT o.order_customer_id,
	   SUM(oi.order_item_subtotal) AS customer_total_spend
FROM orders AS o
	 JOIN order_items AS oi
		ON o.order_id = oi.order_item_order_id
GROUP BY 1)

SELECT * 
FROM
(SELECT customer_fname,
	   customer_lname,
	   RANK() OVER(ORDER BY customer_total_spend DESC) AS cust_rank,
	   customer_total_spend
FROM customers AS c
	JOIN cust_spend AS cp
	   ON c.customer_id = cp.order_customer_id)
WHERE cust_rank < = 3;


--2
WITH product_price_per_category
AS
(SELECT c.category_name,
	   p.product_name,
	   p.product_price,
	   DENSE_RANK() OVER (PARTITION BY product_category_id ORDER BY product_price DESC) as drnk
FROM categories c
	 LEFT JOIN products p 
	 		ON c.category_id = p.product_category_id)
SELECT category_name,product_name
FROM product_price_per_category
WHERE drnk = 2
ORDER BY 1,2

--3
SELECT DISTINCT to_char(order_date::date,'yyyy-MM')
FROM orders
ORDER BY 1


--4
SELECT d.department_name,
	   SUM(order_item_subtotal) as department_total
FROM order_items AS oi
	   JOIN products AS p
		  ON oi.order_item_product_id = p.product_id
	   JOIN categories AS c
	   	  ON p.product_category_id = c.category_id
	   JOIN departments AS d
	   	  ON d.department_id = c.category_department_id
GROUP BY d.department_name
ORDER BY department_total DESC
LIMIT 1;

--5
WITH ord_total
AS
(SELECT order_item_order_id,  
SUM(order_item_subtotal) as order_totals
FROM order_items
GROUP BY 1
ORDER BY 1 ASC)

SELECT order_item_order_id,order_totals
FROM ord_total 
WHERE order_totals > (SELECT SUM(order_item_subtotal)/COUNT(DISTINCT order_item_order_id) as total_avg
FROM order_items)
ORDER BY order_totals DESC;

SELECT order_id, total_order_amount,avg_order_amount
FROM (
    SELECT order_item_order_id AS order_id,
           SUM(order_item_subtotal) AS total_order_amount,
           AVG(SUM(order_item_subtotal)) OVER () AS avg_order_amount
    FROM order_items
    GROUP BY order_item_order_id
) order_data
WHERE total_order_amount > avg_order_amount
ORDER BY total_order_amount DESC;

--6
WITH potential_duplicate_customers
AS
(SELECT customer_fname,
	   customer_lname,
	   customer_city,
	   count(*) AS total_count
FROM customers
GROUP BY 1,2,3)

SELECT customer_fname,
	   customer_lname,
	   customer_city
FROM potential_duplicate_customers
WHERE total_count >= 2
ORDER BY total_count DESC

--7
WITH most_ordered_products
AS
(SELECT category_id,
	   product_id,
	   COUNT(*) AS times_ordered,
	   DENSE_RANK() OVER(PARTITION BY category_id ORDER BY COUNT(*) DESC) AS drnk
FROM order_items AS oi
	   JOIN products AS p
		  ON oi.order_item_product_id = p.product_id
	   JOIN categories AS c
	   	  ON p.product_category_id = c.category_id
GROUP BY 1,2)

SELECT category_id,
	   product_id,
	   times_ordered
FROM most_ordered_products
WHERE drnk = 1


--8
WITH orders_temp
AS
(SELECT o.order_customer_id,COUNT(o.order_id) as order_count
FROM o.orders
GROUP BY 1),

single_orders
AS
(SELECT customer_id
FROM orders_temp 
WHERE order_count =1),

multiple_products
AS
(SELECT o.order_id,so.customer_id,COUNT(order_item_product_id) AS product_count
FROM orders AS o
	 JOIN single_orders  AS so
	   ON so.customer_id = o.order_customer_id
	 JOIN order_items AS oi
	   ON o.order_id = oi.order_item_order_id
GROUP BY 1,2)

SELECT c.customer_id,
FROM customers AS c
	 JOIN multiple_products AS mp 
	     ON c.customer_id = mp.customer_id
WHERE product_count>1

--9

WITH product_revenue
AS
(SELECT category_id,
	   product_id,
	   SUM(order_item_subtotal) AS revenue,
	   DENSE_RANK() OVER(PARTITION BY category_id ORDER BY SUM(order_item_subtotal) DESC) AS drnk
FROM order_items AS oi
	   JOIN products AS p
		  ON oi.order_item_product_id = p.product_id
	   JOIN categories AS c
	   	  ON p.product_category_id = c.category_id
GROUP BY 1,2)

SELECT category_id,
	   product_id,
	   revenue
FROM product_revenue
WHERE drnk<=3

--10

SELECT order_item_product_id,
	   SUM(order_item_subtotal)/(SELECT SUM(order_item_subtotal) FROM order_items)*100 AS PERCENT_CONTRIBUTION
FROM order_items
GROUP BY order_item_product_id
ORDER BY PERCENT_CONTRIBUTION DESC


--Expert

--1
WITH total_rev 
AS
(SELECT SUM(order_item_subtotal) AS total_revenue FROM order_items),

product_revenue
AS
(SELECT p.product_name,
	   ROUND(SUM((oi.order_item_subtotal)/(SELECT * FROM total_rev))::decimal,4)*100 AS percent_total_revenue
FROM products AS p
	JOIN order_items AS oi ON p.product_id = oi.order_item_product_id
GROUP BY p.product_name
ORDER BY product_total_revenue DESC)

SELECT *,
	  SUM(percent_total_revenue) OVER (ORDER BY percent_total_revenue DESC) AS 
FROM product_revenue;


--2

--3

SELECT c.customer_id,
	   c.customer_fname,
	   c.customer_lname,
	   to_char(order_date::date,'yyyy-MM') AS mon,
	   SUM(COUNT(o.order_id)) OVER (PARTITION BY to_char(order_date::date,'yyyy-MM') 
	   ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS order_total
FROM customers AS c
	LEFT JOIN orders AS o ON c.customer_id = o.order_customer_id
GROUP BY 1,2,3,4,order_id
ORDER BY 1 DESC


--4
