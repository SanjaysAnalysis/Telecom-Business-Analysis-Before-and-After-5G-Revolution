select * from fact_atliqo_metrics

select * from fact_market_share

select * from fact_plan_revenue

/*
update fact_atliqo_metrics 
set active_users_lakhs = active_users_lakhs * 100000

update fact_atliqo_metrics
set AtliQo_revenue_crores = AtliQo_revenue_crores * 10000000

update fact_atliqo_metrics
set unsubscribed_users_lakhs = unsubscribed_users_lakhs * 100000

update fact_plan_revenue
set plan_revenue_crores = plan_revenue_crores * 10000000
*/

-- Q1) Calculate the key metrics like total revenue, Average revenue per user (ARPU), Monthly Active users (MAU), Total Unsubscribed users (TUnU)

select
'Total Revenue' as Key_Metric, concat(sum(AtliQo_revenue_crores), ' cr') as Value
from fact_atliqo_metrics
Union
select
'ARPU',  cast(round(avg(arpu),2) As Varchar)
from fact_atliqo_metrics
Union
select
'MAU', concat(round(avg(active_users_lakhs),2),' lakh')
from fact_atliqo_metrics
Union
Select
'TUnU', concat(sum(unsubscribed_users_lakhs),' lakh')
from fact_atliqo_metrics

/* Output
Key_Metric		Value
ARPU			200.74 
TAU				13.48 lakh
Total Revenue	3187.36 cr
TUnU			125.9 lakh
*/

-- Q2) Monthly Revenue Before and After 5G

select DATENAME(MONTH, f.date) as month, 
sum(f.AtliQo_revenue_crores) as [Monthly_Revenue (cr)], d.[before/after_5g]
from fact_atliqo_metrics f left join dim_date d on f.date = d.date
group by DATENAME(MONTH, f.date), d.[before/after_5g]

/*
month	Monthly_Revenue (cr)	before/after_5g
August		419.08					After 5G
July		412.76					After 5G
June		357.56					After 5G
September	400.26					After 5G
April		407.19					Before 5G
February	425.69					Before 5G
January		354.37					Before 5G
March		410.45					Before 5G
*/

-- Q3) Top 5 Cities by Revenue

select Top 5 c.city_name, sum(a.atliqo_revenue_crores) as [City_Revenue (cr)]
from fact_atliqo_metrics a 
left join dim_cities c on a.city_code = c.city_code
group by c.city_name
order by sum(a.atliqo_revenue_crores) desc

/*
city_name	City_Revenue (cr)
Mumbai			489.55
Delhi			387.2
Kolkata			384.39
Bangalore		338.61
Chennai			296.37
*/

-- Q4) Bottom 5 Cities by Revenue

select Top 5 c.city_name as City_name, sum(a.atliqo_revenue_crores) as [City_Revenue (cr)]
from fact_atliqo_metrics a 
left join dim_cities c on a.city_code = c.city_code
group by c.city_name
order by sum(a.atliqo_revenue_crores) asc

/*
City_name	City_Revenue (cr)
Raipur			31.54
Gurgaon			54.65
Chandigarh		61.19
Coimbatore		91.39
Patna			98.2
*/

-- Q5) Total Revenue, ARPU, MAU, TUnU for each city along with percent of change before and after 5G

