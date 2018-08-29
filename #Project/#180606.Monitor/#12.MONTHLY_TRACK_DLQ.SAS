%inc ".\#00.OPTION.SAS";

data Bt_post_info;
set bt.Bt_post_info_&tday.;
where channelType="C001" and loan_mth>="201605";  /* jf only */
run;


%let updatemth=201805
;
%let type=C001
;
%let name=JF
;



proc sort data=Bt_post_info out= Bt_post_info_srt(
keep=memberid orderno  mob Merchant_type loan_day loan_mth totalNum  new_dlq_mthend loanamount Due_amt queue FLAG_RETURN) ;
by memberid  loan_day orderno mob Merchant_type;
run;

/*============== 事业部首次逾期 ==============*/
data Bt_post_frs;
set Bt_post_info_srt;
by memberid  loan_day orderno mob Merchant_type;
if first.orderno then output;
run;

proc sql;
create table First_Due_Merchant as
select	loan_mth,Merchant_type,

		/* # */
		count(distinct memberId) as T_cnt,
   		count(distinct case when new_dlq_mthend>=1 then  memberId end) as T_dlq,
		count(distinct case when 31>new_dlq_mthend>=11 then  memberId end) as T11_31,
		count(distinct case when 11>new_dlq_mthend>=4  then  memberId end) as T4_11,
		count(distinct case when 4>new_dlq_mthend>=1 then  memberId end) as T1_4,
				
		(calculated T_dlq)/(calculated T_cnt) as T_dlq_Rate format percent9.2,
		(calculated T11_31)/(calculated T_cnt) as T_11Rate format percent9.2,
		(calculated T4_11)/(calculated T_cnt) as T_4Rate format percent9.2,
		(calculated T1_4)/(calculated T_cnt) as T_1Rate format percent9.2,
		
		/* $ */
		sum(loanamount) as T_amt format comma12.2,
   		sum( case when new_dlq_mthend>=1 then      loanamount end)  as T_dlqAMT format comma12.2,
		sum( case when 31>new_dlq_mthend>=11 then  loanamount end)  as T11_31AMT format comma12.2,
		sum( case when 11>new_dlq_mthend>=4 then   loanamount end) as T4_11AMT format comma12.2,
		sum( case when 4>new_dlq_mthend>=1  then   loanamount end) as T1_4AMT format comma12.2,
		
			
		(calculated T_dlqAMT)/(calculated T_amt) as T_dlqAmtRate format percent9.2,
		(calculated T11_31AMT)/(calculated T_amt) as T_11_AmtRate format percent9.2,
		(calculated T4_11AMT)/(calculated T_amt) as T_4_AmtRate format percent9.2,
		(calculated T1_4AMT)/(calculated T_amt) as T_1_AmtRate format percent9.2

from Bt_post_frs  
where FLAG_RETURN^=-9
group by loan_mth,Merchant_type
order by loan_mth,Merchant_type
;
quit;



/*proc freq data=Bt_post_frs  ;*/
/*tables merchant_type*totalnum/missing;*/
/*run;*/

/*================前M期曾经有过X次逾期 ==============*/

data Bt_post_order_cnt;
set Bt_post_info_srt;
by memberid loan_day orderno  mob ;
/*where flag_return^=-9;*/

retain DLQ ;
if first.orderno then dlq=0;
if new_dlq_mthend>0 then dlq+1;

Month_intv=intck("month",input(loan_day,yymmdd8.),input("&tday.",yymmdd8.));

if Month_intv>=3 and mob<=3 and dlq>=2 then EVER_3M2=1;else EVER_3M2=0;
if Month_intv>=6 and mob<=6 and dlq>=2 then EVER_6M2=1;else EVER_6M2=0;
if Month_intv>=6 and mob<=6 and dlq>=3 then EVER_6M3=1;else EVER_6M3=0;
run;



proc sql;
create table BT_EVER_status as
select distinct memberid,orderno,loan_mth,Merchant_type,loanamount ,Month_intv,
 		max(EVER_3M2) as EVER_3M2, max(EVER_6M2) as EVER_6M2,max(EVER_6M3) as EVER_6M3
