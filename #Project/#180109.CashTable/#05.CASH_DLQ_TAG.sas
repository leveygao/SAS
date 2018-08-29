%inc ".\#00.OPTION.SAS";


/* ever first due +ever xMy */

proc sort data= dt.cash_post_info_&tday. 
out= cash;
by  memberid Loan_day orderno mob;
run;


/* dlq - first */
data frs_dlq;
set cash;
by  memberid Loan_day orderno;
/*where flag_return^=-9;*/
retain Ever_frs_dlq Ever_frs_dlqday;
;

if first.memberid and flag_return=-9 then do;
Ever_frs_dlq=-1;
Ever_frs_dlqday=-1;
end;

if first.memberid  and flag_return in(1,9) and mob=1 then do;
Ever_frs_dlq=1;
Ever_frs_dlqday=overduenum;
end;

else if first.memberid then  do;
Ever_frs_dlq=0;
Ever_frs_dlqday=0;
end;
Ever_frs_dlq+0;
Ever_frs_dlqday+0;


if first.memberid;

label
Ever_frs_dlq="首逾"
Ever_frs_dlqday="首逾天数"
;
keep  memberid orderno repaydate_num payday_num mob overduenum flag_return mob Loan_day Ever_frs_dlq Ever_frs_dlqday
Customer_Pricing_Acct  memberlevel_acct  totalQuota  channelCode;
run; 




/* BillX_Everdlq */


data cash_order_cnt;
set cash;
by memberid loan_day orderno  mob ;
/*where flag_return^=-9;*/

/*retain DLQ ;*/
/*if first.orderno then dlq=0;*/
/*if new_dlq_mthend>0 and new_dlq_mthend^=99999 and flag_return in(1,9)  then dlq+1;*/
/**/

Month_intv=intck("month",input(loan_day,yymmdd8.),input("&tday.",yymmdd8.));

if   mob<=3 and flag_return in(1,9) then EVER_3M2=1;else EVER_3M2=0;   /* Month_intv>=3 and */
if   mob<=6 and flag_return in(1,9) then EVER_6M2=1;else EVER_6M2=0;
if   mob<=6 and flag_return in(1,9) then EVER_6M3=1;else EVER_6M3=0;
if   flag_return in(1,9) then DLQ_TIMES=1;else DLQ_TIMES=0;

keep memberid orderno loan_day loan_mth orderno  mob  Month_intv   flag_return   EVER_3M2   EVER_6M3 EVER_6M2
num  overduenum   isoverdue   DLQ_TIMES  new_repaydate
;
run;



proc sql;
create table cash_status as
select distinct memberid,orderno,loan_mth, Month_intv,

 		sum(EVER_3M2) as EVER_3M2_MOBcnt, 
		sum(EVER_6M2) as EVER_6M2_MOBcnt,
		sum(EVER_6M3) as EVER_6M3_MOBcnt,
		sum(DLQ_TIMES) as DLQ_TIMES_MOBcnt


from  cash_order_cnt

group by  memberid,orderno,loan_mth
order by  memberid,orderno,loan_mth
;
quit;



proc sql;
create table Cash_DLQ as
select  memberid,  count(distinct orderno) as Order_cnt,

	count(distinct case when   EVER_3M2_MOBcnt>=2 then orderno end) as EVER_3M2_ordercnt,
	count(distinct case when   EVER_6M2_MOBcnt>=2 then orderno end) as EVER_6M2_ordercnt,
	count(distinct case when   EVER_6M3_MOBcnt>=2 then orderno end) as EVER_6M3_ordercnt,
	sum(DLQ_TIMES_MOBcnt) as DLQ_TIMES_cnt
 

from    cash_status  
group by memberid 
order by memberid 
;
quit;



/* ever_dlq_days */

proc sql;
create table tag_dlq 	as
select		distinct memberid, orderno, 
			
			max(mob) as  maxmob, max(num) as maxnum, max(overduenum) as maxdlqday, max(isoverdue) as isoverdue,
			max(Month_intv) as Month_intv , 
			min(new_repaydate) as minnew_repaydate format yymmddn8.
	
		
from  cash_order_cnt  as a
/*where flag_return^=-9 */

