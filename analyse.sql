/*Overall Business Summary*/
-- 1 . Total Revenue
SELECT ROUND(SUM(Sales), 2) AS Total_Revenue FROM sales_new;

-- 2 . Total Profit
SELECT ROUND(SUM(Profit), 2) AS Total_Profit FROM sales_new;

-- 3.  Total Orders
SELECT COUNT(`Order ID`) AS Total_Orders FROM sales_new;

-- 4. Total Quantity Sold
SELECT SUM(Quantity) AS Total_Quantity_Sold
FROM sales_new;

/*Monthly Revenue & Profit Trend*/
-- 1 . Identify peak month
ALTER TABLE sales_new MODIFY `Order Date` DATE,MODIFY `Ship Date` DATE;
SELECT MONTHNAME(`Order Date`) AS Month_Name , ROUND(SUM(Sales),2) AS Total_Sales FROM sales_new group by Month_Name  ORDER BY Total_sales desc limit 1;

-- 2 . Identify peak month
SELECT MONTHNAME(`Order Date`) AS Month_Name , ROUND(SUM(Sales),2) AS Total_Sales FROM sales_new group by Month_Name  ORDER BY Total_sales asc limit 1;

-- 3 . Check Seasonality
SELECT 
    YEAR(`Order Date`) AS Year,
    MONTHNAME(`Order Date`) AS Month_Name,
    ROUND(SUM(Sales)) AS Total_Sales
FROM sales_new
GROUP BY YEAR(`Order Date`), MONTHNAME(`Order Date`) 
ORDER BY Year, Month_Name asc;

/*Year-over-Year Growth (If dataset spans multiple years)*/
SELECT 
    YEAR(`Order Date`) AS Year,
    SUM(Sales) AS Total_Sales,
    LAG(SUM(Sales)) OVER (ORDER BY YEAR(`Order Date`)) AS Previous_Year_Sales,
    ROUND(
        (SUM(Sales) - LAG(SUM(Sales)) OVER (ORDER BY YEAR(`Order Date`))) 
        / LAG(SUM(Sales)) OVER (ORDER BY YEAR(`Order Date`)) * 100,
        2
    ) AS YoY_Growth_Percent
FROM sales_new
GROUP BY YEAR(`Order Date`)
ORDER BY Year;


/*Category Performance */
-- 1. Revenue by category
SELECT Category, ROUND(SUM(sales)) AS Revenue from sales_new 
group by Category 
order by Revenue asc;

-- 2. Profit by category
SELECT Category, ROUND(SUM(Profit)) AS Total_Profit from sales_new 
group by Category 
order by Total_Profit asc;

-- 3. Profit margin %
 SELECT  ROUND((SUM(Profit)  / SUM(sales) * 100) ,2)  AS Profit_Margin FROM sales_new;


/*Sub-Category Deep Dive8 */
-- 1.Top 5 profitable sub-categories
SELECT 
    `Sub-Category`,
    ROUND(SUM(Profit), 2) AS Total_Profit
FROM sales_new
GROUP BY `Sub-Category`
ORDER BY Total_Profit DESC
LIMIT 5;


-- 2. Bottom 5 loss-making ones
SELECT 
    `Sub-Category`,
    ROUND(SUM(Profit), 2) AS Total_Profit
FROM sales_new
GROUP BY `Sub-Category`
HAVING SUM(Profit) < 0
ORDER BY Total_Profit ASC
LIMIT 5;


/* Region Analysis */
-- 1. Revenue by region
SELECT `Region`, ROUND(SUM(sales)) AS Revenue from sales_new 
group by `Region` 
order by Revenue desc;

-- 2. Profit by region
SELECT `Region`, ROUND(SUM(Profit)) AS Total_Profit from sales_new 
group by `Region` 
order by Total_Profit  desc;


-- 3. Margin by region
SELECT 
    Region,
    ROUND(
        SUM(Profit) / (SUM(Sales), 0) * 100,
        2
    ) AS Profit_Margin_Percent
FROM sales_new
GROUP BY Region
ORDER BY Profit_Margin_Percent DESC;

