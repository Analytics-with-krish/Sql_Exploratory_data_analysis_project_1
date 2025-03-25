--DATA EXPLORATION

--Step 1 Dividing the various available table into measures  and dimensions
--Check whether the column is a measure or a dimension, any column that is numeric and can be aggregated is measure and any column that is non numeric or numeric but can not be aggregated than it is a dimension.
--Dimensions are used to find what things can be grouped up while presenting are findings, where as the measures answer the question like “how much” & “how many” etc.
--Eg- Grouping up the product categories and answering how much sales each generate
--step1(1)
select distinct category from gold.dim_products;
--step1(2)
select distinct sales_amount from DataWarehouseAnalytics.gold.fact_sales;
--step1(3)
select distinct product_name from DataWarehouseAnalytics.gold.dim_products;
--step1(4)
select distinct quantity from DataWarehouseAnalytics.gold.fact_sales;
--step1(5)
select distinct birthdate from DataWarehouseAnalytics.gold.dim_customers;
--step1(6)
select distinct customer_id,DATEDIFF(year,birthdate,getdate()) as age from DataWarehouseAnalytics.gold.dim_customers

--Measures -
--sales_amount
--Quantity
--Age

--Dimensions -
--Category
--Product Name
--Birthdate
--Customer_ID

--Step 2 EXPLORING ALL THE TABLES IN OUR DATABASE
select  * from DataWarehouseAnalytics.INFORMATION_SCHEMA.TABLES

--Table Names Result
--dim_customers
--dim_products
--fact_sales


--Step 3 exploring all the columns in our database

--step 3(1)

select  * FROM DataWarehouseAnalytics.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_customers'

--result column names

--customer_key
--customer_id
--customer_number
--first_name
--last_name
--country
--marital_status
--gender
--birthdate
--create_date


--step 3(2)

select  * FROM DataWarehouseAnalytics.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_products'

--result column names
--product_key
--product_id
--product_number
--product_name
--category_id
--category
--subcategory
--maintenance
--cost
--product_line
--start_date


--step 3(3)

select  * FROM DataWarehouseAnalytics.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'fact_sales'

--result column names
--order_number
--product_key
--customer_key
--order_date
--shipping_date
--due_date
--sales_amount
--quantity
--price

--------------------------------------------------------
-- DIMENSION EXPORATION

-- Step 1
-- Use the list of dimension that we created earlier

--step 1(1)
SELECT DISTINCT country from DataWarehouseAnalytics.gold.dim_customers

-- RESULT

--n/a
--Germany
--United States
--Australia
--United Kingdom
--Canada
--France

--step 1(2)
SELECT DISTINCT category,subcategory, product_name from DataWarehouseAnalytics.gold.dim_products order by 1,2,3
--shows us the full category of what we offer to the customers

--------------------------------------

--DATE EXPLORATION
--step 1 
-- IDENTIFYING THE EARLIEST AND LAST DATES (BOUNDARIES)
SELECT MIN(order_date) as first_order_date , Max(order_date) as latest_order_date from DataWarehouseAnalytics.gold.fact_sales

-- step 2
-- calculating how manhy years of sales are available
select datediff(year,MIN(order_date),Max(order_date)),datediff(month,MIN(order_date),Max(order_date)) as total_months_in_business from DataWarehouseAnalytics.gold.fact_sales

-- step 3
-- looking at the customers age profiles (basically youngest and oldest customers age)
select min(birthdate) as oldest_cutomer,max(birthdate) as youngest_customer,
datediff( year, min(birthdate),getdate()) as oldest_cst_age,datediff( year, max(birthdate),getdate()) as youngest_cst_age from DataWarehouseAnalytics.gold.dim_customers

-- shows are customers lie between 39 to 109 years of age

-----------------------------------------------------------------------------------------------------------------

-- MEASURES EXPLORATION 
-- use the measures that we defined in earlier steps

-- Step 1 
--Finding the total sales to undertand the volume of our business
--finding total sales
select sum(sales_amount)as total_sales from DataWarehouseAnalytics.gold.fact_sales
--finding how many items are sold
select sum(quantity) as total_units_sold from DataWarehouseAnalytics.gold.fact_sales 
-- find the avg selling price
select avg(price) as avg_price from DataWarehouseAnalytics.gold.fact_sales
-- find the total number of orders
select count(distinct order_number) from DataWarehouseAnalytics.gold.fact_sales
-- find total number of products
select count(distinct product_key ) as total_products from DataWarehouseAnalytics.gold.dim_products
-- find the total number of customer
select count( distinct customer_key) as total_customers from dataWarehouseAnalytics.gold.dim_customers

