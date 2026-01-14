
-- Creating clustered index
CREATE CLUSTERED INDEX idx_DBCustomers_Customerid on sales.DBCustomers (customerid)

	select * from sales.dbcustomers where customerid = 1

-- Creating non clustered index
CREATE NONCLUSTERED INDEX idx_DBCustomers_LastName on sales.dbcustomers (LastName)

	select * from sales.dbcustomers where Lastname = 'Brown'

-- The default is non clustered
CREATE INDEX idx_DBCustomers_FirstName on sales.dbcustomers (FirstName)

	select * from sales.dbcustomers where FirstName  = 'Anna'

-- you can create non clustered index based on multiple columns if you have complex query logic
CREATE INDEX idx_DBCustomers_CountryScore  on sales.dbcustomers (Country,Score)

	SELECT * FROM Sales.DBCustomers where country = 'USA' and Score > 500

-- Dropping the actual clustered index to create a new one because you can't create more than one
Drop index [idx_DBCustomers_Customerid] on sales.dbcustomers

create clustered columnstore index idx_columnstore_cs on sales.dbcustomers

DROP INDEX idx_columnstore_cs ON sales.dbcustomers

-- Creating non clustered columnstore index because the default id rowstore column store are better in olap
create nonclustered columnstore index idx_columnstore_cs_FirstName on sales.dbcustomers (FirstName)

-- Creating unique index to enforce uniqueness and slightly improve query performance
create unique nonclustered index idx_Products_Product on Sales.Products (Product)

--This process cannot be performed because we introduced unique index
insert into sales.Products (ProductID,Product) Values (106, 'Caps')

--Creating filtered index to targeted optimization and reduce index storage
create index idx_customers_country on sales.customers (country) where country = 'USA'

select * from sales.Customers where country = 'USA'

--List all indexes on a specific table

sp_helpindex 'Sales.DBCustomers'

---------------------------------------
-- 1 -- Monitor index usage # with that we can save storage and improve write performance
---------------------------------------

select * from sys.indexes
select * from sys.tables

select
tbl.name as TableName,
idx.name as IndexName,
idx.type_desc as IndexType,
idx.is_primary_key as IsPrimaryKey,
idx.is_unique As IsUnique,
idx.is_disabled As IsDisabled,
s.user_seeks as UserSeeks,
s.user_scans as UserScans,
s.user_lookups as UserLookups,
s.user_updates as UserUpdates,
coalesce(s.last_user_seek, s.last_user_scan) as LastUpdate
From sys.indexes idx join sys.tables tbl on idx.object_id = tbl.object_id
left join sys.dm_db_index_usage_stats s on s.object_id = idx.object_id and s.index_id = idx.index_id
order by tbl.name, idx.name

select * from sys.dm_db_index_usage_stats

---------------------------------------
-- 2 -- Monitor missing Indexes
---------------------------------------

use AdventureWorksDW2025
select 
	fs.SalesOrderNumber,
	dp.EnglishProductName,
	dp.Color
FROM FactInternetSales fs
inner join DimProduct dp
on fs.ProductKey = dp.ProductKey
WHERE dp.Color = 'Black'
and fs.OrderDateKey BETWEEN 20101229 and 202101231

select * from sys.dm_db_missing_index_details

---------------------------------------
-- 3 -- Monitor Duplicate Indexes 
---------------------------------------

use SalesDB
SELECT
    tbl.name AS TableName,
    col.name AS IndexColumn,
    idx.name AS IndexName,
    idx.type_desc AS IndexType,
	count(*) over (partition by tbl.name , col.name) ColumnCount
FROM sys.indexes idx
JOIN sys.tables tbl ON idx.object_id = tbl.object_id
JOIN sys.index_columns ic ON idx.object_id = ic.object_id AND idx.index_id = ic.index_id
JOIN sys.columns col ON ic.object_id = col.object_id AND ic.column_id = col.column_id
ORDER BY tbl.name, col.name

---------------------------------------
-- 4 -- Update Statistics
---------------------------------------

SELECT
    SCHEMA_NAME(t.schema_id) AS SchemaName,
    t.name AS TableName,
    s.name AS StatisticName,
    sp.last_updated AS LastUpdate,
    DATEDIFF(day, sp.last_updated, GETDATE()) AS LastUpdateDay,
    sp.rows AS 'Rows',
    sp.modification_counter AS ModificationsSinceLastUpdate
FROM sys.stats AS s
JOIN sys.tables t
ON s.object_id = t.object_id
CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) AS sp
ORDER BY
    sp.modification_counter DESC;

update statistics sales.dbcustomers _WA_Sys_00000005_367C1819
update statistics sales.products

exec sp_updatestats

---------------------------------------
-- 5 -- Monitor Fragmentations
---------------------------------------

select 
t.name as TableName,
idx.name as IndexName,
s.avg_fragmentation_in_percent,
s.page_count
from sys.dm_db_index_physical_stats(DB_id(),NULL,NULL,NULL,'Limited') as s
inner join sys.tables t on s.object_id = t.object_id
inner join sys.indexes idx on idx.object_id = s.object_id and idx.index_id = s.index_id
 order by s.avg_fragmentation_in_percent desc

 alter index PK__sysdiagr__C2B05B61F2024598 on sysdiagrams rebuild
 alter index UK_principal_name on sysdiagrams reorganize