from  Bt_post_order_cnt
group by  memberid,orderno,loan_mth,Merchant_type
order by  memberid,orderno,loan_mth,Merchant_type
;
quit;


proc sql;
create table BT_EVER_DLQ as
select  loan_mth, Merchant_type, 
	/* # */
	count(distinct orderno) as Total_Order_cnt,
/*	count(distinct case when Month_intv>=3 then orderno end ) as Valid_3M_cnt,*/
/*	count(distinct case when Month_intv>=6 then orderno end ) as Valid_6M_cnt,*/

	count(distinct case when (Month_intv>=3 and EVER_3M2=1) then orderno end) as Ever_3M2_cnt,
	count(distinct case when (Month_intv>=6 and EVER_6M2=1) then orderno end) as EVER_6M2_cnt,
	count(distinct case when (Month_intv>=6 and EVER_6M3=1) then orderno end) as EVER_6M3_cnt,
	
	(calculated Ever_3M2_cnt)/ (calculated Total_Order_cnt) as Ever_3M2_pct format percent9.2,
	(calculated EVER_6M2_cnt)/ (calculated Total_Order_cnt) as Ever_6M2_pct format percent9.2,
	(calculated EVER_6M3_cnt)/ (calculated Total_Order_cnt) as EVER_6M3_pct format percent9.2,


    /* $ */
	sum(loanAmount) as Total_loan_amt format comma16.2,
/*  sum( case when Month_intv>=3   then loanAmount end) as Valid_3M_amt format comma16.2,*/
/*	sum( case when Month_intv>=6   then loanAmount end) as Valid_6M_amt format comma16.2,*/
	
	sum(case when (Month_intv>=3 and EVER_3M2=1) then loanAmount end) as Ever_3M2_amt format comma16.2,
	sum(case when Month_intv>=6 and EVER_6M2=1 then   loanAmount end) as EVER_6M2_amt format comma16.2,
	sum(case when Month_intv>=6 and EVER_6M3=1 then   loanAmount end) as EVER_6M3_amt format comma16.2,

	(calculated Ever_3M2_amt)/ (calculated Total_loan_amt) as Ever_3M2_amtpct format percent9.2,
    (calculated EVER_6M2_amt)/ (calculated Total_loan_amt) as Ever_6M2_amtpct format percent9.2,
    (calculated EVER_6M3_amt)/ (calculated Total_loan_amt) as Ever_6M3_amtpct format percent9.2


from    BT_EVER_status  
group by loan_mth,Merchant_type
order by loan_mth,Merchant_type
;
quit;



/*===============================================================================================================================*/
/* 当前逾期队列 */
 %put &tday.;
proc sort data=    Bt_post_info  ;
where  channelType="&type.";
by  memberId orderno mob ;
run;

data  post_queue1;
set Bt_post_info (
keep= memberid orderno mob due_amt loanamount flag_return channelType queue loan_mth Merchant_type
repayStatus  orderStatus   new_repaydate  PAYDAY_NUM   new_dlq_mthend    new_payamt  payamt  new_principal principal
);
by  memberId orderno mob ;
where flag_return^=-9 
and substr(put(new_repaydate,yymmddn8.),1,6)<substr("&tday.",1,6);

if last.orderno then output; /* 最新一期 loan_mth<substr("&tday.",1,6)  */
run;

/*proc freq data=post_queue1;*/
/*where loan_mth>='201802';*/
/*tables loan_mth*new_repaydate/missing;*/
/*run;*/


PROC SQL;
CREATE TABLE   QUEUE_all as 
SELECT 
	   loan_mth,Merchant_type, 
	  
	  /* # 笔数 - 包含逾期还款*/	
	  count(distinct memberid) as In_member_cnt,
	  count(distinct orderno) as In_order_cnt,
	  /* $ 放款金额 */
	  sum( loanamount )  as In_Loan_amt format comma13.2 

