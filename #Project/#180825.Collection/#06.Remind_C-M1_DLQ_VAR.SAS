%inc ".\#00.OPTION.SAS";

/* merge act */

proc sort data= dt.Fin_c_m1_list_201706   out=  Fin_c_m1_list    nodupkey;
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
tables  applymth/missing norow nocol;
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

keep  memberid  idRemindEvent   Match_month  applymth  Init_sumOverdueAmt  status_df  ystdReminder_df  ifpaid  Intv  Apply_loan_intv  gender  age  
Ever_frs_dlq     Ever_frs_dlqday    Member_level:   
;
run;


proc freq data=  Fin_c_m1_ID_VAR ;
tables  applymth*ifpaid/missing norow nocol;
run;


/*  sample model */
proc sort data=  Fin_c_m1_ID_VAR;
by applymth;
run;

data Fin_CM1_paid;
set Fin_c_m1_ID_VAR(where=(ifpaid=1));
run;



proc surveyselect data=  Fin_c_m1_ID_VAR out=Fin_CM1_unpaid seed=17 rate=0.2 noprint;
where ifpaid=0;
strata applymth;
run;
proc freq data=  Fin_CM1_unpaid ;
tables  applymth*ifpaid/missing norow nocol;
run;



data Fin_ifpaid;
set Fin_CM1_paid  Fin_CM1_unpaid(drop=SelectionProb  SamplingWeight)  ;
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
tables  applymth*ifpaid/missing norow nocol;
run;



data dt.C_M1_MODEL_SAMPLE01;
SET  Fin_C_m1_Remind_var;
rename ifpaid=target;
run;


proc export data=dt.C_M1_MODEL_SAMPLE01
outfile='.\excel\C_M1_MODEL_SAMPLE01.csv'
dbms=csv replace;
run;



/*
data Card_all_cm1;
set dt.Fin_c_m1_list_201706;

keep Ever_frs_dlqday
Trd_OutClass_RE
Trd_OutClass_PTP
Fst_OutClass_SQM
Fst_OutClass_EM
Apply_loan_intv
Init_sumOverdueAmt
ifpaid;
rename ifpaid=target;
run;


proc export data=  Card_all_cm1
outfile='.\excel\Card_all_cm101.csv'
dbms=csv replace;
run;
