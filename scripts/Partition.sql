
-- Query lists all existing partition Functions
select
name,
function_id,
type,
type_desc,
boundary_value_on_right 
FROM sys.partition_functions

----------------------------------------------
-- Step 1: Create a Partition function
----------------------------------------------

create partition function PartitionByYear (DATE)
AS RANGE LEFT FOR VALUES ('2023-12-31', '2024-12-31', '2025-12-31')

----------------------------------------------
-- Step 2: Create Filegroups
----------------------------------------------
ALTER DATABASE SalesDB add FILEGROUP FG_2023; 
ALTER DATABASE SalesDB add FILEGROUP FG_2024;
ALTER DATABASE SalesDB add FILEGROUP FG_2025; 
ALTER DATABASE SalesDB add FILEGROUP FG_2026;

select * from sys.filegroups where type = 'FG'

----------------------------------------------
-- Step 3 : add .ndf file to each data group
----------------------------------------------
ALTER DATABASE SalesDB ADD FILE 
(
	NAME = P_2023, --Logical Name
	FILENAME = 'D:\New folder\MSSQL17.SQLEXPRESS\MSSQL\DATA\P_2023.ndf'
) TO FILEGROUP FG_2023

ALTER DATABASE SalesDB ADD FILE 
(
	NAME = P_2024, --Logical Name
	FILENAME = 'D:\New folder\MSSQL17.SQLEXPRESS\MSSQL\DATA\P_2024.ndf'
) TO FILEGROUP FG_2024

ALTER DATABASE SalesDB ADD FILE 
(
	NAME = P_2025, --Logical Name
	FILENAME = 'D:\New folder\MSSQL17.SQLEXPRESS\MSSQL\DATA\P_2025.ndf'
) TO FILEGROUP FG_2025

ALTER DATABASE SalesDB ADD FILE 
(
	NAME = P_2026, --Logical Name
	FILENAME = 'D:\New folder\MSSQL17.SQLEXPRESS\MSSQL\DATA\P_2026.ndf'
) TO FILEGROUP FG_2026

--Viewing the filegroup name, logical name, the physical path and the size
SELECT 
	fg.name as FileGroupName,
	mf.name as LogicalFileName,
	mf.physical_name as PhysicalFilePath,
	mf.size / 128 as SizeINMB
FROM 
	sys.filegroups fg
JOIN 
	sys.master_files mf on fg.data_space_id = mf.data_space_id
where
	mf.database_id = DB_id('SalesDB')

----------------------------------------------
-- Step 4: Create PartitionScheme
----------------------------------------------
CREATE PARTITION SCHEME SchemePartitionByYear
AS PARTITION PartitionByYear
-- Be careful with the order (Sort the filegroups according to the result of the function's partition)
TO (FG_2023,FG_2024,FG_2025,FG_2026)

select 
ps.name as PartitionSchemeName,
pf.name as PartitionFunctionName,
ds.destination_id as PartitionNumber,
fg.name as FileGroupName
from sys.partition_schemes ps
join sys.partition_functions pf on ps.function_id = pf.function_id
join sys.destination_data_spaces ds on ps.data_space_id = ds.partition_scheme_id
join sys.filegroups fg on  ds.data_space_id = fg.data_space_id

----------------------------------------------
-- Step 5: Create Partitioned Table
----------------------------------------------
Create Table sales.orders_partitioned 
(
	Orders INT,
	Orderdate DATE,
	Sales INT
) on SchemePartitionByYear (Orderdate)

----------------------------------------------
-- Step 6: Insert Data Into the Partitioned Table
----------------------------------------------
	INSERT INTO	Sales.orders_partitioned values (1, '2023-05-15',100)
	INSERT INTO	Sales.orders_partitioned values (4, '2024-05-15',50)
	INSERT INTO	Sales.orders_partitioned values (3, '2025-05-15',100)
	INSERT INTO	Sales.orders_partitioned values (10, '2026-05-15',100)

	select * from sales.orders_partitioned

-- Viewing if our records are stored in the correct spaces
select 
p.partition_number as PartitionNumber,
f.name As PartitionFileGroup,
p.rows as NumberOfrows
from sys.partitions p
inner join sys.destination_data_spaces dds on p.partition_number = dds.destination_id
inner join sys.filegroups f on f.data_space_id = dds.destination_id
where object_name(p.object_id) = 'Orders_partitioned'

-- creating the same table with no partitions

select *
into sales.Orders_Nopartion
from sales.orders_partitioned

select * from sales.orders_partitioned where orderdate = '2026-05-15'
select * from sales.Orders_Nopartion where orderdate = '2026-05-15'
-- when checking the execution plan We have reduced the number of rows read

