
-- Step 1: Create Table
DROP TABLE IF EXISTS SALES.employeelogs
create table sales.EmployeeLogs (
	LogID INT IDENTITY (1,1) PRIMARY KEY,
	EmployeeID int,
	LogMessage VARCHAR(255),
	LogDate DATE
)
-- Step 2: Create trigger on employees table
CREATE TRIGGER trg_AfterInsertEmployee ON Sales.Employees
AFTER INSERT 
AS
BEGIN 
	INSERT INTO Sales.EmployeeLogs (EmployeeID, LogMessage, LogDate)
	SELECT
	Employeeid,
	'New Employee Added ' + cast(EmployeeID as varchar),
	GETDATE()
	FROM INSERTED
END
-- Step 3: Insert New Data Into Employees
select * from sales.EmployeeLogs
insert into Sales.Employees 
values
(6,'Mary','Doe','HR','1988-01-12','F',80000,3)