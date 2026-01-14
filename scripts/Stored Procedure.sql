
ALTER procedure Scores @country NVARCHAR(50)
As
BEGIN
	BEGIN TRY
		--Declaring variables
		DECLARE @Totalcustomers int, @AvgScore Float;

		-- ======================
		-- Step 1 : Preparing & Clean up data
		-- ======================

		if  exists (select 1 from sales.customers where score is null and country = @country)
			BEGIN
			PRINT 'Updating NULL Scores to 0 ';
			update sales.customers
			set
				score = 0 
				where score is null and country = @country
			END

		Else
			BEGIN
			PRINT 'No nulls found'
			END	

		-- ======================
		-- Step 2 : Generating Summary Reports
		-- ======================
		-- Calculate Total Customers And Average Score for Specific Country 
		select 
			@AvgScore = AVG(score),
			@Totalcustomers = count(*)
		from sales.Customers
		where country = @country
		print 'The average score from ' + @country + ':' + cast(@AvgScore as Nvarchar(50));
		print 'The Total customers from ' + @country + ':' + CAST(@TotalCustomers as Nvarchar(50));

		-- Calculate total number of orders and total sales for specific country
		select
		count(orderid) Total_Orders,
		sum(sales) Total_Sales
		from sales.orders o 
		join sales.customers c on o.CustomerID = c.CustomerID
		where c.country = @country;
	END try
	-- ======================
	-- Error Handling
	-- ======================
	BEGIN CATCH
		PRINT 'An error occured.';
		PRINT 'Error Message: ' + Error_message();
		PRINT 'Error Number: ' + Cast(ERROR_NUMBER() as nvarchar);
		PRINT 'Error Line : ' + cast(error_line() as nvarchar);
		PRINT 'Error Procedure : ' + Error_procedure();
	END CATCH
END
go
exec scores @country = 'USA'