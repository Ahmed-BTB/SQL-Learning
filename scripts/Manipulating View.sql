if object_id('sales_Per_Month' , 'V') is not null
	Drop View Sales_Per_Month;
go
create View Sales_Per_Month as(
	select 
		month(orderdate) Month,
		sum(sales) Sales
	from sales.orders
	group by month(orderdate)
)

select 
	month,
	Sales,
	sum(sales) over (order by month) as running_total
from Sales_Per_Month

