Show table schema
\d+ retail;

Show first 10 rows
SELECT * FROM retail limit 10;

Check # of records
select count(*) from retail;

number of clients (e.g. unique client ID)
select count(distinct(customer_id)) from retail;

invoice date range (e.g. max/min dates)
select max(invoice_date) as max, min(invoice_date) as min from retail;

number of SKU/merchants (e.g. unique stock code)
select count(distinct(stock_code)) from retail;

Calculate average invoice amount excluding invoices with a negative amount (e.g. canceled orders have negative amount)
select avg(sum) from (select invoice_no, sum(quantity) as sum from retail group by invoice_no having sum(quantity)>0) as average;

Calculate total revenue (e.g. sum of unit_price * quantity)
select sum(quantity * unit_price) as sum from retail;

Calculate total revenue by YYYYMM
select ((cast(extract(year from invoice_date) as int)* 100) +  cast(extract(month from invoice_date) as int)) as yyyymm, sum(quantity * unit_price) as sum from retail group by yyyymm order by yyyymm;
EOF >
