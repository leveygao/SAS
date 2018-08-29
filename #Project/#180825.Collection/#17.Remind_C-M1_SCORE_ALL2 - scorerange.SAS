%inc ".\#00.OPTION.SAS";


proc import file= 'D:\GY\18.8.9 Collection Card\card\All_CM1_member_score201705.csv'
out= All_member_score
dbms=csv  replace;
run;



proc sort data=All_member_score  out=All_member_score(keep= memberid Collect_score) nodupkey ;
by memberid ;
run;



/* bt + ch */

proc sort data= ch.Cash_tag_dlq_20180806    
out= Cash_tag_dlq nodupkey ;
by memberid ;
run;

proc sort data= bt.Bt_tag_dlq_20180801    
out= Bt_tag_dlq (drop=Merchant_type 
rename=(Ever_merfrs_dlq=Ever_frs_dlq   Ever_merfrs_dlqday= Ever_frs_dlqday   Loan_day_MerFrs=Loan_day_Frs ) ) 
nodupkey ;
by memberid ;
run;



data CASH_BT_DLQ_TAG;
merge All_member_score(in=a)   Cash_tag_dlq(in=b)   Bt_tag_dlq(in=c);
by memberid;
if a;

match_chbt= compress(a||b||c);

length USED_TYPE $10. Member_price $12.;
if carduser=1  then USED_TYPE='CARD';
else  if carduser=0 then USED_TYPE='CASH';
/*else  if (carduser=0 or missing(carduser)) and match_chbt=1 then USED_TYPE='BT';*/
else USED_TYPE='BT';


if Customer_Pricing_Acct='Other' then Member_price='Old_Cash';
else if missing(Customer_Pricing_Acct) then Member_price='BT';
else Member_price=Customer_Pricing_Acct;

if missing(carduser) then carduser=-1;

if not missing(applydate) then Apply_loan_intv=intck("day", input(applydate,yymmdd8.),  input(Loan_day_Frs,yymmdd8.) );
else Apply_loan_intv=.;

if missing(Apply_loan_intv) then flag_Apply_loan=-99;
else if Apply_loan_intv<0 then flag_Apply_loan=-1;
else if Apply_loan_intv=0  then flag_Apply_loan=0;
else if Apply_loan_intv>0  then flag_Apply_loan=1;


drop total_order  OrderSuccess_rate      
;
run;

proc freq data=  CASH_BT_DLQ_TAG  ;
tables  match_chbt/missing;
run;


data Sample_CM1;
set   CASH_BT_DLQ_TAG(rename=(Collect_score=score));
by memberid;
where match_chbt in('101','110','111');



length  score_range  $20.;
if   missing(score) or score=0 then score_range="(0 | missing)";
else if 0<score<400then score_range="[0,400)";
else if 400<=score<410then score_range="[400,410)";
else if 410<=score<420then score_range="[410,420)";
else if 420<=score<430then score_range="[420,430)";
else if 430<=score<440then score_range="[430,440)";
else if 440<=score<450then score_range="[440,450)";
else if 450<=score<460then score_range="[450,460)";
else if 460<=score<470then score_range="[460,470)";
else if 470<=score<480then score_range="[470,480)";
else if 480<=score<490then score_range="[480,490)";


else if 490=<score<500 then score_range="[490,500)";
else if 500<=score<510then score_range="[500,510)";
else if 510<=score<520then score_range="[510,520)";
else if 520<=score<530then score_range="[520,530)";
else if 530<=score<540then score_range="[530,540)";
else if 540<=score<550then score_range="[540,550)";
else if 550<=score<560then score_range="[550,560)";
else if 560<=score<570then score_range="[560,570)";
else if 570<=score<580then score_range="[570,580)";
else if 580<=score<590then score_range="[580,590)";
else if 590<=score<600then score_range="[590,600)";
else if 600<=score<610then score_range="[600,610)";
else if 610<=score<620then score_range="[610,620)";
else if 620<=score<630then score_range="[620,630)";
else if 630<=score<640then score_range="[630,640)";
else if 640<=score<650then score_range="[640,650)";
else if 650<=score<660then score_range="[650,660)";
else if 660<=score<670then score_range="[660,670)";
else if 670<=score<680then score_range="[670,680)";
else if 680<=score<690then score_range="[680,690)";
else if 690<=score<700then score_range="[690,700)";
else if 700<=score<710then score_range="[700,710)";
else if 710<=score<720then score_range="[710,720)";
else if 720<=score    then score_range="[720,+)";
else score_range='other';

