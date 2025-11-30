--Creating tables and dataset structure:

CREATE TABLE Orders (               
    Order_ID NVARCHAR(50),
    Order_Date NVARCHAR(50),
    Ship_Date NVARCHAR(50),
    Ship_Mode NVARCHAR(100),
    Customer_ID NVARCHAR(50)
);

CREATE TABLE Customers (
    Customer_ID NVARCHAR(50),
    Customer_Name NVARCHAR(100),
    Segment NVARCHAR(50),
    Country NVARCHAR(50),
    City NVARCHAR(100),
    State NVARCHAR(100),
    Region NVARCHAR(50)
);


CREATE TABLE Products (
Category NVARCHAR(100),
Sub_Category NVARCHAR(100),
Product_Name NVARCHAR(200),
Product_ID NVARCHAR(50)
);


CREATE TABLE Sales (
Order_ID NVARCHAR(50),
Sales Float,
Product_ID NVARCHAR(50)
);


--Bulk inserting data:

BULK INSERT Orders
FROM 'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\Orders.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001',
    TABLOCK
);

BULK INSERT Customers
FROM 'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\Customers.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001',
    TABLOCK
);


BULK INSERT Products
FROM 'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\Products.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001',
    TABLOCK
);


BULK INSERT Sales
FROM 'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\Sales.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001',
    TABLOCK
);


-- Data cleaning:
  --checking for duplicates in all tables:

SELECT 'Orders' AS TableName, COUNT(*) AS DuplicateCount
FROM (
    SELECT Order_ID, Order_Date, Ship_Date, Ship_Mode, Customer_ID, COUNT(*) AS cnt
    FROM Orders
    GROUP BY Order_ID, Order_Date, Ship_Date, Ship_Mode, Customer_ID
    HAVING COUNT(*) > 1
) AS Dups;


SELECT 'Customers' AS TableName, COUNT(*) AS DuplicateCount
FROM (
    SELECT Customer_ID, Customer_Name, Segment, Country, City, State, COUNT(*) AS cnt
    FROM Customers
    GROUP BY Customer_ID, Customer_Name, Segment, Country, City, State, Region
    HAVING COUNT(*) > 1
) AS Dups;

SELECT 'Products' AS TableName, COUNT(*) AS DuplicateCount
FROM (
    SELECT Product_ID, Product_Name, Category, Sub_Category, COUNT(*) AS cnt
    FROM Products
    GROUP BY Product_ID, Product_Name, Category, Sub_Category
    HAVING COUNT(*) > 1
) AS Dups;

SELECT 'Sales' AS TableName, COUNT(*) AS DuplicateCount
FROM (
    SELECT Order_ID, Product_ID, Sales, COUNT(*) AS cnt        -------It showed one duplicate 
    FROM Sales
    GROUP BY Order_ID, Product_ID, Sales
    HAVING COUNT(*) > 1
) AS Dups;

SELECT 
    Order_ID, 
    Product_ID, 
    Sales, 
    COUNT(*) AS DuplicateCount
FROM Sales
GROUP BY 
    Order_ID, 
    Product_ID, 
    Sales
HAVING COUNT(*) > 1;

--Dropping the duplicate in the Sales table:
WITH Duplicates AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY Order_ID, Product_ID, Sales
            ORDER BY (SELECT NULL)
        ) AS rn
    FROM Sales
)
DELETE FROM Duplicates
WHERE rn > 1;


--Checking for Nulls:
SELECT 'Orders' AS TableName, COUNT(*) AS NullRows
FROM Orders
WHERE Order_ID IS NULL OR LTRIM(RTRIM(Order_ID)) = ''
   OR Order_Date IS NULL OR LTRIM(RTRIM(Order_Date)) = ''
   OR Ship_Date IS NULL OR LTRIM(RTRIM(Ship_Date)) = ''
   OR Ship_Mode IS NULL OR LTRIM(RTRIM(Ship_Mode)) = ''
   OR Customer_ID IS NULL OR LTRIM(RTRIM(Customer_ID)) = '';

