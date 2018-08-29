%inc ".\#00.OPTION.SAS";

proc sort data=  dt.cash_order_pay_&TDAY.  out= cash_table  ;
by memberid orderno loan_mth bill_num;
run;
proc freq data=cash_table;
tables flag_return/missing norow nocol;
run;

data cash_filter	;
set cash_table	 ; /*(keep=&var. )*/
where orderStatus=2  and orderType= 1	 and repaystatus^=3;	 /* 订单状态2成功3失败1处理中4取消终止0初始化 */  
by memberid orderno loan_mth bill_num;

STAT_DAY=input("&tday.",yymmdd8.);

if last.orderno then do ;
Last_orderno=1;
Last_repayday=REPAYDATE_NUM;
end;

if flag_return in(1,9) then do;  /* new change*/
	if STAT_DAY >= REPAYDATE_NUM then do;
	 	if not missing(PAYDAY_NUM)  then MOB_DIF= intck("month",REPAYDATE_NUM,PAYDAY_NUM);
		else MOB_DIF= intck("month",REPAYDATE_NUM,STAT_DAY);
		end;
 end;
/*else MOB_DIF= 99999;*/


format REPAYDATE_NUM yymmddn8. Last_repayday  yymmddn8. STAT_DAY   yymmddn8.  ;
run;

/*
proc freq data=cash_filter;
tables MOB_DIF*flag_return/missing norow nocol;
run;
*/

/* 应扩展期数 */
proc sql;
create table mob_difmax as
select memberid,orderno,bill_num , MOB_DIF ,REPAYDATE_NUM,payday_num
from cash_filter
where orderno in(select distinct orderno 
from  cash_filter  
where Last_orderno=1 and flag_return in(1,9)  /* 订单最新一期是 1或者9 的*/
)
group by memberid,orderno
;
quit;

/* patch mob_dif --- max */
proc  sort data= mob_difmax  out= mob_difmax2 ;
by memberid orderno  descending bill_num     ;
run;
proc sort data= mob_difmax2 out= mob_difmax3 dupout=mob_difmax_dp nodupkey;
by memberid orderno;
run;

/* patch mob_dif end */						   
																			   
proc sql;
create table mob_difmax1 as
select a.memberid,a.orderno,a.mob_dif,a.bill_num,  
		case when a.mob_dif>0 then a.mob_dif+a.bill_num end as mob_difmax

from mob_difmax3 as a
	right join 
	(select memberid,orderno,max(MOB_DIF) as mob_difmax
	from mob_difmax3
	group by memberid,orderno) as b
	on a.memberid= b.memberid and a.orderno=b.orderno and a.mob_dif=b.mob_difmax
order by memberid,orderno
;
quit;

/*
proc freq data=mob_difmax1;
tables mob_difmax/missing norow nocol;
run;
*/

/* 拼回原表接入应扩展期数 */
proc sql;
create table cash_filter_exp as
select a.*,
		  b.mob_difmax as max_mobdif 
from cash_filter as a left join mob_difmax1 as b
	on a.memberid=b.memberid and a.orderno=b.orderno
	;
	quit;



/* 扩充逾期订单的MOB */
proc sort data=  cash_filter_exp(
  rename=(bill_num=mob)) out= cash_filter_exp1;
by memberid orderno mob;
run;

data cash_filter_exp2;
set cash_filter_exp1 ;
by memberid orderno mob;

	if last.orderno and not missing(max_mobdif) and flag_return in(1,9) then do;
		mob1=mob;
		do mob =mob1+1 to max_mobdif;   /*多一个账单*/
		output;
		end;
	end;


/*keep memberid orderno flag_return mob1 mob max_mobdif Dlqday_mthend REPAYDATE_NUM  PAYDAY_NUM  Loan_mth ;*/
run;


/* 重做标签账期日&&月末天数 */

