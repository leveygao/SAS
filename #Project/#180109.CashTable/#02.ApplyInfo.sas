%INC  ".\#00.OPTION.SAS";


/*取最新一期的申请记录 其他删去*/
proc sort data=  bck.cashcreditapply_&tday.(keep=memberid  refBizId name identityNo    crtTime) 
out= creditapply;
by memberid descending crtTime;
run;

proc sort data=		creditapply	 out= creditapply_ndp( rename=(crttime=creditapply_time) )  dupout= creditapply_dp  nodupkey;
by memberid ;
run;


/* merge apply table */

proc sort data= bck.Cashfstaudit_&tday.   out=cashfstaudit_st(keep=memberid crttime zmscore) ;
by memberid descending crttime ;
run;
proc sort data=cashfstaudit_st out=cashfstaudit( rename=(crttime=fstaudit_time))    nodupkey;
by memberid;
run;


proc sort data= bck.instalacct_&tday. out=instalacct(rename=(crtTime=acct_time))    nodupkey;
where deleted=0 and  acctType=2 ;
by memberid   ;
run;


data apply_info ;
merge instalacct(in=a)  creditapply_ndp(in=b )  cashfstaudit(in=c );
by memberid;
length Conclusion $10.;
/*if a;*/


if a then Conclusion="Pass";
else Conclusion="Fail";


if not missing(acct_time) then Apply_Time= acct_time;
else if  not missing(creditapply_time) then Apply_Time= creditapply_time;
else if  not missing(fstaudit_time) then Apply_Time= fstaudit_time;
else Apply_Time=.;
 
Apply_date=put(datepart(Apply_Time),yymmddn8.);
Match_apply=compress(a||b||c);

if missing(Apply_Time) then missing_applytime=1;else missing_applytime=0;

format Apply_Time DATETIME20. ;
run;

proc freq data=apply_info;
title 	"Match_apply";
tables	 Match_apply /missing norow nocol;
tables	 Conclusion /missing norow nocol;
tables missing_applytime;
run;



data 	 dt.Cash_Apply_Info_&tday.	;
set  	 apply_info;
by memberid;
length memberid1 $56.  ; /*companyName1 $60. contactName11 $20.  contactName21 $20.  name1 $20.   ; */

memberid1=compress(memberid);


/* 资金方渠道 */
length Customer_Pricing_Acct $6.;
	if memberlevel  in(3,11) 		 then  Customer_Pricing_Acct= 'A';		
	else if memberlevel in( 7 , 12 )   then  Customer_Pricing_Acct= 'B';
	else if memberlevel in( 15 )   then  Customer_Pricing_Acct= 'NB';
	else if memberlevel in( 16 , 17 , 27 , 28 , 29 )   then    Customer_Pricing_Acct= 'B-';
	else if memberlevel in( 14  ) then  Customer_Pricing_Acct= 'C-';
	else if memberlevel in( 13 )  then   Customer_Pricing_Acct= 'C';
	else if memberlevel in( 18 )  then   Customer_Pricing_Acct= 'PD';
	
	
	else if memberlevel=100 then Customer_Pricing_Acct='Imp';
	else if missing(memberlevel) then Customer_Pricing_Acct='FAIL';
	else  Customer_Pricing_Acct='Other';

	

drop memberid     missing_applytime ;

rename
memberid1 =memberid        ;

run;


proc contents data=  dt.Cash_Apply_Info_&tday.	;
run;






/*

proc sort data= bck.instalacct_&tday. out=instalacct_test nodupkey ;
by memberid descending crttime ;
run;
proc sort data= bck.Repayschedule_&tday. out=Repayschedule_test nodupkey ;
by memberid   ;
run;

data   insta_repay;
merge instalacct_test(in=a) Repayschedule_test(in=b);
by memberid;
if a;
match_inpay=10*a+b;

run;


proc freq data=insta_repay;
tables	 match_inpay /missing norow nocol;
run;



data   insta_repay1;
merge instalacct(in=a) Repayschedule_test(in=b);
by memberid;
if a;
match_inpay=10*a+b;

run;


proc freq data=insta_repay1;
tables	 match_inpay /missing norow nocol;
run;



proc sql;
create table acct_repay as
select a.*,b.memberid as memberid_b

from    instalacct as a right join  Repayschedule_test as b
			on a.memberid=b.memberid
order by memberid_b
;
quit;



