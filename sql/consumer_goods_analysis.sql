
/*1.  Provide the list of markets in which customer  "Atliq  Exclusive"  operates its 
business in the  APAC  region.*/

SELECT distinct market  
FROM gdb023.dim_customer
where customer="Atliq Exclusive" and region="APAC";

/* 2.  What is the percentage of unique product increase in 2021 vs. 2020? The 
final output contains these fields, 
unique_products_2020 
unique_products_2021 
percentage_chg */

with cte1 as( 
SELECT count( distinct s.product_code) as cnt
FROM gdb023.fact_sales_monthly s 
  where fiscal_year =2020
 ),
 cte2 as(
  
 SELECT count( distinct s.product_code) as cnt
FROM gdb023.fact_sales_monthly s 
where fiscal_year =2021)
 select cte1.cnt as unique_products_2020, cte2.cnt as unique_products_2021,
 round(((cte2.cnt-cte1.cnt)*100/cte1.cnt),2) as percentage_chg
 from cte1,cte2;
 
 
 /*3.  Provide a report with all the unique product counts for each  segment  and 
sort them in descending order of product counts. The final output contains 
2 fields, 
segment 
product_count */

SELECT segment,
       COUNT(DISTINCT(product_code)) AS product_count
FROM dim_product
GROUP BY segment
ORDER by product_count DESC;

/* Follow-up: Which segment had the most increase in unique products in 
2021 vs 2020? The final output contains these fields, 
segment 
product_count_2020 
product_count_2021 
difference*/

with cte1 as( 
SELECT p.segment,count(distinct s.product_code) as cnt
FROM gdb023.fact_sales_monthly s 
join dim_product p
on s.product_code=p.product_code
where fiscal_year =2020
group by p.segment
 ),
 cte2 as(
   SELECT p.segment,count(distinct s.product_code) as cnt
FROM gdb023.fact_sales_monthly s 
join dim_product p
on s.product_code=p.product_code
where fiscal_year =2021
group by p.segment
)
 select cte1.segment,cte1.cnt as products_2020,
        cte2.cnt as products_2021,
        cte2.cnt-cte1.cnt as diffrence
 from cte1 join cte2
 using(segment);
 
 /* Get the products that have the highest and lowest manufacturing costs. 
The final output should contain these fields, 
product_code 
product 
manufacturing_cost */

SELECT F.product_code, P.product, F.manufacturing_cost 
FROM fact_manufacturing_cost F JOIN dim_product P
ON F.product_code = P.product_code
WHERE manufacturing_cost
IN (
	SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost
    UNION
    SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost
    ) 
ORDER BY manufacturing_cost DESC ;

/*  Generate a report which contains the top 5 customers who received an 
average high  pre_invoice_discount_pct  for the  fiscal  year 2021  and in the 
Indian  market. The final output contains these fields, 
customer_code 
customer 
average_discount_percentage*/

SELECT 
pid.customer_code,
c.customer,
round(avg(pid.pre_invoice_discount_pct*100),2) as average_discount_percentage
FROM fact_pre_invoice_deductions pid 
join dim_customer c
on pid.customer_code=c.customer_code
where pid.fiscal_year=2021 and c.market="India"
group by pid.customer_code,
         c.customer
order by average_discount_percentage desc limit 5;

/*  Get the complete report of the Gross sales amount for the customer  “Atliq 
Exclusive”  for each month  .  This analysis helps to  get an idea of low and 
high-performing months and take strategic decisions. 
The final report contains these columns: 
Month 
Year 
Gross sales Amount */

SELECT
    MONTH(DATE_SUB(s.date, INTERVAL 8 MONTH)) as fiscal_month,
    s.fiscal_year as year,
    round(sum(s.sold_quantity*g.gross_price),2) as total_gross_price
	from fact_sales_monthly s
    join fact_gross_price g
    on s.product_code=g.product_code 
       and s.fiscal_year=g.fiscal_year
       where customer_code IN (select customer_code from dim_customer where customer="Atliq Exclusive")
       group by fiscal_month,year
       order by year,fiscal_month;
       
              /*  In which quarter of 2020, got the maximum total_sold_quantity? The final 
output contains these fields sorted by the total_sold_quantity, 
Quarter 
total_sold_quantity*/


sELECT
quarter(DATE_SUB(s.date, INTERVAL 8 MONTH)) AS quarter,
sum(s.sold_quantity) as total_sold_quantity
from fact_sales_monthly s
where s.fiscal_year=2020
group by quarter(DATE_SUB(s.date, INTERVAL 8 MONTH))
order by total_sold_quantity desc ;


  /*Which channel helped to bring more gross sales in the fiscal year 2021 
and the percentage of contribution?  The final output  contains these fields, 
channel 
gross_sales_mln 
percentage*/


with cte1 as (select 
       c.channel,
       round(sum(s.sold_quantity*gp.gross_price),2) as tot_price
       from fact_sales_monthly s
       join fact_gross_price gp
       on s.product_code=gp.product_code
       and s.fiscal_year=gp.fiscal_year
       join dim_customer c
       on s.customer_code=c.customer_code
       where s.fiscal_year=2021
	   group by c.channel
       )
       select channel,
       round(tot_price /1000000,2)as gross_sales_mln,
       round(tot_price/(sum(tot_price) over())*100,2 ) as percentage
       from cte1;
       
       /* Get the Top 3 products in each division that have a high 
total_sold_quantity in the fiscal_year 2021? The final output contains these 
fields, 
division 
product_code,
product 
total_sold_quantity 
rank_order*/

WITH cte1 AS
(
    SELECT
        p.division,
        p.product,
        s.product_code,
        SUM(s.sold_quantity) AS total_sold_quantity,

        RANK() OVER
        (
            PARTITION BY p.division
            ORDER BY SUM(s.sold_quantity) DESC
        ) AS rnk

    FROM fact_sales_monthly s
    JOIN dim_product p
        ON s.product_code = p.product_code

    WHERE s.fiscal_year = 2021

    GROUP BY
        p.division,
        p.product,
        s.product_code
)

SELECT
    division,
    product_code,
    product,
    total_sold_quantity,
    rnk
FROM cte1
WHERE rnk <= 3
ORDER BY division, rnk;