SELECT 'Customers' AS TableName, COUNT(*) AS NullRows
FROM Customers
WHERE Customer_ID IS NULL OR LTRIM(RTRIM(Customer_ID)) = ''
   OR Customer_Name IS NULL OR LTRIM(RTRIM(Customer_Name)) = ''
   OR Segment IS NULL OR LTRIM(RTRIM(Segment)) = ''
   OR Country IS NULL OR LTRIM(RTRIM(Country)) = ''
   OR City IS NULL OR LTRIM(RTRIM(City)) = ''
   OR State IS NULL OR LTRIM(RTRIM(State)) = ''
   OR Region IS NULL OR LTRIM(RTRIM(Region)) = '';


SELECT 'Products' AS TableName, COUNT(*) AS NullRows
FROM Products
WHERE Product_ID IS NULL OR LTRIM(RTRIM(Product_ID)) = ''
   OR Product_Name IS NULL OR LTRIM(RTRIM(Product_Name)) = ''
   OR Category IS NULL OR LTRIM(RTRIM(Category)) = ''
   OR Sub_Category IS NULL OR LTRIM(RTRIM(Sub_Category)) = '';

SELECT 'Sales' AS TableName, COUNT(*) AS NullRows
FROM Sales
WHERE Order_ID IS NULL OR LTRIM(RTRIM(Order_ID)) = ''
   OR Product_ID IS NULL OR LTRIM(RTRIM(Product_ID)) = ''
   OR Sales IS NULL OR LTRIM(RTRIM(Sales)) = '';              ----No Null Values was found----



-----Cleaning Dates:

--Unify the text format
UPDATE Orders
SET [Order_Date] = LTRIM(RTRIM(REPLACE([Order_Date], '-', '/'))),
    [Ship_Date]  = LTRIM(RTRIM(REPLACE([Ship_Date], '-', '/')));

--Split the text into Day / Month / Year columns
ALTER TABLE Orders
ADD [Order_Day] NVARCHAR(2),
    [Order_Month] NVARCHAR(2),
    [Order_Year] NVARCHAR(4),
    [Ship_Day] NVARCHAR(2),
    [Ship_Month] NVARCHAR(2),
    [Ship_Year] NVARCHAR(4);
-- Split Order_Date
UPDATE Orders
SET [Order_Day] = LEFT([Order_Date], CHARINDEX('/', [Order_Date]) - 1),
    [Order_Month] = SUBSTRING([Order_Date], CHARINDEX('/', [Order_Date]) + 1,
                             CHARINDEX('/', [Order_Date], CHARINDEX('/', [Order_Date]) + 1) - CHARINDEX('/', [Order_Date]) - 1),
    [Order_Year] = SUBSTRING([Order_Date], CHARINDEX('/', [Order_Date], CHARINDEX('/', [Order_Date]) + 1) + 1, 4);

-- Split Ship_Date
UPDATE Orders
SET [Ship_Day] = LEFT([Ship_Date], CHARINDEX('/', [Ship_Date]) - 1),
    [Ship_Month] = SUBSTRING([Ship_Date], CHARINDEX('/', [Ship_Date]) + 1,
                             CHARINDEX('/', [Ship_Date], CHARINDEX('/', [Ship_Date]) + 1) - CHARINDEX('/', [Ship_Date]) - 1),
    [Ship_Year] = SUBSTRING([Ship_Date], CHARINDEX('/', [Ship_Date], CHARINDEX('/', [Ship_Date]) + 1) + 1, 4);

--Convert day/month/year to DATE using a calculated column
ALTER TABLE Orders
ADD [Order_Date_Std] DATE,
    [Ship_Date_Std] DATE;

-- Combine Day, Month, Year to a proper DATE
UPDATE Orders
SET [Order_Date_Std] = TRY_CONVERT(DATE, RIGHT('00'+[Order_Day],2)+'/'+RIGHT('00'+[Order_Month],2)+'/'+[Order_Year], 103),
    [Ship_Date_Std]  = TRY_CONVERT(DATE, RIGHT('00'+[Ship_Day],2)+'/'+RIGHT('00'+[Ship_Month],2)+'/'+[Ship_Year], 103);