data cash_filter_set;
set cash_filter_exp1    cash_filter_exp2;
by memberid orderno mob;
retain frs_repayday;
/* new_repayay */
	if first.orderno then frs_repayday= REPAYDATE_NUM  ;
	new_repaydate=intnx("month",frs_repayday,mob-1,"s");

	/* month vars */
	new_MONTHEND=intnx("month",new_repaydate,0,"e");

	new_MONTHBEG=intnx("month",new_repaydate,0,"b");

	NEW_INTC_MTHEND= intck("day",new_repaydate,new_MONTHEND);
	NEW_MTH_DAYS= intck("day",new_MONTHBEG,new_MONTHEND)+1;


format  frs_repayday yymmddn8.   new_repaydate yymmddn8. ;

/*keep memberid orderno flag_return mob1 mob max_mobdif    Loan_mth totalnum  Last_orderno*/
/*REPAYDATE_NUM  PAYDAY_NUM new_repaydate  Dlqday_mthend  NEW_INTC_MTHEND NEW_MTH_DAYS */
/*;*/
run;


/* set后去重*/
proc sort data=cash_filter_set out=cash_filter_set1 dupout=cash_filter_setdp nodupkey;
by memberid orderno mob;
run;



/*==========  new dlq_mthend day + new amt =============*/
data cash_filter_dlqday;
set cash_filter_set1;
by memberid orderno mob;
retain new_dlq_mthend	;
	
	/* new dlq_mthend day */
	if first.orderno then new_dlq_mthend=0 ;
	if flag_return in(1,9) and max_mobdif>0 and mob>mob1 and last_orderno=1 and not missing(mob1)   then do;
		new_dlq_mthend=new_dlq_mthend+NEW_MTH_DAYS;
		END;
	/* =============月末账单日 逾期天数补丁========= */

	ELSE new_dlq_mthend=Dlqday_mthend;
	if last.orderno and  not missing(payday_num)  then new_dlq_mthend=0;
	


	/*  amt */
	if missing(Last_orderno) and missing(mob1) then do;
		new_refund=refundTotalAmt;
		new_payamt=payamt;
		new_remainPrincipal= remainPrincipal;
		end;
	else if not missing(Last_orderno) and missing(mob1) then do;
		new_refund=refundTotalAmt;
		new_payamt=payamt;
		new_remainPrincipal= remainPrincipal;
		end;
	else  do;
		new_refund=0;
		new_payamt=0;
		new_remainPrincipal= 0;
		end;

	if	totalnum>=mob then new_principal=principal; else new_principal=0;


/**/
/*keep memberid orderno flag_return mob1 mob max_mobdif    Loan_mth totalnum  Last_orderno*/
/*REPAYDATE_NUM  PAYDAY_NUM new_repaydate  Dlqday_mthend  NEW_INTC_MTHEND NEW_MTH_DAYS  new_dlq_mthend*/
/*;*/


	drop  Pay_Dlqnum Pay_Dlqnum1 Pay_lag  ;

run;


/* amt + queue */
data  cash_dlqday;
set cash_filter_dlqday;
by memberid orderno mob;
retain Pay_Dlqnum Pay_Dlqnum1;
Pay_lag=lag(PAYDAY_NUM);

char_newrepay=put(new_repaydate,yymmn6.);
if not missing(PAYDAY_NUM) then char_payday=put(PAYDAY_NUM,yymmn6.);
else char_payday=".";




	/*new flag */	
	if first.orderno then Pay_lag=.;

	/* flag=1 */
	if first.orderno  then Pay_Dlqnum=0;
	if missing(PAYDAY_NUM) then Pay_Dlqnum+1;
	
	/* flag=9 逾期还款 */
	if first.orderno  then Pay_Dlqnum1=0;
	if flag_return in(1,9) then do;
		if    put(new_repaydate,yymmn6.)=put(PAYDAY_NUM,yymmn6.)  then Pay_Dlqnum1=0;  /*同月内还清 则清零*/
		 
		else if Pay_lag<=new_repaydate and not missing(PAYDAY_NUM) 
		and char_newrepay<char_payday then do; /*跨月   格式*/
				Pay_Dlqnum1=0;
				Pay_Dlqnum1+1;
				end;
		else if Pay_lag>new_repaydate  then  Pay_Dlqnum1+1;
		else if Pay_Dlqnum1>0 and missing(PAYDAY_NUM) then Pay_Dlqnum1+1;
		else if flag_return=1 then Pay_Dlqnum1=.;  
		else Pay_Dlqnum1=99999;				/*未考虑情况存在与否*/
	end;

	if last.orderno then Pay_lag=.;

