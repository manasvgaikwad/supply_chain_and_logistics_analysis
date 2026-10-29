create database if not exists dataco;

use dataco;

select count(*) from staging_orders;

-- creating tables
-- customers
create table customers (
    customer_id int primary key,
    customer_segment varchar(50),
    customer_city varchar(100),
    customer_state varchar(50),
    customer_country varchar(50)
);

insert into customers
select distinct customer_id, customer_segment, customer_city, customer_state, customer_country
from staging_orders;

-- products
create table products (
    product_card_id int primary key,
    product_name varchar(255),
    product_price decimal(10,2),
    category_id int,
    category_name varchar(100),
    department_id int,
    department_name varchar(100)
);

insert into products
select distinct product_card_id, product_name, product_price, category_id, category_name, department_id, department_name
from staging_orders;

-- orders
create table orders (
    order_id int primary key,
    customer_id int,
    order_date datetime,
    order_status varchar(50),
    payment_type varchar(50),
    market varchar(50),
    order_region varchar(100),
    order_country varchar(100),
    foreign key (customer_id) references customers(customer_id)
);

insert into orders
select distinct order_id, order_customer_id, order_date, order_status, type, market, order_region, order_country
from staging_orders;

-- shipping
create table shipping (
    order_id int primary key,
    shipping_date datetime,
    shipping_mode varchar(50),
    days_for_shipping_real int,
    days_for_shipment_scheduled int,
    shipping_delay int,
    late_shipment boolean,
    delivery_status varchar(50),
    foreign key (order_id) references orders(order_id)
);

insert into shipping
select distinct order_id, shipping_date, shipping_mode, days_for_shipping_real, days_for_shipment_scheduled, shipping_delay, late_shipment, delivery_status
from staging_orders;

alter table staging_orders
rename column `shipping_date_(dateorders)` to shipping_date;

alter table staging_orders
rename column `order_date_(dateorders)` to order_date_original;

alter table staging_orders
rename column `days_for_shipping_(real)` to days_for_shipping_real;

alter table staging_orders
rename column `days_for_shipment_(scheduled)` to days_for_shipment_scheduled;

create table order_items (
    order_item_id int primary key,
    order_id int,
    product_card_id int,
    quantity int,
    item_price decimal(10,2),
    discount decimal(10,2),
    discount_rate decimal(5,2),
    sales decimal(10,2),
    profit decimal(10,2),
    profit_margin decimal(10,4),
    is_loss boolean,
    foreign key (order_id) references orders(order_id),
    foreign key (product_card_id) references products(product_card_id)
);

insert into order_items
select order_item_id, order_id, product_card_id, order_item_quantity, order_item_product_price, order_item_discount, order_item_discount_rate, sales, order_profit_per_order, profit_margin, is_loss
from staging_orders;

-- Data quality check
-- Row counts
select count(*) from shipping;
select count(*) from products;
select count(*) from orders;
select count(*) from customers;
select count(*) from order_items;

-- Nulls
-- order_items
select
    sum(order_item_id is null) as null_order_item_id,
    sum(order_id is null) as null_order_id,
    sum(product_card_id is null) as null_product_card_id,
    sum(quantity is null) as null_quantity,
    sum(item_price is null) as null_item_price,
    sum(discount is null) as null_discount,
    sum(discount_rate is null) as null_discount_rate,
    sum(sales is null) as null_sales,
    sum(profit is null) as null_profit,
    sum(profit_margin is null) as null_profit_margin,
    sum(is_loss is null) as null_is_loss
from order_items;

-- orders
select
    sum(order_id is null) as null_order_id,
    sum(customer_id is null) as null_customer_id,
    sum(order_date is null) as null_order_date,
    sum(order_status is null) as null_order_status,
    sum(payment_type is null) as null_payment_type,
    sum(market is null) as null_market,
    sum(order_region is null) as null_order_region,
    sum(order_country is null) as null_order_country
from orders;

