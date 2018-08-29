%inc ".\#00.OPTION.SAS";

/* merge act */

proc sort data= dt.Fin_c_m1_list_201706   out=  Fin_c_m1_list    nodupkey;
by memberid;
run;


/* merge two */

proc sort data= bck.Remind_tag_table_0806   out=  
Remind_tag_table  (keep=Ever_frs_dlqday
Trd_OutClass_RE
Trd_OutClass_PTP
Fst_OutClass_SQM
Fst_OutClass_EM
memberid)
nodupkey;
by memberid;
run;
proc sort data=Fin_ifpaid;
by memberid;
run;


data Fin_C_m1_All06 ;
merge    Fin_c_m1_list(in=a)  Remind_tag_table(in=b);
by memberid;
match_CM1=10*a+b;
if a;


keep 
memberid
Ever_frs_dlqday
Trd_OutClass_RE
Trd_OutClass_PTP
Fst_OutClass_SQM
Fst_OutClass_EM
Apply_loan_intv
Init_sumOverdueAmt
ifpaid;
rename ifpaid=target;
run;


proc freq data=  Fin_C_m1_All06 ;
title "match_CM1";
tables  match_CM1/missing norow nocol;
run;


proc export data= Fin_C_m1_All06
outfile='.\excel\Fin_C_m1_All06.csv'
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
