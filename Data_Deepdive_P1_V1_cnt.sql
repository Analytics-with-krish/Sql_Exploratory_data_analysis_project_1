  --Data Analysis Deep Dive
  -------------------------------------------------------------------------------------------
  -- STEP 1 change over time analysis
  -- 1(1) Sales over time (Sales Trends)
   
  Select format(order_date,'yyyy-MM') as year_month ,sum(sales_amount) as sales, count(distinct customer_key) as total_customers, sum(quantity) as total_quantity
  from gold.fact_sales where order_date is not null 
  group by format(order_date,'yyyy-MM')  order by format(order_date,'yyyy-MM')

  -- Can be used to show the sales trend and other metrics

  ------------------------------------------------------------------------------------------------
  --Cumulative Analysis
  --Calculating the total sales of each month and cumilative(present and one last month sum) total of sales over time

  Select format(order_date,'yyyy-MM') year_month, sum(sales_amount) as total_sales, lag(sum(sales_amount)) over(order by format(order_date,'yyyy-MM')) as last_month_Sale,
  sum(sales_amount) +  lag(sum(sales_amount)) over(order by format(order_date,'yyyy-MM')) as cumilative_sales
  from DataWarehouseAnalytics.gold.fact_sales where order_date is not null
  group by format(order_date,'yyyy-MM') order by format(order_date,'yyyy-MM')

  -- Calculating the total sales of each month and running total of sales (sum of present and all past months) over time
  Select t.year_month,t.total_sales, sum(t.total_sales) over (order by t.year_month) as running_total_sales from
    --subquery 1 
	(Select datetrunc(month,order_date) as year_month, sum(sales_amount) as total_sales
  from DataWarehouseAnalytics.gold.fact_sales where order_date is not null
  group by datetrunc(month,order_date)) as t

  --------------------------------------------------------------------------------------------------------
  --Performance Analysis
  --comparing the current value to a target value

  --Step 1 Analyse the current performance of each product by comapring it to the average sales and previous year sales
  Select m.years,m.product_name,m.total_sales,m.avg_sale,m.past_sale,
	concat(Round((((CAST(m.total_sales AS float) - CAST(m.avg_sale AS float))/CAST(m.avg_sale AS float))*100.0),2),'%') AS cmp_ts_as,

	concat(Round((((CAST(m.total_sales AS float) - CAST(m.past_sale AS float))/CAST(m.past_sale AS float))*100.0),2),'%') AS cmp_ts_ps,

	case when Round((((CAST(m.total_sales AS float) - CAST(m.avg_sale AS float))/CAST(m.avg_sale AS float))*100.0),2) > 0 then 'above_average'
         else 'below_average'
		 end as category_cmp_ts_as,

		 case when Round((((CAST(m.total_sales AS float) - CAST(m.past_sale AS float))/CAST(m.past_sale AS float))*100.0),2) > 0 then 'above_past_sale'
		 when Round((((CAST(m.total_sales AS float) - CAST(m.past_sale AS float))/CAST(m.past_sale AS float))*100.0),2) < 0 then 'below_past_sale'
         else 'initial_year'
		 end as category_cmp_ts_as
  from
  --subquery 2 
  (select o.years,o.product_name, o.total_sales, 
  avg(o.total_sales) over (partition by product_name) as avg_sale, 
  lag(o.total_sales) over (partition by o.product_name order by o.years) as past_sale
  from
 --subquery 1 
 (select year(s.order_date) as years,p.product_name, sum(s.sales_amount) as total_Sales from DataWarehouseAnalytics.gold.fact_sales as s
  left join DataWarehouseAnalytics.gold.dim_products as p on s.product_key= p.product_key 
  where s.order_date is not null group by year(s.order_date),p.product_name) 
  as o ) as m
  order by m.product_name,m.years


  --the above sorting, rounding off of the data, the category columns depicting change can be presented through mulitple ways,
  --float has been used as int being divided gives 0 and 1 as the values and not actual value

  -------------------------------------------------------------------------------------------------------
  --PART TO WHOLE ANALYSIS
  -- Understanding the impact of one product/ category of the whole segment, in easier terms seeing the performance of one part over the whole 

  --STEP(1) which categories countribute the most to the overall sales
  -- cte
 with cte as ( select p.category, sum(s.sales_amount) as total_sales from DataWarehouseAnalytics.gold.fact_sales as s
  left join DataWarehouseAnalytics.gold.dim_products as p on s.product_key= p.product_key  group by p.category )
  -- main query
  select category, total_sales, concat(round(((((cast(total_sales as float))/(sum(cast(total_sales as float)) over())))* 100),2),' ', '%') 
  as contribution from cte order by total_sales desc

  ----------------------------------------------------------------------------------------------------------------------------------------------------------
  -- Data Segmentation
  -- grouping the data based on a specific range, helps understand the correlation between two measures, it would look like something [measure] by [measure]

  --Step 1 segment the data into cost ranges and count how many products fall into each segment

  -- cte1
  with cte1 as (select product_key,product_name,cost,
  case when cost < 100 then 'below 100'
  when cost>100 and cost<500 then '100-500'
  when cost> 500 and cost< 1000 then '500-1000'
  else 'above 1000'
  end as cost_range
  from DataWarehouseAnalytics.gold.dim_products)

  -- main query
  select cte1.cost_range,count(distinct cte1.product_key) as total_product from cte1 group by cte1.cost_range order by total_product desc

  -- Step 2 Group customers into 3 groups based on their spending behaiour and their life span as 
  --spend >=5000 and life span>= 12 month vip, spend <5000 and life span>= 12 months regular, life span< 12 months new

  -- cte1
  with cte1 as (
  select c.customer_key,sum(s.sales_amount) as spend,
  min(s.order_date) as mini,
  max(s.order_date) as maxi
  from 
  DataWarehouseAnalytics.gold.fact_sales as s left join DataWarehouseAnalytics.gold.dim_customers as c
  on s.customer_key = c.customer_key
  group by c.customer_key),

  -- cte2
  cte2 as (
 select cte1.customer_key, cte1.spend, cte1.mini, cte1.maxi, datediff(month, cte1.mini, cte1.maxi) as lifespan from cte1 ),
  -- cte3
  cte3 as(
  select customer_key, 
  case when spend >= 5000 and lifespan >= 12 then 'vip'
 when spend <5000 and lifespan < 12 then 'regular'
	  else 'new'
	  end as type_of_customer
	  from
	 cte2) 