/*keep memberid orderno flag_return  mob  Loan_mth totalnum  */
/*  principal payamt refundTotalAmt	new_principal new_refund new_payamt  */
/*REPAYDATE_NUM  PAYDAY_NUM new_repaydate  Dlqday_mthend   new_dlq_mthend   */
/*Pay_lag Pay_Dlqnum1 Pay_Dlqnum char_newrepay char_payday*/
/*;*/
format  Pay_lag yymmddn8.;
run;



/* due flag1 */
proc sql;
create table flag1 as
select *
from cash_dlqday
where orderno in (select distinct orderno
from cash_dlqday where flag_return=1)
;
quit;

data flag1amt1;
set flag1;
by memberid orderno mob;
retain Due_amt1;
	if first.orderno then Due_amt1=0;

	if Pay_Dlqnum=1 then  Due_amt1=   realLoanAmt-(mob-1)*new_principal;    /**realLoanAmt/
	if Pay_Dlqnum>=1 then Due_amt1=Due_amt1;

keep memberid orderno flag_return  mob  totalnum  
realLoanAmt 	new_principal   Due_amt1   
REPAYDATE_NUM  PAYDAY_NUM new_repaydate       new_dlq_mthend   
    Pay_Dlqnum 
;
run;


/* due flag9 */
proc sql;
create table flag9 as
select *
from cash_dlqday
where orderno in (select distinct orderno
from cash_dlqday where flag_return=9)
;
quit;

data flag9amt1;
set flag9;
by memberid orderno mob;
retain Due_amt9;
	if first.orderno then Due_amt9=0;

	if Pay_Dlqnum1=1 then  Due_amt9= realLoanAmt -(mob-1)*new_principal;
	if Pay_Dlqnum1>=1 then Due_amt9=Due_amt9;else if Pay_Dlqnum1=0 then Due_amt9=0;
	if last.orderno and new_dlq_mthend=0 then Due_amt9=0;

keep memberid orderno flag_return  mob  totalnum  
realLoanAmt 	new_principal   Due_amt9   
REPAYDATE_NUM  PAYDAY_NUM new_repaydate       new_dlq_mthend   
Pay_lag    Pay_Dlqnum1 
;
run;



/*proc freq data=cash_dlqday;*/
/*tables  /missing;*/
/*run;*/
data 	cash_dlqdayamt;
merge  cash_dlqday(in=a)   flag1amt1(in=b keep= memberid orderno mob  Due_amt1)  flag9amt1(in=c keep= memberid orderno mob  Due_amt9);
by memberid orderno mob;
if a;
Match_flag19=100*a+b*10+c;

if Pay_Dlqnum>=1 then Due_amt=Due_amt1/100;   /* due amt */
else if  flag_return=9 then Due_amt=Due_amt9/100;
else Due_amt=0;

format Due_amt comma12.2;
run;




/* export+merchant */



%let dropvar=   BILLDAY_NUM  DLQ_D1  DLQ_D9  Due_amt1 Due_amt9  FLAG_DLQDAY FLAG_DLQDAY_max 
INTC_MTHEND   Last_orderno  Last_repayday  MOB_DIF  MONTHBEG MONTHEND MTH_DAYS  
NEW_INTC_MTHEND   NEW_MTH_DAYS Pay_Dlqnum Pay_Dlqnum1  Pay_lag  Stats_day STAT_DAY
char_newrepay  char_payday  char_repay id  frs_repayday loanDate max_mobdif mob1
new_MONTHBEG  new_MONTHEND
  Match_flag19
;




