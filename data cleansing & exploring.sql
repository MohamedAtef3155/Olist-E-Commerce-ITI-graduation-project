/* exploratory data analysis */

--orders table
delete from [dbo].[olist_orders_dataset]
where [olist_orders_dataset].order_status = 'delivered'
and [olist_orders_dataset].order_delivered_customer_date is null
-----------------------------------------------------------------------------------------------------
delete from [dbo].[olist_orders_dataset]
--select *
--from [dbo].[olist_orders_dataset]
where [olist_orders_dataset].order_status = 'shipped'
and [olist_orders_dataset].order_delivered_carrier_date is null
-----------------------------------------------------------------------------------------------------
--- checking for duplicated order_id
select *
from
(
	select  [olist_orders_dataset].order_id , count(order_id) count_order_id
	from [olist_orders_dataset]
	group by order_id
)temp
where count_order_id > 1
-----------------------------------------------------------------------------------------------------
--- checking for duplicated customer_id
select *
from
(
	select  [olist_orders_dataset].customer_id , count(customer_id) count_customer_id
	from [olist_orders_dataset]
	group by customer_id
)temp
where temp.count_customer_id > 1
-----------------------------------------------------------------------------------------------------
-- customers table

select [olist_customers_dataset].customer_id , count(customer_id) count_customer_id
from [dbo].[olist_customers_dataset]
group by customer_id
having count(customer_id) > 1
-----------------------------------------------------------------------------------------------------
----checking for customers' locations
--- inserting into geolocation's table zip codes that were in customers'table and were n't found in geolocation's table
insert into [dbo].[olist_geolocation_dataset] ([olist_geolocation_dataset].geolocation_zip_code_prefix ,
												[olist_geolocation_dataset].geolocation_city,
												[olist_geolocation_dataset].geolocation_state 
												)
select distinct [olist_customers_dataset].customer_zip_code_prefix ,[olist_customers_dataset].customer_city,
               [olist_customers_dataset].customer_state
from [dbo].[olist_customers_dataset]
where customer_zip_code_prefix not in (
			select [olist_geolocation_dataset].geolocation_zip_code_prefix
			from [dbo].[olist_geolocation_dataset] 
-----------------------------------------------------------------------------------------------------
--- inserting into geolocation's table zip codes that were in sellers'table and were n't found in geolocation's table

insert into olist_geolocation_dataset ([geolocation_zip_code_prefix] ,[geolocation_city] , [geolocation_state])
select distinct [dbo].[olist_sellers_dataset].seller_zip_code_prefix , [olist_sellers_dataset].seller_city,
                [olist_sellers_dataset].seller_state
from [dbo].[olist_sellers_dataset] 
where [olist_sellers_dataset].seller_zip_code_prefix not in (
						select  [dbo].[olist_geolocation_dataset].geolocation_zip_code_prefix
						from  [dbo].[olist_geolocation_dataset])
						
-----------------------------------------------------------------------------------------------------
--- Delete Duplicated Reviews From order_review
with deleted_duplicates as
(
Select * from (
select * , row_number() over (partition by (review_id) order by (review_id)) as RN
from olist_order_reviews_dataset) as temp
) 
delete from deleted_duplicates
Where RN > 1 
-----------------------------------------------------------------------------------------------------
--- delete all duplicate zip code from geolocation table                                                                 )
select  [dbo].[olist_geolocation_dataset].*
from  [dbo].[olist_geolocation_dataset]
where [olist_geolocation_dataset].geolocation_zip_code_prefix = 1037
-----------------------------------------------------------------------------------------------------
-----is every single order has only one distinct product?
select [olist_order_items_dataset].order_id ,
       count(distinct [olist_order_items_dataset].product_id)
from [dbo].[olist_order_items_dataset]
group by order_id
having count(distinct [olist_order_items_dataset].product_id) > 1
-----------------------------------------------------------------------------------------------------
------update customer_cities that aren't exist in [olist_geolocation_dataset] table and have same zip_codes_prefix that are exists in  [olist_geolocation_dataset] table with geolocation_city 
update [dbo].[olist_customers_dataset] 
set customer_city = (
						select distinct loc.geolocation_city 
						from [olist_geolocation_dataset] as loc
						where loc.geolocation_zip_code_prefix in (
							select distinct [olist_customers_dataset].customer_zip_code_prefix 
							from [dbo].[olist_customers_dataset] 
							where [olist_customers_dataset].customer_city not in (
																					select  [dbo].[olist_geolocation_dataset].geolocation_city
																					from  [dbo].[olist_geolocation_dataset]
																				)
																			           )
                     and [olist_customers_dataset].customer_zip_code_prefix = loc.geolocation_zip_code_prefix
					
                     )   
