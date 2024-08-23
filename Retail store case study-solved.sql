--CASE STUDY BASIC

Create database basicdb;
Select*
From dbo.Customer

Select*
From dbo.prod_cat_info

Select*
From dbo.Transactions

--DATA PREPARATION AND UNDERSTANDING

--1.Total number of rows in each of the 3 tables in the database

SELECT COUNT(*) FROM Customer
SELECT COUNT(*) FROM prod_cat_info
SELECT COUNT(*) FROM Transactions

--2.Total number of transactions that have a return

SELECT COUNT(*) AS Retrn
FROM Transactions
WHERE CONVERT(FLOAT, total_amt) < 0;

--3.Convert the date variables into valid date formats

SELECT CONVERT(DATE, DOB, 103) AS C_Date FROM Customer
SELECT CONVERT(DATE, tran_date, 105) AS T_Date FROM Transactions

--4.What is the time range of the transaction data available for analysis? Show the output in number of days, months and years simultaneously in different columns.


SELECT DATEDIFF(DAY, MIN(CONVERT(DATE, tran_date, 105)), MAX(CONVERT(DATE, tran_date, 105))) AS days_range, 
DATEDIFF(MONTH, MIN(CONVERT(DATE, tran_date, 105)), MAX(CONVERT(DATE, tran_date, 105))) AS months_range,  
DATEDIFF(YEAR, MIN(CONVERT(DATE, tran_date, 105)), MAX(CONVERT(DATE, tran_date, 105))) AS years_range 
FROM Transactions

--5.Which product category does the sub-category “DIY” belong to?

SELECT prod_cat
FROM prod_cat_info
WHERE prod_subcat = 'DIY';

--DATA ANALYSIS

--1.Which channel is most frequently used for transactions?

SELECT TOP 1 
Store_type, COUNT(*) AS t_count
FROM Transactions
GROUP BY Store_type
ORDER BY t_count DESC;

--2.What is the count of Male and Female customers in the database?

SELECT Gender, COUNT(*) AS G_count
FROM Customer
WHERE Gender IN ('M','F')
GROUP BY Gender

--3.From which city do we have the maximum number of customers and how many?

SELECT TOP 1
city_code, COUNT(*) AS C_count
FROM Customer
GROUP BY city_code
ORDER BY C_count desc;

--4.How many sub-categories are there under the Books category?

SELECT COUNT(*) AS B_subcat
FROM prod_cat_info
WHERE prod_cat = 'BOOKS'

--5.What is the maximum quantity of products ever ordered?

SELECT TOP 1 Qty 
FROM Transactions
ORDER BY Qty desc;

--6.What is the net total revenue generated in categories Electronics and Books?

SELECT SUM(CONVERT(DECIMAL(18, 3), total_amt)) AS AMOUNT
FROM Transactions t
INNER JOIN prod_cat_info p  ON p.prod_cat_code = t.prod_cat_code 
AND p.prod_sub_cat_code = t.prod_subcat_code
WHERE prod_cat IN ('BOOKS' , 'ELECTRONICS')

--7.How many customers have >10 transactions with us, excluding returns?

SELECT COUNT(*) AS CUSTOMER_COUNT
FROM Customer
WHERE customer_Id IN 
(
    SELECT cust_id
    FROM Transactions
    JOIN Customer ON customer_Id= cust_id
    WHERE CONVERT(DECIMAL(18,2), total_amt ) >= 0
    GROUP BY cust_id
    HAVING COUNT(transaction_id) > 10
);

--8.What is the combined revenue earned from the “Electronics” & “Clothing” categories, from “Flagship stores”?

SELECT SUM(CONVERT(Decimal(18, 2), total_amt)) AS AMOUNT 
FROM Transactions t
INNER JOIN prod_cat_info p ON p.prod_cat_code  = t.prod_cat_code 
	  AND p.prod_sub_cat_code = t.prod_subcat_code
WHERE prod_cat IN ('CLOTHING','ELECTRONICS') AND Store_type = 'FLAGSHIP STORE'

--9.What is the total revenue generated from “Male” customers in “Electronics” category? Output should display total revenue by prod sub-cat.

SELECT p.prod_subcat, SUM(CONVERT(Decimal(18, 2),total_amt)) AS REVENUE
FROM Transactions t
LEFT JOIN Customer c ON t.cust_id = c.customer_Id
LEFT JOIN prod_cat_info p ON p.prod_sub_cat_code = t.prod_subcat_code AND p.prod_cat_code = t.prod_cat_code
WHERE prod_cat= 'ELECTRONICS' AND Gender= 'M'
GROUP BY p.prod_subcat

--10.What is percentage of sales and returns by product sub category; display only top 5 sub categories in terms of sales?

