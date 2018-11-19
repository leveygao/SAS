%INC  ".\#00.OPTION.SAS";
options user=work;

	

/* InstalAcct_*/
DATA   bck.InstalAcct_&TDAY.   ;
	SET  Ins.InstalAcct ( keep= memberid  frozen  payable  totalquota riskquota risklevel  activetype   deleted   acctType
							channelcode acctTempid accttype category  major  memberlevel  mobile crttime acctstatus
							WHERE=( acctType=2   ));
						UPDATE_DAY="&TDAY.";
	
	RUN;
	

proc sql;
create table cash_id as
select distinct memberid , acctTempid
from  bck.InstalAcct_&TDAY. 
order by memberid,acctTempid
;
quit;



/* REPAY  */
DATA  AcctOptLog  ;
	SET ins.AcctOptLog	(  keep = memberid acctId  acctTempId  memberName optType result
								  comment    beforeData   afterData  crtTime   updTime
							WHERE=( opttype= 29    ))	;
	
							UPDATE_DAY="&TDAY.";
	
	length before_level 8.   after_level 8. ;
	before_level=beforeData+0;
	after_level=afterData+0;

	level_crtTime = put(datepart(crtTime),yymmddn8.);
	level_crtTime_num= input(level_crtTime,yymmdd8.);
	drop afterData  beforeData;
	
	
	RUN;
	


proc sort data=  AcctOptLog  out= AcctOptLog_srt ;
where level_crtTime>="20170901";
by memberid level_crtTime crtTime    ;
run;



data bck.AcctOptLog_level_&tday.  ;
set AcctOptLog_srt;
by memberid level_crtTime crtTime;
where  before_level^=after_level ;

retain before_level_early;
if first.level_crtTime then  before_level_early=before_level;


if last.level_crtTime then output;
run;







	
/* quota  */
DATA   AcctOptLog_quota  ;
	SET ins.AcctOptLog	(  keep = memberid acctId  acctTempId  memberName optType result
								  comment    beforeData   afterData  crtTime   updTime
							WHERE=( opttype in(1,18,21,22,23)   ) )	;
	
							UPDATE_DAY="&TDAY.";
	
	length before_quota 8.   after_quota 8. ;
	before_quota=beforeData+0;
	after_quota=afterData+0;

	quota_crtTime = put(datepart(crtTime),yymmddn8.);
	quota_crtTime_num= input(quota_crtTime,yymmdd8.);
	
	drop afterData  beforeData;
	
	
	RUN;


proc sort data=  AcctOptLog_quota  out= AcctOptLog_quota_srt ;
where quota_crtTime>="20170901";
by memberid quota_crtTime crtTime    ;
run;


data   bck.AcctOptLog_quota_&tday.  ;
set AcctOptLog_quota_srt;
by memberid quota_crtTime crtTime;
where  before_quota^=after_quota ;

retain before_quota_early;
if first.quota_crtTime then  before_quota_early=before_quota;


if last.quota_crtTime then output;



run;



