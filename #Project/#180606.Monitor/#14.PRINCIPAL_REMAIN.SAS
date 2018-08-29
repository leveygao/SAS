%inc ".\#00.OPTION.SAS";


%let updatemth=201805
;
%let type=C001
;
%let name=JF
;


proc sql;
create table temp as

select distinct a.memberId, a.orderno,  bigMerchantId, put(datepart(b.ordertime),yymmn6.) as loanTime,

		sum(distinct b.loanAmount) as loan_amt,		
		sum((a.remainPrincipal)/100) as max_benjin,
		max(case when a.isOverdue =1 then a.overdueNum  else 0  end) as max_yuqitianshu,
		max(a.isOverdue) as isOverdue1
		 

  from ins.RepaySchedule as a
  	left join fq_data.OrderInfo as b on a.orderNo=b.orderNo
	where   b.orderStatus^="0" and a.repayStatus^=3  and a.orderType=2  and b.orderType="1"  and b.channelType="&type." 
 	group by a.memberId,a.orderno,  bigMerchantId,put(datepart(b.ordertime),yymmn6.)
;
quit;


proc sql;
create table Principal_remain as
select 
 
loanTime,
CASE WHEN bigMerchantId='20160001' THEN 'TOUR_INT'
		 	WHEN bigMerchantId='20160007' THEN 'FLIGHT'
			WHEN bigMerchantId='20160006' THEN 'TOUR_DMS'
			WHEN bigMerchantId='20160002' THEN 'TRAIN'
			WHEN bigMerchantId='20160005' THEN 'CRUISE'
			else  'OTHER'  end as Merchant_type
,
sum(loan_amt) as loan_amt ,
sum(case when   c.isOverdue1= 0  then c.max_benjin end ) as M0,
sum( case when c.max_yuqitianshu > 0  and c.max_yuqitianshu<= 30  and c.isOverdue1= 1 then c.max_benjin end) as M1,
sum( case when c.max_yuqitianshu > 30  and c.max_yuqitianshu<= 60  and c.isOverdue1= 1 then c.max_benjin end) as M2,
sum( case when c.max_yuqitianshu > 60  and c.max_yuqitianshu<= 90  and c.isOverdue1= 1 then c.max_benjin end) as M3,
sum( case when c.max_yuqitianshu > 90  and c.max_yuqitianshu<= 120  and c.isOverdue1= 1 then c.max_benjin end) as M4,
sum( case when c.max_yuqitianshu > 120  and c.max_yuqitianshu<= 150  and c.isOverdue1= 1 then c.max_benjin end) as M5,
sum( case when c.max_yuqitianshu > 150  and c.max_yuqitianshu<= 180  and c.isOverdue1= 1 then c.max_benjin end) as M6,
sum( case when c.max_yuqitianshu > 180  and c.max_yuqitianshu<= 210  and c.isOverdue1= 1 then c.max_benjin end) as M7,
sum( case when c.max_yuqitianshu > 210  and c.max_yuqitianshu<= 240  and c.isOverdue1= 1 then c.max_benjin end) as M8,
sum( case when c.max_yuqitianshu > 240  and c.max_yuqitianshu<= 270  and c.isOverdue1= 1 then c.max_benjin end) as M9,
sum( case when c.max_yuqitianshu > 270    and c.isOverdue1= 1 then c.max_benjin end) as M10


from
temp as c

 where  loanTime<"&updatemth."
 group by loanTime,Merchant_type
order by  loanTime desc
;

quit;



PROC EXPORT DATA=  Principal_remain
            OUTFILE= ".\report\Principal_remain.xlsx" 
            DBMS=EXCEL REPLACE;
     SHEET="Principal_remain"; 
RUN;




