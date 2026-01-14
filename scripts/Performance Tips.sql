
-- Filltering data 

-- ======================================
-- Tip 1: Select only what you need
-- ======================================
-- Bad practice 
SELECT * FROM sales.Customers
-- Good practice 
select customerID, FirstName, LastName from sales.Customers

-- ======================================
-- Tip 2: Avoid unnecessary distince & order by
-- ======================================
-- Bad Practice 
select distinct 
firstname
from sales.customers
order by FirstName
-- Good Practice
select 
firstname
from sales.customers

-- ======================================
-- Tip 3: For exploration purpose, Limit Rows!
-- ======================================
-- Bad Practice 
select 
	OrderId,
	Sales
from sales.orders
-- Good Practice
select Top 10
	OrderId,
	Sales
from sales.orders

-- ======================================
-- Tip 4: Create non clustered index on frequently used columns in where claues
-- ======================================
-- Bad Practice 
select * from sales.orders where OrderStatus = 'Delivered'
-- Good Practice
create nonclustered index idx_orders_orderstatus on Sales.orders(orderstatus)
select * from sales.orders where OrderStatus = 'Delivered'

-- ======================================
-- Tip 5: Avoid applying functions to columns in where clause
-- ======================================
-- Note function on columns can block index usage
-- Bad Practice 
select *
from sales.customers 
where substring(FirstName, 1,1) = 'A'
-- Good Practice
SELECT * FROM Sales.customers
where FirstName like 'A%'

-- ======================================
-- Tip 6: Avoid leading wildcards as they prevent index usage
-- ======================================
-- Bad Practice 
Select * from sales.customers where LastName like '%Gold%'
-- Good Practice
Select * from sales.customers where LastName like 'Gold%'

-- ======================================
-- Tip 7: Use in instead of multiple OR conditions
-- ======================================
-- Bad Practice
SELECT * From sales.Customers where customerid = 1 or customerid = 2 or customerid = 3
-- Good Practice
SELECT * From sales.Customers where customerid in (1,2,3)

 
-- Joining data

-- ======================================
-- Tip 8: Understand the speed of joins and use inner join when possible
-- ======================================
-- Best Practice 
select c.firstname from sales.Customers c INNER JOIN Sales.orders o on o.CustomerID = c.customerid
-- slightly slower performance
select c.firstname from sales.Customers c left JOIN Sales.orders o on o.CustomerID = c.customerid
-- Worst performance
select c.firstname from sales.Customers c full outer JOIN Sales.orders o on o.CustomerID = c.customerid

-- ======================================
-- Tip 9: use explicit join (ansi join) instead of implicit join (non-ansi join)
-- ======================================
-- Bad Practice 
select o.ORDERID, c.FirstName
from sales.Customers c,sales.orders o
where c.CustomerID = o.CustomerID
-- Good Practice
select o.ORDERID, c.FirstName
from sales.Customers c
inner join sales.orders o
on o.customerid = c.customerid

-- ======================================
-- Tip 10: Index columns used in JOIN conditions for better performance
-- ======================================
-- Query using ANSI INNER JOIN
SELECT c.FirstName, o.OrderID
FROM Sales.Orders o
INNER JOIN Sales.Customers c
ON c.CustomerID = o.CustomerID;

-- Create a nonclustered index to optimize the JOIN
CREATE NONCLUSTERED INDEX IX_Orders_CustomerID
ON Sales.Orders(CustomerID);

-- ======================================
-- Tip 11: Filter before joining (big tables)
-- ======================================
-- Note : Try to isolate the preparation step in a cte or a subquery
-- Filter After join (where)
select 
C.firstname, o.orderid
from sales.Customers c
inner join sales.orders o
on c.CustomerID = o.customerid
where o.OrderStatus = 'Delivered'
-- filter during join (on)
select 
C.firstname, o.orderid
from sales.Customers c
inner join sales.orders o
on c.CustomerID = o.customerid
and o.OrderStatus = 'Delivered'
--filter before join (subquery)
select c.firstname, o.orderid
from sales.customers c
inner join (select orderid, customerid from sales.orders o where orderstatus = 'Delivered') o
on c.customerid = o.customerid

-- ======================================
-- Tip 12: Aggregate before joining (big tables)
-- ======================================

--Best practice for small-medium tables
-- Grouping and joining
select c.customerid, c.firstname, count(o.orderid) as ordercount
from sales.customers c
inner join sales.orders o 
on c.CustomerID = o.CustomerID
group by c.CustomerID, c.FirstName

--Best practice for big tables
-- pre aggregated subquery
select c.customerid, c.FIRSTNAME, o.ordercount
from sales.customers c
inner join ( select customerid , count (orderid) ordercount from sales.orders group by customerid) o
on c.CustomerID = o.CustomerID

-- bad practice
select
c.customerid,
c.firstname,
(select count (*) from sales.orders o where o.customerid = c.customerid) ordercount
from sales.Customers c

-- ======================================
-- Tip 13: Use union instead of or in joins 
-- ======================================