-- shipping
select
    sum(order_id is null) as null_order_id,
    sum(shipping_date is null) as null_shipping_date,
    sum(shipping_mode is null) as null_shipping_mode,
    sum(days_for_shipping_real is null) as null_days_real,
    sum(days_for_shipment_scheduled is null) as null_days_scheduled,
    sum(shipping_delay is null) as null_shipping_delay,
    sum(late_shipment is null) as null_late_shipment,
    sum(delivery_status is null) as null_delivery_status
from shipping;

-- customers
select
    sum(customer_id is null) as null_customer_id,
    sum(customer_segment is null) as null_segment,
    sum(customer_city is null) as null_city,
    sum(customer_state is null) as null_state,
    sum(customer_country is null) as null_country
from customers;

-- products
select
    sum(product_card_id is null) as null_product_card_id,
    sum(product_name is null) as null_product_name,
    sum(product_price is null) as null_product_price,
    sum(category_id is null) as null_category_id,
    sum(category_name is null) as null_category_name,
    sum(department_id is null) as null_department_id,
    sum(department_name is null) as null_department_name
from products;

-- Duplicates
select order_item_id, count(*)
from order_items
group by order_item_id
having count(*) > 1;

select customer_id, count(*)
from customers
group by customer_id
having count(*) > 1;

select order_id, count(*)
from orders
group by order_id
having count(*) > 1;

select product_card_id, count(*)
from products
group by product_card_id
having count(*) > 1;

select order_id, count(*)
from shipping
group by order_id
having count(*) > 1;

select order_id, shipping_date, shipping_mode, days_for_shipping_real, days_for_shipment_scheduled, count(*)
from shipping
group by order_id, shipping_date, shipping_mode, days_for_shipping_real, days_for_shipment_scheduled
having count(*) > 1;

-- Overall Performance
-- 1. What percentage of all orders are delivered late
select
count(*) as total_orders,
sum(late_shipment) as late_orders,
round(sum(late_shipment)/count(*) * 100,2) as late_delivered_order_percentage
from shipping;

-- 2. What percentage of all orders are loss-making?
select
count(*) as total_orders,
sum(is_loss) as loss_making_orders,
round(sum(is_loss) / count(*) * 100,2) as loss_making_orders_percentage
from order_items;

-- 3. What do sales and profit per order look like overall?
select
    count(*) as total_orders,
    round(sum(sales), 2) as total_sales,
    round(avg(sales), 2) as avg_sales,
    min(sales) as min_sales,
    max(sales) as max_sales,
    round(sum(profit), 2) as total_profit,
    round(avg(profit), 2) as avg_profit,
    min(profit) as min_profit,
    max(profit) as max_profit
from order_items;

-- Delivery Performance
-- 4. Which shipping mode has the highest late shipment rate?
select
shipping_mode,
round(avg(late_shipment) * 100,2) as late_shipment_rate
from shipping
group by shipping_mode
order by late_shipment_rate desc;

-- 5. Which order regions have the worst late shipment rate?
select
o.order_region,
round(avg(s.late_shipment) * 100,2) as late_shipment_rate
from orders o
join shipping s on o.order_id = s.order_id
group by o.order_region
order by late_shipment_rate desc;

-- 6. Which markets have the worst late shipment rate?
select
o.market,
round(avg(s.late_shipment) * 100,2) as late_shipment_rate
from orders o
join shipping s on o.order_id = s.order_id
group by o.market
order by late_shipment_rate desc;

-- Product profitability
-- 7. Which categories generate the most profit?
select
p.category_name,
sum(o.profit) as total_profit
from products p
join order_items o on o.product_card_id = p.product_card_id
group by p.category_name
order by total_profit desc;

-- 8. Which categories lose the most money?
select
p.category_name,
sum(o.profit) as total_loss
from products p
join order_items o on o.product_card_id = p.product_card_id
where o.profit < 0
group by p.category_name
order by total_loss asc;