-- step 2 Generating a report of all metrics in the business (Showing the Key Metrics)
select 'Total Sales' as measure_name,sum(sales_amount)as measure_value from DataWarehouseAnalytics.gold.fact_sales
Union all
select 'Total quantity' as measure_name,sum(quantity)as measure_value from DataWarehouseAnalytics.gold.fact_sales
union all
select 'Average Price' as measure_name, avg(price) as measure_value from DataWarehouseAnalytics.gold.fact_sales
union all
select 'Total Orders' as measure_name, count(distinct order_number) as measure_value from DataWarehouseAnalytics.gold.fact_sales
union all
select 'Total Product Quanity' as measure_name, count(distinct product_key ) as measure_value from DataWarehouseAnalytics.gold.fact_sales
union all
select 'Total Number of Cutomers' as measure_name, count( distinct customer_key) as measure_value from DataWarehouseAnalytics.gold.fact_sales

---------------------------------------------------------------------
--Magnitude Analysis
--( measure by dimension , e.g. sales splitted country wise)

--step 1(1) spliting the number of customer by countries
Select  country, count( distinct DataWarehouseAnalytics.gold.fact_sales.customer_key) as value from 
DataWarehouseAnalytics.gold.dim_customers left join DataWarehouseAnalytics.gold.fact_sales
on DataWarehouseAnalytics.gold.dim_customers.customer_key = DataWarehouseAnalytics.gold.fact_sales.customer_key
group by country order by value desc
-- used join here but a simpler version would be putting count on DataWarehouseAnalytics.gold.dim_customers , both columns required are available in customers table

--step 1(2) finding total customers by gender (Demographics)
select gender, count(distinct customer_key) as total_customers from DataWarehouseAnalytics.gold.dim_customers group by gender order by total_customers desc

--step 1(3) find total products by category
select category, count(distinct product_key ) as value from DataWarehouseAnalytics.gold.dim_products  group by category order by value desc

--step 1(4) average cost in each category
select category, avg(cost) as value from DataWarehouseAnalytics.gold.dim_products  group by category order by value desc

--step 1(5) total revenue generated for each category 
select p.category, sum(f.sales_amount) from datawarehouseanalytics.gold.fact_sales as f 
left join datawarehouseanalytics.gold.dim_products as p on f.product_key= p.product_key group by p.category order by sum(f.sales_amount) desc

--step 1(6) total revenue generated for each customer along with their key details
select c.customer_key as Customer_id,concat(c.first_name,' ',c.last_name) as Full_name, sum(f.sales_amount) as revenue1 
from datawarehouseanalytics.gold.fact_sales as f 
left join datawarehouseanalytics.gold.dim_customers as c on c.customer_key= f.customer_key 
group by c.customer_key,c.first_name,c.last_name order by revenue1 desc

--step 1(7) Find the total quantities sold across countires
select c.country as Country, sum(f.quantity) as quantity
from datawarehouseanalytics.gold.fact_sales as f 
left join datawarehouseanalytics.gold.dim_customers as c on c.customer_key= f.customer_key 
group by c.country order by quantity desc

-------------------------------------------------------------------------------------------------
--RANKING ANALYSIS
-- ranking data to understand the significance of the output

--Step 1(1) Which 5 products generate the highest revenue (5 best sellers)
select TOP 5 p.product_name, sum(f.sales_amount) AS sales_data from datawarehouseanalytics.gold.fact_sales as f 
left join datawarehouseanalytics.gold.dim_products as p on f.product_key= p.product_key group by p.product_name order by sum(f.sales_amount) desc

--Step 1(2) Which 5 products generate the lowest revenue (5 worst sellers)
select TOP 5 p.product_name, sum(f.sales_amount) AS sales_data from datawarehouseanalytics.gold.fact_sales as f 
left join datawarehouseanalytics.gold.dim_products as p on f.product_key= p.product_key group by p.product_name order by sum(f.sales_amount) asc

-- for more felxible and complex queries with extra details we  can use the window function for the same
-- solution through window function
Select * from (select p.product_name, sum(f.sales_amount) as sales_data, rank() over (order by sum(f.sales_amount) asc) as ranking from datawarehouseanalytics.gold.fact_sales as f 
left join datawarehouseanalytics.gold.dim_products as p on f.product_key= p.product_key group by p.product_name) as T where T.ranking <=5