--Bad practice
Select o.orderid, c.firstname
from sales.Customers c
inner join sales.orders o 
on c.CustomerID = o.CustomerID or c.CustomerID = o.SalesPersonID

-- Good practice
Select o.orderid, c.firstname
from sales.Customers c
inner join sales.orders o 
on c.CustomerID = o.CustomerID 
union 
Select o.orderid, c.firstname
from sales.Customers c
inner join sales.orders o 
on c.CustomerID = o.SalesPersonID

-- ======================================
-- Tip 14: Check for nested loops and use sql hints
-- ======================================
select o.orderid, c.firstname
from sales.customers c
inner join sales.orders o
on c.CustomerID = o.CustomerID
option (hash join) -- SQL HINT
.
-- ======================================
-- Tip 15: use union all instead of union if duplicates are acceptable
-- ======================================

-- ======================================
-- Tip 16: use union all + distinct instead of union if duplicates are acceptable
-- ======================================


-- Aggregating data 
-- ======================================
-- Tip 17: use columnstore index for aggregations on large tables
-- ======================================
create clustered columnstore index idx_orders_cs on sales.orders
select customerid, count(orderid) as ordercount from sales.orders group by customerid
-- ======================================
-- Tip 18: pre-aggregate data and store it in a new table
-- ======================================
select 
month (orderdate) orderyear, 
sum(sales) as TotalSales 
INTO Sales.SalesSummary
from sales.orders group by month(orderdate)

-- ======================================
-- Tip 19: JOIN VS EXISTS VS IN
-- ======================================
-- Best Practices : Subqueries

-- JOIN 
-- BEST practice if the performance equals to exists
select o.orderid, o.sales
from sales.orders o
join sales.customers c on O.CustomerID = c.customerid
where country = 'USA'

-- EXISTS
-- exists better than join because it stops at first match and avoid data duplication
select 
	o.orderid,
	o.sales
from sales.orders o where exists (select 1 from sales.customers c where c.customerid = o.customerid and country = 'USA') 

--	IN 
-- Bad practice the in operator processes and evaluates all rows it lacks an early exit mechanism
select 
o.orderid,
o.sales
from sales.orders o where o.CustomerID in (select customerid from sales.customers where country = 'USA')

-- ======================================
-- Tip 20: Avoid redundant logic in your query
-- ======================================

select employeeid, firstname, 'Above Average' Status
from sales.employees
where salary > (select avg (salary) from sales.employees)
union all
select employeeid, firstname, 'Below Average' status
from sales.employees
where salary < (select avg(salary) from sales.employees)

WITH cte_name AS (
    SELECT 
        EmployeeID,
        CASE 
            WHEN Salary > (AVG(Salary) OVER()) THEN 'Above Average'
            WHEN Salary < (AVG(Salary) OVER()) THEN 'Below Average'
            ELSE 'Average'
        END AS Status
    FROM Sales.Employees
)
SELECT 
    e.EmployeeID,
    e.FirstName,
    e.Salary,
    c.Status
FROM Sales.Employees e
INNER JOIN cte_name c ON e.EmployeeID = c.EmployeeID;


-- BEST Practices creating tables ddl

-- ======================================
-- Tip 21: AVOID TYPES VARCHAR & TEXT
-- ======================================
-- VARCHAR AND TEXT ARE VERY EXPENSIVE IN CREATING AN INDEX OR SORTING THE DATA
-- TEXT > VARCHAR > INT > DATETIME > DATE

-- ======================================
-- Tip 22: AVOID (MAX) unnecessarily large lengths in data types
-- ======================================

-- ======================================
-- Tip 23: use the not null constraint where applicable
-- ======================================

-- ======================================
-- Tip 24: Ensure all your tables have a clustered Primary Key
-- ======================================

-- ======================================
-- Tip 25: Create a non-clusterd index for foreign keys that are used frequently
-- ======================================

create table customerinfo (
    customerid int PRIMARY KEY,
    firstname varchar(50) NOT NULL,
    lastname varchar (50) NOT NULL,
    country varchar (50) NOT NULL,
    TotalPurchases FLOAT,
    Score INT,
    BirthDate DATE,
    EmployeeID INT,
    CONSTRAINT FK_CustomerInfo_EmployeeID FOREIGN KEY (EmployeeID)
        REFERENCES Sales.Employees(EmployeeID)
)
create nonclustered index ix_good_customers_employeeid
on customersinfo(employeeid)


-- BEST Practices INDEXING

-- ======================================
-- Tip 26: Avoid over indexing
-- ======================================

-- ======================================
-- Tip 27: Drop unused indexes
-- ======================================

-- ======================================
-- Tip 28: Update Statistics (Weekly)
-- ======================================

-- ======================================
-- Tip 29: Reorganize & Rebuild indexes (Weekly)
-- ======================================

-- ======================================
-- Tip 30: Partition Large Tables (Facts) to improve performance
-- ======================================
-- Next apply columnstore index then you will have the best performance if you have large tables