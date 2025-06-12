--4
SELECT department_name, SUM(order_item_subtotal) as total_revenue
FROM order_items AS oi
	JOIN products AS p 
		ON p.product_id = oi.order_item_product_id
	JOIN categories AS c
		ON c.category_id = p.product_category_id
	JOIN departments AS d
		ON d.department_id = c.category_department_id
GROUP BY d.department_id

--5

SELECT c.customer_id,c.customer_fname,c.customer_lname
FROM customers AS c
	LEFT JOIN orders AS o
		ON c.customer_id = o.order_customer_id
WHERE o.order_id is NULL
ORDER BY c.customer_id

--6
SELECT p.product_name, SUM(oi.order_item_quantity) AS total_quantity 
FROM order_items AS oi
	JOIN products AS p 
		ON oi.order_item_product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_quantity DESC
LIMIT 5;

--7
SELECT c.category_name,
	   COUNT(p.product_id) AS total_products, 
	   SUM(p.product_price) AS total_product_price,
	   SUM(p.product_price)/COUNT(p.product_id) AS avg_product_price
FROM categories AS c
	LEFT JOIN products AS p
		ON c.category_id = p.product_category_id
GROUP BY c.category_name
ORDER BY avg_product_price

--8
SELECT p.product_name, oi.order_item_subtotal
FROM order_items oi
INNER JOIN products p ON oi.order_item_product_id = p.product_id
WHERE oi.order_item_subtotal > 100;

--9
SELECT c.category_name,count(p.product_id) AS product_count
FROM categories AS c
	LEFT JOIN products AS p
		ON c.category_id = p.product_category_id
GROUP BY c.category_name

--10
SELECT d.department_name
FROM departments AS d
   	LEFT JOIN categories AS c
		ON d.department_id = c.category_department_id
	LEFT JOIN products AS p
		ON c.category_id = p.product_category_id
WHERE c.category_id IS NULL OR p.product_id IS NULL;


--INTERMEDIATE
--1
SELECT to_char(o.order_date::date,'yyyy-MM') AS year_month, 
	   SUM(oi.order_item_subtotal) as month_total_revenue,
	   SUM(oi.order_item_subtotal)-LAG(SUM(oi.order_item_subtotal)) OVER(ORDER BY to_char(o.order_date::date,'yyyy-MM')) AS difference,
	   round(((SUM(oi.order_item_subtotal)-LAG(SUM(oi.order_item_subtotal)) OVER(ORDER BY to_char(o.order_date::date,'yyyy-MM')))/LAG(SUM(oi.order_item_subtotal)) OVER(ORDER BY to_char(o.order_date::date,'yyyy-MM')) * 100)::numeric,2) AS percent_change 
FROM orders AS o 
	JOIN order_items AS oi
		ON o.order_id = oi.order_item_order_id
GROUP BY year_month

WITH monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', order_date) AS month,
        SUM(order_item_subtotal) AS revenue
    FROM orders o
    INNER JOIN order_items oi ON o.order_id = oi.order_item_order_id
    WHERE EXTRACT(YEAR FROM order_date) = 2013
    GROUP BY month
)
SELECT 
    month,
    revenue,
    round(
        ((revenue - LAG(revenue, 1) OVER (ORDER BY month)) / LAG(revenue, 1) OVER (ORDER BY month))::numeric * 100, 
        2
    ) AS growth_percentage
FROM monthly_sales
ORDER BY month;

--2
WITH customer_spending AS (
    SELECT 
        c.customer_id,
        SUM(oi.order_item_subtotal) AS total_spent
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.order_customer_id
    LEFT JOIN order_items oi ON o.order_id = oi.order_item_order_id
    GROUP BY c.customer_id
)
SELECT customer_id, total_spent
FROM customer_spending
WHERE total_spent > (SELECT AVG(total_spent) FROM customer_spending);

--3
WITH customer_spend_per_department
AS
(SELECT d.department_name,
		cu.customer_id,
		cu.customer_fname,
		cu.customer_lname,
	    SUM(oi.order_item_subtotal) as total_cust_spend,
	    RANK() OVER(PARTITION BY d.department_name ORDER BY SUM(oi.order_item_subtotal) DESC) as rnk
FROM departments AS d
	LEFT JOIN categories AS ca ON ca.category_department_id = d.department_id
	LEFT JOIN products AS p ON p.product_category_id = ca.category_id
	LEFT JOIN order_items AS oi ON oi.order_item_product_id = p.product_id
	RIGHT JOIN orders AS o ON o.order_id = oi.order_item_order_id
	RIGHT JOIN customers AS cu ON cu.customer_id = o.order_customer_id
GROUP BY d.department_name,cu.customer_id,cu.customer_fname,cu.customer_lname)