where exists(
             select distinct loc.geolocation_zip_code_prefix 
						from [olist_geolocation_dataset] as loc
						where loc.geolocation_zip_code_prefix in (
							select distinct [olist_customers_dataset].customer_zip_code_prefix 
							from [dbo].[olist_customers_dataset] 
							where [olist_customers_dataset].customer_city not in (
																					select  [dbo].[olist_geolocation_dataset].geolocation_city
																					from  [dbo].[olist_geolocation_dataset]
																				)
																			           )
                     and [olist_customers_dataset].customer_zip_code_prefix = loc.geolocation_zip_code_prefix
					 )

-----------------------------------------------------------------------------------------------------
------update seller_cities that aren't exist in [olist_geolocation_dataset] table and have same zip_codes_prefix that are exists in  [olist_geolocation_dataset] table with geolocation_city 
update [dbo].[olist_sellers_dataset] 
set seller_city = (
						select distinct max(distinct loc.geolocation_city)---to filter returned cities with only one city
						from [olist_geolocation_dataset] as loc
						where loc.geolocation_zip_code_prefix in (
							select distinct [olist_sellers_dataset].seller_zip_code_prefix 
							from [dbo].[olist_sellers_dataset] 
							where [olist_sellers_dataset].seller_city not in (
																					select  [dbo].[olist_geolocation_dataset].geolocation_city
																					from  [dbo].[olist_geolocation_dataset]
																				)
																			           )
                     and [olist_sellers_dataset].seller_zip_code_prefix = loc.geolocation_zip_code_prefix
					 group by geolocation_zip_code_prefix
                     )   
where exists(
             select distinct max(distinct loc.geolocation_city)
						from [olist_geolocation_dataset] as loc
						where loc.geolocation_zip_code_prefix in (
							select distinct [olist_sellers_dataset].seller_zip_code_prefix 
							from [dbo].[olist_sellers_dataset] 
							where [olist_sellers_dataset].seller_city not in (
																					select  [dbo].[olist_geolocation_dataset].geolocation_city
																					from  [dbo].[olist_geolocation_dataset]
																				)
																			           )
                     and [olist_sellers_dataset].seller_zip_code_prefix = loc.geolocation_zip_code_prefix
					 group by geolocation_zip_code_prefix
					 )
-----------------------------------------------------------------------------------------------------
---- deleting orders with more than one distinct  product
delete from [dbo].[olist_order_items_dataset]
where [order_id] in (
						select [order_id] 
						from [dbo].[olist_order_items_dataset]
						group by [order_id]
						having count(distinct[product_id]) > 1
					)
---------------------------------------------------------------------------------------
--add count_of_products col to [olist_order_items_dataset] table (not applied yet it has effect on other tables)

--alter table [dbo].[olist_order_items_dataset] add count_of_products int 


--update [dbo].[olist_order_items_dataset] 
--set [olist_order_items_dataset].[count_of_products] = (
--							select count([product_id]) count_prod
--							from [dbo].[olist_order_items_dataset] orders
--							where orders.order_id = [olist_order_items_dataset].order_id
--							group by [order_id]
--                         )

--select * 
--from [olist_order_items_dataset]
--order by [count_of_products] desc

--delete from [olist_order_items_dataset]
--where order_item_id > 1

--alter table [olist_order_items_dataset]
--drop column order_item_id
---------------------------------------------------------------------------------------------
select * 
from (
		select * , row_number () over (partition by order_id order by  order_id) rn
		from [olist_order_items_dataset]
			  ) temp
where temp.rn = 1


---creating table for payment types 
USE [E_commerce]
GO