----------------------------------------------------------------------------------------------------------------------------------
--Analysis questions:
---Customer analysis:----
--1)Who are the top 10 customers in terms of total revenue?
SELECT TOP 10
    C.Customer_ID,
    C.Customer_Name,
    SUM(S.Sales) AS Total_Sales
FROM Sales AS S
JOIN Orders AS O
    ON S.Order_ID = O.Order_ID
JOIN Customers AS C
    ON O.Customer_ID = C.Customer_ID
GROUP BY 
    C.Customer_ID,
    C.Customer_Name
ORDER BY 
    Total_Sales DESC;
--2)Who are the top 10 customers in terms of total orders?
SELECT TOP 10
    C.Customer_ID,
    C.Customer_Name,
    COUNT(O.Order_ID) AS Total_Orders
FROM Orders AS O
JOIN Customers AS C
    ON O.Customer_ID = C.Customer_ID
GROUP BY 
    C.Customer_ID,
    C.Customer_Name
ORDER BY 
    Total_Orders DESC;

--3)How do customer segments differ in purchase frequency and order size?
SELECT
    C.Segment,
    COUNT(DISTINCT O.Order_ID) AS Total_Orders,
    COUNT(DISTINCT O.Customer_ID) AS Total_Customers,
    ROUND(COUNT(DISTINCT O.Order_ID) * 1.0 / COUNT(DISTINCT O.Customer_ID), 2) AS Avg_Orders_Per_Customer,
    ROUND(AVG(S.Sales), 2) AS Avg_Order_Size,
    ROUND(SUM(S.Sales), 2) AS Total_Sales
FROM Sales AS S
JOIN Orders AS O
    ON S.Order_ID = O.Order_ID
JOIN Customers AS C
    ON O.Customer_ID = C.Customer_ID
GROUP BY 
    C.Segment
ORDER BY 
    Total_Sales DESC;

--4)Which customer segment (Consumer, Corporate, Home Office) generates the highest revenue?
SELECT
    C.Segment,
    SUM(S.Sales) AS Total_Revenue
FROM Sales AS S
JOIN Orders AS O
    ON S.Order_ID = O.Order_ID
JOIN Customers AS C
    ON O.Customer_ID = C.Customer_ID
GROUP BY 
    C.Segment
ORDER BY 
    Total_Revenue DESC;

--5)What’s the average order value for each customer segment?
SELECT
    C.Segment,
    ROUND(SUM(S.Sales) / COUNT(DISTINCT O.Order_ID), 2) AS Avg_Order_Value,
    SUM(S.Sales) AS Total_Sales,
    COUNT(DISTINCT O.Order_ID) AS Total_Orders
FROM Sales AS S
JOIN Orders AS O
    ON S.Order_ID = O.Order_ID
JOIN Customers AS C
    ON O.Customer_ID = C.Customer_ID
GROUP BY 
    C.Segment
ORDER BY 
    Avg_Order_Value DESC;


--6)Which regions and cities have the most profitable customers?
SELECT TOP 10
    C.Region,
    C.City,
    SUM(S.Sales) AS Total_Revenue,
    COUNT(DISTINCT O.Order_ID) AS Total_Orders,
    COUNT(DISTINCT O.Customer_ID) AS Total_Customers,
    ROUND(SUM(S.Sales) / COUNT(DISTINCT O.Order_ID), 2) AS Avg_Order_Value,
    ROUND(SUM(S.Sales) / COUNT(DISTINCT O.Customer_ID), 2) AS Avg_Revenue_Per_Customer
FROM Sales AS S
JOIN Orders AS O
    ON S.Order_ID = O.Order_ID
JOIN Customers AS C
    ON O.Customer_ID = C.Customer_ID
GROUP BY 
    C.Region, 
    C.City
ORDER BY 
    Total_Revenue DESC;

--7)What’s the average order frequency per customer per year?

SELECT
    YEAR(O.Order_Date_Std) AS Order_Year,
    ROUND(COUNT(DISTINCT O.Order_ID) * 1.0 / COUNT(DISTINCT O.Customer_ID), 2) AS Avg_Orders_Per_Customer
FROM Orders AS O
GROUP BY 
    YEAR(O.Order_Date_Std)