--creating a cte to calculate the metrics for pre 5G period
with cte1 as (
select C.City_name, 
sum(AtliQo_revenue_crores) Before_5G_Revenue, 
avg(arpu) as Before_5G_ARPU, 
avg(active_users_lakhs) as Before_5G_MAU, 
sum(unsubscribed_users_lakhs) as Before_5G_TUnU
from fact_atliqo_metrics A
left join dim_cities C on A.city_code = C.city_code
left join dim_date D on A.date = D.date
where [before/after_5g] = 'Before 5G'
group by C.city_name
),
--creating a cte to calculate the metrics for post 5G period
cte2 as (
select C.City_name, sum(AtliQo_revenue_crores) After_5G_revenue, 
avg(arpu) as After_5G_ARPU, avg(active_users_lakhs) as  After_5G_MAU, sum(unsubscribed_users_lakhs) as  After_5G_TUnU
from fact_atliqo_metrics A
left join dim_cities C on A.city_code = C.city_code
left join dim_date D on A.date = D.date
where [before/after_5g] = 'After 5G'
group by C.city_name
)
--combining both cte’s and calculating the % change
select cte1.City_name,
--Revenue
concat(Before_5G_Revenue/10000000,' cr') as [Revenue Before 5G (cr)], 
concat(After_5G_revenue/10000000,' cr') as [Revenue After 5G (cr)], 
concat(round(((After_5G_revenue-Before_5G_Revenue)/Before_5G_Revenue * 100),2),'%') as [Revenue % change],
--ARPU
Before_5G_ARPU, After_5G_ARPU, concat(round(((After_5G_ARPU-Before_5G_ARPU)/Before_5G_ARPU *100),2),'%') as [ARPU % change],
--MAU
concat(Before_5G_MAU/100000,' lakh') as [MAU Before 5G (lakhs)], 
concat(After_5G_MAU/100000,' lakh') as [MAU After 5G (lakhs)], 
concat(round(((After_5G_MAU-Before_5G_MAU)/Before_5G_MAU *100),2), '%') as [MAU % change],
--TUnU	
concat(Before_5G_TUnU/100000,' lakh') as [TUnU Before 5G (lakhs)], 
concat(After_5G_TUnU/100000,' lakh') as [TUnU After 5G (lakhs)], 
concat(round(((After_5G_TUnU-Before_5G_TUnU)/Before_5G_TUnU * 100),2),'%') as [TUnU % change]
from cte1 join cte2 on cte1.city_name = cte2.city_name
order by cte1.city_name

/*
City_name	Revenue Before 5G (cr)	Revenue After 5G (cr)	Revenue % change	Before_5G_ARPU	After_5G_ARPU	ARPU % change	MAU Before 5G (lakhs)	MAU After 5G (lakhs)	MAU % change	TUnU Before 5G (lakhs)	TUnU After 5G (lakhs)	TUnU % change
Ahmedabad		94.49 cr				92.58 cr				-2.02%				176.25			214.75			21.84%			13.3775 lakh			10.845 lakh				-18.93%			3.32 lakh				3.86 lakh				16.27%
Bangalore		168.67 cr				169.94 cr				0.75%				174.75			209				19.6%			24.135 lakh				20.77 lakh				-13.94%			5.71 lakh				6.89 lakh				20.67%
Chandigarh		30.68 cr				30.51 cr				-0.55%				182.5			200.75			10%				4.2125 lakh				4.0025 lakh				-4.99%			1.03 lakh				1.5 lakh				45.63%
Chennai			150.13 cr				146.24 cr				-2.59%				203				197.75			-2.59%			18.4775 lakh			18.5425 lakh			0.35%			5.17 lakh				7.08 lakh				36.94%
Coimbatore		45.67 cr				45.72 cr				0.11%				200				216.5			8.25%			5.7925 lakh				5.255 lakh				-9.28%			1.55 lakh				1.96 lakh				26.45%
Delhi			196.38 cr				190.82 cr				-2.83%				181.5			214.5			18.18%			27.0425 lakh			22.275 lakh				-17.63%			7.7 lakh				8.98 lakh				16.62%
Gurgaon			27.12 cr				27.53 cr				1.51%				183.5			214.5			16.89%			3.685 lakh				3.2025 lakh				-13.09%			0.91 lakh				1.02 lakh				12.09%
Hyderabad		118.63 cr				117.1 cr				-1.29%				196.5			217.25			10.56%			15.15 lakh				14.0175 lakh			-7.48%			3.86 lakh				5.33 lakh				38.08%
Jaipur			70.09 cr				70.78 cr				0.98%				195				209.25			7.31%			9.035 lakh				8.535 lakh				-5.53%			2.23 lakh				3.4 lakh				52.47%
Kolkata			192.55 cr				191.84 cr				-0.37%				183.75			193				5.03%			26.0775 lakh			24.84 lakh				-4.75%			6.93 lakh				8.86 lakh				27.85%
Lucknow			64.83 cr				66.01 cr				1.82%				203.25			219.5			8%				7.9275 lakh				8.1375 lakh				2.65%			1.72 lakh				3.06 lakh				77.91%
Mumbai			244.4 cr				245.15 cr				0.31%				196.75			231				17.41%			31.335 lakh				26.8375 lakh			-14.35%			9.58 lakh				8.37 lakh				-12.63%
Patna			48.74 cr				49.46 cr				1.48%				192.5			231.5			20.26%			6.3625 lakh				5.3375 lakh				-16.11%			1.71 lakh				1.89 lakh				10.53%
Pune			129.64 cr				130.12 cr				0.37%				200				174.25			-12.88%			16.1275 lakh			19.04 lakh				18.06%			4.34 lakh				6.74 lakh				55.3%
Raipur			15.68 cr				15.86 cr				1.15%				184.25			225.25			22.25%			2.145 lakh				1.7875 lakh				-16.67%			0.57 lakh				0.63 lakh				10.53%
*/