from ( 	select distinct memberid,orderno,loanamount,loan_mth,Merchant_type 
from  Bt_post_info
where repayStatus=1 and orderStatus in("1","3")  /* valid to pay */
)
group by  loan_mth,Merchant_type
order by  loan_mth,Merchant_type
;
quit;

PROC SQL;
CREATE TABLE   QUEUE_dlq as 
SELECT 
	   loan_mth,Merchant_type, queue , 
	  
	  /* # 笔数 - 包含逾期还款*/	
	  count(case when flag_return=1 then orderno end) as Dlq_order_dlq,

	  /* $ 放款金额 */
	  sum( due_amt ) as DUE_AMT  format comma13.2

from   post_queue1
where  repayStatus=1 and orderStatus in("1","3") and queue^='C'

group by  loan_mth,Merchant_type,queue 
order by  loan_mth,Merchant_type,queue
;
quit;

PROC SQL;
CREATE TABLE   POST_QUEUE as 
SELECT 
	   a.*, b.queue, b.Dlq_order_dlq ,  b.DUE_AMT,
		b.Dlq_order_dlq/In_order_cnt as Dlq_order_pct format percent10.2,
		b.DUE_AMT/In_Loan_amt as Due_amt_pct format percent10.2  
	

from  QUEUE_all as a inner join  QUEUE_dlq as b
	on a.loan_mth = b.loan_mth   and a.Merchant_type=b.Merchant_type
/*group by  loan_mth,Merchant_type,queue */
order by  loan_mth,Merchant_type,queue
;
quit;




/* cnt pct */
proc sort data=POST_QUEUE  out= QUEUE_cnt(keep= loan_mth Merchant_type queue In_order_cnt Dlq_order_pct  );
by  loan_mth Merchant_type In_order_cnt;
run;
proc transpose data=QUEUE_cnt out=BT_QUEUE_cnt_tps;
by  loan_mth Merchant_type In_order_cnt;
id  queue  ;
var  Dlq_order_pct;
run;

data  &name._QUEUE_CNT_PCT;
retain 
Loan_mth Merchant_type  In_order_cnt  M0_M1 M1_M2 M2_M3 M3_M4 M4_M5 M5_M6 M6_M7 M7_M8 M8_M9  M9_M10 M10_;
set BT_QUEUE_cnt_tps(drop=_NAME_  );

run;


/* amt pct */
proc sort data=POST_QUEUE  out= QUEUE_amt(keep= loan_mth Merchant_type queue In_Loan_amt  Due_amt_pct  );
by  loan_mth Merchant_type In_order_cnt;
run;
proc transpose data=QUEUE_amt out=BT_QUEUE_amt_tps;
by  loan_mth Merchant_type In_Loan_amt;
id  queue  ;
var  Due_amt_pct;
run;

data &name._QUEUE_AMT_PCT;
retain 
Loan_mth Merchant_type  In_Loan_amt  M0_M1 M1_M2 M2_M3 M3_M4 M4_M5 M5_M6 M6_M7 M7_M8 M8_M9  M9_M10 M10_;
set BT_QUEUE_AMT_tps(drop=_NAME_  );

run;

%inc ".\#00.OPTION.SAS";

proc sql;
create table Principal_remain as
select 
 
loanTime,
CASE WHEN bigMerchantId='20160001' THEN 'TOUR_INT'
		 	WHEN bigMerchantId='20160007' THEN 'FLIGHT'
			WHEN bigMerchantId='20160006' THEN 'TOUR_DMS'
			WHEN bigMerchantId='20160002' THEN 'TRAIN'
			WHEN bigMerchantId='20160005' THEN 'CRUISE'
			else  'OTHER'  end as Merchant_type
