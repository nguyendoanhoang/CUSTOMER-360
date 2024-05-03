with data1 as (
		select CustomerID ,
				datediff('2022-09-01', STR_TO_DATE(max(Purchase_Date), '%m/%d/%Y')) as Recency,
				count(Purchase_date) as trans_num,
				sum(GMV) as Monetary
		from customer_transaction ct 
		where CustomerID != '0'
		group by CustomerID
		order by trans_num desc
			),
	data2 as (
			select  ID, case when stopdate = '' then datediff('2022-09-01', STR_TO_DATE(created_date, '%m/%d/%Y'))/365.25
					else datediff(STR_TO_DATE(stopdate, '%m/%d/%Y'), STR_TO_DATE(created_date, '%m/%d/%Y'))/365.25
					end as Contract_term
			from   customer_registered cr  
			),
	RFM_cal as (select CustomerID,
					Recency,
					trans_num/Contract_term as Frequency,
					Monetary
			from data1
			join data2
			on data1.CustomerID = data2.ID
			),
	RFM_score as ( 
				select *, 
					ntile(4) over(order by Recency DESC) as R,
					ntile(4) over(order by Frequency) as F,
					ntile(4) over(order by Monetary) as M
				from RFM_cal)
select *,concat(R,F,M) as RFM,
		case 
			when concat(R,F,M) in ('444','443','434','433','344','343','334','333') then 'Star'
			when concat(R,F,M) in ('424','423','413','414','313','314','323','324',
									'233','234','244','243','133','134','143','144') then 'Cash_cow'
			when concat(R,F,M) in ('441','442','431','432','341','342','331','332','131','132','141','142',
									'241','242','231','232','113','114','123','124','213','214','223','224') then 'Question_mark'
			else 'Dog'
			end as BGC
from RFM_score

-- Tính các quartiles cho từng yếu tố RFM
with a as
		(select r1.customerID, recency,
			row_number() over (order by recency desc) as rn_recency
		from rfm_score r1) , 
	b as 
		(select r2.customerID, Frequency,
			row_number() over (order by Frequency desc) as rn_Frequency
		from rfm_score r2 ),
	c as 
		(select r3.customerID, Monetary,
			row_number() over (order by Monetary desc) as rn_Monetary
		from rfm_score r3),
	d as (
		select a.customerID,a.recency, a.rn_recency ,b.Frequency, b.rn_Frequency,c.Monetary, c.rn_Monetary
		from a
		left join b
		on a.customerID=b.customerID
		left join c
		on a.customerID=c.customerID)
select min(recency) as min,
	(select recency from d where rn_recency = (select FLOOR(count(CustomerID)*0.75) from rfm_score)) as Q1,
	(select recency from d where rn_recency = (select FLOOR(count(CustomerID)*0.5) from rfm_score)) as Q2,
	(select recency from d where rn_recency = (select FLOOR(count(CustomerID)*0.25) from rfm_score)) as Q3,
	max(recency) as max
from d
union
select min(Frequency) as min,
	(select Frequency from d where rn_Frequency = (select FLOOR(count(CustomerID)*0.75) from rfm_score)) as Q1,
	(select Frequency from d where rn_Frequency = (select FLOOR(count(CustomerID)*0.5) from rfm_score)) as Q2,
	(select Frequency from d where rn_Frequency = (select FLOOR(count(CustomerID)*0.25) from rfm_score)) as Q3,
	max(Frequency) as max
from d
union
select min(Monetary) as min,
	(select Monetary from d where rn_Monetary = (select FLOOR(count(CustomerID)*0.75) from rfm_score)) as Q1,
	(select Monetary from d where rn_Monetary = (select FLOOR(count(CustomerID)*0.5) from rfm_score)) as Q2,
	(select Monetary from d where rn_Monetary = (select FLOOR(count(CustomerID)*0.25) from rfm_score)) as Q3,
	max(Monetary) as max
from d