-- 9. Which categories have the highest share of loss-making orders?
select
    p.category_name,
    count(*) as total,
    sum(o.profit < 0) as loss_lines,
    round(sum(o.profit < 0) * 100.0 / count(*), 2) as loss_share_pct
from products p
join order_items o on o.product_card_id = p.product_card_id
group by p.category_name
order by loss_share_pct desc;

-- Customers and departments
-- 10. Which customer segment brings in the most sales and profit?
select
c.customer_segment,
sum(oi.sales) as total_sales,
sum(oi.profit) as total_profit
from customers c
join orders o on c.customer_id = o.customer_id
join order_items oi on o.order_id = oi.order_id
group by c.customer_segment
order by total_sales desc, total_profit desc; 

-- 11. Which departments are the most and least profitable?
select
p.department_name,
count(*) as total_orders,
sum(o.sales) as total_sales,
sum(o.profit) as total_profit,
round(sum(o.profit) * 100.0 / sum(o.sales),2) as profit_margin_percentage
from products p
join order_items o on o.product_card_id = p.product_card_id
group by p.department_name
order by total_profit desc;

-- Trends
-- 12. How have sales and profit changed month by month and year by year?
select
month(o.order_date) as month,
year(o.order_date) as year,
sum(oi.profit) as total_profit,
sum(oi.sales) as total_sales
from orders o
join order_items oi on o.order_id = oi.order_id
group by month, year
order by year,month;

select
year(o.order_date) as year,
sum(oi.profit) as total_profit,
sum(oi.sales) as total_sales
from orders o
join order_items oi on o.order_id = oi.order_id
group by year
order by year;

-- 13. Does the late shipment rate change over time?
select
year(o.order_date) as year,
round(avg(s.late_shipment) * 100,2) as late_shipment_rate
from orders o
join shipping s on o.order_id = s.order_id
group by year
order by year;

select
month(o.order_date) as month,
year(o.order_date) as year,
round(avg(s.late_shipment) * 100,2) as late_shipment_rate
from orders o
join shipping s on o.order_id = s.order_id
group by year, month
order by year, month;

-- Payments and order status
-- 14. Which payment types are used most?
select
payment_type,
count(*) as total_payments
from orders
group by payment_type
order by total_payments desc;

-- 15. What share of orders are completed, canceled, or suspected fraud?
select
    order_status,
    count(*) as total_orders,
    round(count(*) * 100.0 / sum(count(*)) over (), 2) as share_pct
from orders
group by order_status
order by total_orders desc;

-- Connecting the findings
-- 16. Do late shipments have a lower profit margin than on-time ones?
select
case 
when  s.late_shipment = 1 then 'Late Shipment' else 'On time'
end as shipment_status,
round(sum(oi.profit) * 100.0 / sum(oi.sales), 2) as profit_margin
from shipping s
join order_items oi on oi.order_id = s.order_id
group by shipment_status;

-- 17. Do higher discounts lead to more loss-making orders?
select
case
when discount_rate < 0.05 then '0-5%'
when discount_rate < 0.10 then '5-10%'
when discount_rate < 0.15 then '10-15%'
when discount_rate < 0.20 then '15-20%'
else '20%+'
end as discount_group,
round(sum(profit < 0) * 100.0 / count(*), 2) as loss_rate_percentage,
count(*) as total_orders,
sum(profit < 0) as loss_lines
from order_items
group by discount_group
order by min(discount_rate);

--  month-over-month growth
with cte as (
select
month(o.order_date) as month,
year(o.order_date) as year,
sum(oi.profit) as total_profit,
sum(oi.sales) as total_sales
from orders o
join order_items oi on o.order_id = oi.order_id
group by month, year
)
select
month,
year,
total_sales,
lag(total_sales) over(order by year, month) as previous_month_total_sales,
total_profit,
lag(total_profit) over(order by year, month) as previous_month_total_profit,
round((total_sales - lag(total_sales) over (order by year, month)) * 100.0 / lag(total_sales) over (order by year, month), 2) as sales_growth_pct,
round((total_profit - lag(total_profit) over (order by year, month)) * 100.0 / lag(total_profit) over (order by year, month), 2) as profit_growth_pct
from cte
order by year, month;