,
sum(loan_amt) as loan_amt ,
sum(case when   c.isOverdue1= 0  then c.max_benjin end ) as M0,
sum( case when c.max_yuqitianshu > 0  and c.max_yuqitianshu<= 30  and c.isOverdue1= 1 then c.max_benjin end) as M1,
sum( case when c.max_yuqitianshu > 0  and c.max_yuqitianshu<= 60  and c.isOverdue1= 1 then c.max_benjin end) as M2,
sum( case when c.max_yuqitianshu > 0  and c.max_yuqitianshu<= 90  and c.isOverdue1= 1 then c.max_benjin end) as M3,
sum( case when c.max_yuqitianshu > 0  and c.max_yuqitianshu<= 120  and c.isOverdue1= 1 then c.max_benjin end) as M4,
sum( case when c.max_yuqitianshu > 0  and c.max_yuqitianshu<= 150  and c.isOverdue1= 1 then c.max_benjin end) as M5,
sum( case when c.max_yuqitianshu > 0  and c.max_yuqitianshu<= 180  and c.isOverdue1= 1 then c.max_benjin end) as M6,
sum( case when c.max_yuqitianshu > 0  and c.max_yuqitianshu<= 210  and c.isOverdue1= 1 then c.max_benjin end) as M7,
sum( case when c.max_yuqitianshu > 0  and c.max_yuqitianshu<= 240  and c.isOverdue1= 1 then c.max_benjin end) as M8,
sum( case when c.max_yuqitianshu > 0  and c.max_yuqitianshu<= 270  and c.isOverdue1= 1 then c.max_benjin end) as M9,
sum( case when c.max_yuqitianshu > 270    and c.isOverdue1= 1 then c.max_benjin end) as M10


from
(
  select a.memberId,   sum(distinct b.loanAmount) as loan_amt,
  		put(datepart(b.ordertime),yymmn6.) as loanTime,
		sum((a.remainPrincipal)/100) as max_benjin,
		max(a.overdueNum) as max_yuqitianshu,
		max(a.isOverdue) as isOverdue1,bigMerchantId

		


  from ins.RepaySchedule as a
  	left join fq_data.OrderInfo as b on a.orderNo=b.orderNo
	where   b.orderStatus^="0" and a.repayStatus^=3  and a.orderType=2  and b.orderType="1"  and b.channelType='C001' 
 	group by a.memberId,a.orderno,put(datepart(b.ordertime),yymmn6.) , bigMerchantId
 ) as c
 
 group by loanTime,Merchant_type
order by  loanTime desc;

quit;




/* cnt pct */
%MACRO A;
%LET TABLE=  Principal_remain  Jf_queue_cnt_pct  Jf_queue_amt_pct First_due_merchant 							
;

%do i=1 %to 4;
 %let mname=%scan(&TABLE,&i," ");	   /* %scan(&text,&i,&delim) */
 %put &mname.;

 PROC EXPORT DATA=  &mname.
            OUTFILE= ".\REPORT\&mname._&updatemth..xlsx" 
            DBMS=EXCEL REPLACE;
     SHEET="&mname."; 
RUN;


%end;



%mend;
%a;











endsas;



/* all merchant */

PROC SQL;
CREATE TABLE   QUEUE_all_mer as 
SELECT 
	   loan_mth, 
	  
	  /* # 笔数 - 包含逾期还款*/	
	  count(distinct memberid) as In_member_cnt,
	  count(distinct orderno) as In_order_cnt,
	  /* $ 放款金额 */
	  sum( loanamount )  as In_Loan_amt format comma13.2 

from ( 	select distinct memberid,orderno,loanamount,loan_mth,Merchant_type 
from  Bt_post_info
where repayStatus=1 and orderStatus in("1","3")  /* valid to pay */
)
group by  loan_mth 
order by  loan_mth 
;
quit;

PROC SQL;
CREATE TABLE   QUEUE_dlq_mer as 
SELECT 
	   loan_mth,  queue , 
	  
	  /* # 笔数 - 包含逾期还款*/	
	  count(case when flag_return=1 then orderno end) as Dlq_order_dlq,

	  /* $ 放款金额 */
	  sum( due_amt ) as DUE_AMT  format comma13.2

from   post_queue1
where  repayStatus=1 and orderStatus in("1","3") 

group by  loan_mth ,queue 
order by  loan_mth ,queue
;
quit;

