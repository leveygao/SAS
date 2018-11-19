%inc ".\#00.OPTION.SAS";




data ch_table;
SET CH.cash_post_info_&tday.;

STATS_DAY= intnx("month",input(UPDATE_DAY,yymmdd8.),-1);
/* STATS_DAY= intnx("month",input(UPDATE_DAY,yymmdd8.),0);*/
STATS_MTH= put(STATS_DAY,yymmn6.);
run;



%let dlq= 1
;


data BT_VINM1  ;
set ch_table;

if  new_dlq_mthend>&dlq. then output BT_VINM1;
/*
else if  mob>=2 and queue="M1-M2" then output BT_VINM2;
else if  mob>=3 and queue not in ("C","Î´µ½ÆÚ") then output BT_VINM3;
*/
run;




proc sql;
create table BT_VIN_M1 as
select loan_mth,mob,  membergrade_cashpcl_lvl,
		sum(due_amt) as Due_amt_m1 format comma12.2

from BT_VINM1
where  loan_mth<STATS_MTH and  PUT(new_repaydate,YYMMN6.)<= STATS_MTH

group by loan_mth,mob  ,membergrade_cashpcl_lvl
order by loan_mth,mob
;
quit;

/*proc freq data= BT_VIN_M1 ;*/
/*tables membergrade_cashpcl_lvl ;*/
/*run;*/


proc sql;
create table Loan_amt as
select loan_mth,  sum(loan_amt)/100  as loan_amt format comma15.2  ,membergrade_cashpcl_lvl
from (
select distinct memberid, orderno, loan_amt,loan_mth ,membergrade_cashpcl_lvl

from ch_table
where  loan_mth<STATS_MTH and  PUT(new_repaydate,YYMMN6.)<= STATS_MTH
)


group by loan_mth ,membergrade_cashpcl_lvl
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

from loan_amt as a left join Bt_vin_m1 as b on a.loan_mth=b.loan_mth and a.membergrade_cashpcl_lvl=b.membergrade_cashpcl_lvl 
order by   loan_mth ,membergrade_cashpcl_lvl
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

data M1_&sheetname.;
set M1_VINTAGE;
if upcase(membergrade_cashpcl_lvl)=upcase("&name.");

run;


proc transpose data=  M1_&sheetname.(keep=Loan_mth membergrade_cashpcl_lvl loan_amt mob Due_Percent)  out= TPS_M1_&sheetname. prefix=mob;
by Loan_mth membergrade_cashpcl_lvl loan_amt;
id mob;
var  Due_Percent ;
run;

data  Vin_&sheetname._table;
retain loan_mth  membergrade_cashpcl_lvl loan_amt mob1-mob28;
set TPS_M1_&sheetname.;
drop _NAME_;
run;



PROC EXPORT DATA=   Vin_&sheetname._table
             OUTFILE= ".\EXCEL\CH_Member_DlqBK&dlq._&tday..XLSX" 
             DBMS=EXCEL REPLACE;
     SHEET="CH_bk&dlq._&sheetname."; 
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

from loan_amt as a left join Bt_vin_m2 as b on a.loan_mth=b.loan_mth and a.membergrade_cashpcl_lvl=b.membergrade_cashpcl_lvl
order by membergrade_cashpcl_lvl,loan_mth
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
if membergrade_cashpcl_lvl="&name." ;

run;


proc transpose data= M2_&name.(keep=Loan_mth membergrade_cashpcl_lvl loan_amt mob Due_Percent)  out= TPS_M2_&name. prefix=mob;
by Loan_mth membergrade_cashpcl_lvl loan_amt;
id mob;
var  Due_Percent ;
run;

data  M2_&name._table;
retain loan_mth  membergrade_cashpcl_lvl loan_amt mob1-mob22;
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

from loan_amt as a left join Bt_vin_m3 as b on a.loan_mth=b.loan_mth and a.membergrade_cashpcl_lvl=b.membergrade_cashpcl_lvl
order by membergrade_cashpcl_lvl,loan_mth
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
if membergrade_cashpcl_lvl="&name." ;

run;


proc transpose data= M3_&name.(keep=Loan_mth membergrade_cashpcl_lvl loan_amt mob Due_Percent)  out= TPS_M3_&name. prefix=mob;
by Loan_mth membergrade_cashpcl_lvl loan_amt;
id mob;
var  Due_Percent ;
run;

data  M3_&name._table;
retain loan_mth  membergrade_cashpcl_lvl loan_amt mob1-mob22;
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














