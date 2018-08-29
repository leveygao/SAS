%inc ".\#00.OPTION.SAS";
OPTIONS COMPRESS=YES;

%let update=20180809
;

proc sql;
create table bck.RemindDalilyReport_&update. as 
select *
from rcs_cms.RemindDalilyReport
;
quit;