group by memberid, orderno 
order by memberid, orderno    
;
quit;


/*取最坏订单情况*/
proc sql;
create table tag_dlq1 	as
select		memberid, 	orderno,	  maxmob, maxnum, maxdlqday , isoverdue ,Month_intv ,

			/* 逾期天数标签 :  -1表示没有或未到表现期*/
			case when maxdlqday>=60 then 1 
				 when maxdlqday<60  and intck("day",  minnew_repaydate ,input("&tday.",yymmdd8.) )>=60 then 0
				 when maxdlqday<60  and intck("day",  minnew_repaydate ,input("&tday.",yymmdd8.) )<60 then -1
				 else 999   end as Overday_E60dlq,

			case when maxdlqday>=30 then 1 
				 when maxdlqday<30  and intck("day",  minnew_repaydate ,input("&tday.",yymmdd8.) )>=30 then 0
				 when maxdlqday<30  and intck("day",  minnew_repaydate ,input("&tday.",yymmdd8.) )<30 then -1
				 else 999   end as Overday_E30dlq,

			case when maxdlqday>=10 then 1 
				 when maxdlqday<10  and intck("day",  minnew_repaydate ,input("&tday.",yymmdd8.) )>=10 then 0
				 when maxdlqday<10  and intck("day",  minnew_repaydate ,input("&tday.",yymmdd8.) )<10 then -1
				 else 999   end as Overday_E10dlq
				
				
from tag_dlq as a
  
order by  memberid	 
;
quit;



proc sql;
create table tag_dlq2	as
select		memberid, 	 
			 
		    max(maxdlqday) as Max_dlqday ,
			 max(isoverdue) as Cur_dlq  , 
			max(Overday_E60dlq) as Overday_E60dlq,
			max(Overday_E30dlq) as Overday_E30dlq,
			max(Overday_E10dlq) as Overday_E10dlq 

				
from tag_dlq1  
group by memberid	 
order by memberid 
;
quit;



/*================ 最终标签状态================*/
proc sql;
create table cashorderinfo as
select 
memberid,  	
count(distinct orderno) as total_order,
count(distinct case when  orderStatus=2  then orderno end) as Succe_order,
(calculated  Succe_order)/(calculated  total_order) as OrderSuccess_rate format percent9.2

from bck.Cashorderinfo_&tday.
group by memberid
order by memberid
;
quit;



proc sql;
create table tag_all as
select a.*,
		b.Ever_frs_dlq,Ever_frs_dlqday ,  Loan_day as Loan_day_Frs,  
		b.Customer_Pricing_Acct,  b.memberlevel_acct ,  b.totalQuota ,  b.channelCode ,
		c.*,
		d.total_order, d.OrderSuccess_rate
	


from Tag_dlq2 as a   
	join frs_dlq as b
	on a.memberid= b.memberid   
					join cash_dlq as c
					on a.memberid= c.memberid  
						join  cashorderinfo as d
							on   a.memberid= d.memberid  
								

order by memberid,Ever_frs_dlq asc 

	;
quit;



%inc ".\#00.OPTION.SAS";
proc sort data=  Ins.InstalApply
out=instalapply(keep= memberid  channelcode  crttime activeType state opttype productType) nodupkey;
where activeType='virtual_card'  AND opttype=5 and state=1 ;/*  and  channelcode ="C001";  and productType='CASH_LOAN' */
by memberid ;
run;


proc sql;
create table final_table as
select a.*, 
			case when b.activeType='virtual_card' then 1 else 0 end as carduser,
			c.applydate
			


from tag_all as a left join instalapply   as b
on a.memberid=b.memberid
	left join   dt.Cash_apply_info_&tday. as c
on a.memberid=c.memberid

order by memberid
;
quit;




proc sort data=final_table out= DT.CASH_TAG_DLQ_&tday. nodupkey;
by memberid;  
run;









 

proc sql;
title "CASH_DLQ_TAG_&tday.";
select count(distinct memberid) as member
from DT.CASH_TAG_DLQ_&tday.
;
quit;


proc sql;
title "dt.cash_post_info_&tday. ";
select count(distinct memberid) as member
from  DT.CASH_TAG_DLQ_&tday.
;
quit;