-- category rank within market
with cte as (
select
o.market,
p.category_name,
round(sum(oi.profit), 2) as total_profit
from orders o
join order_items oi on o.order_id = oi.order_id
join products p on oi.product_card_id = p.product_card_id
group by o.market, p.category_name
)
select
market,
category_name,
total_profit,
rank() over (partition by market order by total_profit desc) as profit_rank
from cte
order by market, profit_rank;

--  running total
with cte as (
select
month(o.order_date) as month,
year(o.order_date) as year,
sum(oi.profit) as total_profit,
sum(oi.sales) as total_sales
from orders o
join order_items oi on o.order_id = oi.order_id
group by month, year
)
select
month,
year,
total_profit,
total_sales,
sum(total_sales) over(partition by year order by month) as running_total
from cte
order by year, month;

--  top customer per region
with cte as (
select
o.order_region as region,
o.customer_id as customer,
sum(oi.sales) as total_sales
from orders o
join order_items oi on oi.order_id = o.order_id
group by o.order_region,o.customer_id
),
cte1 as (
select *,
row_number() over(partition by region order by total_sales desc) as row_rank
from cte
)
select *
from cte1
where row_rank = 1
order by total_sales desc;

-- CREATING VIEWS
create or replace view vw_sales_summary as
select
    oi.order_item_id,
    o.order_id,
    o.order_date,
    year(o.order_date) as order_year,
    month(o.order_date) as order_month,
    o.market,
    o.order_region,
    o.order_country,
    o.order_status,
    o.payment_type,
    c.customer_id,
    c.customer_segment,
    p.category_name,
    p.department_name,
    oi.quantity,
    oi.discount_rate,
    oi.sales,
    oi.profit,
    oi.is_loss
from order_items oi
join orders o on oi.order_id = o.order_id
join customers c on o.customer_id = c.customer_id
join products p on oi.product_card_id = p.product_card_id;

create or replace view vw_delivery_performance as
select
    s.order_id,
    o.order_date,
    year(o.order_date) as order_year,
    month(o.order_date) as order_month,
    o.market,
    o.order_region,
    s.shipping_mode,
    s.days_for_shipment_scheduled,
    s.days_for_shipping_real,
    s.shipping_delay,
    s.late_shipment,
    s.delivery_status
from shipping s
join orders o on s.order_id = o.order_id;

create or replace view vw_product_profit as
select
    p.department_name,
    p.category_name,
    count(*) as order_lines,
    round(sum(oi.sales), 2) as total_sales,
    round(sum(oi.profit), 2) as total_profit,
    round(sum(oi.profit) * 100.0 / sum(oi.sales), 2) as profit_margin_pct,
    sum(oi.profit < 0) as loss_lines,
    round(sum(oi.profit < 0) * 100.0 / count(*), 2) as loss_share_pct
from order_items oi
join products p on oi.product_card_id = p.product_card_id
group by p.department_name, p.category_name;
create or replace view vw_monthly_trends as
select
    year(o.order_date) as order_year,
    month(o.order_date) as order_month,
    count(*) as total_orders,
    round(sum(t.sales), 2) as total_sales,
    round(sum(t.profit), 2) as total_profit,
    round(sum(t.profit) * 100.0 / sum(t.sales), 2) as profit_margin_pct,
    round(avg(s.late_shipment) * 100, 2) as late_shipment_pct
from orders o
join (
    select order_id, sum(sales) as sales, sum(profit) as profit
    from order_items
    group by order_id
) t on t.order_id = o.order_id
join shipping s on s.order_id = o.order_id
group by year(o.order_date), month(o.order_date);

select count(*) from vw_sales_summary;
select count(*) from vw_delivery_performance;
select count(*) from vw_product_profit;
select count(*) from vw_monthly_trends;
