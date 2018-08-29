%inc ".\#00.OPTION.SAS";

/* merge act */

proc sort data= dt.fin_cm1_last_list_201706   out=  Fin_c_m1_list    nodupkey;
by memberid;
run;



proc sort data= dt.Fin_c_m1_id_decode1   out=  Fin_c_m1_id_decode1(drop= identityNo  birthday) nodupkey;
by memberid;
run;

proc sort data= bt.Bt_apply_info_20180801   out=  Bt_apply_info (keep= memberid sex age) nodupkey;
by memberid;
run;



data Fin_c_m1_ID  ;
merge Fin_c_m1_list(in=a)  Fin_c_m1_id_decode1(in=b) Bt_apply_info(in=c  );
by memberid;
match_id=compress(a||b||c);
if a;


if missing(sex) or  missing(age) then mis_bid=1;
else mis_bid=0;
run;



proc freq data=  Fin_c_m1_ID ;
title "mis_id";
tables  match_id /missing norow nocol;
tables  Member_price/missing norow nocol;
 
run; 


data Fin_c_m1_ID_VAR;
set Fin_c_m1_ID;
by memberid;

if index(Member_price,"A") then Member_level_A= 1; else  Member_level_A= 0;
if index(Member_price,"B") and compress(Member_price)^='BT' then Member_level_B= 1; else  Member_level_B= 0;
if index(Member_price,"C") then Member_level_C= 1; else  Member_level_C= 0;
if index(Member_price,"Old_Cash") or  index(Member_price,"BT") or  index(Member_price,"Imp") then 
Member_level_OT= 1; else  Member_level_OT= 0;

if sex='M' then gender=1;
else gender=0;

if USED_TYPE='CARD' then carduser=1;else carduser=0;

keep  memberid  idRemindEvent   Match_month  applymth  Init_sumOverdueAmt  status_df  ystdReminder_df  ifpaid  
Intv  Apply_loan_intv  gender  age  carduser
Ever_frs_dlq     Ever_frs_dlqday    Member_level:   
;
run;

/*  sample model */

%let apply_mth=		201705		;

proc freq data=  Fin_c_m1_ID_VAR ;
where applymth>="&apply_mth."  ;
tables  applymth*ifpaid/missing norow nocol;
run;


proc sort data=  Fin_c_m1_ID_VAR  out=Fin_c_m1_ID_VAR_subset		;
where    applymth>="&apply_mth."		;
by applymth;
run;


proc surveyselect data=  Fin_c_m1_ID_VAR_subset out=Fin_CM1_paid seed=323 rate=0.9 noprint;
where ifpaid=1 ;
strata applymth;
run;


proc surveyselect data=  Fin_c_m1_ID_VAR_subset out=Fin_CM1_unpaid seed=17 rate=0.3 noprint;
where ifpaid=0;
strata applymth;
run;


data Fin_ifpaid;
set Fin_CM1_paid  Fin_CM1_unpaid ;
drop SelectionProb  SamplingWeight; 
run;

proc freq data=  Fin_ifpaid ;
tables   ifpaid/missing norow nocol;
tables   applymth*ifpaid/missing norow nocol;
run;



/* merge two */

proc sort data= bck.Remind_tag_table_0806   out=  Remind_tag_table_0806 nodupkey;
by memberid;
run;
proc sort data=Fin_ifpaid;
by memberid;
run;

data Fin_C_m1_Remind_var  ;
merge    Fin_ifpaid(in=a)  Remind_tag_table_0806(in=b);
by memberid;
match_CM1=10*a+b;
if a;

run;


proc freq data=  Fin_C_m1_Remind_var ;
title "match_CM1";
tables  match_CM1/missing norow nocol;
run;



proc freq data=  Fin_C_m1_Remind_var ;
title "ifpaid";
tables  applymth*carduser/missing norow nocol;
run;



/* refill */

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

keep  memberid  Overday_E60dlq  Overday_E30dlq  Overday_E10dlq   Order_cnt  
EVER_3M2_ordercnt  EVER_6M3_ordercnt DLQ_TIMES_cnt 

;
run;


/* merge all */

data 			CM1_LAST_MODEL ;
merge  			Fin_C_m1_Remind_var(in=a)
				CASH_BT_DLQ_TAG(in=b);
by memberid;
if a;

match_MODEL= 10*a+b;
if ifpaid=1 then target=0;
else target=1;

drop ifpaid  ;
run;

proc freq data=  CM1_LAST_MODEL ;
tables match_MODEL/missing norow nocol;
run;




data dt.CM1_LAST_MODEL_&apply_mth.;
set CM1_LAST_MODEL;
drop match:   ifpaid;
run;


proc export data= dt.CM1_LAST_MODEL_&apply_mth.
outfile=".\excel\CM1_LAST_MODEL_&apply_mth..csv"
dbms=csv replace;
run;


/*

data ALL_CM1_LAST_MODEL_&apply_mth.;
set dt.CM1_LAST_MODEL_&apply_mth.;

keep  memberid
applymth
Fst_OutClass_M
Fst_OutClass_SQM
Fst_OutClass_EM
Trd_OutClass_RE
Trd_OutClass_NOST
Sec_OutClass_NOFF
Sec_OutClass_ABNO
Sec_OutClass_ZC
Init_sumOverdueAmt
DLQ_TIMES_cnt

target;

run;


proc export data=  ALL_CM1_LAST_MODEL_&apply_mth.
outfile=".\excel\ALL_CM1_LAST_MODEL_&apply_mth..csv"
dbms=csv replace;
run;
