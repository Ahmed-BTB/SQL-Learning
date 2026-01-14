-- Heap
Select * 
INTO FactInternerSales_HP
From FactInternetSales

-- RowStore
select *
into FactInternetSales_RS
From FactInternetSales

create clustered index idx_FactInternetSales_RS_PK
on Factinternetsales_rs (SalesOrderNumber, SalesOrderLineNumber)

-- ColumnStore
select *
into FactInternetSales_CS
From FactInternetSales

create clustered columnstore index idx_FactInternetSales_CS_PK
on Factinternetsales_CS