data cash_dlqdayamt1;
set cash_dlqdayamt;
length   queue $10.    ;


 
	/* queue */
	if     		 new_dlq_mthend=0 then  Queue="C";
	else if 	30>=new_dlq_mthend>0 then Queue="M0-M1";
	else if 	60>=new_dlq_mthend>30 then Queue="M1-M2";
	else if 	90>=new_dlq_mthend>60 then Queue="M2-M3";
	else if 	120>=new_dlq_mthend>90 then Queue="M3-M4";
	else if 	150>=new_dlq_mthend>120 then Queue="M4-M5";
	else if 	180>=new_dlq_mthend>150 then Queue="M5-M6";
	else if 	210>=new_dlq_mthend>180 then Queue="M6-M7";
	else if 	240>=new_dlq_mthend>210 then Queue="M7-M8";
	else if 	270>=new_dlq_mthend>240 then Queue="M8-M9";
	else if 	300>=new_dlq_mthend>270 then Queue="M9-M10";
	else if 	 99999>new_dlq_mthend>300 then Queue="M10+";
	else if      new_dlq_mthend=99999   then Queue="未到期";
	else 		Queue="other";   /*其他情况 */

	
	label
	BILL_DAY ="账单日"
	Due_amt="增补账期月末逾期金额"
	Loan_mth ="放贷月" 
	 
	Queue ="增补账期月末逾期队列"
	mob="增补账期"
	num="原账期"
	new_dlq_mthend="增补账期月末逾期天数"
	Dlqday_mthend="月末逾期天数"
	
	;
	
	drop  &dropvar.   	match:
;
run;







/* new memberlevel && quota */
%inc ".\#00.OPTION.SAS";

proc sort data= Ins.InstalAcct out=InstalAcct
(keep= memberid  frozen  payable  totalquota riskquota risklevel  activetype
channelcode acctTempid accttype category  major  memberlevel  mobile crttime acctstatus
rename=(memberlevel=memberlevel_acct)) nodupkey; 
where deleted=0 and  acctType=2  ;
by memberid;

run;

proc sort data=cash_dlqdayamt1;
by memberid;
run;





data dt.cash_post_info_&tday.;
merge  cash_dlqdayamt1(in=a) 
		InstalAcct(in=b keep= memberid  totalquota  memberlevel_acct  channelcode accttype acctstatus activetype) ;
by memberid;
if a;
match_post=10*a+b;

/* 资金方渠道 */
length Customer_Pricing_Acct $6.;
	if memberlevel_acct in(3,11) 		 then  Customer_Pricing_Acct= 'A';		
	else if memberlevel_acct in( 7 , 12 )   then  Customer_Pricing_Acct= 'B';
	else if memberlevel_acct in( 15 )   then  Customer_Pricing_Acct= 'NB';
	else if memberlevel_acct in( 16 , 17 , 27 , 28 , 29 )   then    Customer_Pricing_Acct= 'B-';
	else if memberlevel_acct in( 14  ) then  Customer_Pricing_Acct= 'C-';
	else if memberlevel_acct in( 13 )  then   Customer_Pricing_Acct= 'C';
	
	/*
	if memberlevel_acct in(3,11) 		 then  Customer_Pricing_Acct= 'A';			
	else if memberlevel_acct in(7,12)   then  Customer_Pricing_Acct= 'B';
	else if memberlevel_acct in(15)   then    Customer_Pricing_Acct= 'NB';
	else if memberlevel_acct in(27, 28, 16 ) then  Customer_Pricing_Acct= 'B-';
	else if memberlevel_acct in(13 )  then   Customer_Pricing_Acct= 'C';
	else if memberlevel_acct in(14 )  then   Customer_Pricing_Acct= 'C-';
	
	*/
	
	
	else if memberlevel_acct=100 then Customer_Pricing_Acct='Imp';
	else  Customer_Pricing_Acct='Other';

run;

proc freq data=  dt.cash_post_info_&tday.;
tables match_post;
tables Customer_Pricing_Acct;

run;



proc contents data=  dt.cash_post_info_&tday.;
run;








