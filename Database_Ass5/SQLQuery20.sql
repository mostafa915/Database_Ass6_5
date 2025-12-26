--question 1
create function calc (@quantity  dec , @price dec , @discount dec)
returns dec
begin 
return (@quantity * @price - @discount)
end
declare @total_amount dec = (
select sum(dbo.calc(oi.quantity , oi.list_price , discount)) as total_amount
from sales.customers c join sales.orders o
on c.customer_id  = 1 and o.customer_id = 1
left join sales.order_items oi
on oi.order_id = o.order_id
)
print @total_amount ;
if @total_amount  > 5000 
	print 'customer 1 is VIP'
else 
	print 'customer 1 is Regular'

-- question 2

declare @num int = 1500;
declare @count int = (
select COUNT(*) 
from production.products p
where list_price > @num
)
print 'Number of Products is cost more than ' + cast(@num as varchar(10)) + ' is ' + cast(@count as varchar(10)) + ' Product';

--question 3

declare @staff_id int = 2;
declare @Year_of_order int = 2023;
declare @no_of_sales int = (
select COUNT(*) 
from sales.staffs s join sales.orders o
on s.staff_id = @staff_id and o.staff_id = @staff_id
where YEAR(o.order_date) = @Year_of_order
)

print 'Staff Number ' + cast(@staff_id as varchar(10)) + ' Has ' + cast(@no_of_sales as varchar(10)) + ' In ' + cast(@Year_of_order as varchar(10));

--question 4

select 
@@SERVERNAME as Server_Name,
@@VERSION as version_sql_server,
@@ROWCOUNT as row_affected

-- question 5

declare @quantity int = (
select quantity 
from production.stocks 
where product_id  =1 and store_id = 1
)
if @quantity > 20 
	print 'Well Stocked';
else if @quantity between 10 and 20
	print 'Moderate Stock'
else if @quantity < 10
	print 'Low Stock - reorder needed'

-- question 6
declare @batchNumber int = 1
while exists (
select 1
from production.stocks 
where quantity < 5
)
begin 
	update top (3) production.stocks
	set quantity = quantity + 10
	where quantity < 5;
	print 'batch' + cast(@batchNumber as varchar) + ' completed 3 product update'
	set	@batchNumber  = @batchNumber + 1
end

-- question 7
create or alter proc check_Product_price (@product_id int)
as
begin 
declare @product_price dec;
--declare @mess varchar;
	SET @product_price  = 
	(
	select list_price from production.products
	where product_id= @product_id 
	)
	if @product_price < 300
		print 'Budget'
	else if @product_price between 300 and 800
		print 'Mid_range'
	else if @product_price between 801 and 2000
		print 'Premium'
	else if @product_price > 2000
		begin 
			print 'Luxury'
		end

end
exec check_Product_price 2100

-- question 8
if exists (select  1  from sales.customers where customer_id = 5)
	begin 
		select count(*) as No_Orders  from sales.customers c join sales.orders o on c.customer_id = 5 and o.customer_id = 5
	end
else 
	print 'Not exists'

--question 9
create  or alter function cost_calc(@price dec)
returns dec
begin
declare @cost dec;
	if @price > 100
	begin
		set @cost = 0
	end
	else if @price between 50 and 99
	begin
		set @cost = 5.99
	end
	else if @price < 50
	begin
		set @cost = 12.99 
	end
	--print @cost
	return @cost
end
declare @cost dec = (select dbo.cost_calc(p.list_price) from production.products as p where product_id = 2)
if @cost > 100
	print 'Free Shipping'
else if @cost between 50 and 99
	print 'Reduced Shipping ' + cast(@cost as varchar)
else if @cost < 50
print 'Standard Shipping ' + cast(@cost as varchar)

-- question 10
create or alter function GetProductByPriceRange(@min_num dec , @max_num dec)
returns @product table (
Product_id int,
Product_name varchar(255),
catagory_name varchar(255),
brand_name varchar(255)
)
as 
begin
insert into @product
select p.product_id,p.Product_name,c.category_id,b.brand_id
from production.products p join production.categories c
on p.category_id = c.category_id
join production.brands b
on b.brand_id = p.brand_id
where p.list_price between @min_num and @max_num;
return;
end
-- question 11
CREATE OR ALTER FUNCTION GetCustomerYearlySummary (@cus_id INT)
RETURNS @cus_table TABLE
(
    year_order INT,
    total_order INT,
    total_spent DECIMAL(10, 2),
    avg_order_value DECIMAL(10, 2)
)
AS
BEGIN

    INSERT INTO @cus_table
    SELECT
        YEAR(o.order_date) AS year_order,
        COUNT(DISTINCT o.order_id) AS total_order,
        SUM((oi.list_price * oi.quantity) - oi.discount) AS total_spent,
        AVG((oi.list_price * oi.quantity) - oi.discount) AS avg_order_value
    FROM sales.customers c
    JOIN sales.orders o
        ON c.customer_id = o.customer_id
    JOIN sales.order_items oi
        ON oi.order_id = o.order_id
    WHERE c.customer_id = @cus_id
    GROUP BY YEAR(o.order_date);

    RETURN;