/****** Object:  Table [dbo].[payment_types]    Script Date: 12/23/2022 6:05:27 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[payment_types](
	[id] [int] NOT NULL,
	[payment_type] [nvarchar](50) NULL,
 CONSTRAINT [PK_payment_types] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
USE [E_commerce]
GO
---- insert values in [payment_types] table
INSERT INTO [dbo].[payment_types]
           ([id]
           ,[payment_type])
     VALUES
           (1
           ,'credit_card'),(2,'voucher') , (3,'boleto') , (4,'debit_card') , (5,'not_defined')
GO

select *
from [dbo].[payment_types]


--- cleansing of [dbo].[olist_order_payments_dataset] table			


update [dbo].[olist_order_payments_dataset]
set [payment_type_id] = case when [payment_type_id] = 'credit_card' then 1 
                          when [payment_type_id] = 'voucher' then 2
						  when [payment_type_id] = 'boleto' then 3
						  when [payment_type_id] = 'debit_card' then 4
						  when [payment_type_id] = 'not_defined' then 5 end

select *
from [olist_order_payments_dataset]
where  [payment_type_id] not in (1,2,3,4,5)
-----------------------------------------------------------------------------------------------------
--- referntial integrity between [payment_types] and [olist_order_payments_dataset]
alter table [olist_order_payments_dataset] 
add constraint fk_payment_types foreign key ([payment_type])
references [dbo].[payment_types] (id)
-----------------------------------------------------------------------------------------------------
-- Cleaning Geo_location Table
Insert Into [dbo].[Geo_Loc]

select geolocation_zip_code_prefix,geolocation_lat,geolocation_lng,geolocation_city,geolocation_state from (
                select * , row_number() over (partition by (geolocation_zip_code_prefix) order by(geolocation_zip_code_prefix)) as RN
                From olist_geolocation_dataset) as Temp
where rn = 1		
-------------------------------------------------------------------------------------------------------------
                                       --**Data Warehouse**--
---------------------------------------------------------------------------------------------------------
-- We joined Tables (orders,Order_items) Using SSIS
-- It can also be Done Using this query
Select orders.order_id,order_items.order_item_id,orders.order_status,order_items.product_id,orders.customer_id,
       Order_Items.seller_id,
	   orders.order_purchase_timestamp,orders.order_approved_at,orders.order_delivered_carrier_date,
	   order_items.shipping_limit_date,orders.order_delivered_customer_date,Orders.order_estimated_delivery_date,
	   Order_Items.price,Order_Items.freight_value
Into
From Order_Items left outer join Orders
On orders.order_id=Order_Items.order_id
------------------------------------------------------------------------------------------------------------------------
-- Building Customers_Dim Using SSIS (by using This query)
Select Customers.*,Geo_Loc.geolocation_city, Geo_Loc.geolocation_state 
From Customers
Left Outer Join Geo_Loc 
On Customers.customer_zip_code_prefix=Geo_Loc.geolocation_zip_code_prefix 
----------------------------------------------------------------------------------------------------------------------------
-- Building Sellers Dim Using SSIS (by using This Query)
Select Sellers.*,Geo_Loc.geolocation_city, Geo_Loc.geolocation_state 
From Sellers
Left Outer Join Geo_Loc 
On Sellers.seller_zip_code_prefix=Geo_Loc.geolocation_zip_code_prefix
----------------------------------------------------------------------------------------------------------------------------
-- Building Products Dim (SQL)
Select products.*
Into olist_DW.dbo.Products_Dim
From Products
----------------------------------------------------------------------------------------------------------------------------
-- Building Review Dim (SQL)
Select Order_Review.*
Into olist_DW.dbo.Review_Dim
From Order_Review
----------------------------------------------------------------------------------------------------------------------------
-- Buidling Payments_Dim (SQL)
Select Order_Payments.order_id,Order_Payments.payment_sequential,Payment_Types.payment_type,Order_Payments.payment_installments,
       Order_Payments.payment_value
Into olist_dw.dbo.Payments_Dim
From Order_Payments,Payment_Types
Where Order_Payments.payment_type_id=Payment_Types.id
----------------------------------------------------------------------------------------------------------------------------
-- Adding Custmer_zip_code,Seller_ZipCode To Fact_table
Select Fact_Orders.*,Customers_Dim.customer_zip_code_prefix,Sellers_Dim.seller_zip_code_prefix
into Order_details
From Fact_Orders Left outer join Customers_Dim on Fact_Orders.customer_id=Customers_Dim.customer_id
Left outer join Sellers_Dim On Fact_Orders.seller_id = Sellers_Dim.seller_id
Order by order_id
-------------------------------------------------------------------------------------------------------
-- Creating Status Table And updating Status in Fact_table
Select Distinct order_status 
From Order_details

Update Order_details Set order_status = 1 Where Order_status ='delivered'
Update Order_details Set order_status = 2 Where Order_status ='approved'
Update Order_details Set order_status = 3 Where Order_status ='shipped'
Update Order_details Set order_status = 4 Where Order_status ='invoiced'
Update Order_details Set order_status = 5 Where Order_status ='processing'
Update Order_details Set order_status = 6 Where Order_status ='canceled'
Update Order_details Set order_status = 7 Where Order_status ='unavailable'
-------------------------------------------------------------------------------------------------------
--Updating payment_type Values (triming spaces)
Update Order_details Set payment_type = 'credit_card' Where payment_type like '%credit%'
Update Order_details Set payment_type = 'voucher' Where payment_type like '%voucher%'
Update Order_details Set payment_type = 'boleto' Where payment_type like '%boleto%'
Update Order_details Set payment_type = 'debit_card' Where payment_type like '%debit%'
Update Order_details Set payment_type = 'not_defined' Where payment_type is Null
-------------------------------------------------------------------------------------------------------
--Updating Payment_type Value (after creating Table For Id And type)
Update Order_details Set payment_type = 1 Where payment_type ='credit_card'
Update Order_details Set payment_type = 2 Where payment_type ='voucher'
Update Order_details Set payment_type = 3 Where payment_type ='boleto'
Update Order_details Set payment_type = 4 Where payment_type ='debit_card'
Update Order_details Set payment_type = 5 Where payment_type ='not_defined'
-------------------------------------------------------------------------------------------------------