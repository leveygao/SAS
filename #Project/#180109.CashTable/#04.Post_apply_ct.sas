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

	if Pay_Dlqnum=1 then  Due_amt1=   realLoanAmt-(mob-1)*new_principal;    /*realLoanAmt*/
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



/* mthend_remainprincipal calculate patch*/

proc sort data=  cash_dlqdayamt    out=  cash_dlqdayamt1(
keep = memberid orderno flag_return  mob  Loan_mth loan_day totalnum   loan_amt
  remainPrincipal new_remainPrincipal principal 
  PAYDAY_NUM new_repaydate     new_dlq_mthend    );

by memberid loan_day orderno mob;
run;



data cash_dlqdayamt2;
set cash_dlqdayamt1 ;
by memberid loan_day orderno mob ;
/*where flag_return^=-9;*/
retain     cumsum_principal dlq_cnt;

if first.orderno  then  do;
cumsum_principal=0;
dlq_cnt=0;
end;

if new_dlq_mthend>0 and flag_return^=-9 then do;
dlq_cnt+1;
cumsum_principal=cumsum_principal+principal;
end;
else if new_dlq_mthend=0 then do;
dlq_cnt = 0;
cumsum_principal= 0;
end;
/*else if flag_return=-9 then do;*/
/*dlq_cnt=-999;*/
/*cumsum_principal=-999;*/
/*end;*/

run;



data cash_dlqdayamt3;
set cash_dlqdayamt2 ;
by memberid loan_day orderno mob ;

lag_dlq=lag(dlq_cnt);
retain mob_remainPrincipal;
if first.orderno  then  do;
lag_dlq=. ;
mob_remainPrincipal=loan_amt ;
end;

if dlq_cnt=0 and (lag_dlq=0 or  lag_dlq=. )  		then mob_remainPrincipal=mob_remainPrincipal-  principal ;
else if  dlq_cnt>0 and (lag_dlq=0 or  lag_dlq=. )   then mob_remainPrincipal=mob_remainPrincipal  ;
else if  dlq_cnt>0 and lag_dlq>0  then mob_remainPrincipal=mob_remainPrincipal  ;
else if  dlq_cnt=0 and lag_dlq>0  then mob_remainPrincipal=mob_remainPrincipal -  cumsum_principal ;
else   mob_remainPrincipal=-99999;


if   last.orderno and flag_return^=-9 and  new_dlq_mthend=0 then mob_remainPrincipal=0; 
run;



proc sort data=  cash_dlqdayamt3    ;
/*where flag_return^=-9;  */
/*100014984  100087267  101607663  */
by memberid loan_day orderno descending mob;
run;


/* advance clean*/
data cash_dlqdayamt4 ;
set cash_dlqdayamt3;
by  memberid loan_day orderno descending mob ;

retain temp_rmprin ;
lag_payday=lag(PAYDAY_NUM) ;

if first.orderno then do;
temp_rmprin = mob_remainPrincipal ;
lag_payday=.;
end;

if      PAYDAY_NUM<=lag_payday<new_repaydate and flag_return=-1 then  temp_remainPrincipal=temp_rmprin;else temp_remainPrincipal=.;

if not missing(temp_remainPrincipal) and temp_remainPrincipal^=. then  mthend_remainPrincipal=temp_remainPrincipal;
else mthend_remainPrincipal=mob_remainPrincipal;

format lag_payday yymmdd8.;
run;



proc means data=cash_dlqdayamt4 n max min p1 p10 p25 p50 p75 p90 ;
title "remainPrincipal";
var mob_remainPrincipal temp_remainPrincipal mthend_remainPrincipal ;
run;



proc sql;
create table  cash_dlqdayamt5 as
select a.*,
		b.mob_remainPrincipal  ,  b.mthend_remainPrincipal

from Cash_dlqdayamt as a left join  cash_dlqdayamt4 as b
	on a.memberid=b.memberid and a.orderno=b.orderno and a.mob=b.mob

order by memberid , loan_day , orderno , mob 
;
quit;