/*Discount Impact Analysis*/
SELECT 
    CASE 
        WHEN Discount = 0 THEN '0%'
        WHEN Discount > 0 AND Discount <= 0.10 THEN '1–10%'
        WHEN Discount > 0.10 AND Discount <= 0.20 THEN '10–20%'
        ELSE '20%+'
    END AS Discount_Range,
    
    ROUND(AVG(Profit), 2) AS Avg_Profit,
    ROUND(SUM(Sales), 2) AS Total_Revenue,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2) AS Profit_Margin_Percent
    
FROM sales_new
GROUP BY Discount_Range;

/*Top Customers Analysis*/
-- 1. Top 10 customers by revenue
SELECT `Customer Name` , ROUND(SUM(sales)) AS Total_sales from sales_new 
group by `Customer Name` 
order by Total_sales desc LIMIT 10 ;

-- 2.Revenue contribution %
SELECT 
    `Customer Name`,
    ROUND(SUM(Sales), 2) AS Customer_Revenue,
    ROUND(
        SUM(Sales) / 
        (SELECT SUM(Sales) FROM sales_new) * 100,
        2
    ) AS Revenue_Contribution_Percent
FROM sales_new
GROUP BY `Customer Name`
ORDER BY Revenue_Contribution_Percent DESC;

-- 3. Pareto check (Does 20% customers drive 80% revenue?)
WITH customer_revenue AS (
    SELECT 
        `Customer Name`,
        SUM(Sales) AS Customer_Revenue
    FROM sales_new
    GROUP BY `Customer Name`
),

ranked_data AS (
    SELECT
        `Customer Name`,
        Customer_Revenue,
        SUM(Customer_Revenue) OVER (ORDER BY Customer_Revenue DESC) AS Running_Revenue,
        SUM(Customer_Revenue) OVER () AS Total_Revenue,
        ROW_NUMBER() OVER (ORDER BY Customer_Revenue DESC) AS Customer_Rank,
        COUNT(*) OVER () AS Total_Customers
    FROM customer_revenue
)

SELECT
    `Customer Name`,
    ROUND(Customer_Revenue, 2) AS Customer_Revenue,
    ROUND(Running_Revenue / Total_Revenue * 100, 2) AS Cumulative_Revenue_Percent,
    ROUND(Customer_Rank / Total_Customers * 100, 2) AS Customer_Percent
FROM ranked_data
ORDER BY Customer_Revenue DESC;
  
  
  
/* Loss-Making Products */
-- 1. Identify products with negative total profit
SELECT `Product Name` , ROUND(SUM(Profit)) AS Total_profit from sales_new GROUP BY `Product Name` HAVING Total_profit < 0 ORDER BY Total_profit ;
  
-- 2. Check if high discount is cause  
SELECT
    CASE
        WHEN Discount = 0 THEN '0%'
        WHEN Discount > 0 AND Discount <= 0.10 THEN '1–10%'
        WHEN Discount > 0.10 AND Discount <= 0.20 THEN '10–20%'
        ELSE '20%+'
    END AS Discount_Range,

    ROUND(AVG(Profit), 2) AS Avg_Profit,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    ROUND(SUM(Sales), 2) AS Total_Revenue,
    ROUND(SUM(Profit) / SUM(Sales) * 100, 2) AS Profit_Margin_Percent

FROM sales_new
GROUP BY Discount_Range
ORDER BY Discount_Range;



/*Repeat vs One-Time Customers*/
-- 1. Count customers with multiple orders
SELECT 
    `Customer ID`,
    COUNT(DISTINCT `Order ID`) AS Total_Orders
FROM sales_new
GROUP BY `Customer ID`
HAVING COUNT(DISTINCT `Order ID`) > 1
ORDER BY Total_Orders DESC;
   
   
   
SELECT COUNT(*) AS Customers_With_Multiple_Orders
FROM (
    SELECT `Customer ID`
    FROM sales_new
    GROUP BY `Customer ID`
    HAVING COUNT(DISTINCT `Order ID`) > 1
) AS sub;   

-- 2. Compare revenue from repeat vs single-order customers
SELECT
    Customer_Type,
    ROUND(SUM(Customer_Revenue), 2) AS Total_Revenue
FROM (
    SELECT
        `Customer ID`,
        SUM(`Sales`) AS Customer_Revenue,
        CASE 
            WHEN COUNT(DISTINCT `Order ID`) > 1 THEN 'Repeat'
            ELSE 'Single-Order'
        END AS Customer_Type
    FROM sales_new
    GROUP BY `Customer ID`
) AS customer_summary
GROUP BY Customer_Type;