PROC SQL;
CREATE TABLE   POST_QUEUE_mer as 
SELECT 
	   a.*, b.queue, b.Dlq_order_dlq ,  b.DUE_AMT,
		b.Dlq_order_dlq/In_order_cnt as Dlq_order_pct format percent10.2,
		b.DUE_AMT/In_Loan_amt as Due_amt_pct format percent10.2  
	

from  QUEUE_all_mer as a inner join  QUEUE_dlq_mer as b
	on a.loan_mth = b.loan_mth    
/*group by  loan_mth,Merchant_type,queue */
order by  loan_mth, queue
;
quit;

/* all */
proc sort data=POST_QUEUE_mer  out= POST_QUEUE_ALLMER_DUE(keep= loan_mth   queue In_Loan_amt  Due_amt  );
by  loan_mth   In_Loan_amt;
run;
proc transpose data=POST_QUEUE_ALLMER_DUE 	out= POST_QUEUE_ALLMER_DUE_tps;
by  loan_mth   In_Loan_amt;
id  queue  ;
var  Due_amt;
run;

data &name._POST_QUEUE_ALLMER_DUE_tps;
retain 
Loan_mth    In_Loan_amt  M0_M1 M1_M2 M2_M3 M3_M4 M4_M5 M5_M6 M6_M7 M7_M8 M8_M9  M9_M10 M10_;
set POST_QUEUE_ALLMER_DUE_tps(drop=_NAME_ c);

run;


/* queue divide */

PROC SQL;
CREATE TABLE   POST_QUEUE_q1 as 
SELECT 
	   a.*, b.queue, b.Dlq_order_dlq ,  b.DUE_AMT,
		b.Dlq_order_dlq/In_order_cnt as Dlq_order_pct format percent10.2,
		b.DUE_AMT/In_Loan_amt as Due_amt_pct format percent10.2  
	

from  QUEUE_all as a inner join  QUEUE_dlq as b
	on a.loan_mth = b.loan_mth   and a.Merchant_type=b.Merchant_type
/*group by  loan_mth,Merchant_type,queue */
order by  loan_mth,Merchant_type,queue
;
quit;


PROC SQL;
CREATE TABLE   POST_QUEUE_q2 as 
SELECT 
	   loan_mth, queue ,  
		sum(In_Loan_amt) as In_Loan_amt format comma12.2,
		sum(DUE_AMT) as DUE_AMT format comma12.2,
		case when queue='C' then 0
			 when queue='M0-M1' then 1
			 when queue='M1-M2' then 2
			 when queue='M2-M3' then 3
			 when queue='M3-M4' then 4
			 when queue='M4-M5' then 5
			 when queue='M5-M6' then 6
			 when queue='M6-M7' then 7
			 when queue='M7-M8' then 8
			 when queue='M8-M9' then 9
			 when queue='M9-M10' then 10
			 when queue='M10+' then 11
			 else 99 end as queuenum
	

from  POST_QUEUE_q1
	 
group by  loan_mth, queue 
order by  loan_mth, queuenum
;
quit;



/*
PROC EXPORT DATA=  POST_QUEUE_q2
            OUTFILE= ".\POST_QUEUE_1805.XLSX" 
            DBMS=EXCEL REPLACE;
     SHEET="POST_QUEUE1805"; 
RUN;


proc sort data=POST_QUEUE_q2  out= POST_QUEUE_q2_DUE ;
by  loan_mth   queuenum;
run;
proc transpose data=POST_QUEUE_q2_DUE 	out= POST_QUEUE_q2_DUE_tps;
by  loan_mth   ;
id  queue    ;
var  In_Loan_amt Due_amt;
run;

data &name._POST_QUEUE_q2_DUE_tps;
retain 
Loan_mth    In_Loan_amt  M0_M1 M1_M2 M2_M3 M3_M4 M4_M5 M5_M6 M6_M7 M7_M8 M8_M9  M9_M10 M10_;
set POST_QUEUE_q2_DUE_tps(drop=_NAME_  );

run;