-- Q6) Market share by different companies

select Company, round(avg([market_share_%]),2) as [Total_Market_share_%]
from fact_market_share
group by company
order by avg([market_share_%]) desc

/*
Company		Total_Market_share_%
PIO				35.42
Britel			27.49
AtliQo			19.56
DADAFONE		10.31
Others			7.23
*/


-- Q7) Market share of each company before 5G and After 5G
with cte1 as(select company, [market_share_%] as msb5
			from fact_market_share f 
			left join dim_date d on f.date = d.date 
			where d.date in (select date 
							from dim_date 
							where [before/after_5g] = 'Before 5G'
							)
			),
cte2 as(select company, [market_share_%] as msa5
			from fact_market_share f 
			left join dim_date d on f.date = d.date 
			where d.date in (select date 
							from dim_date 
							where [before/after_5g] = 'After 5G'
							)
			)
select cte1.company, round(avg(msb5),2) as [Market_share%_Before_5G], 
round(avg(msa5),2) as Market_share_After_5G, 
concat(round((avg(msa5)-avg(msb5))/avg(msb5)*100,2),'%') as [% change]
from  cte1 join cte2 on cte1.company = cte2.company
group by cte1.company
order by avg(msa5) desc

/*
company		Market_share%_Before_5G		Market_share_After_5G		% change
PIO			35.11				35.72			1.72%
Britel			27.26				27.71			1.67%
AtliQo			20.24				18.88			-6.69%
DADAFONE		10.22				10.39			1.71%
Others			7.17				7.29			1.7%
*/


--Now Lets Analyze the metrics based on different plans

-- Q8) Total Revenue by plans

select p.plans, d.plan_description, sum(p.plan_revenue_crores) as [Total_Revenue (cr)]
from fact_plan_revenue p
left join dim_plan d
on p.plans = d.[plan]
group by p.plans, d.plan_description
order by [Total_Revenue (cr)] desc

/*
plans				plan_description				Total_Revenue (cr)
p1		Smart Recharge Pack (2 GB / Day Combo For 3 months)			419.93
p2		Super Saviour Pack (1.5 GB / Day Combo For 56 days)			297.53
p3		Elite saver Pack (1 GB/ Day) Valid: 28 Days				261.54
p4		Mini Data Saver Pack (500 MB/ Day) Valid: 20 Days			195.22
p11		Ultra Fast Mega Pack (3GB / Day Combo For 80 days)			185.95
p5		Rs. 99 Full Talktime Combo Pack						165.61
p6		Xstream Mobile Data Pack: 15GB Data | 28 days				124.37
p12		Ultra Duo Data Pack (1.8GB / Day Combo For 55 days )			116.13
p7		25 GB Combo 3G / 4G Data Pack						73.8
p8		Daily Saviour (1 GB / Day) validity: 1 Day				43.43
p13		Mini Ultra Saver Pack (750 MB/Day for 28 Days)				31.45
p9		Combo TopUp: 14.95 Talktime and 300 MB data				22.68
p10		Big Combo Pack (6 GB / Day) validity: 3 Days				13.11
*/

