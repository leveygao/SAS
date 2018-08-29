%inc ".\#00.OPTION.SAS";


%let apply_mth=		201705		;


/* merge act */

proc sort data= dt.fin_cm1_last_list_201706   out=  Fin_c_m1_list    nodupkey;
by memberid;
run;


/* merge two */

proc sort data= bck.Remind_tag_table_0806   out=  Remind_tag_table_0806 nodupkey;
by memberid;
run;


data Fin_C_m1_Remind_var  ;
merge    Fin_c_m1_list(in=a)  Remind_tag_table_0806(in=b);
by memberid;
match_CM1=10*a+b;
if a;

run;


proc freq data=  Fin_C_m1_Remind_var ;
title "match_CM1";
tables  match_CM1/missing norow nocol;
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

data 			ALL_CM1_LAST_MODEL ;
merge  			Fin_C_m1_Remind_var(in=a)
				CASH_BT_DLQ_TAG(in=b);
by memberid;
if a;

match_MODEL= 10*a+b;
if ifpaid=1 then target=0;
else target=1;

drop ifpaid  ;
run;

proc freq data=  ALL_CM1_LAST_MODEL ;
tables match_MODEL/missing norow nocol;
run;




data  ALL_CM1_LAST_MODEL_&apply_mth.;
set ALL_CM1_LAST_MODEL;


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


proc sort data=ALL_CM1_LAST_MODEL_&apply_mth.;
by descending memberid;
run;

proc export data= ALL_CM1_LAST_MODEL_&apply_mth.
outfile=".\excel\ALL_CM1_LAST_MODEL_&apply_mth..csv"
dbms=csv replace;
run;