-- main query
select type_of_customer, count(distinct customer_key) from cte3 group by type_of_customer

------------------------------------------------------------------------------------------------------------------------------------------------
--Reporting (The final step)
/*
--------------------------------------
--------------------------------------
customer report
-----------------------------------------
Purpose - This report tries to consolidate key customer metric
-----------------------------------------

Highlights:
1. Gathers essential fields such as names, ages, and transaction details.
2. Segments customers into categories (VIP, Regular, New) and age groups.
3. Aggregates customer-level metrics:
total orders
total sales
total quantity purchased
total products
lifespan (in months)
4. Calculates valuable KPIs:
recency (months since last order)
average order value
average monthly spend
------------------------------------------------

------------------------------------------------
*/

with base_query as(
-- base queries to retrieve core columns and basic filteration and changes from the table
select s.order_number as order_number ,s.product_key as product_key ,s.order_date as order_date ,s.sales_amount as sales_amount ,s.quantity as quantity,
c.customer_key as customer_key, c.customer_number as customer_number, concat(c.first_name,' ', c.last_name) as full_name, datediff(year,c.birthdate, getdate()) as age
from DataWarehouseAnalytics.gold.fact_sales as s left join DataWarehouseAnalytics.gold.dim_customers as c on s.customer_key=c.customer_key
where s.order_date is not null),