/* mthend_remainprincipal end*/



data cash_dlqdayamt_fin;
set cash_dlqdayamt5;
by memberid;

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
	 
	flag_return='当期还款状态'
	Queue ="增补账期月末逾期队列"
	mob="增补账期"
	num="原账期"
	new_dlq_mthend="增补账期月末逾期天数"
	Dlqday_mthend="月末逾期天数"
	mob_remainPrincipal = "增补账期月末剩余本金"
	mthend_remainPrincipal = "增补账期月末剩余本金(清贷)"
	;
	
	drop  &dropvar.   	match:
;
run;







/* new memberlevel && quota */

proc sort data= bck.instalacct_&tday. out=InstalAcct
(keep= memberid   totalquota riskquota  risklevel  activetype
channelcode acctTempid accttype category  major  memberlevel  mobile crttime 
rename=(memberlevel=memberlevel_acct)) nodupkey; 

where deleted=0 and  acctType=2  ;
by memberid;

run;


data  cash_post_info_merge ;
merge  cash_dlqdayamt_fin(in=a) 
		InstalAcct(in=b keep= memberid  totalquota  memberlevel_acct  channelcode accttype  activetype ) ;
by memberid;
if a;
match_post=10*a+b;

/* 资金方渠道 */
length Customer_Pricing_Acct $16.;
	if memberlevel_acct in(3,11) 		 then  Customer_Pricing_Acct= 'A';		
	else if memberlevel_acct in( 7 , 12 )   then  Customer_Pricing_Acct= 'B';
	else if memberlevel_acct in( 15 )   then  Customer_Pricing_Acct= 'NB';
	else if memberlevel_acct in( 16 , 17 , 27 , 28 , 29 )   then    Customer_Pricing_Acct= 'B-';
	else if memberlevel_acct in( 14  ) then  Customer_Pricing_Acct= 'C-';
	else if memberlevel_acct in( 13 )  then   Customer_Pricing_Acct= 'C';
	else if memberlevel_acct in( 18 )  then   Customer_Pricing_Acct= 'PD';
	else if (memberlevel_acct)=0  then   Customer_Pricing_Acct= 'NANJING_BANK';
	else if missing(memberlevel_acct)  then   Customer_Pricing_Acct= 'NONE';

	
	else if memberlevel_acct in(99, 100)   then Customer_Pricing_Acct='Imp';
	else if memberlevel_acct=10000    then Customer_Pricing_Acct='Test';
	else  Customer_Pricing_Acct='Other';

run;
proc freq data= cash_post_info_merge;
title "matchpost";
tables match_post /missing;

run;





/*  quota/level track back    */
proc sql;
create table Cash_post_info_level_min	   as
select 
		a.memberid, a.orderno , a.loan_day  , a.memberlevel_acct , a.loan_date , 

		b.before_level_early , b.after_level  , b.level_crtTime  , 
	    case when  loan_date<=  level_crtTime_num  then 1 
			 when  loan_date>  level_crtTime_num and not missing(level_crtTime_num)  then 0 
			 else . end as loan_before_level_change,

		abs(loan_date-level_crtTime_num) as level_change_intv

from cash_post_info_merge as a  left join    bck.Acctoptlog_level_&tday.  as b
	on a.memberid = b.memberid

/*group by a.memberid , loan_day , orderno*/
order by memberid , loan_day , orderno

;
quit;


proc sort data= Cash_post_info_level_min  out= Cash_post_info_level_min_srt  ;
by  memberid  loan_day  orderno  level_change_intv  ;
run;

proc sort data= Cash_post_info_level_min_srt  out= Cash_post_info_level_min_ndp nodupkey  ;
by  memberid  loan_day  orderno    ;
run;




proc sql;
create table Cash_post_info_quota_min	   as
select 
		a.memberid, a.orderno , a.loan_day  , a.totalquota , a.loan_date ,

		b.before_quota_early , b.after_quota  , b.quota_crtTime  , 
	    case when  loan_date<=  quota_crtTime_num  then 1
			 when  loan_date>  quota_crtTime_num and not missing(quota_crtTime_num)  then 0 
			 else . end as loan_before_quota_change,

		abs(loan_date-quota_crtTime_num) as quota_change_intv

