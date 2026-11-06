-- 1. Create Database
CREATE DATABASE CustomerSegmentationDB;
GO

USE CustomerSegmentationDB;
GO

-- # 3. Create Retail Transactions Table
CREATE TABLE dbo.RetailTransactions (
    InvoiceNo NVARCHAR(20),
    StockCode NVARCHAR(50),
    Description VARCHAR(255),
    Quantity INT,
    InvoiceDate DATETIME,
    UnitPrice DECIMAL(10, 2),
    CustomerID INT,
    Country NVARCHAR(100)
);
GO


-- # Check Table and Row Count
SELECT COUNT(*) AS TotalRows
FROM dbo.RetailTransactions;

SELECT COUNT(*) AS TotalCustomers
FROM dbo.CustomerSegments;

-- # View Sample Data
SELECT TOP 10 *
FROM dbo.RetailTransactions;

SELECT TOP 10 *
FROM dbo.CustomerSegments;



-- 1. Customers with Highest Revenue
SELECT TOP 10 CustomerID, SUM(Quantity * UnitPrice) AS Revenue
FROM dbo.RetailTransactions
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY Revenue DESC;

-- 2. Percentage of Repeat Customers
WITH C AS (
    SELECT CustomerID, COUNT(DISTINCT InvoiceNo) AS Purchases
    FROM dbo.RetailTransactions
    WHERE CustomerID IS NOT NULL AND InvoiceNo NOT LIKE 'C%'
    GROUP BY CustomerID
)
SELECT 100.0 * SUM(CASE WHEN Purchases > 1 THEN 1 ELSE 0 END)
       / COUNT(*) AS RepeatPercentage
FROM C;

-- 3. Average Days Between Purchases
WITH P AS (
    SELECT DISTINCT CustomerID, InvoiceNo, InvoiceDate
    FROM dbo.RetailTransactions
    WHERE CustomerID IS NOT NULL AND InvoiceNo NOT LIKE 'C%'
),
D AS (
    SELECT DATEDIFF(DAY,
        LAG(InvoiceDate) OVER (PARTITION BY CustomerID ORDER BY InvoiceDate),
        InvoiceDate) AS Days
    FROM P
)
SELECT AVG(1.0 * Days) AS AverageDays
FROM D WHERE Days IS NOT NULL;

-- 4. Repeat Rate by First-Purchase Month
WITH C AS (
    SELECT CustomerID, MIN(InvoiceDate) AS FirstDate,
           COUNT(DISTINCT InvoiceNo) AS Purchases
    FROM dbo.RetailTransactions
    WHERE CustomerID IS NOT NULL AND InvoiceNo NOT LIKE 'C%'
    GROUP BY CustomerID
)
SELECT YEAR(FirstDate) AS CohortYear, MONTH(FirstDate) AS CohortMonth,
       100.0 * SUM(CASE WHEN Purchases > 1 THEN 1 ELSE 0 END) / COUNT(*) AS RepeatRate
FROM C
GROUP BY YEAR(FirstDate), MONTH(FirstDate)
ORDER BY CohortYear, CohortMonth;

-- 5. Revenue by RFM Segment (requires dbo.CustomerSegments)
SELECT S.Segment, SUM(T.Quantity * T.UnitPrice) AS Revenue
FROM dbo.RetailTransactions T
JOIN dbo.CustomerSegments S ON T.CustomerID = S.CustomerID
GROUP BY S.Segment
ORDER BY Revenue DESC;

-- 6. Repeat Customers by Country
WITH C AS (
    SELECT Country, CustomerID, COUNT(DISTINCT InvoiceNo) AS Purchases
    FROM dbo.RetailTransactions
    WHERE CustomerID IS NOT NULL AND InvoiceNo NOT LIKE 'C%'
    GROUP BY Country, CustomerID
)
SELECT Country, COUNT(*) AS Customers,
       SUM(CASE WHEN Purchases > 1 THEN 1 ELSE 0 END) AS RepeatCustomers
FROM C
GROUP BY Country
ORDER BY RepeatCustomers DESC;
 