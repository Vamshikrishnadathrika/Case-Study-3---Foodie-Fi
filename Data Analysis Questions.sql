--1.How many customers has Foodie-Fi ever had?
SELECT Count(Distinct(customer_id)) [no of customers]
from subscriptions


--2.What is the monthly distribution of trial plan start_date values for our dataset 
-- use the start of the month as the group by value
SELECT datepart(month,start_date) num, datename(month,start_date) month, count(*)
From subscriptions
Where plan_id = 0
Group By datename(month,start_date), datepart(month,start_date)
Order By num



-- 3.What plan start_date values occur after the year 2020 for our dataset? 
--Show the breakdown by count of events for each plan_name
SELECT plan_name, count(*) num
From subscriptions s
left Join plans p
On s.plan_id = p.plan_id
Where start_date > '2020-12-31'
Group By plan_name



--4.What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
Select Round(cast((cast(chruned as float)*100/ cast(total as float)) as float),2) percentage_chruned
From
(Select count(distinct customer_id) total,
(select count(distinct customer_id) from subscriptions where plan_id=4) as chruned
From subscriptions) a



-- 5.How many customers have churned straight after their initial free trial
-- what percentage is this rounded to the nearest whole number?
Drop table If Exists #temp1
Select customer_id, plan_id, 
lag(plan_id,1) Over(partition by customer_id order by start_date) as previous_plan
into #temp1
From subscriptions
Select count(*) num_chruned
From #temp1
Where plan_id = 4 and previous_plan = 0

Select Round(cast((cast(free as float)*100/ cast(total as float)) as float),2) percentage_chruned_after_trail
From
(Select (select count(*) from #temp1 where previous_plan = 0 And plan_id = 4) free,
  count(*)  total
From #temp1
where  plan_id = 4) a



-- 6.What is the number and percentage of customer plans after their initial free trial?
Select a.plan_id, p.plan_name, num,
Round(cast((cast(num as float)*100/ cast(total as float)) as float),2) percentage
From
(select plan_id, count(*) num, (Select 1000) total
From #temp1
Where previous_plan = 0
Group By plan_id) a
Left Join plans p
On a.plan_id = p.plan_id
Order By percentage desc



-- 7.What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
Select plan_id, num,
Round(cast((cast(num as float)*100/ cast(1000 as float)) as float),2) percentage
From
(Select plan_id, count(*) num
From
(SELECT customer_id, plan_id, start_date
FROM subscriptions s1
WHERE  start_date = (select max(start_date) 
                     from subscriptions s2 
					 Where s1.customer_id=s2.customer_id and start_date < '2020-12-31')) a
Group By plan_id) b
Order By plan_id



-- 8.How many customers have upgraded to an annual plan in 2020?

select count(distinct customer_id) as num_of_customers
from subscriptions
Where plan_id = 3 and start_date < '2021-01-01'



-- 9.How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
Select avg(datediff(day,astart_date,start_date)) as avg_days
From
(Select *, Lag(start_date) Over(Partition by customer_id order by plan_id) as astart_date
From subscriptions
where plan_id in (0,3)) a
Where astart_date is not null



-- 10.Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
Select asmonth, concat(asmonth*30+1,'-',(asmonth+1)*30,'days') range, count(*) number
from 
(Select *, floor(days/30) asmonth
From
(Select datediff(day,astart_date,start_date) days
From
(Select *, Lag(start_date) Over(Partition by customer_id order by plan_id) as astart_date
From subscriptions
where plan_id in (0,3)) a
Where astart_date is not null) b) c
group by concat(asmonth*30+1,'-',(asmonth+1)*30,'days'), asmonth



-- 11.How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
Select count(*) as downgraded
from #temp1
where plan_id = 1 and previous_plan = 2