SELECT department_name,
		customer_id,
		customer_fname,
		customer_lname,
		total_cust_spend
FROM customer_spend_per_department
WHERE rnk = 1 AND total_cust_spend IS NOT NULL
ORDER BY department_name,total_cust_spend DESC;

--4
SELECT p.product_name
FROM products AS p 
	LEFT JOIN order_items AS oi ON p.product_id = oi.order_item_product_id
WHERE order_item_product_id IS NULL;

--5

WITH avg_product_price_per_category
AS
(SELECT c.category_name, COALESCE(AVG(p.product_price),0) AS avg_product_price
FROM categories AS c 
	LEFT JOIN products AS p ON c.category_id = p.product_category_id
GROUP BY c.category_name)

SELECT category_name,avg_product_price
FROM avg_product_price_per_category
WHERE avg_product_price > (SELECT AVG(avg_product_price) FROM avg_product_price_per_category);


--6
SELECT c.customer_id,
	   c.customer_fname,
	   c.customer_lname, 
	   COALESCE(COUNT(DISTINCT(DATE_TRUNC('month', o.order_date))),0) AS number_of_months
FROM customers AS c 
	LEFT JOIN orders AS o ON c.customer_id = o.order_customer_id
WHERE DATE_TRUNC('year', o.order_date) = to_date('2013','yyyy')
GROUP BY  c.customer_id,c.customer_fname,c.customer_lname
ORDER BY number_of_months;

--7
SELECT o.order_id, 
	   count(distinct oi.order_item_product_id) AS distinct_products
FROM orders AS o 
	JOIN order_items AS oi ON o.order_id = oi.order_item_order_id
GROUP BY o.order_id
HAVING count(distinct oi.order_item_product_id) > 5;

--8
SELECT c.customer_state, 
	   round(COALESCE(SUM(oi.order_item_subtotal),0)::numeric,2) AS state_total_revenue
FROM customers AS c 
	LEFT JOIN orders AS o ON c.customer_id = o.order_customer_id
	LEFT JOIN order_items AS oi ON o.order_id = oi.order_item_order_id
GROUP BY c.customer_state
ORDER BY state_total_revenue DESC;

--9 Rework this problem
WITH prod_quantity_last_3
AS
(SELECT p.product_name,
	  date_trunc('month',o.order_date) AS year_month,
	  COUNT(oi.order_item_quantity) AS quantity
FROM products AS p
	JOIN order_items AS oi ON p.product_id = oi.order_item_product_id
	JOIN orders AS o ON oi.order_item_order_id = o.order_id
GROUP BY p.product_name,date_trunc('month',o.order_date)
	HAVING ((SELECT MAX(order_date) FROM orders)-date_trunc('month',o.order_date)) <= INTERVAL '3' MONTH
),
month_lg
AS
(SELECT product_name,
	   year_month,
	   quantity,
	   LAG(quantity,1) OVER(PARTITION BY product_name ORDER BY year_month) AS prev_month_1,
	   LAG(quantity,2) OVER(PARTITION BY product_name ORDER BY year_month) AS prev_month_2
FROM prod_quantity_last_3)	   
SELECT product_name
FROM month_lg
WHERE quantity>prev_month_1 AND prev_month_1>prev_month_2

--10
WITH product_price_rank
AS
(SELECT c.category_name,
	   p.product_name,
	   p.product_price,
	   DENSE_RANK() OVER(PARTITION BY c.category_name ORDER BY p.product_price DESC) as drnk
FROM categories AS c
	LEFT JOIN products AS p ON c.category_id = p.product_category_id)

SELECT category_name,
	   product_name,
	   product_price
FROM product_price_rank	
WHERE drnk = 2



--Advanced

--1

--2

SELECT  c.customer_id,c.customer_fname,c.customer_lname,
	    to_char(order_date::date,'Q') AS quarter,
	    SUM(order_item_subtotal) AS quarterly_revenue,
		LAG(SUM(order_item_subtotal)) OVER (PARTITION BY c.customer_id ORDER BY to_char(order_date::date,'Q')) AS previous_quarter
FROM customers AS c
	LEFT JOIN orders AS o ON c.customer_id = o.order_customer_id
	LEFT JOIN order_items AS oi ON o.order_id = oi.order_item_order_id
WHERE to_char(order_date::date,'yyyy') = '2013'
GROUP BY to_char(order_date::date,'Q'),c.customer_id,c.customer_fname,c.customer_lname
ORDER BY 1,quarter ASC







