%INC  ".\#00.OPTION.SAS";
options user=work;


/*==========================================ORDER+REPAY========================================*/
/* order */

proc sort data= bck.cashorderinfo_&tday. 
out= work.orderinfo_&tday. ;
WHERE orderType= 1 ;    /*	1-cash	and orderStatus=2*/
by  memberid orderNo;
run;


/* repay */
data work.repayschedule_&tday.;
set  bck.repayschedule_&tday.;

WHERE orderType=1;  /* cash */
length orderno1 $56. memberid1 $56.;

orderno1=compress(orderno);
memberid1=compress(memberid);


drop orderno memberid ;
rename 	orderno1=orderno  memberid1=memberid 	orderType=repay_orderType	;
run;
proc sort data= repayschedule_&tday.  ;
/*where REPAYSTATUS^=3  ;*/
by  memberid orderNo;
run;


/* 	order+repay	  */
data  order_pay;
merge orderinfo_&tday.(in=a )   repayschedule_&tday. (in=b);
by 	memberid orderno;
length bankname1 $30.;

if  a;    
Match_repay=10*a+b;

bankName1=compress(bankName);
drop bankName ;
rename bankName1=bankName ;
run;


proc freq data= order_pay;
title " Match_repay ";
tables 	  Match_repay/missing norow nocol;
run;



/*==========================================TAG POST========================================*/
proc sort data=bck.loanbill_&tday. out= loanbill  ;
where  deleted=0  ;
by  memberid;
run;


/* loan_bill */
/* 有贷后表现的 */	
proc sql;
create table  applyorder_repay as
select a.*,
		b.loanAmount as loan_amt,
		b.loanDate as  loan_date,
		b.acctTempId as loan_acctTempId
		

from order_pay as a left join  loanbill as b
	on 	a.memberid=b.memberid  and a.orderno=b.orderno
			
			
where  Match_repay=11 and a.deleted=0  and b.deleted=0  

order by  a.memberid, a.orderno , a.repayDate , a.payDate

 ;
quit;

proc sql;
create table  apply_order_pay as
select a.*,		
		c.memberlevel

from 	applyorder_repay	 as a 
			left join   dt.Cash_apply_info_&tday. as c    /*===========use apply info for memberlevel==========*/
				on a.memberid= c.memberid
		
order by  a.memberid, a.orderno , a.repayDate , a.payDate

 ;
quit;






/*================================*/
%let Month_begin=1;
%let Month_mid=14;

/* FDQ */ 

DATA APPLY_ORDER_PAY_CAL;
SET  apply_order_pay ;
BY MEMBERID ORDERNO  REPAYDATE PAYDATE;

length BILLDAY_NUM 8.    BILL_DAY1 $15.    LoanMonth_Half $40.;

