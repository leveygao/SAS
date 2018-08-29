%inc ".\#00.OPTION.SAS";

/*
proc sql;
create table bck.merchant_ordrule_cnt as
select
 count(distinct a.refBizTxnId) as order_cnt,
 count(distinct a.memberid) as member_cnt, 
   put(datepart(a.crttime),yymmddn8.) as time,
 a.idrule, b.ruleName,		b.ruleSetCode
 
case when idRule=1547 then 'FLIGHT-MALE  '  
	when idRule=1546 then 'FLIGHT-FEMALE' 
 		when idRule=1545 then 'DMS_MALE     '      
 		when idRule=1544 then 'DMS_FEMALE   '     
 		when idRule=1542 then 'INT_MALE     '       end as Merchant



from fq_rcs.RuleDetailLog as a left join fq_rcs.RiskRule as b
	on a.idrule=b.idRiskRule

where a.idRule in (1547,1546,1545,1544,1542)  
group by  time,a.idRule ,b.ruleName,b.ruleSetCode
order by time,idrule
;
quit;
*/

proc sql;
create table merchant_ordrule_pct as
select
  put(datepart(a.crttime),yymmddn8.) as time, a.idRule,  b.ruleName,		b.ruleSetCode,
  
 count(distinct a.refBizTxnId) as order_cnt,
 count(distinct a.memberid) as member_cnt,
 
 count(distinct case when hitflag=1 then a.refBizTxnId end ) as rej_order_cnt,
 count(distinct case when hitflag=1 then a.memberid end ) as rej_member_cnt,
 
 
(calculated rej_order_cnt )/ (calculated order_cnt )  as Rej_order_pct format percent9.2,
(calculated rej_member_cnt )/ (calculated member_cnt)  as Rej_member_pct format percent9.2



from fq_rcs.RuleDetailLog as a left join fq_rcs.RiskRule as b
	on a.idrule=b.idRiskRule

where idRule in (1547,1546,1545,1544,1542)  
group by time,a.idRule ,b.ruleName,b.ruleSetCode
order by time,idRule
;
quit;


proc sql;
create table merchant_ordrule_pct0401 as
select
  put(datepart(a.crttime),yymmddn8.) as time, a.idRule,  b.ruleName,		b.ruleSetCode,
  
 count(distinct a.refBizTxnId) as order_cnt,
 count(distinct a.memberid) as member_cnt,
 
 count(distinct case when hitflag=1 then a.refBizTxnId end ) as rej_order_cnt,
 count(distinct case when hitflag=1 then a.memberid end ) as rej_member_cnt,
 
 
(calculated rej_order_cnt )/ (calculated order_cnt )  as Rej_order_pct format percent9.2,
(calculated rej_member_cnt )/ (calculated member_cnt)  as Rej_member_pct format percent9.2



from fq_rcs.RuleDetailLog_20180401 as a left join fq_rcs.RiskRule as b
	on a.idrule=b.idRiskRule

where idRule in (1547,1546,1545,1544,1542)  
group by time,a.idRule ,b.ruleName,b.ruleSetCode
order by time,idRule
;
quit;

data bck.merchant_ordrule_pct_&tday. ;
set   merchant_ordrule_pct   merchant_ordrule_pct0401;
run;

PROC EXPORT DATA=   bck.merchant_ordrule_pct_&tday. 
            OUTFILE= ".\EXCEL\merchant_ordrule_pct&TDAY..XLSX" 
            DBMS=EXCEL REPLACE;
     SHEET="merchant_rule&tday."; 
RUN;

/*
proc sql ;
create table  bck.merchant_orderrule_pct as
select 
distinct time,idrule,merchant,
case when hitFlag=1 then member_cnt end as Rej_member,
case when hitFlag=1 then order_cnt end as Rej_order,
case when hitFlag=0 then member_cnt end as Acp_member,
case when hitFlag=0 then order_cnt end as Acp_order,

(calculated Rej_member)/((calculated Acp_member)+(calculated Rej_member)) as Rej_member_pct format percent9.2,
(calculated Rej_order)/((calculated Acp_order)+(calculated Rej_order)) as Rej_order_pct format percent9.2

from bck.merchant_orderrule
order by time,merchant;
quit;





