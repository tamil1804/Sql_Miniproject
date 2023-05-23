use supply_chain;
-- Part A
-- 1) Import the csv file to a table in the database. 
-- completed

-- 2) Remove the column 'Player Profile' from the table.
select * from icc_test_batting_figures;
alter table icc_test_batting_figures drop column `Player Profile`;

-- 3) Extract the country name and player names from the given data and store it in separate columns for further usage.
alter table icc_test_batting_figures add column player_name varchar(25);
update icc_test_batting_figures set player_name = substring_index(player,'(',1);

alter table icc_test_batting_figures add column country_name varchar(15);
update icc_test_batting_figures set country_name = trim(leading '(' from trim(trailing ')' from substr(player,instr(player,'('))));
update icc_test_batting_figures set country_name = substr(country_name,instr(country_name,'/')+1);

-- 4) From the column 'Span' extract the start_year and end_year and store them in separate columns for further usage.
alter table icc_test_batting_figures add column start_year date;
alter table icc_test_batting_figures modify start_year int;

desc icc_test_batting_figures;

update icc_test_batting_figures set start_year = substring_index(span,'-',1);

alter table icc_test_batting_figures add column end_year int;
update icc_test_batting_figures set end_year = trim(leading '-' from substr(span,instr(span,'-')));

-- 5) The column 'HS' has the highest score scored by the player so far in any given match. 
-- The column also has details if the player had completed the match in a NOT OUT status. 
-- Extract the data and store the highest runs and the NOT OUT status in different columns.
select * from icc_test_batting_figures;
alter table icc_test_batting_figures add column highest_runs int;
update icc_test_batting_figures set highest_runs =  trim(trailing '*' from hs); 

alter table icc_test_batting_figures add column wicket_status char(1) default null;
update icc_test_batting_figures set wicket_status = substr(hs,instr(hs,'*'));
select * from icc_test_batting_figures;

-- 6) Using the data given, considering the players who were active in the year of 2019, 
-- create a set of batting order of best 6 players using the selection criteria of those who have a good average score across all matches for India.
select * from icc_test_batting_figures;
with table1 as(
select *
from icc_test_batting_figures
where country_name = 'india')
select player_name,avg,country_name from table1 
where start_year = 2019 or end_year=2019
order by avg desc
limit 6;

-- 7) Using the data given, considering the players who were active in the year of 2019, 
-- create a set of batting order of best 6 players using the selection criteria of those who have the highest number of 100s across all matches for India.
select * from icc_test_batting_figures;
with table1 as(
select *
from icc_test_batting_figures
where country_name = 'india')
select player_name, `100` as 100s_scored,country_name from table1 
where start_year = 2019 or end_year = 2019
order by `100` desc
limit 6;

-- 8) Using the data given, considering the players who were active in the year of 2019, 
-- create a set of batting order of best 6 players using 2 selection criteria of your own for India.
with table1 as(
select *
from icc_test_batting_figures
where country_name = 'india')
select player_name, `100` as 100s_scored, `50` as 50s_scored from table1 
where start_year = 2019 or end_year= 2019 and `50` >= 10 and `100` > 1;

-- 9) Create a View named ‘Batting_Order_GoodAvgScorers_SA’ using the data given, considering the players who were active in the year of 2019, 
-- create a set of batting order of best 6 players using the selection criteria of those who have a good average score across all matches for South Africa.
create or replace view Batting_Order_GoodAvgScorers_SA as(
with table2 as(
with table1 as (
select * 
from icc_test_batting_figures
where start_year = 2019 or end_year=2019
order by avg desc)
select *,dense_rank() over(order by avg desc) as ranking from table1 where country_name = 'sa')
select player_name, avg, country_name from table2 where ranking <= 6);

select * from Batting_Order_GoodAvgScorers_SA;

