%inc ".\#00.OPTION.SAS";

libname bt "D:\GY\18.1.31 BT_TABLE_SUM\data";


/* C001 */

data  bt_table;
SET bt.bt_post_info_&tday.;
WHERE channelType ="C001";

/*STATS_DAY= intnx("month",input(UPDATE_DAY,yymmdd8.),-1);*/
STATS_DAY= intnx("month",input(UPDATE_DAY,yymmdd8.),0);
STATS_MTH= put(STATS_DAY,yymmn6.);
run;

%let dlq=  1
;

proc sql;
create table 	bt_table_vin	 as
select loan_mth,mob,merchant_type,
		COUNT(DISTINCT case when flag_return in(1,9) and new_dlq_mthend>&dlq.	then  ORDERNO end)  
		as Due_orderno 

from   bt_table

where  loan_mth<STATS_MTH and PUT(new_repaydate,YYMMN6.)<= STATS_MTH

group by loan_mth,mob,merchant_type
order by loan_mth,mob
;
quit;


proc sql;
create table order_total as
select loan_mth,merchant_type, count(distinct orderno)  as Order_total  
from (
select distinct memberid, orderno, loan_mth,merchant_type
from  bt_table

where  loan_mth<STATS_MTH and PUT(new_repaydate,YYMMN6.)<= STATS_MTH
)

group by loan_mth,merchant_type
order by loan_mth
;
quit;


/* all merchant */
proc sql;
create table 	bt_table_vin_all	 as
select loan_mth,mob,
		COUNT(DISTINCT case when flag_return in(1,9) and new_dlq_mthend>&dlq. then  ORDERNO end)  
		as Due_orderno 

from   bt_table

where  loan_mth<STATS_MTH and PUT(new_repaydate,YYMMN6.)<= STATS_MTH

group by loan_mth,mob
order by loan_mth,mob
;
quit;


proc sql;
create table order_total_all	 as
select loan_mth, count(distinct orderno)  as Order_total  
from (
select distinct memberid, orderno, loan_mth
from  bt_table

where  loan_mth<STATS_MTH and PUT(new_repaydate,YYMMN6.)<= STATS_MTH
)

group by loan_mth
order by loan_mth
;
quit;

/*========================== vintage ========================*/

/* VIN */
proc sql;
create table  VINTAGE_Merchant AS
select a.*,
		b.mob,b.Due_orderno,
		Due_orderno/Order_total as Due_Percent format percent15.2

from order_total as a left join bt_table_vin as b 
	on a.loan_mth=b.loan_mth and a.merchant_type=b.merchant_type
order by merchant_type,loan_mth
;
quit;



%MACRO a; 
%LET TABLE= CRUISE FLIGHT OTHER TOUR_DMS TOUR_INT TRAIN								
;

%do i=1 %to 6;
 %let name=%scan(&TABLE,&i," ");	   /* %scan(&text,&i,&delim) */
 %put &name.;

data  Vintage_&name.;
set  VINTAGE_Merchant;
if merchant_type="&name." ;

run;


proc transpose data=   Vintage_&name.(keep=Loan_mth merchant_type Order_total mob Due_Percent)  out= TPS_M1_&name. prefix=mob;
by Loan_mth merchant_type Order_total;
id mob;
var  Due_Percent ;
run;

data    bck.BT_&name._vintage_CNT_&tday. ;
retain loan_mth  merchant_type Order_total mob1-mob20;
set TPS_M1_&name.;
drop _NAME_;
run;


PROC EXPORT DATA=    bck.BT_&name._vintage_CNT_&tday.
            OUTFILE= ".\EXCEL\BT_&name._D&dlq._CNT_&tday..XLSX" 
            DBMS=EXCEL REPLACE;
     SHEET="Vintage_&name"; 
RUN;



%end;
	
%mend;
%a;





/* VIN-ALL */
proc sql;
create table  VINTAGE_Merchant_all AS
select a.*,
		b.mob,b.Due_orderno,
		Due_orderno/Order_total as Due_Percent format percent15.2

from order_total_all as a left join bt_table_vin_all as b 
	on a.loan_mth=b.loan_mth  
order by loan_mth
;
quit;

proc transpose data=   VINTAGE_Merchant_all(keep=Loan_mth   Order_total mob Due_Percent)  out= TPS_M1_all prefix=mob;
by Loan_mth   Order_total;
id mob;
var  Due_Percent ;
run;

data    bck.BT_vintage_all_cnt_&tday. ;
retain loan_mth    Order_total mob1-mob20;
set   TPS_M1_all;
drop 	_NAME_;
run;

PROC EXPORT DATA=    bck.BT_vintage_all_cnt_&tday.
            OUTFILE= ".\EXCEL\BT_D&dlq._all_cnt_&tday..XLSX" 
            DBMS=EXCEL REPLACE;
     SHEET="Vintage_&name"; 
RUN;
