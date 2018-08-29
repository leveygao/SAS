%inc ".\#00.OPTION.SAS";

/* all C-M1 action */

proc sort data=  bck.Event_info_dalilyreport out= Event_info_dalilyreport  nodupkey ;
by memberId Match_month;
run;

proc freq data=Event_info_dalilyreport;
title "Month";
tables  Match_month/missing norow nocol;
run;



/*  C-M1 list */
DATA C_M1_LIST;
set Event_info_dalilyreport;
where Queue_num=1 and roll_over=1;
run;


proc sql;
title "Month";
select Match_month,
		count(distinct memberid) as member,  
		sum(ifpaid) as paid,
		(calculated   paid)/(calculated   member) as Paid_pct format percent9.2

from C_M1_LIST
group by Match_month
order by Match_month
;
quit;




/* bt + ch */

proc sort data= ch.Cash_tag_dlq_20180806    
out= Cash_tag_dlq nodupkey ;
/*(keep= memberid  Customer_Pricing_Acct memberlevel_acct applydate carduser)  */
by memberid ;
run;

proc sort data= bt.Bt_tag_dlq_20180801    
out= Bt_tag_dlq (drop=Merchant_type 
rename=(Ever_merfrs_dlq=Ever_frs_dlq   Ever_merfrs_dlqday= Ever_frs_dlqday   Loan_day_MerFrs=Loan_day_Frs ) ) 
nodupkey ;
by memberid ;
run;



data CASH_BT_DLQ_TAG;
merge Cash_tag_dlq(in=a) Bt_tag_dlq(in=b);
by memberid;
match_chbt=10*a+b;

length USED_TYPE $10. Member_price $12.;
if carduser=1  then USED_TYPE='CARD';
else  if carduser=0 then USED_TYPE='CASH';
/*else  if (carduser=0 or missing(carduser)) and match_chbt=1 then USED_TYPE='BT';*/
else USED_TYPE='BT';


if Customer_Pricing_Acct='Other' then Member_price='Old_Cash';
else if missing(Customer_Pricing_Acct) then Member_price='BT';
else Member_price=Customer_Pricing_Acct;

if missing(carduser) then carduser=-1;

if not missing(applydate) then Apply_loan_intv=intck("day", input(applydate,yymmdd8.),  input(Loan_day_Frs,yymmdd8.) );
else Apply_loan_intv=.;

if missing(Apply_loan_intv) then flag_Apply_loan=-99;
else if Apply_loan_intv<0 then flag_Apply_loan=-1;
else if Apply_loan_intv=0  then flag_Apply_loan=0;
else if Apply_loan_intv>0  then flag_Apply_loan=1;


drop total_order  OrderSuccess_rate      
;
run;


proc freq data=CASH_BT_DLQ_TAG;
title "USERTYPE";
tables  match_chbt*carduser/missing norow nocol;
tables  USED_TYPE*carduser/missing norow nocol;
tables  USED_TYPE*Member_price/missing norow nocol;

run;


proc freq data=CASH_BT_DLQ_TAG;
title "Intv";
tables USED_TYPE*flag_Apply_loan/missing norow nocol;
 
run;



data CASH_BT_DLQ_TAG_excp;
set CASH_BT_DLQ_TAG;
by memberid;
where flag_Apply_loan>=0;
run;






/* C-M1 TAGDLQ */

data C_m1_list_tag_dlq;
merge C_m1_list(in=a) 
	  CASH_BT_DLQ_TAG_excp(in=b  
	keep= memberid Loan_day_Frs   applydate   USED_TYPE   Member_price  Apply_loan_intv flag_Apply_loan Ever_frs_dlq Ever_frs_dlqday

		);
by memberid;
Match_list_dlq=10*a+b;
 
applymth=substr(applydate,1,6);
Loan_mth_frs=substr(Loan_day_Frs,1,6);

run;


proc freq data=C_m1_list_tag_dlq;
title "Match_list_dlq";
tables Match_list_dlq/missing norow nocol;

run;


proc sql;
title "applymth";
select  applymth,
		count(distinct memberid) as member,  
		sum(ifpaid) as paid,
		(calculated   paid)/(calculated   member) as Paid_pct format percent9.2

from C_m1_list_tag_dlq
where Match_list_dlq=11  
group by applymth
order by applymth
;
quit;


%let lower=201706
;
%let upper=201806
;



proc sql;
title "applymth";
select Member_price,
		count(distinct memberid) as member,  
		count(distinct case when ifpaid=1 then memberid end) as paid,
		(calculated   paid)/(calculated   member) as Paid_pct format percent9.2

from C_m1_list_tag_dlq

where Match_list_dlq=11 and  "&upper.">=applymth>="&lower."
group by  Member_price
;
quit;




data Fin_C_M1_list_remain ;
set C_m1_list_tag_dlq;
where Match_list_dlq=11 and    "&upper.">=applymth>="&lower."
;


run;


proc sort data= Fin_C_M1_list_remain  ;
by memberid   applymth   Match_month;
run;



/* first C-M1 dlq */
proc sort data= Fin_C_M1_list_remain out= dt.Fin_C_M1_list_&lower. dupout= Fin_C_M1_list_&lower._dp nodupkey;
by memberid;
run;




proc sql;
title "dt.Fin_C_M1_list ";
select 
		count(distinct memberid) as member,  
		count(distinct case when ifpaid=1 then memberid end) as paid,
		(calculated   paid)/(calculated   member) as Paid_pct format percent9.2

from dt.Fin_C_M1_list_&lower.

;
quit;