ORDER BY 
    Order_Year;

--8)Which regions have the highest average sales per customer?
SELECT
    C.Region,
    SUM(S.Sales) AS Total_Sales,
    COUNT(DISTINCT C.Customer_ID) AS Total_Customers,
    ROUND(SUM(S.Sales) / COUNT(DISTINCT C.Customer_ID), 2) AS Avg_Sales_Per_Customer
FROM Sales AS S
JOIN Orders AS O
    ON S.Order_ID = O.Order_ID
JOIN Customers AS C
    ON O.Customer_ID = C.Customer_ID
GROUP BY 
    C.Region
ORDER BY 
    Avg_Sales_Per_Customer DESC;

--9)What is the repeated purchase per segment and region?
SELECT TOP 10
    C.Region,
    C.Segment,
    COUNT(DISTINCT CASE WHEN OrderCount > 1 THEN C.Customer_ID END) AS Repeat_Customers,
    COUNT(DISTINCT C.Customer_ID) AS Total_Customers,
    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN OrderCount > 1 THEN C.Customer_ID END)
        / COUNT(DISTINCT C.Customer_ID), 2
    ) AS Repeat_Purchase_Rate
FROM (
    SELECT 
        O.Customer_ID,
        COUNT(DISTINCT O.Order_ID) AS OrderCount
    FROM Orders AS O
    GROUP BY O.Customer_ID
) AS CustomerOrders
JOIN Customers AS C
    ON CustomerOrders.Customer_ID = C.Customer_ID
GROUP BY 
    C.Region, C.Segment
ORDER BY 
    Repeat_Purchase_Rate DESC;

--10. Which cities have the highest customer retention or loyalty trends (by order frequency)?
WITH CustomerOrderFreq AS (
    SELECT 
        O.Customer_ID,
        C.City,
        COUNT(DISTINCT O.Order_ID) AS TotalOrders
    FROM Orders AS O
    JOIN Customers AS C 
        ON O.Customer_ID = C.Customer_ID
    GROUP BY O.Customer_ID, C.City
)
SELECT 
    City,
    ROUND(AVG(TotalOrders), 2) AS Avg_Orders_Per_Customer,
    COUNT(DISTINCT Customer_ID) AS Total_Customers
FROM CustomerOrderFreq
GROUP BY City
HAVING COUNT(DISTINCT Customer_ID) > 5  -- optional: filter cities with enough customers
ORDER BY Avg_Orders_Per_Customer DESC;


--11)What is the total number of customers filtered by each regions?
SELECT 
    Region,
    COUNT(DISTINCT Customer_ID) AS Total_Customers
FROM Customers
GROUP BY Region
ORDER BY Total_Customers DESC;

--12)How many customers in each state?
SELECT 
    State,
    COUNT(DISTINCT Customer_ID) AS Total_Customers
FROM Customers
GROUP BY State
ORDER BY Total_Customers DESC;

--13)What customer segments are most profitable (e.g., by region,)?
SELECT TOP 10
    c.Region,
    c.Segment,
    SUM(s.Sales) AS Total_Sales
FROM Sales s
JOIN Orders o ON s.Order_ID = o.Order_ID
JOIN Customers c ON o.Customer_ID = c.Customer_ID
GROUP BY c.Region, c.Segment
ORDER BY Total_Sales DESC;

-----------------------------------------------------------------------------------------------------------------------------------------------------
---Products analysis:--
--1)What are the top 10 best-selling products and the bottom 10 least-selling?
---Top 10 Best-Selling Products
SELECT TOP 10 
    p.Product_Name,
    SUM(s.Sales) AS Total_Sales
FROM Sales s
JOIN Products p ON s.Product_ID = p.Product_ID
GROUP BY p.Product_Name
ORDER BY Total_Sales DESC;

--- Bottom 10 Least-Selling Products
SELECT TOP 10 
    p.Product_Name,
    SUM(s.Sales) AS Total_Sales
FROM Sales s
JOIN Products p ON s.Product_ID = p.Product_ID
GROUP BY p.Product_Name
ORDER BY Total_Sales ASC;