-- 10) Create a View named ‘Batting_Order_HighestCenturyScorers_SA’ Using the data given, considering the players who were active in the year of 2019, 
-- create a set of batting order of best 6 players using the selection criteria of those who have highest number of 100s across all matches for South Africa.
create or replace view Batting_Order_HighestCenturyScorers_SA as(
with table2 as(
with table1 as (
select * 
from icc_test_batting_figures
where start_year = 2019 or end_year=2019
order by avg desc)
select *,dense_rank() over(order by `100` desc) as ranking from table1 where country_name = 'sa' order by ranking)
select player_name,`100`,country_name from table2 where ranking <= 6);

select * from Batting_Order_HighestCenturyScorers_SA;

-- 11) Using the data given, Give the number of player_played for each country.
select country_name,count(distinct player_name) as player_count 
from icc_test_batting_figures
group by country_name;

-- 12) Using the data given, Give the number of player_played for Asian and Non-Asian continent
select distinct country_name from icc_test_batting_figures;

-- Part B
-- 1) Company sells the product at different discounted rates. Refer actual product price in product table and selling price in the order item table. 
-- Write a query to find out total amount saved in each order then display the orders from highest to lowest amount saved. 
select productname ,p.unitprice as actual_price , oi.unitprice as selling_price, (p.unitprice-oi.unitprice) as amount_saved 
from product p join orderitem oi
on p.id = oi.id 
having amount_saved > 0;

-- 2) Mr. Kavin want to become a supplier. He got the database of "Richard's Supply" for reference. Help him to pick: 
-- a. List few products that he should choose based on demand.
-- b. Who will be the competitors for him for the products suggested in above questions.
with table1 as(
select productname, sum(quantity) as demand
from orderitem oi join product p
on p.id = oi.id
group by productname
order by demand desc)
select *, dense_rank() over(order by demand desc) as ranking from table1;

-- 3) Create a combined list to display customers and suppliers details considering the following criteria 
-- ●	Both customer and supplier belong to the same country
-- ●	Customer who does not have supplier in their country
-- ●	Supplier who does not have customer in their country
select * from customer;
select * from supplier;
select c.FirstName,c.country as customer_country, s.CompanyName,s.country as supplier_country
from customer c join supplier s 
on c.id = s.id
where c.country in (
select country from supplier);

select c.FirstName,c.country as customer_country
from customer c 
where c.country not in (
select country from supplier) ;
select s.companyName,s.country as supplier_country
from supplier s 
where s.country not in (
select country from customer) ;

-- 4) Every supplier supplies specific products to the customers. Create a view of suppliers and total sales made by their products and 
-- write a query on this view to find out top 2 suppliers (using windows function) in each country by total sales done by the products.
 create or replace view details as(
 select supplierid ,ProductName ,country,(oi.unitprice*quantity) as total_Sales
 from product p join orderitem oi
 on p.id = oi.id
 join supplier s
 on s.id = p.id);
 with table1 as(
select *, dense_rank() over(partition by country order by total_sales) as ranking
from details)
select * from table1 where ranking <= 2;

-- 5) Find out for which products, UK is dependent on other countries for the supply. List the countries which are supplying these products in the same list.
select productid, productname , s.country
from product p join orderitem oi
on p.id = oi.id
join customer c 
on c.id = oi.id
join supplier s
on s.id = p.id 
where s.country<>'uk';

-- 6) Create two tables as ‘customer’ and ‘customer_backup’ as follow - 
-- ‘customer’ table attributes -
-- Id, FirstName,LastName,Phone
-- ‘customer_backup’ table attributes - 
-- Id, FirstName,LastName,Phone
-- Create a trigger in such a way that It should insert the details into the  ‘customer_backup’ table when you delete the record from the ‘customer’ table automatically.
create table cust(
id int,
firstname varchar(15),
lastname varchar(15),
phone varchar(15));

create table cust_backup(
id int,
firstname varchar(15),
lastname varchar(15),
phone varchar(15));

delimiter //
create trigger insert_backup
after delete on cust
for each row
begin
insert into cust_backup values(old.id,old.firstname,old.lastname,old.phone);
end //
delimiter ;

insert into cust values(1,'Mohammed','Abrar',8428952192);
insert into cust values(2,'Zayeem','Ahmed',9344307123);

set sql_safe_updates=0;

select * from cust;
select * from cust_backup;

delete from cust where id =1;