WITH SalesPercentage AS (
    SELECT 
        p.prod_subcat, 
        SUM(CAST(t.total_amt AS DECIMAL(18, 2))) AS TotalSales,
        (SUM(CAST(t.total_amt AS DECIMAL(18, 2))) * 100.0 / 
        (SELECT SUM(CAST(total_amt AS DECIMAL(18, 2))) FROM Transactions)) AS PercentOfSales
    FROM 
        Transactions t
    INNER JOIN 
        prod_cat_info p ON t.prod_cat_code = p.prod_cat_code 
                        AND t.prod_subcat_code = p.prod_sub_cat_code
    GROUP BY 
        p.prod_subcat
),
ReturnsPercentage AS (
    SELECT 
        p.prod_subcat, 
        SUM(CAST(t.total_amt AS DECIMAL(18, 2))) AS TotalReturns,
        (SUM(CASE WHEN t.qty < 0 THEN CAST(t.total_amt AS DECIMAL(18, 2)) ELSE 0 END) * 100.0 / 
        (SELECT SUM(CAST(total_amt AS DECIMAL(18, 2))) FROM Transactions WHERE qty < 0)) AS PercentOfReturns
    FROM 
        Transactions t
    INNER JOIN 
        prod_cat_info p ON t.prod_cat_code = p.prod_cat_code 
                        AND t.prod_subcat_code = p.prod_sub_cat_code
    GROUP BY 
        p.prod_subcat
)
SELECT TOP 5 
    s.prod_subcat, 
    s.TotalSales, 
    s.PercentOfSales, 
    r.TotalReturns, 
    r.PercentOfReturns
FROM 
    SalesPercentage s
LEFT JOIN 
    ReturnsPercentage r ON s.prod_subcat = r.prod_subcat
ORDER BY 
    s.PercentOfSales DESC;



--11.For all customers aged between 25 to 35 years find what is the net total revenue generated by these consumers in last 30 days of transactions
-- from max transaction date available in the data?

SELECT cust_id, SUM(CONVERT(Decimal(18, 2),total_amt))AS REVENUE 
FROM Transactions
WHERE cust_id IN 
	(SELECT customer_Id
	 FROM Customer
     WHERE DATEDIFF(YEAR,CONVERT(DATE,DOB,103),GETDATE()) BETWEEN 25 AND 35)
     AND CONVERT(DATE,tran_date,103) BETWEEN DATEADD(DAY,-30,(SELECT MAX(CONVERT(DATE,tran_date,103)) FROM Transactions)) 
	 AND (SELECT MAX(CONVERT(DATE,tran_date,103)) FROM Transactions)
GROUP BY cust_id

--12.Which product category has seen the max value of returns in the last 3 months of transactions?

SELECT TOP 1 prod_cat, 
SUM(CONVERT(Decimal(18, 2),total_amt)) AS tot_returns
FROM Transactions t
INNER JOIN prod_cat_info p ON t.prod_cat_code = p.prod_cat_code
AND t.prod_subcat_code = p.prod_sub_cat_code
WHERE
CONVERT(Decimal(18, 2), t.total_amt) < 0 
AND
CONVERT(date, tran_date, 103) BETWEEN DATEADD(MONTH,-3,(SELECT MAX(CONVERT(DATE,tran_date,103)) FROM Transactions)) 
AND (SELECT MAX(CONVERT(DATE,tran_date,103)) FROM Transactions)
GROUP BY prod_cat
ORDER BY tot_returns DESC

--13.Which store-type sells the maximum products; by value of sales amount and by quantity sold?

SELECT TOP 1
Store_type,
SUM(CONVERT(Decimal(18, 2), total_amt)) AS total_sales_amount,
SUM(CAST(Qty AS INT)) AS total_quantity_sold
FROM 
Transactions
GROUP BY 
Store_type
ORDER BY 
total_sales_amount DESC, 
total_quantity_sold DESC;

--14.What are the categories for which average revenue is above the overall average.

SELECT 
prod_cat, 
AVG(CONVERT(DECIMAL(18, 2), total_amt)) AS AVERAGE
FROM 
Transactions t
INNER JOIN 
prod_cat_info p ON t.prod_cat_code = p.prod_cat_code 
AND t.prod_subcat_code = p.prod_sub_cat_code
GROUP BY 
p.prod_cat
HAVING 
AVG(CONVERT(DECIMAL(18, 2), total_amt)) > 
(SELECT AVG(CONVERT(DECIMAL(18, 2), total_amt)) FROM Transactions);

--15.Find the average and total revenue by each subcategory for the categories which are among top 5 categories in terms of quantity sold.
--Not able to get the top 5 categories
SELECT prod_cat, prod_subcat, 
AVG(CONVERT(DECIMAL(18, 2), total_amt)) AS AVG_REV, 
SUM(CONVERT(Decimal(18, 2), total_amt)) AS TOT_REV
FROM Transactions t
INNER JOIN 
prod_cat_info p ON t.prod_cat_code = p.prod_cat_code 
AND 
t.prod_subcat_code = p.prod_sub_cat_code
WHERE p.prod_cat IN
(
SELECT TOP 5 
pc.prod_cat
FROM Transactions tr
INNER JOIN 
prod_cat_info pc ON tr.prod_cat_code = pc.prod_cat_code 
AND 
tr.prod_subcat_code = pc.prod_sub_cat_code
GROUP BY pc.prod_cat
ORDER BY SUM(CAST(tr.Qty AS INT)) DESC
)
GROUP BY p.prod_cat, p.prod_subcat 