IF FIRST.ORDERNO THEN BILL_NUM=0 ;/* FST */
BILL_NUM+1;

	/* ordertime ~=loan_date */
	if not missing(loan_date) then loanDate=loan_date; else loanDate=.;

	if not missing(loanDate) then do;
	Loan_day=put(loanDate,yymmddn8.);   /* no datepart */
	Loan_mth= PUT(loanDate,YYMMN6.);
	end;

	else do;
	Loan_day="Missing";
	Loan_mth= "Missing";
	end;


	/* billday */
	
	if Loan_day^="Missing" then 	Bill_day=substr(compress(Loan_day),7,2); else Bill_day=".";
	IF BILL_DAY IN ("28","29","30","31") THEN BILL_DAY1="28";
		ELSE  BILL_DAY1=BILL_DAY;
	if BILL_DAY1^="." then BILLDAY_NUM=BILL_DAY1+0; else BILLDAY_NUM=.;


	REPAYDATE_NUM= INPUT( PUT(REPAYDATE,YYMMDDN8.),YYMMDD8.);
	IF MISSING(PAYDATE) THEN PAYDAY_NUM=.;
	ELSE PAYDAY_NUM=  INPUT(  PUT(DATEPART(PAYDATE),YYMMDD8.),YYMMDD8.);

	IF 		&Month_begin<= BILLDAY_NUM <= &Month_mid  then 
			LoanMonth_Half=catt(Loan_mth,"上半月");    		/*账单日在上半月的*/
	else if   &Month_mid<= BILLDAY_NUM  then 
			LoanMonth_Half=	catt(Loan_mth,"下半月");   		 /*账单日在下半月的*/
		
	
	/*观察日状态*/
	IF 	PAYDAY_NUM=. AND  REPAYDATE_NUM-INPUT("&TDAY.",YYMMDD8.)>0 THEN FLAG_RETURN=-9; /*未到账单日-未还款*/
	else if  not missing(PAYDAY_NUM) and PAYDAY_NUM<REPAYDATE_NUM  then  FLAG_RETURN=-1 ;  /* 提前还款 */
 	else if  missing(PAYDAY_NUM) and INPUT("&TDAY.",YYMMDD8.)>=REPAYDATE_NUM  then   FLAG_RETURN=1;    /* 未还款-包括当天   */
	else if  INPUT("&TDAY.",YYMMDD8.)>=REPAYDATE_NUM  and PAYDAY_NUM>REPAYDATE_NUM
				  then  FLAG_RETURN=9;	/*  逾期还款 */
	else if  INPUT("&TDAY.",YYMMDD8.)>=REPAYDATE_NUM  and PAYDAY_NUM=REPAYDATE_NUM
				  then  FLAG_RETURN=0;	/* 当天正常还款 */
	else     FLAG_RETURN=99999 ;   /* 其他情况 */


	/*观察日逾期天数*/
	IF flag_return in(-1,0) then Dlqday_mth=0;
	Else if   flag_return =1  then Dlqday_mth= INPUT(COMPRESS(&TDAY.),YYMMDD8.)- REPAYDATE_NUM;
	Else if   flag_return =9  then Dlqday_mth= PAYDAY_NUM - REPAYDATE_NUM;	   /*  逾期还款 */
	else if	  flag_return =-9 then Dlqday_mth=99999;	   /*  数据未更新 */
	Else      Dlqday_mth= -99999 ;   /* 其他情况 */

	/* month vars */
	MONTHEND=intnx("month",REPAYDATE_NUM,0,"e");

	MONTHBEG=intnx("month",REPAYDATE_NUM,0,"b");

	INTC_MTHEND= intck("day",REPAYDATE_NUM,MONTHEND);
	MTH_DAYS= intck("day",MONTHBEG,MONTHEND)+1;
	

FORMAT PAYDAY_NUM YYMMDDN8.	REPAYDATE_NUM YYMMDDN8.  MONTHEND yymmddn8. MONTHBEG yymmddn8.;
DROP BILL_DAY;
RENAME BILL_DAY1=BILL_DAY;
run;

proc freq data=APPLY_ORDER_PAY_CAL;
tables Loan_mth*flag_return/missing norow nocol;
run;


/*================================PATCH FOR DLQ_DAYS CAL ===============================*/

proc sort data= APPLY_ORDER_PAY_CAL out=APPLY_ORDER_PAY_NDP  dupout= APPLY_ORDER_PAY_dpot nodupkey ; /*重复键 忽略 */
title "去重检测 ";
by memberId  orderno    repayDate  Loan_mth;
run;

proc sql;
create table dlqpatch as
select memberid, orderno,repaydate   ,Loan_mth,
		max(case when FLAG_RETURN in(1,9) then Dlqday_mth else 0  end) as FLAG_DLQDAY_max /*  距统计日最大逾期天数 */
from   APPLY_ORDER_PAY_NDP
group by orderno,FLAG_RETURN
order by memberId, orderno, repayDate,Loan_mth
;
quit;




data  APPLY_ORDER_DLQ4 ;
merge  APPLY_ORDER_PAY_NDP   dlqpatch;
by memberId orderno   repayDate   Loan_mth;

retain Pay_Dlqnum Pay_Dlqnum1;

Stats_day= INPUT(COMPRESS(&TDAY.),YYMMDD8.);

	
char_repay=put(REPAYDATE_NUM,yymmn6.);
if not missing(PAYDAY_NUM) then char_payday=put(PAYDAY_NUM,yymmn6.);
else char_payday=".";


Pay_lag=lag(PAYDAY_NUM);
if first.orderno then Pay_lag=.;


/* flag=1 未还款 */
if first.orderno  then Pay_Dlqnum=0;
if missing(paydate) then Pay_Dlqnum+1;


