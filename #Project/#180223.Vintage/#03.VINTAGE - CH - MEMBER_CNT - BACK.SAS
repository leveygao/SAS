%inc ".\#00.OPTION.SAS";



data ch_table;
SET CH.cash_post_info_&tday.;

STATS_DAY= intnx("month",input(UPDATE_DAY,yymmdd8.),-1);
/* STATS_DAY= intnx("month",input(UPDATE_DAY,yymmdd8.),0);*/
STATS_MTH= put(STATS_DAY,yymmn6.);
run;


%let dlq=  1
;


proc sql;
create table 	bt_table_vin	 as
select loan_mth,mob,membergrade_cashpcl_lvl,
		COUNT(DISTINCT case when flag_return in(1,9) and new_dlq_mthend>&dlq.	then  MEMBERID end)  
		as Due_member 

from   ch_table

where  loan_mth<STATS_MTH and PUT(new_repaydate,YYMMN6.)<= STATS_MTH

group by loan_mth,mob,membergrade_cashpcl_lvl
order by loan_mth,mob
;
quit;


proc sql;
create table order_total as
select loan_mth,membergrade_cashpcl_lvl, count(distinct MEMBERID)  as MEMBER_total  
from (
select distinct memberid, orderno, loan_mth,membergrade_cashpcl_lvl
from  ch_table

where  loan_mth<STATS_MTH and PUT(new_repaydate,YYMMN6.)<= STATS_MTH
)

group by loan_mth,membergrade_cashpcl_lvl
order by loan_mth
;
quit;


/* all merchant */
proc sql;
create table 	bt_table_vin_all	 as
select loan_mth,mob,
		COUNT(DISTINCT case when flag_return in(1,9) and new_dlq_mthend>&dlq. then  MEMBERID end)  
		as Due_MEMBER 

from   ch_table

where  loan_mth<STATS_MTH and PUT(new_repaydate,YYMMN6.)<= STATS_MTH

group by loan_mth,mob
order by loan_mth,mob
;
quit;


proc sql;
create table order_total_all	 as
select loan_mth, count(distinct MEMBERID)  as member_total  
from (
select distinct memberid, orderno, loan_mth
from  ch_table

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
		b.mob,b.Due_member,
		Due_member/member_total as Due_Percent format percent15.2

from order_total as a left join bt_table_vin as b 
	on a.loan_mth=b.loan_mth and a.membergrade_cashpcl_lvl=b.membergrade_cashpcl_lvl
order by membergrade_cashpcl_lvl,loan_mth
;
quit;



%MACRO a; 
%LET TABLE= A NB B B- C C- IMP  OTHER  PD  NANJING_BANK	 	 						
;

%LET TABLENAME= A NB B Bm C Cm IMP OTHER  PD NANJING_BANK	 						
;

%do i=1 %to %eval( %sysfunc(countw( &TABLE., " ")) - 0 )  ;
 %let name=%scan(&TABLE,&i," ");
 %let sheetname=%scan(&TABLENAME,&i," ");/* %scan(&text,&i,&delim) */
 %put &name.;

data  Vintage_&sheetname.;
set  VINTAGE_Merchant;
if upcase(membergrade_cashpcl_lvl) = upcase("&name.") ;

run;


proc transpose data=   Vintage_&sheetname.(keep=Loan_mth membergrade_cashpcl_lvl member_total mob Due_Percent)  out= TPS_M1_&sheetname. prefix=mob;
by Loan_mth membergrade_cashpcl_lvl member_total;
id mob;
var  Due_Percent ;
run;

data     CH_&sheetname._vintage  ;
retain loan_mth  membergrade_cashpcl_lvl member_total mob1-mob28;
set TPS_M1_&sheetname.;
drop _NAME_;
run;


PROC EXPORT DATA=    CH_&sheetname._vintage 
            OUTFILE= ".\EXCEL\CH_BK&dlq._MIDCNT_&tday..XLSX" 
            DBMS=EXCEL REPLACE;
     SHEET="CH_BKD&dlq._&sheetname"; 
RUN;



%end;
	
%mend;
%a;






/* VIN-ALL */
proc sql;
create table  VINTAGE_Merchant_all AS
select a.*,
		b.mob,b.Due_member,
		Due_member/member_total as Due_Percent format percent15.2

from order_total_all as a left join bt_table_vin_all as b 
	on a.loan_mth=b.loan_mth  
order by loan_mth
;
quit;

proc transpose data=   VINTAGE_Merchant_all(keep=Loan_mth   member_total  mob  Due_Percent)  out= TPS_M1_all prefix=mob;
by Loan_mth   member_total;
id mob;
var  Due_Percent ;
run;

data     BT_vintage_all_cnt  ;
retain loan_mth    member_total   mob1-mob28;
set   TPS_M1_all;
drop 	_NAME_;
run;

PROC EXPORT DATA=  BT_vintage_all_cnt
            OUTFILE= ".\EXCEL\CH_BKD&dlq._all_midcnt_&tday..XLSX" 
            DBMS=EXCEL REPLACE;
     SHEET="D&dlq._BK_All"; 
RUN;
