%inc ".\#00.OPTION.SAS";


proc sql;
create table sy_dlq as
select 

count(distinct memberid) as member_cnt,
count(distinct case when Ever_merfrs_dlq>0 then memberid  end) as Frs_memid,
count(distinct case when Ever_merfrs_dlqday>10 then memberid  end) as Frs10_memid,
count(distinct case when Ever_merfrs_dlqday>30 then memberid  end) as Frs30_memid,

(calculated Frs_memid)/(calculated member_cnt) as Frs_pct format percent9.2,
(calculated Frs10_memid)/(calculated member_cnt) as Frs10_pct format percent9.2,
(calculated Frs30_memid)/(calculated member_cnt) as Frs30_pct format percent9.2,
Merchant_type

from   bt.Bt_dlq_tag_20180409
group by Merchant_type
order by Merchant_type
;
quit;

/* frs */
proc sort data= bt.Bt_post_info_20180409  out=Bt_post_info ;
by Merchant_type  memberid Loan_day orderno mob ;
run;

data frs_mer;
set Bt_post_info;
by Merchant_type memberid Loan_day orderno mob ;
where flag_return^=-9;
retain Ever_merfrs_dlq Ever_merfrs_dlqday;
;

if first.memberid  and flag_return in(1,9) and mob=1 then do;
Ever_merfrs_dlq=1;
Ever_merfrs_dlqday=overduenum;
end;

else if first.memberid then  do;
Ever_merfrs_dlq=0;
Ever_merfrs_dlqday=0;
end;
Ever_merfrs_dlq+0;
Ever_merfrs_dlqday+0;


if first.memberid;

label
Ever_merfrs_dlq="事业部首逾"
Ever_merfrs_dlqday="事业部首逾天数"
;
keep Merchant_type memberid orderno repaydate_num payday_num mob overduenum flag_return mob Loan_day Ever_merfrs_dlq Ever_merfrs_dlqday  ;

run;


proc sql;
create table sy_dlq_mth as
select 
substr(Loan_day,1,6) as loan_mth,
count(distinct memberid) as member_cnt,
count(distinct case when Ever_merfrs_dlq>0 then memberid  end) as Frs_memid,
count(distinct case when Ever_merfrs_dlqday>10 then memberid  end) as Frs10_memid,
count(distinct case when Ever_merfrs_dlqday>30 then memberid  end) as Frs30_memid,

(calculated Frs_memid)/(calculated member_cnt) as Frs_pct format percent9.2,
(calculated Frs10_memid)/(calculated member_cnt) as Frs10_pct format percent9.2,
(calculated Frs30_memid)/(calculated member_cnt) as Frs30_pct format percent9.2,
Merchant_type

from  frs_mer
group by loan_mth,Merchant_type
order by loan_mth,Merchant_type
;
quit;


DATA frs_mer_DAY;
SET frs_mer;
by Merchant_type memberid Loan_day orderno mob ;
length mth $20.;

IF LOAN_day>="20180310" then mth="4: >3.10";
else if   "20180310">LOAN_day>="20180201" then mth="3: 2.1-3.9";
else if   "20180201">LOAN_day>="20180101" then mth="2: 1.1-2.1";
else if   "20180101">LOAN_day>="20171201" then mth="1: 12.1-1.1";
else mth="0: 11-";

run;


proc sql;
create table sy_dlq_mth_rule as
select 
mth,
count(distinct memberid) as member_cnt,
count(distinct case when Ever_merfrs_dlq>0 then memberid  end) as Frs_memid,
count(distinct case when Ever_merfrs_dlqday>10 then memberid  end) as Frs10_memid,
count(distinct case when Ever_merfrs_dlqday>30 then memberid  end) as Frs30_memid,

(calculated Frs_memid)/(calculated member_cnt) as Frs_pct format percent9.2,
(calculated Frs10_memid)/(calculated member_cnt) as Frs10_pct format percent9.2,
(calculated Frs30_memid)/(calculated member_cnt) as Frs30_pct format percent9.2,
Merchant_type

from  frs_mer_DAY
group by mth,Merchant_type
order by mth,Merchant_type
;
quit;


proc sql;
create table sy_dlq_mth_rule02 as
select 
loan_day,
count(distinct memberid) as member_cnt,
count(distinct case when Ever_merfrs_dlq>0 then memberid  end) as Frs_memid,
count(distinct case when Ever_merfrs_dlqday>10 then memberid  end) as Frs10_memid,
count(distinct case when Ever_merfrs_dlqday>30 then memberid  end) as Frs30_memid,

(calculated Frs_memid)/(calculated member_cnt) as Frs_pct format percent9.2,
(calculated Frs10_memid)/(calculated member_cnt) as Frs10_pct format percent9.2,
(calculated Frs30_memid)/(calculated member_cnt) as Frs30_pct format percent9.2,
Merchant_type

from  frs_mer_DAY
where loan_day>="20180201"
group by loan_day,Merchant_type
order by loan_day,Merchant_type
;
quit;
