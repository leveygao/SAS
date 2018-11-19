%INC ".\#00.OPTION.SAS";
OPTIONS NOCENTER LS=MAX ps=max;
/*%let date=0806;*/

%put &tday.;

proc sql;
create table Remind_table  as
select distinct memberid,idRemindEvent,
extendFieldStr1,remindType, outCallResult, actionCode,record_operateTime,lastDistributionTime


from dt.remind_table_&tday.
group by memberid,idRemindEvent
;
quit;






data Remind0;
set  Remind_table ;
if index(outCallResult,'-')>0 then do;
Fst_OutClass=scan(outCallResult,1,'-' );
Sec_OutClass=scan(outCallResult,2,'-' );
Trd_OutClass=scan(outCallResult,3,'-');
end;

else 
Otr_OutClass=outCallResult;

if not missing(lastDistributionTime) then 
Distdate= put(datepart(lastDistributionTime),yymmddn8.) ;
else Distdate="";
run;



proc freq data= Remind0;
tables Fst_OutClass/missing ;
tables Sec_OutClass/missing ;
tables Trd_OutClass/missing ;
tables Otr_OutClass/missing ;
run;




proc sql;
create table member_event_level as
select distinct memberid,  Distdate, idRemindEvent ,
		count(distinct idRemindEvent) as RemindEvent_cnt  ,
		
		
		count(record_operateTime)  as Fst_OutClass_Rec,
		count(case when missing( Fst_OutClass) then record_operateTime  end) as Fst_OutClass_mis,
		count(case when Fst_OutClass='M' then record_operateTime   end) as Fst_OutClass_M,
		count(case when Fst_OutClass='EM' then record_operateTime  end) as Fst_OutClass_EM,
		count(case when Fst_OutClass='SQM' then record_operateTime  end) as Fst_OutClass_SQM,
		count(case when  Fst_OutClass in('SFIX','WFIX') then record_operateTime  end)  as Fst_OutClass_IX,


		count(record_operateTime)  as Sec_OutClass_Rec,
		count(case when missing( Sec_OutClass) then record_operateTime  end) as Sec_OutClass_mis,
		count(case when Sec_OutClass='ABNO' then record_operateTime   end) as Sec_OutClass_ABNO,
		count(case when Sec_OutClass='BUSY' then record_operateTime  end) as Sec_OutClass_BUSY,
		count(case when Sec_OutClass='CA' then record_operateTime  end) as Sec_OutClass_CA,
		count(case when Sec_OutClass='EA' then record_operateTime  end)  as Sec_OutClass_EA,	
		count(case when Sec_OutClass='NCUT' then record_operateTime  end)  as Sec_OutClass_NCUT,
		count(case when Sec_OutClass='NOAS' then record_operateTime  end)  as Sec_OutClass_NOAS,
		count(case when Sec_OutClass='NOCH' then record_operateTime  end)  as Sec_OutClass_NOCH,
		count(case when Sec_OutClass='NOFF' then record_operateTime  end)  as Sec_OutClass_NOFF,
		count(case when Sec_OutClass='NSUS' then record_operateTime  end)  as Sec_OutClass_NSUS,
		count(case when Sec_OutClass='NTHZ' then record_operateTime  end)  as Sec_OutClass_NTHZ,

		count(case when Sec_OutClass in( 'NULL','null') then record_operateTime  end)  as Sec_OutClass_NULL,
		count(case when Sec_OutClass='OFF' then record_operateTime  end)  as Sec_OutClass_OFF,
		count(case when Sec_OutClass='OTH' then record_operateTime  end)  as Sec_OutClass_OTH,
		count(case when Sec_OutClass='SUSP' then record_operateTime  end)  as Sec_OutClass_SUSP,
		count(case when Sec_OutClass='ZC' then record_operateTime  end)  as Sec_OutClass_ZC,


		count(record_operateTime)  as Trd_OutClass_Rec,
		count(case when missing( Trd_OutClass) then record_operateTime  end) as  Trd_OutClass_mis,
		count(case when Trd_OutClass='ALPA' then record_operateTime  end)  as Trd_OutClass_ALPA,
		count(case when Trd_OutClass='NOST' then record_operateTime  end)  as Trd_OutClass_NOST,
		count(case when Trd_OutClass='NPTP' then record_operateTime  end)  as Trd_OutClass_NPTP,
		count(case when Trd_OutClass='OPTP' then record_operateTime  end)  as Trd_OutClass_OPTP,
		count(case when Trd_OutClass='PTP' then record_operateTime  end)  as Trd_OutClass_PTP,
		count(case when Trd_OutClass='QT' then record_operateTime  end)  as Trd_OutClass_QT,
		count(case when Trd_OutClass='RE' then record_operateTime  end)  as Trd_OutClass_RE,
		count(case when Trd_OutClass='RN' then record_operateTime  end)  as Trd_OutClass_RN,
		count(case when Trd_OutClass='WGT' then record_operateTime  end)  as Trd_OutClass_WGT,
		count(case when Trd_OutClass='YCY' then record_operateTime  end)  as Trd_OutClass_YCY,
		count(case when Trd_OutClass='WCY' then record_operateTime  end)  as Trd_OutClass_WCY


	

