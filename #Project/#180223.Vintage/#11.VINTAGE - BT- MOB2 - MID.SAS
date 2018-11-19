%inc ".\#00.OPTION.SAS";




/* C001 */

data  bt_table;
SET bt.bt_post_info_&tday.;
WHERE channelType ="C001";

STATS_DAY= intnx("month",input(UPDATE_DAY,yymmdd8.),-1);
STATS_MTH= put(STATS_DAY,yymmn6.);
run;

%let dlq=1
;

proc sql;
create table 	bt_table_vin	 as
select loan_mth,mob,merchant_type,
		COUNT(DISTINCT case when flag_return in(1,9) and new_dlq_mthend>=&dlq. then  memberid end)  
		as Due_memberid 

from   bt_table

where  loan_mth<STATS_MTH and PUT(new_repaydate,YYMMN6.)<= STATS_MTH

group by loan_mth,mob,merchant_type
order by loan_mth,mob
;
quit;


proc sql;
create table order_total as
select loan_mth,merchant_type, count(distinct memberid)  as memberid_total  
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
		COUNT(DISTINCT case when flag_return in(1,9) and  new_dlq_mthend>=&dlq.  then  memberid  end)  
		as Due_memberid 

from   bt_table

where  loan_mth<STATS_MTH and PUT(new_repaydate,YYMMN6.)<= STATS_MTH

group by loan_mth,mob
order by loan_mth,mob
;
quit;


proc sql;
create table order_total_all	 as
select loan_mth, count(distinct memberid)  as memberid_total  
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
		b.mob,	b.Due_memberid	,
		Due_memberid/memberid_total as Due_Percent format percent15.2

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


proc transpose data=   Vintage_&name.(keep=Loan_mth merchant_type memberid_total mob Due_Percent)  out= TPS_M1_&name. prefix=mob;
by Loan_mth merchant_type memberid_total;
id mob;
var  Due_Percent ;
run;

data     bt_&name._vintage_MID_&tday. ;
retain loan_mth  merchant_type memberid_total mob1-mob20;
set TPS_M1_&name.;
drop _NAME_;
run;


PROC EXPORT DATA=    bt_&name._vintage_MID_&tday.
            OUTFILE= ".\EXCEL\BT_D&dlq._MID_&tday..XLSX" 
            DBMS=EXCEL REPLACE;
     SHEET="bt_&name"; 
RUN;



%end;
	
%mend;
%a;





/* VIN-ALL */
proc sql;
create table  VINTAGE_Merchant_all AS
select a.*,
		b.mob,	b.Due_MEMBERID,
		Due_MEMBERID/MEMBERID_total as Due_Percent format percent15.2

from order_total_all as a left join bt_table_vin_all as b 
	on a.loan_mth=b.loan_mth  
order by loan_mth
;
quit;

proc transpose data=   VINTAGE_Merchant_all(keep=Loan_mth   MEMBERID_total  mob  Due_Percent)  out= TPS_M1_all prefix=mob;
by Loan_mth  MEMBERID_total;
id mob;
var  Due_Percent ;
run;

data    bt_vintage_all_mid_&tday. ;
retain loan_mth    MEMBERID_total 	mob1-mob20;
set   TPS_M1_all;
drop 	_NAME_;
run;

PROC EXPORT DATA=    bt_vintage_all_mid_&tday.
            OUTFILE= ".\EXCEL\bt_all_mid_&tday..XLSX" 
            DBMS=EXCEL REPLACE;
     SHEET="bt_all"; 
RUN;