from cash_post_info_merge as a  left join    bck.Acctoptlog_quota_&tday.  as b
	on a.memberid = b.memberid

/*group by a.memberid , loan_day , orderno*/
order by memberid , loan_day , orderno

;
quit;


proc sort data= Cash_post_info_quota_min  out= Cash_post_info_quota_min_srt  ;
by  memberid  loan_day  orderno  quota_change_intv  ;
run;

proc sort data= Cash_post_info_quota_min_srt  out= Cash_post_info_quota_min_ndp nodupkey  ;
by  memberid  loan_day  orderno    ;
run;



proc sql;
create table  Cash_post_info_level_quota as 
select  a.*,

b.level_crtTime, b.before_level_early, b.after_level,
c.quota_crtTime,  c.before_quota_early, c.after_quota,
/*b.*,*/
/*c.*,*/
case when  loan_before_quota_change=1 then  before_quota_early 
	 when  loan_before_quota_change=0 then  after_quota 
	 when  missing(loan_before_quota_change) then a.totalquota
	 else  -9999	end as memberquota_acct_back,

case when  loan_before_level_change=1 then  before_level_early 
	 when  loan_before_level_change=0 then  after_level 
	 when  missing(loan_before_level_change) then a.memberlevel
	 else  -9999 end as memberlevel_acct_back

from cash_post_info_merge as a 
	left join  Cash_post_info_level_min_ndp as b
		on a.memberid=b.memberid and a.orderno=b.orderno
	left join Cash_post_info_quota_min_ndp as c
		on a.memberid=c.memberid and a.orderno=c.orderno

order by memberid ,loan_day , orderno 
;
quit;

proc freq data= Cash_post_info_level_quota   ;
tables memberlevel_acct_back  /missing;

run;


/*  level/quota end    */

/* cash pcl */
proc sort data= bck.Cash_orderinfo_daily_&tday. out=Cash_orderinfo_daily 
(keep=memberid orderno   memberlevel membergrade  orderdate 
rename=(memberlevel=memberlevel_cashpcl  membergrade=membergrade_cashpcl  orderdate=orderdate_cashpcl)
)		dupout=Cash_orderinfo_daily_dp(keep=memberid orderno   memberlevel membergrade  orderdate 
rename=(memberlevel=memberlevel_cashpcl  membergrade=membergrade_cashpcl  orderdate=orderdate_cashpcl)
)		nodupkey	;
by memberid  orderno ;
run;


proc sql;
create table  Cash_post_info_&tday. as
select a.*,
		b.memberlevel_cashpcl, b.membergrade_cashpcl , substr(b.orderdate_cashpcl,1,10) as orderdate_cashpcl  length=12
from Cash_post_info_level_quota as a left join  Cash_orderinfo_daily as b
	on a.memberid=b.memberid and a.orderno=b.orderno

order by memberid , loan_day , orderno , mob;
;
quit;

proc freq data=   Cash_post_info_&tday.  ;
tables  membergrade_cashpcl*memberlevel /missing ;
run;



/* fin */

data     dt.Cash_post_info_&tday.	;
set      Cash_post_info_&tday.    ;
by   memberid  loan_day   orderno  mob;