from Remind0
group by memberid ,Distdate , idRemindEvent
order by memberid ,Distdate
;
quit;





/*
proc sql;
create table member_event   as
select distinct memberid,idRemindEvent,

	  

		sum(Fst_OutClass_Rec)  as Fst_OutClass_Rec,
		sum(Fst_OutClass_mis)  as Fst_OutClass_mis,
		sum(Fst_OutClass_M)  as  Fst_OutClass_M,
		sum(Fst_OutClass_EM)  as  Fst_OutClass_EM,
		sum(Fst_OutClass_SQM)  as  Fst_OutClass_SQM,
		sum(Fst_OutClass_IX)  as  Fst_OutClass_IX,



		sum(Sec_OutClass_Rec)  as Sec_OutClass_Rec,
		sum(Sec_OutClass_mis)  as Sec_OutClass_mis,
		sum(Sec_OutClass_ABNO)  as  Sec_OutClass_ABNO,
		sum(Sec_OutClass_BUSY)  as  Sec_OutClass_BUSY,
		sum(Sec_OutClass_CA)  as  Sec_OutClass_CA,
		sum(Sec_OutClass_EA)  as  Sec_OutClass_EA,
		sum(Sec_OutClass_NCUT)  as Sec_OutClass_NCUT,
		sum(Sec_OutClass_NOAS)  as  Sec_OutClass_NOAS,
		sum(Sec_OutClass_NOCH)  as  Sec_OutClass_NOCH,
		sum(Sec_OutClass_NOFF)  as  Sec_OutClass_NOFF,
		sum(Sec_OutClass_NSUS)  as  Sec_OutClass_NSUS,
		sum(Sec_OutClass_NTHZ)  as  Sec_OutClass_NTHZ,

		sum(Sec_OutClass_NULL)  as Sec_OutClass_NULL,
		sum(Sec_OutClass_OFF)  as Sec_OutClass_OFF,
		sum(Sec_OutClass_OTH)  as  Sec_OutClass_OTH,
		sum(Sec_OutClass_SUSP)  as  Sec_OutClass_SUSP,
		sum(Sec_OutClass_ZC)  as  Sec_OutClass_ZC,


		sum(Trd_OutClass_Rec)  as Trd_OutClass_Rec,
		sum(Trd_OutClass_mis)  as Trd_OutClass_mis,
		sum(Trd_OutClass_ALPA)  as  Trd_OutClass_ALPA,
		sum(Trd_OutClass_NOST)  as  Trd_OutClass_NOST,
		sum(Trd_OutClass_NPTP)  as  Trd_OutClass_NPTP,
		sum(Trd_OutClass_OPTP)  as Trd_OutClass_OPTP,
		sum(Trd_OutClass_PTP)  as Trd_OutClass_PTP,
		sum(Trd_OutClass_QT)  as  Trd_OutClass_QT,
		sum(Trd_OutClass_RE)  as  Trd_OutClass_RE,
		sum(Trd_OutClass_WGT)  as  Trd_OutClass_WGT,
		sum(Trd_OutClass_YCY)  as  Trd_OutClass_YCY,
		sum(Trd_OutClass_WCY)  as  Trd_OutClass_WCY,




		avg(Fst_OutClass_Rec)  as Fst_OutClass_Rec_avg,
		avg(Fst_OutClass_mis)  as Fst_OutClass_mis_avg,
		avg(Fst_OutClass_M)  as  Fst_OutClass_M_avg,
		avg(Fst_OutClass_EM)  as  Fst_OutClass_EM_avg,
		avg(Fst_OutClass_SQM)  as  Fst_OutClass_SQM_avg,
		avg(Fst_OutClass_IX)  as  Fst_OutClass_IX_avg,



		avg(Sec_OutClass_Rec)  as Sec_OutClass_Rec_avg,
		avg(Sec_OutClass_mis)  as Sec_OutClass_mis_avg,
		avg(Sec_OutClass_ABNO)  as  Sec_OutClass_ABNO_avg,
		avg(Sec_OutClass_BUSY)  as  Sec_OutClass_BUSY_avg,
		avg(Sec_OutClass_CA)  as  Sec_OutClass_CA_avg,
		avg(Sec_OutClass_EA)  as  Sec_OutClass_EA_avg,
		avg(Sec_OutClass_NCUT)  as Sec_OutClass_NCUT_avg,
		avg(Sec_OutClass_NOAS)  as  Sec_OutClass_NOAS_avg,
		avg(Sec_OutClass_NOCH)  as  Sec_OutClass_NOCH_avg,
		avg(Sec_OutClass_NOFF)  as  Sec_OutClass_NOFF_avg,
		avg(Sec_OutClass_NSUS)  as  Sec_OutClass_NSUS_avg,
		avg(Sec_OutClass_NTHZ)  as  Sec_OutClass_NTHZ_avg,

		avg(Sec_OutClass_NULL)  as Sec_OutClass_NULL_avg,
		avg(Sec_OutClass_OFF)  as Sec_OutClass_OFF_avg,
		avg(Sec_OutClass_OTH)  as  Sec_OutClass_OTH_avg,
		avg(Sec_OutClass_SUSP)  as  Sec_OutClass_SUSP_avg,
		avg(Sec_OutClass_ZC)  as  Sec_OutClass_ZC_avg,


		avg(Trd_OutClass_Rec)  as Trd_OutClass_Rec_avg,
		avg(Trd_OutClass_mis)  as Trd_OutClass_mis_avg,
		avg(Trd_OutClass_ALPA)  as  Trd_OutClass_ALPA_avg,
		avg(Trd_OutClass_NOST)  as  Trd_OutClass_NOST_avg,
		avg(Trd_OutClass_NPTP)  as  Trd_OutClass_NPTP_avg,
		avg(Trd_OutClass_OPTP)  as Trd_OutClass_OPTP_avg,
		avg(Trd_OutClass_PTP)  as Trd_OutClass_PTP_avg,
		avg(Trd_OutClass_QT)  as  Trd_OutClass_QT_avg,
		avg(Trd_OutClass_RE)  as  Trd_OutClass_RE_avg,
		avg(Trd_OutClass_WGT)  as  Trd_OutClass_WGT_avg,
		avg(Trd_OutClass_YCY)  as  Trd_OutClass_YCY_avg,
		avg(Trd_OutClass_WCY)  as  Trd_OutClass_WCY_avg
	
from member_event_level



group by memberid ,idRemindEvent
order by memberid ,idRemindEvent
;
quit;




*/

data dt.Remind_actvar_date_&tday.   ;
set member_event_level   ;
run;

/*


if missing(outCallResult) then Miss_Result=1; else  Miss_Result=0;
if not missing(outCallResult) and substr(outCallResult,1,2)="M-" then If_loaner=1; else  If_loaner=0;
if not missing(outCallResult) and substr(outCallResult,1,3)="EM-" then If_loaner=1; else  If_loaner=0;
