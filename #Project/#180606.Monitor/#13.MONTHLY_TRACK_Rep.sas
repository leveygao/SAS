%INC  ".\#00.OPTION.SAS";
libname btbck "D:\GY\18.1.31 BT_TABLE_SUM\bck";

%let type=C001
;
%let name=JF
;


/*=========================申请表===========================*/
PROC SQL;
CREATE TABLE BT_APPLY_MTH_&name. AS
select
	  
 put(datepart(a.apply_crtTime),yymmn6.) as Apply_Month,    
 count(distinct case when channelcode="C001" and activeType^="virtual_card" then a.memberid end) as Applynum_JF ,
 count(distinct case when (conclusion="Pass" and  channelcode="C001" and activeType^="virtual_card")  then a.memberid end) as Passnum_JF  , /*核准用户数*/       
/* count(distinct case when (conclusion="Pass" and  channelcode="C001" and activeType="virtual_card")  then a.memberid end) as Passnum_JF_Card, */
(calculated Passnum_JF)/(calculated Applynum_JF) as Apply_JF_Rate FORMAT percent8.2,
	
 count(distinct case when channelcode='C005' and acctTempId=300005 and requestChannel='hybrid'   then a.memberid end) as Applynum_DM ,
 count(distinct case when (conclusion='Pass' and a.state=1 and  channelcode='C005' and acctTempId=300005  and requestChannel='hybrid')
 then a.memberid end) as Passnum_DM,
 (calculated Passnum_DM)/(calculated Applynum_DM) as Apply_DM_Rate FORMAT percent8.2
			
 from bt.Bt_apply_info_20180420	 as a 
group by (calculated Apply_Month) 
;
quit;


/*=========================放款表===========================*/
/*交易表*/
proc sql;
create table Orderinfo_cnt as
select
put(datepart(orderTime),yymmn6.) as Loan_mth , 
	case when index(bigMerchantId,"20160007")>0 		then "FLIGHT" 
		 when index(bigMerchantId,"20160006")>0 	then "TOUR_DMS" 
		 when index(bigMerchantId,"20160002")>0 	THEN "TRAIN"
		 when index(bigMerchantId,"20160001")>0 	THEN "TOUR_INT"
		 when index(bigMerchantId,"20160005")>0 		THEN "CRUISE"
		 ELSE "OTHER"		
		 end as Merchant_type,
	
	count(distinct a.orderno ) as Total_order_cnt,
	count(distinct case when orderStatus^="0" then a.OrderNo end) as Valid_order_cnt,
	count(distinct case when orderStatus not in('0','2') then a.OrderNo end) as PayDlq_order_cnt,
	(calculated Valid_order_cnt)/(calculated Total_order_cnt)  as Valid_order_pct format percent10.2,
	(calculated PayDlq_order_cnt)/(calculated Valid_order_cnt)  as Paydlq_order_pct format percent10.2

	from  btbck.Orderinfo_&tday. as a
	where a.channelType="&type." and not missing(a.orderTime) 
group by Loan_mth,    Merchant_type
order by Loan_mth,	  Merchant_type

;
quit;


PROC SQL;
CREATE TABLE Orderinfo_amt AS
SELECT 
	put(datepart(orderTime),yymmn6.) as Loan_mth , 
	case when index(bigMerchantId,"20160007")>0 		then "FLIGHT" 
		 when index(bigMerchantId,"20160006")>0 	then "TOUR_DMS" 
		 when index(bigMerchantId,"20160002")>0 	THEN "TRAIN"
		 when index(bigMerchantId,"20160001")>0 	THEN "TOUR_INT"
		 when index(bigMerchantId,"20160005")>0 		THEN "CRUISE"
		 ELSE "OTHER"		
		 end as Merchant_type,
	
	sum(case when orderStatus^="0" and repayStatus^=3  then loanAmount end) as Valid_loanAmount format comma16.2,
	sum(case when orderStatus not in('0','2') and repayStatus^=3  then loanAmount end) as PayDlq_loanAmount format comma16.2,
    (calculated PayDlq_loanAmount)/(calculated Valid_loanAmount)  as Paydlq_amt_pct format percent10.2
	
	from (

	select distinct a.memberid,a.orderno,a.orderTime,a.bigMerchantId,a.loanAmount,a.orderStatus ,b.repaystatus

	from  btbck.Orderinfo_&tday. as a  left join btbck.Repayschedule_&tday. as  b
				on a.memberid=b.memberid and a.orderno=b.orderno
	where a.channelType="&type." and not missing(a.orderTime)and b.num=1

	)
group by Loan_mth,    Merchant_type
order by Loan_mth,	  Merchant_type
;	
quit;

