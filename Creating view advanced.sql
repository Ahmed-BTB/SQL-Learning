if object_id('sales.info_orders', 'V') is not null
	drop view sales.info_orders
go
create view sales.info_orders as(
select
	o.orderid,
	o.orderdate,
	p.product,
	p.Category,
	COALESCE(c.FirstName, 'unknown') + ' ' + COALESCE(C.LastName, '') AS CustomerName,
	c.country Customercountry,
	COALESCE(e.FirstName, 'unknown') + ' ' + COALESCE(e.LastName, '') AS EmployeeName,
	e.department,
	o.sales,
	o.Quantity
from sales.orders o
left join sales.Customers c on c.CustomerID = o.CustomerID
left join sales.Products p on p.productid = o.ProductID
left join sales.Employees e on o.SalesPersonID = e.EmployeeId
where c.Country != 'USA'
)
select * from sales.info_orders
select * from sales.orders
select  * from sales.customers
select * from sales.Employees