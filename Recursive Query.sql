--CTE level
with cte as
(--Anchor query 
select
	EmployeeID,
	FirstName,
	managerid,
	1 as level
from sales.employees 
where ManagerID is null
union all
--recursive query
select
	e.employeeid,
	e.firstname,
	e.managerid,
	level + 1
from sales.employees e
inner	 join cte on e.managerid= cte.EmployeeID
)

--Main query
select *
from cte