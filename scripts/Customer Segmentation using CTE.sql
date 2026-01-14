--STep 1 TotalSales
with cte_customer_sales as(
select
	customerid,
	sum(sales) Total_Sales
from sales.orders
group by customerid
)
--Step 2 Last order
,cte_last_order as
(
select 
customerid,
max(orderdate) as lastorder
from sales.orders
group by customerid
)
--Step 3 Rank
,CTE_Rank_Customers as 
(
select 
	CUSTOMERID,
	rank() over (order by Total_Sales desc) Rank
from cte_customer_sales
)
--Step 4  customers segmentation based on their total sales 
,CTE_Customers_segments as
(
select 
customerid,
case when Total_Sales > 100 then 'High'
	 when Total_Sales > 50 then 'Medium'
	 Else 'Low' 
end Segment
from cte_customer_sales
)
-- main query
select
	c.customerid,
	c.firstname,
	c.lastname,
	cts.Total_Sales,
	lastorder,
	Cro.Rank ,
	ccs.segment
from sales.customers c
left join cte_customer_sales cts on c.CustomerID = cts.CustomerID
left join cte_last_order clo on c.CustomerID = clo.CUSTOMERID
left join CTE_Rank_Customers as CRO on c.customerid = cro.customerid
left join CTE_Customers_segments ccs on c.CustomerID = ccs.CustomerID 
order by total_sales desc