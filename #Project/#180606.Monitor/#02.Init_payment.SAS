%inc ".\#00.OPTION.SAS";


proc sql;
create table bck.Init_pay_cnt as
select
 count(distinct a.refBizTxnId) as order_cnt,
 count(distinct a.memberid) as member_cnt, 
 a.hitFlag , a.idRule, put(datepart(a.crttime),yymmn6.) as Month,
 	b.ruleName,		b.ruleSetCode
 /*
case when idRule=287 then 'DMS_INIT_PAY  '  
	when idRule=191 then 'FLIGHT_DEST_INIT_PAY' 
 		when idRule=296 then 'FLIGHT_INIT_PAY     '      
 		when idRule=224 then 'DM_INIT_PAY   '     
 		when idRule=233 then 'DM_DMS_INIT_PAY     '       end as Rule
*/

from fq_rcs.RuleDetailLog as a left join fq_rcs.RiskRule as b
	on a.idrule=b.idRiskRule

where a.idRule in (287,191,296,224,233)  
group by hitflag,Month,idrule,ruleName,ruleSetCode
order by Month,idrule
;
quit;


proc sql;
create table bck.Init_pay_pct as
select
  put(datepart(a.crttime),yymmn6.) as Month, a.idRule, b.ruleName,		b.ruleSetCode,
  
 count(distinct a.refBizTxnId) as order_cnt,
 count(distinct a.memberid) as member_cnt,
 
 count(distinct case when hitflag=1 then a.refBizTxnId end ) as rej_order_cnt,
 count(distinct case when hitflag=1 then a.memberid end ) as rej_member_cnt,
 
 
(calculated rej_order_cnt )/ (calculated order_cnt )  as Rej_order_pct format percent9.2,
(calculated rej_member_cnt )/ (calculated member_cnt)  as Rej_member_pct format percent9.2



from fq_rcs.RuleDetailLog as a left join fq_rcs.RiskRule as b
	on a.idrule=b.idRiskRule

where  a.idRule in (287,191,296,224,233)  
group by Month,a.idRule ,b.ruleName,b.ruleSetCode
order by Month,idrule
;
quit;

PROC EXPORT DATA=   bck.Init_pay_pct 
            OUTFILE= ".\EXCEL\Init_pay_pct&TDAY..XLSX" 
            DBMS=EXCEL REPLACE;
     SHEET="Init_pay_pct&tday."; 
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