intermed_query as(
-- doing basic aggregations
select customer_key,customer_number,age,full_name,
count(distinct order_number) as total_orders,
sum(sales_amount) as total_sales,
sum(quantity) as toal_quantity,
count(distinct product_key) as total_products,
max(order_date) as last_order_date,
datediff(month,min(order_date),max(order_date)) as life_span
from base_query
group by
customer_key,customer_number,age,full_name)

-- main query
select customer_key,customer_number,full_name,age,
case 
     when age<20 then 'minor'
     when age > 20 and age< 30 then 'young'
	 when age>30 and age<40 then 'middle_aged'
	 when age>40 and age<50 then'aged'
	 else 'senior_citizen'
end age_group,
case 
	when total_sales >= 5000 and life_span >= 12 then 'vip'
	when total_sales <5000 and life_span < 12 then 'regular'
	else 'new'
end as type_of_customer,
total_orders,
last_order_date,
datediff(month,last_order_date,getdate()) as recency,
total_sales,
toal_quantity,
-- average order value (aov) calculation (there might be 0 orders from someone , take care of that using case when)
case when total_orders= 0 then 0
else (total_Sales/total_orders)
end as AOV,
-- average monthly spend (amo) calculation
case when life_span=0 then total_sales
else total_sales/life_span 
end as amo,
total_products,
life_span
from intermed_query

-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
/*
-------------------------------
Product Report
---------------------------------
Purpose:
This report consolidates key product metrics and behaviors.
Highlights:
1. Gathers essential fields such as product name, category, subcategory, and cost.
2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers. 3. Aggregates product-level metrics:
total orders
total sales
total quantity sold
total customers (unique)
lifespan (in months)
4. Calculates valuable KPIs:
recency (months since last sale)
average order revenue (AOR)
average monthly revenue
--------------------------------------------------------
--------------------------------------------------------
*/

with base_query as (
-- base queries to retrieve core columns and basic filteration and changes from the table
select s.order_number as order_number,
s.order_date as order_date,
s.customer_key as customer_key,
s.sales_amount as sales_amount,
s.quantity as quantity,
p.product_key as product_key,
p.product_name as product_name,
p.category as category,
p.subcategory as subcategory,
p.cost as cost 
from
DataWarehouseAnalytics.gold.fact_sales as s
left join DataWarehouseAnalytics.gold.dim_products as p
on s.product_key = p.product_key
where s.order_date is not null),

intermed_query as (
-- doing basic aggregations
select product_key, product_name, category, subcategory, cost ,
datediff(month,min(order_date),max(order_date)) as life_span,
max(order_date) as last_order_date,
count(distinct order_number) as total_orders,
count(distinct customer_key) as total_customers,
sum(sales_amount) as total_sales,
sum(quantity) as total_quantity,
-- calculating avg selling price
round(avg(cast(sales_amount as float)/nullif(cast(quantity as float),0)),2) as asp
from base_query
group by product_key, product_name, category, subcategory, cost)


--main query
select product_key, product_name, category, subcategory, cost , last_order_date,
datediff(month,last_order_date,getdate()) as recency,
case
	when total_sales>50000 then 'best_performer'
	when total_sales<10000 then 'mid_performer'
else 'low_performer'
end as product_segment,
life_span,
total_orders,
total_sales,
total_quantity,
total_customers,
asp,
-- average order revenue
case
	when total_orders = 0  then 0
else total_sales/total_orders 
end as aor,
-- average monthly revenue
case
	when life_span = 0 then total_sales
else total_sales/life_span
end as amr
from intermed_query

-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
--end of the project 
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-- Thank You! 

-- This SQL journey has been all about exploring data and uncovering insights.  
-- I appreciate you taking the time to check out this project! If it helped you in any way,  
-- I'd love to connect and hear your thoughts.  

-- Happy Querying! :)  

-- – Krish Wadhwa  
-- 🔗 LinkedIn:
--https://www.linkedin.com/in/contactkrishwadhwa/
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
