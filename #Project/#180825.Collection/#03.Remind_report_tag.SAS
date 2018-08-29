%inc ".\#00.OPTION.SAS";


/*proc sql;*/
/*select count(distinct memberid) as member*/
/*from    ch.Remind_table_20180806*/
/*;*/
/*quit;*/
proc sort data=  bck.Reminddalilyreport_20180809 out=Reminddalilyreport  ;
by memberid idRemindEvent idRemindDalilyReport crttime;
run;


data  Reminddalilyreport_tag;
set Reminddalilyreport;
by memberid idRemindEvent idRemindDalilyReport;


retain status_df ystdReminder_df;
last_state=lag(status);
last_reminder=lag(ystdReminder);


if first.idRemindEvent then do;
	status_df=0;
	ystdReminder_df=0;
	last_state=.;
	last_reminder=.;
end;

if not first.idRemindEvent then do;
if status^=last_state and not missing(last_state) then status_df+1;
if ystdReminder^=last_reminder and not missing(last_reminder) then ystdReminder_df+1;
end;

if first.idremindevent or  last.idremindevent then flagout=1;

if last.idRemindEvent and sumOverdueAmt=0 then ifpaid=1;
else if last.idRemindEvent then  ifpaid=0;
run;


data Reminddalilyreport_tagout;
set Reminddalilyreport_tag(where=(flagout=1));
by memberid idRemindEvent idRemindDalilyReport;

lag_period=lag(period);
Init_sumOverdueAmt=lag(sumOverdueAmt);

if first.idRemindEvent   then  do;
	lag_period=.;
	Intv=0;
	Init_sumOverdueAmt=.;
end;

if last.idRemindEvent and not missing(lag_period) then 
	Intv=intck("day",input(lag_period,yymmdd8.),input(period,yymmdd8.));


run;



data Sum_dalilyreport;
set Reminddalilyreport_tagout;
by memberid idRemindEvent idRemindDalilyReport;

if intv=. then intv=0;

if  lag_period=. then Init_period=period;
else  Init_period=lag_period;

if missing(Init_sumOverdueAmt) then Init_sumOverdueAmt=ystdSumOverdueAmt;
/*else  Init_sumOverdueAmt=lag_period;*/

length Init_period_mth $6.  Period_mth $6.;
Init_period_mth=substr(compress(Init_period),1,6);
Period_mth=substr(compress(period),1,6);

if last.idRemindEvent ;
keep memberid idRemindEvent  period sumOverdueAmt ystdSumOverdueAmt status_df ystdReminder_df ifpaid 
	lag_period   Init_sumOverdueAmt Init_period  Intv  
	Init_period_mth   Period_mth
;
run;

proc sort data=Sum_dalilyreport nodupkey;
by memberid Init_period_mth;
run;


proc sort data=  bck.ch_bt_roll_tag_list0810_v2_ndp out=Ch_bt_roll_tag_list  ;
by memberid New_Bill_mth;
run;



/* merge  */
data Post_info_dalilyreport;
merge   Ch_bt_roll_tag_list(in=a rename=(New_Bill_mth=Match_month))
		Sum_dalilyreport(in=b  rename=(Init_period_mth=Match_month));
		
where Match_month<='201807';


by memberid  Match_month;
match_dlqrm=10*a+b;

run;

proc freq data=Post_info_dalilyreport;
tables  match_dlqrm/missing norow nocol;
run;





/* match remind action */
proc sort data=Post_info_dalilyreport out= bck.Event_info_dalilyreport  ;
where match_dlqrm=11;
by memberid idRemindEvent;
run;




