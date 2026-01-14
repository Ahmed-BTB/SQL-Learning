-----------------------------------------------
-- Creating index to optimize scan performance 
-----------------------------------------------

-- Creating new table without indexes
select * into FactResellersSales_hp from FactResellerSales

-- Table scan : slower (without index)
select *
from FactResellersSales_hp

-- Index scan : faster (scanning all data in an index to find matching rows
create index idx_FactReseller_CTA on FactResellerSales (carrierTrackingNumber)
select *
from FactResellerSales

-- Index seek : more faster (a targeted search within an index, retrieving only specific rows)
select *
from FactResellerSales
where carrierTrackingNumber = '4E0A-4F89-AE'

-- Nested Loops : compares tables row by row (best for small tables)
-- Hash Match : Matching Rows using a hash Table (Best for large tables)
-- Merge Join : Merge two sorted tables (efficient when both are sorted)

select 
	p.EnglishProductName as ProductName,
	Sum(s.salesamount) as TotalSales
from FactResellerSales as s
join DimProduct as p on p.ProductKey = s.ProductKey
group by p.EnglishProductName

-- creating clustered index  to check the performance
create clustered columnstore index idx_FactResellersSales_hp_cs on FactResellersSales_hp
-- Fact Columnstore Costs = 0.012 
-- Fact Rowstore Costs = 1.308

select 
	p.EnglishProductName as ProductName,
	Sum(s.salesamount) as TotalSales
from FactResellersSales_hp as s
join DimProduct as p on p.ProductKey = s.ProductKey
group by p.EnglishProductName

-----------------------------------------------
-- SQL HINTS
-----------------------------------------------
USE SalesDB

select 
o.sales,
c.country 
from sales.orders o  --with (forceseek)
left join sales.customers c with (index([PK_customers]))
on o.customerid = c.CustomerID
--option (hash join)

-- Rule
-- # Avoid Over Indexing : Slows performance & Confuse Execution Plan

-- Indexing strategy 
-- #1 Phase  Initial Indexing Strategy (2 Steps)
--OLAP => Optimize Read Performance, Switch Large frequently used tables into columnstore
--OLTP => Optimize Write Performance, Clustered index Primary Keys

-- #2 phase usage patterns indexing (3 Steps)
-- identify frequently used TAbles & Columns
-- Choose right index
-- Test index

-- #3 Scenario-Based indexing (4 Steps)
-- identify slow queries
-- check execution plan
-- choose right index 
-- (Test) Compare execution plans 

-- #4 Monitoring & Maintenance (5 Steps)
-- monitor index usage 
-- monitor missing indexes
-- Monitor duplicate indexes
-- update statistics
-- Monitor fragmentations