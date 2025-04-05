-- The Coffee Shop Data Analysis

-- Q1: Estimate coffee drinkers per city (25% of population)
SELECT 
    city_name,
    ROUND(population * 0.25 / 1000000.0, 2) AS coffee_consumers_in_millions,
    city_rank
FROM city
ORDER BY coffee_consumers_in_millions DESC;

-- Q2: Total revenue from coffee sales in Q4 2023
-- (A) Overall revenue
SELECT 
    COALESCE(SUM(total), 0) AS total_revenue
FROM sales
WHERE sale_date >= DATE '2023-10-01'
  AND sale_date < DATE '2024-01-01';

-- (B) Revenue by city
SELECT 
    ci.city_name,
    SUM(s.total) AS total_revenue
FROM city ci
JOIN customers c ON ci.city_id = c.city_id
JOIN sales s ON s.customer_id = c.customer_id
WHERE sale_date >= '2023-10-01'
  AND sale_date < '2024-01-01'
GROUP BY ci.city_name
ORDER BY total_revenue DESC;

-- Q3: Total number of orders per product
SELECT 
    p.product_name,
    COUNT(s.sale_id) AS total_orders
FROM products p
LEFT JOIN sales s ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_orders DESC;

-- Q4: Average sales amount per customer by city
SELECT 
    ci.city_name,
    SUM(s.total) AS total_sales,
    COUNT(DISTINCT s.customer_id) AS customer_count,
    ROUND(SUM(s.total)::numeric / NULLIF(COUNT(DISTINCT s.customer_id), 0), 2) AS avg_sales_per_customer
FROM city ci
JOIN customers c ON ci.city_id = c.city_id
JOIN sales s ON s.customer_id = c.customer_id
GROUP BY ci.city_name
ORDER BY total_sales DESC;

-- Q5: Coffee consumers vs actual customers per city
SELECT 
    ci.city_name,
    ROUND(ci.population * 0.25 / 1000000.0, 2) AS coffee_consumers,
    COUNT(DISTINCT c.customer_id) AS total_customers
FROM city ci
JOIN customers c ON ci.city_id = c.city_id
JOIN sales s ON s.customer_id = c.customer_id
GROUP BY ci.city_name, ci.population
ORDER BY total_customers DESC;

-- Q6: Top 3 selling products by city
SELECT *
FROM (
    SELECT 
        ci.city_name,
        p.product_name,
        COUNT(s.sale_id) AS total_orders,
        RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) AS rank
    FROM sales s
    JOIN products p ON p.product_id = s.product_id
    JOIN customers c ON c.customer_id = s.customer_id
    JOIN city ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name, p.product_name
) ranked
WHERE rank <= 3;

-- Q7: Unique coffee product buyers per city
SELECT 
    ci.city_name,
    COUNT(DISTINCT c.customer_id) AS coffee_customers
FROM city ci
JOIN customers c ON ci.city_id = c.city_id
JOIN sales s ON s.customer_id = c.customer_id
JOIN products p ON p.product_id = s.product_id
WHERE p.product_category = 'Coffee'
GROUP BY ci.city_name;

-- Q8: Average sale and rent per customer
SELECT 
    ci.city_name,
    ci.estimated_rent,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    ROUND(SUM(s.total)::numeric / COUNT(DISTINCT s.customer_id), 2) AS avg_sales_per_customer,
    ROUND(ci.estimated_rent::numeric / COUNT(DISTINCT s.customer_id), 2) AS avg_rent_per_customer
FROM city ci
JOIN customers c ON ci.city_id = c.city_id
JOIN sales s ON s.customer_id = c.customer_id
GROUP BY ci.city_name, ci.estimated_rent
ORDER BY avg_sales_per_customer DESC;

-- Q9: Monthly sales growth rate by city
SELECT 
    city_name,
    month,
    year,
    cr_month_sale,
    last_month_sale,
    ROUND((cr_month_sale - last_month_sale)::numeric / NULLIF(last_month_sale, 0) * 100, 2) AS growth_percentage
FROM (
    SELECT 
        ci.city_name,
        EXTRACT(MONTH FROM s.sale_date) AS month,
        EXTRACT(YEAR FROM s.sale_date) AS year,
        SUM(s.total) AS cr_month_sale,
        LAG(SUM(s.total)) OVER(PARTITION BY ci.city_name ORDER BY EXTRACT(YEAR FROM s.sale_date), EXTRACT(MONTH FROM s.sale_date)) AS last_month_sale
    FROM city ci
    JOIN customers c ON ci.city_id = c.city_id
    JOIN sales s ON s.customer_id = c.customer_id
    GROUP BY ci.city_name, EXTRACT(YEAR FROM s.sale_date), EXTRACT(MONTH FROM s.sale_date)
) monthly_data
WHERE last_month_sale IS NOT NULL;

-- Q10: Top 3 cities based on market potential
SELECT 
    ci.city_name,
    SUM(s.total) AS total_sales,
    ci.estimated_rent,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    ROUND(ci.population * 0.25 / 1000000.0, 3) AS estimated_coffee_consumers,
    ROUND(SUM(s.total)::numeric / COUNT(DISTINCT c.customer_id), 2) AS avg_sales_per_customer,
    ROUND(ci.estimated_rent::numeric / COUNT(DISTINCT c.customer_id), 2) AS avg_rent_per_customer
FROM city ci
JOIN customers c ON ci.city_id = c.city_id
JOIN sales s ON s.customer_id = c.customer_id
GROUP BY ci.city_name, ci.estimated_rent, ci.population
ORDER BY total_sales DESC
LIMIT 3;
/*
-- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.



