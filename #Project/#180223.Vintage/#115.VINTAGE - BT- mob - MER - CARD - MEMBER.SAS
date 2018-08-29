%inc ".\#00.OPTION.SAS";
libname bt "D:\GY\18.1.31 BT_TABLE_SUM\data";

proc sort data=  Ins.InstalApply
out=instalapply(keep= memberid  channelcode  crttime activeType state opttype productType) nodupkey;
where activeType='virtual_card' and opttype=5 and state=1 ;  /*  and  channelcode ="C001"; */
by memberid ;
run;


data bt_table1;
SET bt.bt_post_info_&tday.;
WHERE channelType ="C001";


STATS_DAY= intnx("month",input(UPDATE_DAY,yymmdd8.),-1);
STATS_MTH= put(STATS_DAY,yymmn6.);
run;

proc sql;
create table bt_table as
select a.*, 
			case when b.activeType='virtual_card' then 1 else 0 end as carduser,
			case when b.activeType='virtual_card' and loan_mth>='201802' then 1 else 0 end as cardorder 

from bt_table1 as a left join instalapply   as b
on a.memberid=b.memberid
order by memberid
;
quit;

proc sql;
select carduser,count(distinct memberid) as member
from  bt_table
where loan_mth='201804'
group by carduser
;
quit;




%let dlq= 1
;


%let vcard=0
;

data BT_VINM1  ;
set bt_table;

if  new_dlq_mthend>&dlq. and   carduser= &vcard.   then output BT_VINM1;
/*
else if  mob>=2 and queue="M1-M2" then output BT_VINM2;
else if  mob>=3 and queue not in ("C","Î´µ½ÆÚ") then output BT_VINM3;
*/
run;


proc sql;
create table BT_VIN_M1 as
select loan_mth,mob,  merchant_type,
		COUNT(distinct memberid) as Due_memberid  format comma12.2

from BT_VINM1
where  loan_mth<STATS_MTH and  PUT(new_repaydate,YYMMN6.)<= STATS_MTH

group by loan_mth,mob  ,merchant_type
order by loan_mth,mob
;
quit;


proc sql;
create table Loan_amt as
select loan_mth,  count(distinct memberid)  as Member_total format comma15.2  ,merchant_type
from (
select distinct memberid, orderno, loanamount,loan_mth ,merchant_type

from bt_table
where  loan_mth<STATS_MTH and  PUT(new_repaydate,YYMMN6.)<= STATS_MTH and carduser=&vcard.
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
		b.mob,b.Due_memberid,
		Due_memberid/Member_total as Due_Percent format percent15.2

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


proc transpose data=  M1_&name.(keep=Loan_mth merchant_type Member_total mob Due_Percent)  out= TPS_M1_&name. prefix=mob;
by Loan_mth merchant_type Member_total;
id mob;
var  Due_Percent ;
run;

data  M1_&name._table;
retain loan_mth  merchant_type Member_total mob1-mob28;
set TPS_M1_&name.;
drop _NAME_;
run;



PROC EXPORT DATA=   M1_&name._table
            OUTFILE= ".\EXCEL\Card&vcard._BT_MID_&dlq._&name..XLSX" 
            DBMS=EXCEL REPLACE;
     SHEET="Card&vcard._BT_MID_&dlq._&name."; 
RUN;



%end;
	
%mend;
%a;

 



/* VIN-ALL */

proc sql;
create table BT_VIN_M1_all as
select loan_mth,mob,  
		COUNT(distinct memberid) as Due_memberid  format comma12.2

from BT_VINM1
where  loan_mth<STATS_MTH and  PUT(new_repaydate,YYMMN6.)<= STATS_MTH

group by loan_mth,mob  
order by loan_mth,mob
;
quit;


proc sql;
create table Loan_amt_all as
select loan_mth,  count(distinct memberid)  as MEMBERID_total format comma15.2   
from (
select distinct memberid, orderno, loanamount,loan_mth  

from bt_table
where  loan_mth<STATS_MTH and  PUT(new_repaydate,YYMMN6.)<= STATS_MTH and carduser=&vcard.
)


group by loan_mth  
order by loan_mth
;
quit;

/* M1 */
proc sql;
create table M1_VINTAGE_all AS
select a.*,
		b.mob,b.Due_memberid,
		Due_memberid/MEMBERID_total as Due_Percent format percent15.2

from Loan_amt_all as a left join BT_VIN_M1_all as b on a.loan_mth=b.loan_mth  
order by   loan_mth 
;
quit;




proc transpose data=   M1_VINTAGE_all(keep=Loan_mth   MEMBERID_total  mob  Due_Percent)  out= TPS_M_all prefix=mob;
by Loan_mth  MEMBERID_total;
id mob;
var  Due_Percent ;
run;

data    Vintage_all_mid_&tday. ;
retain loan_mth    MEMBERID_total 	mob1-mob24;
set   TPS_M_all;
drop 	_NAME_;
run;

PROC EXPORT DATA=    Vintage_all_mid_&tday.
            OUTFILE= ".\EXCEL\Card&vcard._BT_MID_&dlq._all.XLSX" 
            DBMS=EXCEL REPLACE;
     SHEET="Card&vcard._BT_MID_&dlq._all"; 
RUN;



