END;


-- question 12

CREATE OR ALTER FUNCTION CalculateBulkDiscount(@quantity int)
returns varchar
as 
begin
declare @discountPrecent int
		if @quantity < 3
			begin
				set @discountPrecent = 0
			end
		else if @quantity between 3 and 5
			begin
				set @discountPrecent = 5
			end
		else if @quantity between 6 and 9
			begin
				set @discountPrecent = 10
			end
		else if @quantity >= 10
			begin 
				set @discountPrecent = 15
			end
return (cast(@discountPrecent as varchar) + '% Dicount');
end

-- question 13

CREATE OR ALTER PROC sp_GetCustomerOrderHistory (
@cus_id int,
@start_date date = null,
@end_date date = null
)
as
begin
	select c.customer_id , c.first_name + ' ' + c.last_name as 'Name' , o.order_id , o.order_date ,
	SUM((quantity * list_price) - discount) as Order_Total_Price
	from sales.customers c join sales.orders o
	on c.customer_id = o.customer_id
	join sales.order_items oi
	on oi.order_id = o.order_id
	where c.customer_id = @cus_id 
	and (@start_date is null or o.order_date >= @start_date)
	and (@end_date is null or o.order_date <= @end_date)
	group by c.customer_id,first_name,c.last_name,o.order_id,o.order_date
end

exec sp_GetCustomerOrderHistory 2 , '2024-05-25' , '2024-06-26'

--QUESTION 14

CREATE  OR ALTER PROC sp_RestockProduct 
(
@stroe_id int,
@product_id int,
@restock_quantity int,
@old_quantity int output,
@new_quantity int output
)
as
begin
	set @old_quantity = (
		select SUM(quantity)
		from sales.stores s join sales.orders o
		on o.store_id = s.store_id
		join sales.order_items oi
		on oi.order_id = o.order_id
		where s.store_id = @stroe_id and oi.product_id = @product_id
	)
	set @new_quantity = @old_quantity + @restock_quantity  
end
--question 17

SELECT s.product_id , quantity FROM production.stocks s
where quantity > 0
union 
SELECT s.product_id, quantity FROM production.stocks s
WHERE quantity = 0 or quantity is null
union 
SELECT p.product_id , quantity FROM production.products p
join production.stocks s
on  s.product_id != p.product_id

--question 18

SELECT c.customer_id , c.first_name + ' ' + c.last_name as Full_name , order_id  , YEAR(order_date) FROM sales.customers c
join sales.orders o
on o.customer_id = c.customer_id
where YEAR(order_date) = 2017
INTERSECT 
SELECT c.customer_id , c.first_name + ' ' + c.last_name as Full_name , order_id  , YEAR(order_date) FROM sales.customers c
join sales.orders o
on o.customer_id = c.customer_id
where YEAR(order_date) = 2018

--QUESTION 19

SELECT OI.product_id  , P.product_name  FROM sales.stores S
JOIN sales.orders O
ON S.store_id = O.store_id
JOIN sales.order_items OI
ON OI.order_id  = OI.order_id
JOIN production.products P
ON P.product_id = OI.product_id
WHERE S.store_id = 1 
INTERSECT
SELECT OI.product_id  , P.product_name  FROM sales.stores S
JOIN sales.orders O
ON S.store_id = O.store_id
JOIN sales.order_items OI
ON OI.order_id  = OI.order_id
JOIN production.products P
ON P.product_id = OI.product_id
WHERE S.store_id = 2
INTERSECT
SELECT OI.product_id  , P.product_name FROM sales.stores S
JOIN sales.orders O
ON S.store_id = O.store_id
JOIN sales.order_items OI
ON OI.order_id  = OI.order_id
JOIN production.products P
ON P.product_id = OI.product_id
WHERE S.store_id = 3


SELECT OI.product_id  , P.product_name , S.store_id FROM sales.stores S
JOIN sales.orders O
ON S.store_id = O.store_id
JOIN sales.order_items OI
ON OI.order_id  = OI.order_id
JOIN production.products P
ON P.product_id = OI.product_id
WHERE S.store_id = 1
EXCEPT
SELECT OI.product_id  , P.product_name , S.store_id FROM sales.stores S
JOIN sales.orders O
ON S.store_id = O.store_id
JOIN sales.order_items OI
ON OI.order_id  = OI.order_id
JOIN production.products P
ON P.product_id = OI.product_id
WHERE S.store_id = 2