length Customer_Pricing_Acct_back $16.   membergrade_cashpcl_lvl $16. ;
	 
	if memberlevel_acct_back in(3,11) 		 then  Customer_Pricing_Acct_back= 'A';		
	else if memberlevel_acct_back in( 7 , 12 )   then  Customer_Pricing_Acct_back= 'B';
	else if memberlevel_acct_back in( 15 )   then  Customer_Pricing_Acct_back= 'NB';
	else if memberlevel_acct_back in( 16 , 17 , 27 , 28 , 29 )   then    Customer_Pricing_Acct_back= 'B-';
	else if memberlevel_acct_back in( 14  ) then  Customer_Pricing_Acct_back= 'C-';
	else if memberlevel_acct_back in( 13 )  then   Customer_Pricing_Acct_back= 'C';
	else if memberlevel_acct_back in( 18 )  then   Customer_Pricing_Acct_back= 'PD';
	else if (memberlevel_acct_back)=0  then   	   Customer_Pricing_Acct_back= 'NANJING_BANK';
	else if missing(memberlevel_acct_back)  then   Customer_Pricing_Acct_back= 'NONE';

	else if memberlevel_acct_back in(99, 100)   then Customer_Pricing_Acct_back='Imp';
	else if memberlevel_acct_back=10000    then   Customer_Pricing_Acct_back='Test';
	else  Customer_Pricing_Acct_back='Other';
	
	
	 
	if memberlevel_cashpcl in(3,11) 		 then  membergrade_cashpcl_lvl= 'A';		
	else if memberlevel_cashpcl in( 7 , 12 )   then  membergrade_cashpcl_lvl= 'B';
	else if memberlevel_cashpcl in( 15 )   then  membergrade_cashpcl_lvl= 'NB';
	else if memberlevel_cashpcl in( 16 , 17 , 27 , 28 , 29 )   then    membergrade_cashpcl_lvl= 'B-';
	else if memberlevel_cashpcl in( 14  ) then  membergrade_cashpcl_lvl= 'C-';
	else if memberlevel_cashpcl in( 13 )  then   membergrade_cashpcl_lvl= 'C';
	else if memberlevel_cashpcl in( 18 )  then   membergrade_cashpcl_lvl= 'PD';
	else if (memberlevel_cashpcl)=0  then   	   membergrade_cashpcl_lvl= 'NANJING_BANK';
	else if missing(memberlevel_cashpcl)  then   membergrade_cashpcl_lvl= 'NONE';

	else if memberlevel_cashpcl in(99, 100)   then membergrade_cashpcl_lvl='Imp';
	else if memberlevel_cashpcl=10000    then   membergrade_cashpcl_lvl='Test';
	else  membergrade_cashpcl_lvl='Other';



	label 
	Customer_Pricing_Acct='现行定价等级'
	memberquota_acct_back='回溯当期额度'
	Customer_Pricing_Acct_back='回溯当期定价等级'
	
	
	before_level_early =  '当天调整前最早等级'
	after_level=  '当天调整后最终等级'

	before_quota_early='当天调整前最小额度'
	after_quota='当天调整后最终额度'

	quota_crtTime='额度调整日期'
	level_crtTime='等级调整日期'

	membergrade_cashpcl='订单时点定价'
	memberlevel_cashpcl='订单时点定价等级'
	membergrade_cashpcl_lvl='订单时点定价等级(EN)'
	;
	
	
drop  dayLoanDiscount deferredFlag  deleted  discountParty  dueLoanAmt  fee
	initAdvanceFee     initFee            interestStatus  isFree  
	latefee  loanDiscountfee  acctTempId  payLoanDiscountfee   periodType    poundage    
 remainAdvanceFee  remainFee  remainLatefee  remainOverdue   remainPrincipal   remainTotalAmt  remittanceType 
 remittanceType   repayDiscountfee   rotateStatus   successLogicDate  successTime  
 updTime    uptTime  waiverAdvanceFee       waiverFee     waiverLatefee    waiverOverdue    waiverPoundage     
 match:
;	
	
run;

/*proc sort data =  dt.cash_post_info_&tday. ;*/
/*by memberid loan_day orderno mob;*/
/*run;*/

proc sql;
title "summary";
select count(distinct memberid) as member , count(distinct orderno) as orderno
from  dt.cash_post_info_&tday.
;
quit;



proc freq data=  dt.cash_post_info_&tday.;
tables Customer_Pricing_Acct*Customer_Pricing_Acct_back /missing;
run;



proc contents data=  dt.cash_post_info_&tday.;
run;








