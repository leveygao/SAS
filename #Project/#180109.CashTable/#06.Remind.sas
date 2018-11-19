%inc ".\#00.OPTION.SAS";

%put &tday;


data  RemindEvent;
set  rcs_cms.RemindEvent(drop=outCallNote);
run;

data  RemindRecord;
set  rcs_cms.RemindRecord(drop=outCallNote);
run;

proc sql;
create table dt.Remind_table_&tday. as
select
a.idRemindEvent, a.memberid, a.status, a.statusUpdTime, a.reminder  , a.operateTime as event_operateTime, 
a.extendFieldStr1,  a.lastDistributionTime,  a.lastRecordTime, a.dealTo, a.isSendMeg,
b.stage, b.remindType , b.msgTemplet ,b.outCallResult, b.operator, b.operateTime as record_operateTime,
b.crtTime , b.actionCode,  b.totop

from Remindevent as a 
join Remindrecord as b
  on a.idRemindEvent=b.idRemindEvent
order by memberid,b.operateTime,idRemindEvent
;
quit;
