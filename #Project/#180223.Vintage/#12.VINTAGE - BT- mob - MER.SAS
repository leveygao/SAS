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

if  new_dlq_mthend>&dlq. then output BT_VINM1;
/*
else if  mob>=2 and queue="M1-M2" then output BT_VINM2;
else if  mob>=3 and queue not in ("C","Î´µ½ÆÚ") then output BT_VINM3;
*/
run;


proc sql;
create table BT_VIN_M1 as
select loan_mth,mob,  merchant_type,
		sum(due_amt) as Due_amt_m1 format comma12.2

from BT_VINM1
where  loan_mth<STATS_MTH and  PUT(new_repaydate,YYMMN6.)<= STATS_MTH

group by loan_mth,mob  ,merchant_type
order by loan_mth,mob
;
quit;

proc sql;
create table BT_VIN_M2 as
select loan_mth,mob,   merchant_type,
		sum(due_amt)  as Due_amt_m2 format comma12.2

from BT_VINM2
where  loan_mth<STATS_MTH and  PUT(new_repaydate,YYMMN6.)<= STATS_MTH

group by loan_mth,mob ,merchant_type
order by loan_mth,mob
;
quit;

proc sql;
create table BT_VIN_M3 as
select loan_mth,mob,   merchant_type,
		sum(due_amt)  as Due_amt_m3 format comma12.2

from BT_VINM3
where  loan_mth<STATS_MTH and  PUT(new_repaydate,YYMMN6.)<= STATS_MTH

group by loan_mth,mob  ,merchant_type
order by loan_mth,mob
;
quit;


proc sql;
create table Loan_amt as
select loan_mth,  sum(loanamount)  as loan_amt format comma15.2  ,merchant_type
from (
select distinct memberid, orderno, loanamount,loan_mth ,merchant_type

from bt_table
where  loan_mth<STATS_MTH and  PUT(new_repaydate,YYMMN6.)<= STATS_MTH
)


group by loan_mth ,merchant_type
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

from loan_amt as a left join Bt_vin_m1 as b on a.loan_mth=b.loan_mth and a.merchant_type=b.merchant_type 
order by   loan_mth ,merchant_type
;
quit;




%MACRO a; 
%LET TABLE= CRUISE FLIGHT OTHER TOUR_DMS TOUR_INT TRAIN								
;

%do i=1 %to 6;
 %let name=%scan(&TABLE,&i," ");	   /* %scan(&text,&i,&delim) */
 %put &name.;

data M1_&name.;
set M1_VINTAGE;
if merchant_type="&name." ;

run;


proc transpose data=  M1_&name.(keep=Loan_mth merchant_type loan_amt mob Due_Percent)  out= TPS_M1_&name. prefix=mob;
by Loan_mth merchant_type loan_amt;
id mob;
var  Due_Percent ;
run;

data  M1_&name._table;
retain loan_mth  merchant_type loan_amt mob1-mob28;
set TPS_M1_&name.;
drop _NAME_;
run;



PROC EXPORT DATA=   M1_&name._table
            OUTFILE= ".\EXCEL\BT_&dlq._&name..XLSX" 
            DBMS=EXCEL REPLACE;
     SHEET="BT_&dlq._&name."; 
RUN;



%end;
	
%mend;
%a;


endsas;




















/* M2 */
proc sql;
create table M2_VINTAGE AS
select a.*,
		b.mob,b.Due_amt_m2,
		Due_amt_m2/loan_amt as Due_Percent format percent15.2

from loan_amt as a left join Bt_vin_m2 as b on a.loan_mth=b.loan_mth and a.merchant_type=b.merchant_type
order by merchant_type,loan_mth
;
quit;


%MACRO b ; 
%LET TABLE= CRUISE FLIGHT OTHER TOUR_DMS TOUR_INT TRAIN								
;

%do i=1 %to 6;
 %let name=%scan(&TABLE,&i," ");	   /* %scan(&text,&i,&delim) */
 %put &name.;

data M2_&name.;
set M2_VINTAGE;
if merchant_type="&name." ;

run;


proc transpose data= M2_&name.(keep=Loan_mth merchant_type loan_amt mob Due_Percent)  out= TPS_M2_&name. prefix=mob;
by Loan_mth merchant_type loan_amt;
id mob;
var  Due_Percent ;
run;

data  M2_&name._table;
retain loan_mth  merchant_type loan_amt mob1-mob22;
set TPS_M2_&name.;
drop _NAME_;
run;



PROC EXPORT DATA=   M2_&name._table
            OUTFILE= ".\EXCEL\M2_&name..XLSX" 
            DBMS=EXCEL REPLACE;
     SHEET="M2_&name"; 
RUN;



%end;
	
%mend;
%b ;




/* M3 */
proc sql;
create table M3_VINTAGE AS
select a.*,
		b.mob,b.Due_amt_m3,
		Due_amt_m3/loan_amt as Due_Percent format percent15.2

from loan_amt as a left join Bt_vin_m3 as b on a.loan_mth=b.loan_mth and a.merchant_type=b.merchant_type
order by merchant_type,loan_mth
;
quit;

%MACRO c ; 
%LET TABLE= CRUISE FLIGHT OTHER TOUR_DMS TOUR_INT TRAIN								
;

%do i=1 %to 6;
 %let name=%scan(&TABLE,&i," ");	   /* %scan(&text,&i,&delim) */
 %put &name.;

data M3_&name.;
set M3_VINTAGE;
if merchant_type="&name." ;

run;


proc transpose data= M3_&name.(keep=Loan_mth merchant_type loan_amt mob Due_Percent)  out= TPS_M3_&name. prefix=mob;
by Loan_mth merchant_type loan_amt;
id mob;
var  Due_Percent ;
run;

data  M3_&name._table;
retain loan_mth  merchant_type loan_amt mob1-mob22;
set TPS_M3_&name.;
drop _NAME_;
run;



PROC EXPORT DATA=   M3_&name._table
            OUTFILE= ".\EXCEL\M3_&name..XLSX" 
            DBMS=EXCEL REPLACE;
     SHEET="M3_&name"; 
RUN;



%end;
	
%mend;
%c;