proc sql;
create table  Bt_order_info_&name. as
select a.*,
		b.Valid_loanAmount ,b.PayDlq_loanAmount ,b.Paydlq_amt_pct

from Orderinfo_cnt as a join Orderinfo_amt as b
	on a.loan_mth=  b.loan_mth and   a.Merchant_type = b.Merchant_type

order by  Loan_mth,	  Merchant_type
;
quit;


/*=====================产品结构======================*/
proc sql;
create table BT_Product_&name. as
select 
		Loan_mth,	Merchant_type,
		sum(a.loanAmount ) as loanamt format comma15.2,	

		count(distinct a.memberId) as Membernum,
		count(distinct a.orderno) as Total_orderno,
		count(distinct case when a.totalNum=1 then a.orderNo end)/count(distinct a.orderNo) as Period1 format percent10.2,
		count(distinct case when a.totalNum=3 then a.orderNo end)/count(distinct a.orderNo) as Period3 format percent10.2,
		count(distinct case when a.totalNum=5 then a.orderNo end)/count(distinct a.orderNo) as Period5 format percent10.2,
		count(distinct case when a.totalNum=6 then a.orderNo end)/count(distinct a.orderNo) as Period6 format percent10.2,
		count(distinct case when a.totalNum=9 then a.orderNo end)/count(distinct a.orderNo) as Period6 format percent10.2,
		count(distinct case when a.totalNum=11 then a.orderNo end)/count(distinct a.orderNo) as Period11 format percent10.2,
		count(distinct case when a.totalNum=12 then a.orderNo end)/count(distinct a.orderNo) as Period12  format percent10.2

	from (select distinct memberid,orderno,totalNum,Loan_mth,Merchant_type,loanAmount
		from 	bt.Bt_post_info_&tday.
		where 	 channelType="&type.") as a
	
group by  Loan_mth,Merchant_type
order by Loan_mth  

;
quit;







/*======================== 本金回收率 =======================*/

proc sort data= bt.Bt_post_info_&tday.  out=  bt_Post_queue  ;
where  channelType="&type.";
by  memberId orderno mob ;
run;

data  post_queue1;
set bt_Post_queue (
keep= memberid orderno mob due_amt loanamount flag_return channelType queue loan_mth Merchant_type
repayStatus  orderStatus   new_repaydate  PAYDAY_NUM   new_dlq_mthend    new_payamt  payamt  new_principal principal BILL_DAY
);
by  memberId orderno mob ;
where flag_return^=-9 
and substr(put(new_repaydate,yymmddn8.),1,6)<substr("&tday.",1,6);



if last.orderno then output; /* 最新一期 */
run;

proc freq data=post_queue1;
where orderStatus^='2' and loan_mth<substr("&tday.",1,6);
tables loan_mth*flag_return/missing;
run;

proc sql;
create table BT_topay_return_&name. as
select
		loan_mth , merchant_type,
		/* CNT */
		count(distinct  orderno  ) as Topay_order_cnt,
		count(distinct case when flag_return=1 then orderno end) as Dlq_order_cnt,
		count(distinct case when flag_return^=1 and 1>=(PAYDAY_NUM-new_repaydate) then orderno end) as Order_T1_cnt,
		count(distinct case when flag_return^=1 and 4>=(PAYDAY_NUM-new_repaydate) then orderno end) as Order_T1_4_cnt,
		count(distinct case when flag_return^=1 and 11>=(PAYDAY_NUM-new_repaydate) then orderno end) as Order_T4_11_cnt,
		count(distinct case when flag_return^=1 and 30>=(PAYDAY_NUM-new_repaydate) then orderno end) as Order_T11_30_cnt,

		(calculated Order_T1_cnt)/(calculated Topay_order_cnt) as Order_T1_pct format percent9.2,
		(calculated Order_T1_4_cnt)/(calculated Topay_order_cnt) as Order_T1_4_pct format percent9.2,
		(calculated Order_T4_11_cnt)/(calculated Topay_order_cnt) as Order_T4_11_pct format percent9.2,
		(calculated Order_T11_30_cnt)/(calculated Topay_order_cnt) as Order_T11_30_pct format percent9.2,

		/* AMT */
		sum(principal)/100 as Total_principal format comma15.2,
		sum(case when flag_return=1 then principal  end )/100 as Dlq_principal format comma15.2,
		sum(case when flag_return^=1  and 1>=(PAYDAY_NUM-new_repaydate)  then principal end)/100 as Order_T1_amt format comma15.2,
		sum(case when flag_return^=1  and 4>=(PAYDAY_NUM-new_repaydate)  then principal end)/100 as Order_T1_4_amt format comma15.2,
		sum(case when flag_return^=1  and 11>=(PAYDAY_NUM-new_repaydate)  then principal end)/100 as Order_T4_11_amt format comma15.2 ,
		sum(case when flag_return^=1  and 30>=(PAYDAY_NUM-new_repaydate) then principal end)/100 as Order_T11_30_amt format comma15.2,

		(calculated Order_T1_amt)/(calculated Total_principal) as Order_T1_amtpct format percent9.2,
		(calculated Order_T1_4_amt)/(calculated Total_principal) as Order_T1_4_amtpct format percent9.2,
		(calculated Order_T4_11_amt)/(calculated Total_principal) as Order_T4_11_amtpct format percent9.2,
		(calculated Order_T11_30_amt)/(calculated Total_principal) as Order_T11_30_amtpct format percent9.2