SELECT OI.product_id  , P.product_name , S.store_id FROM sales.stores S
JOIN sales.orders O
ON S.store_id = O.store_id
JOIN sales.order_items OI
ON OI.order_id  = OI.order_id
JOIN production.products P
ON P.product_id = OI.product_id
WHERE S.store_id = 1 
INTERSECT
SELECT OI.product_id  , P.product_name , S.store_id FROM sales.stores S
JOIN sales.orders O
ON S.store_id = O.store_id
JOIN sales.order_items OI
ON OI.order_id  = OI.order_id
JOIN production.products P
ON P.product_id = OI.product_id
WHERE S.store_id = 2
INTERSECT
SELECT OI.product_id  , P.product_name , S.store_id FROM sales.stores S
JOIN sales.orders O
ON S.store_id = O.store_id
JOIN sales.order_items OI
ON OI.order_id  = OI.order_id
JOIN production.products P
ON P.product_id = OI.product_id
WHERE S.store_id = 3
UNION
SELECT OI.product_id  , P.product_name , S.store_id FROM sales.stores S
JOIN sales.orders O
ON S.store_id = O.store_id
JOIN sales.order_items OI
ON OI.order_id  = OI.order_id
JOIN production.products P
ON P.product_id = OI.product_id
WHERE S.store_id = 1
EXCEPT
SELECT OI.product_id  , P.product_name , S.store_id FROM sales.stores S
JOIN sales.orders O
ON S.store_id = O.store_id
JOIN sales.order_items OI
ON OI.order_id  = OI.order_id
JOIN production.products P
ON P.product_id = OI.product_id
WHERE S.store_id = 2


--20
SELECT * FROM sales.customers S
JOIN sales.orders O
ON O.customer_id = S.customer_id
WHERE YEAR(O.order_date) = 2022
EXCEPT
SELECT * FROM sales.customers S
JOIN sales.orders O
ON O.customer_id = S.customer_id
WHERE YEAR(O.order_date) = 2023
UNION
SELECT * FROM sales.customers S
JOIN sales.orders O
ON O.customer_id = S.customer_id
WHERE YEAR(O.order_date) = 2023
EXCEPT
SELECT * FROM sales.customers S
JOIN sales.orders O
ON O.customer_id = S.customer_id
WHERE YEAR(O.order_date) = 2022
UNION
SELECT * FROM sales.customers S
JOIN sales.orders O
ON O.customer_id = S.customer_id
WHERE YEAR(O.order_date) = 2022
UNION
SELECT * FROM sales.customers S
JOIN sales.orders O
ON O.customer_id = S.customer_id
WHERE YEAR(O.order_date) = 2023

--QUESTION 15

CREATE PROCEDURE sp_ProcessNewOrder
    @customer_id INT,
    @product_id INT,
    @quantity INT,
    @store_id INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO sales.orders (customer_id, order_date, store_id)
        VALUES (@customer_id, GETDATE(), @store_id);

        DECLARE @order_id INT;
        SET @order_id = SCOPE_IDENTITY();

        INSERT INTO sales.order_items (order_id, product_id, quantity)
        VALUES (@order_id, @product_id, @quantity);

        UPDATE production.stocks
        SET quantity = quantity - @quantity
        WHERE store_id = @store_id
          AND product_id = @product_id;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT 'Error occurred while processing the order';
    END CATCH
END;

-- question 16

WITH RevenuePerYear AS (
    SELECT
        p.brand,
        YEAR(o.order_date) AS order_year,
        SUM(oi.quantity * oi.list_price) AS total_revenue
    FROM sales.orders o
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    JOIN production.products p ON oi.product_id = p.product_id
    WHERE YEAR(o.order_date) IN (2016, 2017, 2018)
    GROUP BY p.brand, YEAR(o.order_date)
),
PivotRevenue AS (
    SELECT
        brand,
        MAX(CASE WHEN order_year = 2016 THEN total_revenue END) AS Revenue_2016,
        MAX(CASE WHEN order_year = 2017 THEN total_revenue END) AS Revenue_2017,
        MAX(CASE WHEN order_year = 2018 THEN total_revenue END) AS Revenue_2018
    FROM RevenuePerYear
    GROUP BY brand
)
SELECT
    brand,
    Revenue_2016,
    Revenue_2017,
    Revenue_2018,
    CASE 
        WHEN Revenue_2016 IS NOT NULL AND Revenue_2017 IS NOT NULL 
        THEN ROUND((Revenue_2017 - Revenue_2016) * 100.0 / Revenue_2016, 2)
    END AS Growth_17_16,
    CASE 
        WHEN Revenue_2017 IS NOT NULL AND Revenue_2018 IS NOT NULL 
        THEN ROUND((Revenue_2018 - Revenue_2017) * 100.0 / Revenue_2017, 2)
    END AS Growth_18_17
FROM PivotRevenue
ORDER BY brand;


-- من اول السؤال 15 لغاية الاخر اتلخبت وعملتهم من ASSINGMENT 5