run;




proc sql;
create table score_dlq as
select score_range,
		count(memberid ) as member,
		sum(Overday_E30dlq) as dlq30,
		sum(Overday_E60dlq) as dlq60,

/*		count(case when EVER_3M2_ordercnt=1 then memberid end) as E3M2_1_CNT,*/
/*		count(case when EVER_3M2_ordercnt=2 then memberid end) as E3M2_2_CNT,*/
/*		count(case when EVER_3M2_ordercnt>=3 then memberid end) as E3M2_3P_CNT,*/

		(calculated dlq30)/(calculated member) as  dlq30_pct format percent9.2,
		(calculated dlq60)/(calculated member) as  dlq60_pct format percent9.2
/*		(calculated E3M2_1_CNT)/(calculated member) as  E3M2_1_pct format percent9.2,*/
/*		(calculated E3M2_2_CNT)/(calculated member) as  E3M2_2_pct format percent9.2,*/
/*		(calculated E3M2_3P_CNT)/(calculated member) as  E3M2_3P_pct format percent9.2*/
	

from Sample_CM1
where Overday_E60dlq>=0

group by score_range
order by score_range
;
quit;



proc sql;
create table score_dlq_acct as
select score_range,    Customer_Pricing_Acct,
		count(memberid ) as member,
		sum(Overday_E30dlq) as dlq30,
		sum(Overday_E60dlq) as dlq60,

/*		count(case when EVER_3M2_ordercnt=1 then memberid end) as E3M2_1_CNT,*/
/*		count(case when EVER_3M2_ordercnt=2 then memberid end) as E3M2_2_CNT,*/
/*		count(case when EVER_3M2_ordercnt>=3 then memberid end) as E3M2_3P_CNT,*/

		(calculated dlq30)/(calculated member) as  dlq30_pct format percent9.2,
		(calculated dlq60)/(calculated member) as  dlq60_pct format percent9.2
/*		(calculated E3M2_1_CNT)/(calculated member) as  E3M2_1_pct format percent9.2,*/
/*		(calculated E3M2_2_CNT)/(calculated member) as  E3M2_2_pct format percent9.2,*/
/*		(calculated E3M2_3P_CNT)/(calculated member) as  E3M2_3P_pct format percent9.2*/
	

from Sample_CM1
where Overday_E60dlq>=0

group by score_range,Customer_Pricing_Acct
order by score_range
;
quit;



proc sql;
create table ifpaid as 
select  a.score_range,  a.Customer_Pricing_Acct,
		count(a.memberid ) as member,
		sum(b.ifpaid) as paid,

		(calculated paid)/(calculated member) as  Paid_acct_pct format percent9.2
		

from Sample_CM1 as a left join  dt.Fin_cm1_last_list_201706 as b 
	on a.memberid = b.memberid
where a.Overday_E60dlq>=0
group by a.score_range,a.Customer_Pricing_Acct
order by  score_range,Customer_Pricing_Acct
;
quit;


proc sql;

select  a.Customer_Pricing_Acct,
		count(a.memberid ) as member,
		sum(b.ifpaid) as paid,

		(calculated paid)/(calculated member) as  Paid_acct_pct format percent9.2
		

from Sample_CM1 as a left join  dt.Fin_cm1_last_list_201706 as b 
	on a.memberid = b.memberid
where a.Overday_E60dlq>=0
group by  a.Customer_Pricing_Acct
order by  Customer_Pricing_Acct
;
quit;



/*


proc export data= score_dlq
outfile='.\card\Allscore_dlq_range1705.xlsx'
dbms= excel replace;
run;


proc export data= score_dlq_acct
outfile='.\card\Allscore_dlq_acct_range1705.xlsx'
dbms= excel replace;
run;



proc export data= ifpaid
outfile='.\card\Allscore_paid_acct_range1705.xlsx'
dbms= excel replace;
run;