--2)Which product categories contribute the most to total revenue?
SELECT 
    p.Category,
    SUM(s.Sales) AS Total_Sales
FROM Sales s
JOIN Products p ON s.Product_ID = p.Product_ID
GROUP BY p.Category
ORDER BY Total_Sales DESC;

--3)Which product categories and sub-categories generate the highest sales ?
SELECT 
    p.Category,
    p.Sub_Category,
    SUM(s.Sales) AS Total_Sales
FROM Sales s
JOIN Products p ON s.Product_ID = p.Product_ID
GROUP BY p.Category, p.Sub_Category
ORDER BY Total_Sales DESC;

--4)How does product performance vary across regions and customer segments?
SELECT 
    p.Category,
    p.Sub_Category,
    SUM(s.Sales) AS Total_Sales
FROM Sales s
JOIN Products p ON s.Product_ID = p.Product_ID
GROUP BY 
    p.Category,
    p.Sub_Category
ORDER BY 
    p.Category,
    Total_Sales DESC;

--5)Which product categories show the fastest sales growth over time?
SELECT 
    p.Category,
    YEAR(o.Order_Date_Std) AS Order_Year,
    SUM(s.Sales) AS Total_Sales
FROM Sales s
JOIN Orders o ON s.Order_ID = o.Order_ID
JOIN Products p ON s.Product_ID = p.Product_ID
WHERE o.Order_Date_Std IS NOT NULL
GROUP BY 
    p.Category,
    YEAR(o.Order_Date_Std)
ORDER BY 
    p.Category,
    Order_Year;

--6)How can we visualize the contribution of each sub-category to overall revenue?
SELECT 
    p.Category,
    p.Sub_Category,
    SUM(s.Sales) AS Total_Sales,
    ROUND(
        SUM(s.Sales) * 100.0 / SUM(SUM(s.Sales)) OVER (),
        2
    ) AS Percentage_of_Total
FROM Sales s
JOIN Products p ON s.Product_ID = p.Product_ID
GROUP BY p.Category, p.Sub_Category
ORDER BY Total_Sales DESC;

--7)What are the most frequently ordered products per region or customer segment?
SELECT Top 10
    c.Region,
    p.Product_Name,
    COUNT(s.Order_ID) AS Order_Frequency
FROM Sales s
JOIN Orders o ON s.Order_ID = o.Order_ID
JOIN Customers c ON o.Customer_ID = c.Customer_ID
JOIN Products p ON s.Product_ID = p.Product_ID
GROUP BY 
    c.Region,
    p.Product_Name
ORDER BY 
    c.Region,
    Order_Frequency DESC;
-------------------------------------------------------------------------------------------------------------------
---Orders & Sales analysis:
--1)What are the total sales and average sales per order?
SELECT o.Order_ID,
    SUM(s.Sales) AS Total_Sales_Per_Order,
	AVG(s.Sales) AS Avg_Sales_Per_Order
FROM Sales s
JOIN Orders o ON s.Order_ID = o.Order_ID
JOIN Customers c ON o.Customer_ID = c.Customer_ID
GROUP BY o.Order_ID
ORDER BY Total_Sales_Per_Order DESC;

--2)How many orders have been placed in every year?
SELECT 
    YEAR(Order_Date_Std) AS Order_Year,
    COUNT(Order_ID) AS Total_Orders
FROM Orders
WHERE Order_Date_Std IS NOT NULL
GROUP BY YEAR(Order_Date_Std)
ORDER BY Order_Year;

--3)What is the distribution of orders that mostly purchased by region?
SELECT 
    c.Region,
    COUNT(o.Order_ID) AS Total_Orders,
    ROUND(
        (COUNT(o.Order_ID) * 100.0) / SUM(COUNT(o.Order_ID)) OVER (), 
        2
    ) AS Percentage_of_Total
FROM Orders o
JOIN Customers c ON o.Customer_ID = c.Customer_ID
GROUP BY c.Region
ORDER BY Total_Orders DESC;

--4)What is the average shipping time (difference between Order Date & Ship Date)?
SELECT 
    AVG(DATEDIFF(DAY, Order_Date_Std, Ship_Date_Std)) AS Avg_Shipping_Time_Days