from  post_queue1
where    orderStatus^='2' and loan_mth<substr("&tday.",1,6)
group by loan_mth,  merchant_type
;
quit;



/*  mob 入催率  */

data  mob_dlq0;
set bt_Post_queue (
keep= memberid orderno mob due_amt loanamount flag_return channelType queue loan_mth Merchant_type 
repayStatus  orderStatus   new_repaydate  PAYDAY_NUM   new_dlq_mthend    new_payamt  payamt  new_principal principal BILL_DAY UPDATE_DAY
);
by  memberId orderno mob 	;
m=lag(flag_return);

if first.orderno then m=.;
 	if m not in(1,9) and flag_return in(1,9) then flow_dlq=1;
	else flow_dlq=0;

if   flag_return =9 then Flowin_day= abs(PAYDAY-new_repaydate)		;
else if   flag_return =1  then Flowin_day= new_dlq_mthend	;
else  Flowin_day=0;



STATS_DAY= intnx("month",input(UPDATE_DAY,yymmdd8.),-1);
STATS_MTH= put(STATS_DAY,yymmn6.);
run;

proc sql;
create table  mob_dlq1 as
select 
	loan_mth, mob	,  Merchant_type,
	count(distinct orderno) as Total_order_cnt,
	count(distinct case when  flow_dlq=1 and  Flowin_day>=1  then orderno end ) as FlowinT1_order,
/*	count(distinct case when  flow_dlq=0 then orderno end ) as NormalT0_order,*/

	count(distinct case when  flow_dlq=1 and  Flowin_day>=4	 then orderno end ) as FlowinT4_order,
/*	count(distinct case when  flow_dlq=0 and  1<Flowin_day<=4	then orderno end ) as NormalT1_4_order,*/

	count(distinct case when  flow_dlq=1 and  Flowin_day>=11	 then orderno end ) as FlowinT11_order,
/*	count(distinct case when  flow_dlq=0 and  4<Flowin_day<=11	then orderno end ) as NormalT4_11_order,*/

	count(distinct case when  flow_dlq=1 and  Flowin_day>=20	 then orderno end ) as FlowinT20_order,
/*	count(distinct case when  flow_dlq=0 and  11<Flowin_day<=30	then orderno end ) as NormalT11_30_order,*/


	(calculated FlowinT1_order)/(calculated Total_order_cnt) as FlowinT1_rate format percent10.2,
	(calculated FlowinT4_order)/(calculated Total_order_cnt) as FlowinT4_rate format percent10.2,
	(calculated FlowinT11_order)/(calculated Total_order_cnt) as FlowinT11_rate format percent10.2,
	(calculated FlowinT20_order)/(calculated Total_order_cnt) as FlowinT20_rate format percent10.2

from mob_dlq0
where flag_return ^=-9  and mob<=6 and  loan_mth<STATS_MTH and substr(put(new_repaydate,yymmddn8.),1,6)<substr("&tday.",1,6)
group by loan_mth, Merchant_type,mob	 
order by loan_mth, Merchant_type,mob	  
;
quit;

/* cnt pct */
%MACRO A;
%LET TABLE= T1 T4 T11 T20								
;

%do i=1 %to 4;
 %let mname=%scan(&TABLE,&i," ");	   /* %scan(&text,&i,&delim) */
 %put &mname.;

proc transpose data=mob_dlq1(keep= loan_mth Merchant_type mob Flowin&mname._rate ) out=Flow_&mname._tps(drop=_name_) prefix=MOB&mname._ ;
by  loan_mth Merchant_type  ;
id  mob  ;
var  Flowin&mname._rate;
run;

proc sort data=Flow_&mname._tps;
by loan_mth Merchant_type;
run;

%end;


data JF_flow;
merge  Flow_:;
by loan_mth Merchant_type;
run;

data  JF_flow;
retain loan_mth Merchant_type  MOBT1: MOBT4: MOBT11:  MOBT20:;
set JF_flow;
run;

%mend;
%a;