-- Q9) Top 3 Plans by revenue before 5G

select top 3 plans, sum(plan_revenue_crores) as [Plan_Revenue_Before_5G (cr)]
from fact_plan_revenue p
left join dim_date d
on p.date = d.date
where month_name in ('Jan', 'Feb', 'Mar', 'Apr')
group by plans
order by [Plan_Revenue_Before_5G (cr)] Desc

/*
plans	Plan_Revenue_Before_5G (cr)
p1		181.27
p2		148.8
p3		131.93
*/

-- Q10) Top 3 plans by revenue After 5G

select top 3 plans, sum(plan_revenue_crores) as [Plan_revenue_After_5G (cr)]
from fact_plan_revenue p
left join dim_date d
on p.date = d.date
where [before/after_5g] = 'After 5G'
group by plans
order by [Plan_revenue_After_5G (cr)] Desc

/*
plans	Plan_revenue_After_5G (cr)
p1		238.66
p11		185.95
p2		148.73
*/

-- Q11) Top 3 Cities by Revenue for each plan Before and After 5G

-- creating a cte to calculate the metrics for pre 5G plans
with B5GCityRank as (
select c.city_name, p.plans, sum(plan_revenue_crores) as B5GRevenue,
row_number() over (partition by p.plans order by sum(plan_revenue_crores) desc) as rn
from fact_plan_revenue p
Left join dim_cities c on p.city_code = c.city_code
left join dim_date d on p.date = d.date
where[before/after_5g] = 'Before 5G'
group by c.city_name, p.plans
), 
--creating a cte to calculate the metrics for post 5G plans
A5GCityRank as (
select c.city_name, p.plans, sum(plan_revenue_crores) as A5GRevenue,
ROW_NUMBER() over (partition by p.plans order by sum(plan_revenue_crores) desc) as rn
from fact_plan_revenue p
left join dim_cities c on p.city_code = c.city_code
left join dim_date d on p.date = d.date
where [before/after_5g] = 'After 5G'
group by c.city_name, plans
)
--combining both cte’s and finding if the ranking of cities is same or different as before 
select a.plans, b.city_name as Before_5G_City, b.B5GRevenue as [Before_5G_Revenue(cr)],
a.city_name as After_5G_City, a.A5GRevenue as [After_5G_Revenue(cr)],
case when b.city_name = a.city_name then 'same' else 'different' end as [Same city or Different]
from B5GCityRank b 
--full outer 
Join A5GCityRank a on b.rn = a.rn and a.plans = b.plans
where a.rn <=3
order by a.plans, a.rn
/*
plans	Before_5G_City	Before_5G_Revenue(cr)  	After_5G_City	After_5G_Revenue(cr)	Same city or Different
p1			Mumbai			25.38					Mumbai			35.72						same
p1			Kolkata			21.7					Kolkata			29.61						same
p1			Delhi			20.51					Delhi			29.48						same
p2			Mumbai			20.53					Mumbai			23						same
p2			Kolkata			19.17					Delhi			18.43						different
...	
p6			Kolkata			9.81					Kolkata			6.04						same
p6			Bangalore		9.11					Delhi			5.77						different
p7			Mumbai			8.13					Bangalore		2.24						different
p7			Delhi			7.62					Delhi			2.02						same
p7			Kolkata			7.19					Kolkata			1.91						same
*/