/* flag=9 逾期还款 */
	if first.orderno  then Pay_Dlqnum1=0;
	if flag_return in(1,9) then do;
		if   char_repay = char_payday then Pay_Dlqnum1=0;  /*同月内还清 则清零*/


		 
		else if ( Pay_lag<=REPAYDATE_NUM 	or  put(REPAYDATE_NUM,yymmn6.) = put(Pay_lag,yymmn6.) )
		and  not missing(PAYDAY_NUM)    
		and  char_repay<char_payday  then do; /*跨月   先清零在计数      */
				Pay_Dlqnum1=0;
				Pay_Dlqnum1+1;
				end;

		else if Pay_lag>REPAYDATE_NUM  then  Pay_Dlqnum1+1;
		else if Pay_Dlqnum1>0 and missing(PAYDAY_NUM) then Pay_Dlqnum1+1;   /*逾期还款又开始持续逾期的*/
		else if flag_return=1 then Pay_Dlqnum1=.;  
		else Pay_Dlqnum1=99999;				/*未考虑情况存在与否*/
	end;
	
	else  	Pay_Dlqnum1=0;
		 

	if last.orderno then Pay_lag=.;


format Stats_day yymmddn8. Pay_lag yymmddn8.;



/*keep  memberId  orderno    repayDate  Loan_mth   REPAYDATE_NUM  PAYDAY_NUM  MTH_DAYS Pay_Dlqnum*/
/*Pay_Dlqnum1 Pay_lag BILL_NUM Dlqday_mth FLAG_DLQDAY_max flag_return INTC_MTHEND   char_repay  char_payday*/
/*;*/

run;



data  APPLY_ORDER_DLQ5;
set  APPLY_ORDER_DLQ4  ;
by memberId orderno  repayDate  Loan_mth;
retain DLQ_D1 DLQ_D9;


if first.orderno then do;
	DLQ_D1=0;
	DLQ_D9=0;
	end;

if flag_return=1 then do;
 	if Pay_Dlqnum=1 then DLQ_D1=INTC_MTHEND;
	
	else  DLQ_D1=DLQ_D1+MTH_DAYS;
end;	

if flag_return in(1,9) then do;
	if  Pay_Dlqnum1=0 and put(REPAYDATE_NUM,yymmn6.)=  put(PAYDAY_NUM,yymmn6.)  then DLQ_D9=intck("day",REPAYDATE_NUM,PAYDAY_NUM);
	
/*	else if Pay_Dlqnum1=1 and INTC_MTHEND=0 then DLQ_D9=INTC_MTHEND+1;	 */

	else if Pay_Dlqnum1=0 and intck("month",REPAYDATE_NUM,PAYDAY_NUM)>=1  then DLQ_D9=INTC_MTHEND;
	else if Pay_Dlqnum1=1 and INTC_MTHEND^=0 then DLQ_D9=INTC_MTHEND;  /*非月末*/
	else if Pay_Dlqnum1=1 and INTC_MTHEND=0 then DLQ_D9=INTC_MTHEND+1;	 /*月末*/
	else if Pay_Dlqnum1>1 then DLQ_D9=DLQ_D9+MTH_DAYS;

end;	
else DLQ_D9=0;


/*keep  memberId  orderno    repayDate  Loan_mth   REPAYDATE_NUM  PAYDAY_NUM  MTH_DAYS   char_repay  char_payday*/
/*Pay_Dlqnum1 Pay_lag BILL_NUM Dlqday_mth FLAG_DLQDAY_max flag_return INTC_MTHEND  DLQ_D1 DLQ_D9  */
/*;*/

run;



data  CASH_ORDER_PAY_&TDAY.;
set APPLY_ORDER_DLQ5;
 

	/* DLQ_DAYS */
	if flag_return=1 and dlq_d1>dlq_d9  then Dlqday_mthend=dlq_d1;

	else if flag_return=1 and dlq_d1<=dlq_d9  then Dlqday_mthend=dlq_d9;

	else if flag_return=9 and  put(REPAYDATE_NUM,yymmn6.)=put(PAYDAY_NUM,yymmn6.)   then Dlqday_mthend= 0;
	ELSE IF flag_return=9    then Dlqday_mthend=dlq_d9;
	else Dlqday_mthend=Dlqday_mth;

/*keep  memberId  orderno    repayDate  Loan_mth   REPAYDATE_NUM  PAYDAY_NUM  MTH_DAYS
Pay_Dlqnum1 Pay_lag BILL_NUM Dlqday_mth FLAG_DLQDAY_max flag_return Dlqday_mthend INTC_MTHEND  DLQ_D1 DLQ_D9 totalnum
;
*/
 
run;



/*================================DLQ_DAYS CAL END================================*/
proc contents data=	 CASH_ORDER_PAY_&TDAY.;
run;




proc freq data=   CASH_ORDER_PAY_&TDAY.;
tables flag_return*memberlevel/missing;
run;

proc sort data=    CASH_ORDER_PAY_&TDAY.   out= dt.CASH_ORDER_PAY_&TDAY.;
by memberid orderno loan_mth REPAYDATE_NUM;
run;