FROM Orders
WHERE Order_Date_Std IS NOT NULL 
  AND Ship_Date_Std IS NOT NULL;

--5)What’s the average order frequency per customer per year?
WITH CustomerYearOrders AS (
    SELECT 
        Customer_ID,
        YEAR(Order_Date_Std) AS Order_Year,
        COUNT(Order_ID) AS Orders_Per_Year
    FROM Orders
    WHERE Order_Date_Std IS NOT NULL
    GROUP BY Customer_ID, YEAR(Order_Date_Std)
)
SELECT 
    ROUND(AVG(Orders_Per_Year), 2) AS Avg_Orders_Per_Customer_Per_Year
FROM CustomerYearOrders;

--6)What is the total sales revenue over time (quarterly or annually)?
SELECT 
    YEAR(o.Order_Date_Std) AS Order_Year,
    DATEPART(QUARTER, o.Order_Date_Std) AS Order_Quarter,
    SUM(s.Sales) AS Total_Sales
FROM Sales s
JOIN Orders o ON s.Order_ID = o.Order_ID
WHERE o.Order_Date_Std IS NOT NULL
GROUP BY 
    YEAR(o.Order_Date_Std), 
    DATEPART(QUARTER, o.Order_Date_Std)

UNION ALL

SELECT 
    YEAR(o.Order_Date_Std) AS Order_Year,
    NULL AS Order_Quarter,
    SUM(s.Sales) AS Total_Sales
FROM Sales s
JOIN Orders o ON s.Order_ID = o.Order_ID
WHERE o.Order_Date_Std IS NOT NULL
GROUP BY YEAR(o.Order_Date_Std)

ORDER BY Order_Year, Order_Quarter;

--7)Does Ship Mode affect total sales and delivery speed?
SELECT 
    o.Ship_Mode,
    COUNT(DISTINCT o.Order_ID) AS Total_Orders,
    SUM(s.Sales) AS Total_Sales,
    AVG(DATEDIFF(DAY, o.Order_Date_Std, o.Ship_Date_Std)) AS Avg_Shipping_Days
FROM Orders o
JOIN Sales s ON o.Order_ID = s.Order_ID
WHERE o.Order_Date_Std IS NOT NULL 
  AND o.Ship_Date_Std IS NOT NULL
GROUP BY o.Ship_Mode
ORDER BY Total_Sales DESC;

--8)Which shipping modes are most used and most profitable?
SELECT 
    o.Ship_Mode,
    COUNT(DISTINCT o.Order_ID) AS Total_Orders,
    SUM(s.Sales) AS Total_Sales,
    ROUND(SUM(s.Sales) * 1.0 / COUNT(DISTINCT o.Order_ID), 2) AS Avg_Sales_Per_Order
FROM Orders o
JOIN Sales s ON o.Order_ID = s.Order_ID
WHERE o.Order_Date_Std IS NOT NULL
GROUP BY o.Ship_Mode
ORDER BY Total_Sales DESC;

--9)How do sales fluctuate over time (monthly, quarterly, yearly)?
SELECT 
    YEAR(o.Order_Date_Std) AS Order_Year,
    DATEPART(QUARTER, o.Order_Date_Std) AS Order_Quarter,
    SUM(s.Sales) AS Total_Sales
FROM Sales s
JOIN Orders o ON s.Order_ID = o.Order_ID
WHERE o.Order_Date_Std IS NOT NULL
GROUP BY YEAR(o.Order_Date_Std), DATEPART(QUARTER, o.Order_Date_Std)
ORDER BY Order_Year, Order_Quarter;

--10)Are there any seasonal patterns (e.g., sales peaks around holidays)?
SELECT 
    MONTH(o.Order_Date_Std) AS Order_Month,
    SUM(s.Sales) AS Total_Sales,
    AVG(s.Sales) AS Avg_Sales_Per_Order
FROM Sales s
JOIN Orders o ON s.Order_ID = o.Order_ID
WHERE o.Order_Date_Std IS NOT NULL
GROUP BY MONTH(o.Order_Date_Std)
ORDER BY Order_Month;












