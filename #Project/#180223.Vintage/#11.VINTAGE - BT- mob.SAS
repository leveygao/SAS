%inc ".\#00.OPTION.SAS";
libname bt "D:\GY\18.1.31 BT_TABLE_SUM\data";

 

data bt_table;
SET bt.bt_post_info_&tday.;
WHERE channelType ="C001";

STATS_DAY= intnx("month",input(UPDATE_DAY,yymmdd8.),-1);
/* STATS_DAY= intnx("month",input(UPDATE_DAY,yymmdd8.),0);*/
STATS_MTH= put(STATS_DAY,yymmn6.);
run;



%let dlq= 4
;



data BT_VINM1 BT_VINM2 BT_VINM3;
set bt_table;

if new_dlq_mthend>&dlq. then output BT_VINM1;
/*else if  mob>=2 and queue="M1-M2" then output BT_VINM2;
else if  mob>=3 and queue not in ("C","Î´µ½ÆÚ") then output BT_VINM3; */

run;


proc sql;
create table BT_VIN_M1 as
select loan_mth,mob,  
		sum(due_amt) as Due_amt_m1 format comma12.2

from BT_VINM1
where  loan_mth<STATS_MTH and  PUT(new_repaydate,YYMMN6.)<= STATS_MTH

group by loan_mth,mob  
order by loan_mth,mob
;
quit;

proc sql;
create table BT_VIN_M2 as
select loan_mth,mob,   
		sum(due_amt)  as Due_amt_m2 format comma12.2

from BT_VINM2
where  loan_mth<STATS_MTH and  PUT(new_repaydate,YYMMN6.)<= STATS_MTH

group by loan_mth,mob 
order by loan_mth,mob
;
quit;

proc sql;
create table BT_VIN_M3 as
select loan_mth,mob,   
		sum(due_amt)  as Due_amt_m3 format comma12.2

from BT_VINM3
where  loan_mth<STATS_MTH and  PUT(new_repaydate,YYMMN6.)<= STATS_MTH

group by loan_mth,mob  
order by loan_mth,mob
;
quit;

/*proc sql;*/
/*create table etst as*/
/*select distinct memberid, orderno, loanamount,loan_mth, */
/*from dt.bt_dlqdayamt*/
/*;*/
/*quit;*/
/**/

proc sql;
create table Loan_amt as
select loan_mth,  sum(loanamount)  as loan_amt format comma15.2
from (
select distinct memberid, orderno, loanamount,loan_mth 

from bt_table
where  loan_mth<STATS_MTH and  PUT(new_repaydate,YYMMN6.)<= STATS_MTH
)


group by loan_mth 
order by loan_mth
;
quit;

/*========================== vintage ========================*/

/* M1 */
proc sql;
create table M1_VINTAGE AS
select a.*,
		b.mob,b.Due_amt_m1,
		Due_amt_m1/loan_amt as Due_Percent format percent15.2

from loan_amt as a left join Bt_vin_m1 as b on a.loan_mth=b.loan_mth 
order by   loan_mth
;
quit;



/* M2 */
proc sql;
create table M2_VINTAGE AS
select a.*,
		b.mob,b.Due_amt_m2,
		Due_amt_m2/loan_amt as Due_Percent format percent15.2

from loan_amt as a left join Bt_vin_m2 as b on a.loan_mth=b.loan_mth  
order by   loan_mth
;
quit;



/* M3 */
proc sql;
create table M3_VINTAGE AS
select a.*,
		b.mob,b.Due_amt_m3,
		Due_amt_m3/loan_amt as Due_Percent format percent15.2

from loan_amt as a left join Bt_vin_m3 as b on a.loan_mth=b.loan_mth  
order by  loan_mth
;
quit;


/* 1 only */


%MACRO c ; 
%LET TABLE= M1 M2 M3								
;

%do i=1 %to 1;
 %let mname=%scan(&TABLE,&i," ");	   /* %scan(&text,&i,&delim) */
 %put &mname.;


proc transpose data= &mname._VINTAGE (keep=Loan_mth loan_amt mob Due_Percent)  out= TPS_&mname. prefix=mob;
by Loan_mth   loan_amt;
id mob;
var  Due_Percent ;
run;

data   &mname._table;
 
retain loan_mth    loan_amt mob1-mob28;
set TPS_&mname.;
drop _NAME_;
run;



PROC EXPORT DATA=    &mname._table
            OUTFILE= ".\EXCEL\&mname._bt&dlq._all.XLSX" 
            DBMS=EXCEL REPLACE;
     SHEET="&mname._bt&dlq._all"; 
RUN;



%end;
	
%mend;
%c;
