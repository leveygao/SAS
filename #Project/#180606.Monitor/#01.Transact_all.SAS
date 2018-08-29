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
create table  merchant_trans_pct as
select
  put(datepart(a.crttime),yymmn6.) as Month, a.idRule,  b.ruleName,		b.ruleSetCode,

    
 count(distinct a.refBizTxnId) as order_cnt,
 count(distinct a.memberid) as member_cnt,
 
 count(distinct case when hitflag=1 then a.refBizTxnId end ) as rej_order_cnt,
 count(distinct case when hitflag=1 then a.memberid end ) as rej_member_cnt,
 
 
(calculated rej_order_cnt )/ (calculated order_cnt )  as Rej_order_pct format percent9.2,
(calculated rej_member_cnt )/ (calculated member_cnt)  as Rej_member_pct format percent9.2



from fq_rcs.RuleDetailLog as a left join fq_rcs.RiskRule as b
	on a.idrule=b.idRiskRule

where  a.runMode="1"   and a.idrule in(559,561,562,563,564,
619,620,621,622,623,624,625,626,627,628,630,631,632,633,634,635,636,637,538,639,640,641,642,
538,566,569,570,571,571,572,187,188,320,573,537,587,264,313,302,266,286,225,341,608,
594,119,643,234,310,646,585,713,714,1547,1546,
593,586,647,645,1543,
68,1536,1537,1538,1539,1542, 73 ,229,
65,70,71,72,318,319,66,592,591,922,1544,1545
)
group by Month,a.idRule ,b.ruleName,b.ruleSetCode 
order by Month,idrule
;
quit;

proc sql;
create table bck.merchant_transact_pct as
select *,
  
  case when a.idRule in(559,561,562,563,564) then 'BLACK_LIST'
		when a.idRule in(619,620,621,622,623,624,625,626,627,628,630,631,632,633,634,635,636,637,538,639,640,641,642) then 'TICKET_VENDOR'
		when a.idRule in(538,566,569,570,571,571,572,187,188,320,573,537,587,264,313,302,266,286,225,341,608)  then 'ALL_MERCHANT'
		when a.idRule in(594,119,643,234,310,646,585,713,714,1547,1546) then 'FLIGHT'
		when a.idRule in(593,586,647,645,1543) then 'TRAIN'
		when a.idRule in(68,1536,1537,1538,1539,1542, 73 ,229) then 'TOUR_INT&CRUISE'
		when a.idRule in(65,70,71,72,318,319,66,592,591,922,1544,1545) then 'TOUR_DMS'

		end as Merchant length=20
		
from merchant_trans_pct as  a
order by Month,Merchant,idRule
;
quit;
		
		

PROC EXPORT DATA=   bck.merchant_transact_pct 
            OUTFILE= ".\EXCEL\merchant_transact_pct&TDAY..XLSX" 
            DBMS=EXCEL REPLACE;
     SHEET="merchant_transact_pct&tday."; 
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





