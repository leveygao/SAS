%inc ".\#00.OPTION.SAS";


proc sql;
create table bck.BT_Counter_cnt as
select
 count(distinct a.refBizTxnId) as order_cnt,
 count(distinct a.memberid) as member_cnt, 
   put(datepart(a.crttime),yymmn6.) as Month,
 
 a.idrule, b.ruleName,		b.ruleSetCode
 /*
case when idRule=877 then 'REJ_yunnan_guangzhou_agency  '  
	when idRule=867 then 'Rej_DLQ60+              ' 
 		when idRule=864 then 'Rct60DAY_Merchant_num    '      
 		when idRule=860 then 'Rej_Cash_dlq        '     
 		when idRule=878 then 'Rej_nanfang_air     '
		when idRule=873 then 'Rej_new_user      '
		 	end as Rule
*/


from fq_rcs.RuleDetailLog as a left join fq_rcs.RiskRule as b
	on a.idrule=b.idRiskRule

where a.idRule in (877,867,864,860,878,873)  
group by  Month,a.idRule ,b.ruleName,b.ruleSetCode
order by Month,idrule
;
quit;


proc sql;
create table bck.BT_Counter_pct as
select
  put(datepart(a.crttime),yymmn6.) as Month, a.idRule,  b.ruleName,		b.ruleSetCode ,
  
 count(distinct a.refBizTxnId) as order_cnt,
 count(distinct a.memberid) as member_cnt,
 
 count(distinct case when hitflag=1 then a.refBizTxnId end ) as rej_order_cnt,
 count(distinct case when hitflag=1 then a.memberid end ) as rej_member_cnt,
 
 
(calculated rej_order_cnt )/ (calculated order_cnt )  as Rej_order_pct format percent9.2,
(calculated rej_member_cnt )/ (calculated member_cnt)  as Rej_member_pct format percent9.2 


from fq_rcs.RuleDetailLog as a left join fq_rcs.RiskRule as b
	on a.idrule=b.idRiskRule

where   a.idRule in (877,867,864,860,878,873)  
group by  Month,a.idRule ,b.ruleName,b.ruleSetCode
order by Month,idRule
;
quit;

PROC EXPORT DATA=   bck.BT_Counter_pct 
            OUTFILE= ".\EXCEL\BT_Counter_pct&TDAY..XLSX" 
            DBMS=EXCEL REPLACE;
     SHEET="BT_Counter_pct&tday."; 
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





