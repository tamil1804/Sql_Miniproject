-- part 1 Shipping 
use shipping;
alter table orders_dimen add column orderdate date;
update orders_dimen set orderdate = str_to_date(order_date,'%d-%m-%Y');
select * from orders_dimen;
alter table orders_dimen drop column order_date;
alter table orders_dimen rename column orderdate to order_date; 

alter table shipping_dimen add column shipdate date;
set sql_safe_updates=0;
update shipping_dimen set shipdate = str_to_date(ship_date,'%d-%m-%Y');
select * from shipping_dimen;
alter table shipping_dimen drop column Ship_Date;
alter table shipping_dimen rename column shipdate to ship_date; 

-- 1) Find the top 3 customers who have the maximum number of orders
select * from orders_dimen;
with table2 as(
with table1 as(
select mf.cust_id , count(mf.ord_id) as total_orders
from orders_dimen od join market_fact mf
on od.ord_id = mf.ord_id
join cust_dimen cd
on cd.cust_id = mf.cust_id
group by mf.cust_id
order by total_orders desc)
select *, dense_rank() over(order by total_orders desc) as ranking from table1)
select cust_id,total_orders
from table2 
where ranking <= 3;

-- 2) Create a new column DaysTakenForDelivery that contains the date difference between Order_Date and Ship_Date.
select od.order_id, order_date,ship_date, datediff(ship_date,order_date) as days_taken_for_delivery
from orders_dimen od join shipping_dimen sd
on od.order_id = sd.order_id
order by days_taken_for_delivery desc;


-- 3) Find the customer whose order took the maximum time to get delivered.
with table1 as(
select customer_name,datediff(ship_date,order_date) as days_taken_for_delivery, max(datediff(ship_date,order_date)) over() as max_delivery
from orders_dimen od join shipping_dimen sd
on od.order_id = sd.order_id
join market_fact mf 
on mf.ord_id = od.ord_id
join cust_dimen cd
on cd.cust_id = mf.cust_id
order by days_taken_for_delivery desc)
select distinct customer_name,days_taken_for_delivery from table1
where days_taken_for_delivery = max_delivery;

-- 4) Retrieve total sales made by each product from the data (use Windows function)
select distinct prod_id,round(sum(sales) over(partition by prod_id),3) as total_Sales 
from market_fact
order by total_sales desc;

-- 5) : Retrieve the total profit made from each product from the data (use windows function)
with table1 as(
select distinct prod_id, round(sum(profit) over(partition by prod_id),3) as total_profit 
from market_fact)
select * from table1 
where total_profit > 0;

-- 6) Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011
select count(distinct cust_id) as cust_count, year(order_date) as year, monthname(order_date) as month
from market_fact mf join orders_dimen od
on od.ord_id = mf.ord_id
where year(order_date)=2011 and Cust_id = any(
select distinct cust_id from market_fact mf join orders_dimen od on mf.ord_id = od.ord_id where year(order_date)=2011 and month(order_date)=01)
group by year(order_date),monthname(order_date)
order by month asc;

-- Part 2 Restaurant
use restaurants;
-- 1)  We need to find out the total visits to all restaurants under all alcohol categories available.
select count(distinct name) as restaurants_with_alcohol,count(distinct up.userid) as distinct_user_count, count(up.userid) as total_visit
from geoplaces2 gp join rating_final rf
on gp.placeid = rf.placeid
join userprofile up
on up.userID = rf.userID
where alcohol not like '%no%';

-- 2) Let's find out the average rating according to alcohol and price so that we can understand the rating in respective price categories as well.
select * from rating_final;
select distinct alcohol,price,round(avg(rating) over(partition by alcohol,price),2) as avg_rating 
from geoplaces2 gp join rating_final rf
on gp.placeID = rf.placeID;

-- 3) Let’s write a query to quantify that what are the parking availability as well in different alcohol categories along with the total number of restaurants.
select * from geoplaces2;
select * from chefmozparking;
select parking_lot,alcohol, count(name) as restaurant_count
from geoplaces2 gp join chefmozparking cp
on gp.placeid = cp.placeid
group by alcohol,parking_lot;

-- 4) Also take out the percentage of different cuisine in each alcohol type.
with table1 as(
select alcohol, count(distinct Rcuisine) as count_cuisine, 
(select count(distinct rcuisine) from geoplaces2 gp join chefmozcuisine cc on gp.placeID = cc.placeID) as total_cuisine
from geoplaces2 gp join chefmozcuisine cc
on gp.placeID = cc.placeID
group by alcohol)
select *, round((count_cuisine/total_cuisine)*100,2) as percent from table1;

-- 5) let’s take out the average rating of each state.
select * from geoplaces2;
select * from rating_final;
select avg(rating) as avg_rating, state
from rating_final rf join geoplaces2 gp 
on rf.placeid = gp.placeid
group by state
order by avg_rating desc;

-- 6) ' Tamaulipas' Is the lowest average rated state. Quantify the reason why it is the lowest rated 
-- by providing the summary on the basis of State, alcohol, and Cuisine.
select state, alcohol,Rcuisine,avg(rating) as avg_rating
from geoplaces2 gp join chefmozcuisine cc
on gp.placeid = cc.placeID
join rating_final rf
on rf.placeid = gp.placeID
where state like '%tamaulipas%'
group by state,alcohol,rcuisine;

-- 7) Find the average weight, food rating, and service rating of the customers who have visited KFC and tried Mexican or Italian types of cuisine, 
-- and also their budget level is low.
select  name ,avg(weight) over(partition by name) avg_weight,Rcuisine ,food_rating, service_rating, budget
from rating_final rf join userprofile up
on rf.userID = up.userID
join geoplaces2 gp
on gp.placeID = rf.placeID
join chefmozcuisine cc
on cc.placeID = gp.placeID
where budget = 'low' and Rcuisine in('mexican','italian');


-- part 3 Triggers

create table student_details(
student_id int,
student_name varchar(15),
mail_id varchar(30),
phone_number varchar(15));

create table student_details_backup(
student_id int,
student_name varchar(15),
mail_id varchar(30),
phone_number varchar(15));

delimiter //
create trigger delete_backup
before delete on student_details
for each row 
begin
insert into student_details_backup values(old.student_id,old.student_name,old.mail_id,old.phone_number);
end //
delimiter ;

insert into student_details values(1,'Abrar','abrarz7115@gmail.com',null);
insert into student_details values(2,'Kutty','kutty7115@gmail.com',8428952192);
select * from student_details;
select * from student_details_backup;
delete from student_details where student_id=1;