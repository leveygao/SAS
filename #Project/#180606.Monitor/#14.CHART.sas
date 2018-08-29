%INC  ".\#00.OPTION.SAS";
libname btbck "D:\GY\18.1.31 BT_TABLE_SUM\bck";

%let type=C001
;
%let name=JF_EVERDLQ
;



/* ever first due +ever xMy */


/* BillX_Everdlq */
proc sort data=  bt.Bt_post_info_&tday.  
out= BT_MERHCANT_srt;
by memberid loan_day orderno  mob;
run;

data Bt_post_order_cnt;
set BT_MERHCANT_srt;
by memberid loan_day orderno  mob ;
/*where flag_return^=-9;*/

retain DLQ ;
if first.orderno then dlq=0;
if new_dlq_mthend>0 then dlq+1;

Month_intv=intck("month",input(loan_day,yymmdd8.),input("&tday.",yymmdd8.));

if Month_intv>=3 and mob<=3 and dlq>=2 then EVER_3M2=1;else EVER_3M2=0;
if Month_intv>=6 and mob<=6 and dlq>=2 then EVER_6M2=1;else EVER_6M2=0;
if Month_intv>=6 and mob<=6 and dlq>=3 then EVER_6M3=1;else EVER_6M3=0;
run;



proc sql;
create table BT_EVER_status as
select distinct memberid,orderno,loan_mth,Merchant_type,loanamount ,Month_intv,
		
 		max(EVER_3M2) as EVER_3M2, max(EVER_6M2) as EVER_6M2,max(EVER_6M3) as EVER_6M3
from  Bt_post_order_cnt
group by  memberid,loan_mth,orderno,Merchant_type
order by  memberid,loan_mth,orderno,Merchant_type
;
quit;


proc sql;
create table BT_EVER_DLQ as
select  memberid, Merchant_type, loan_mth,

	count(distinct case when (Month_intv>=3 and EVER_3M2=1) then orderno end) as Ever_3M2_cnt,
	count(distinct case when (Month_intv>=6 and EVER_6M2=1) then orderno end) as EVER_6M2_cnt,
	count(distinct case when (Month_intv>=6 and EVER_6M3=1) then orderno end) as EVER_6M3_cnt
 

from    BT_EVER_status  
group by memberid,loan_mth,Merchant_type
order by memberid,loan_mth,Merchant_type
;
quit;

data  BT_EVER_DLQ_tag;
set BT_EVER_DLQ;
by memberid loan_mth Merchant_type;

if Ever_3M2_cnt>0 then Max_Ever_3M2=1; else Max_Ever_3M2=0;
if EVER_6M2_cnt>0 then Max_EVER_6M2=1; else Max_EVER_6M2=0;
if EVER_6M3_cnt>0 then Max_EVER_6M3=1; else Max_EVER_6M3=0;

run;








proc export data=  BT_EVER_DLQ_tag
	outtable="&name."
	dbms=access replace;
	database=".\REPORT\&NAME.";
	run;



