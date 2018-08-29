%inc ".\#00.OPTION.SAS";


/*Cash + Merchant_type*/


data Cash_post_info;
set   ch.Cash_post_info_20180806(keep= memberid orderno  Loan_mth  Loan_day    REPAYDATE_NUM  new_repaydate PAYDAY_NUM 
FLAG_RETURN  new_dlq_mthend  BILL_DAY  queue mob overdueNum   );
New_Bill_mth=  put(new_repaydate,yymmn6.);

if     		 new_dlq_mthend=0 and flag_return^=1 then  Queue_num=0;
else if 	 new_dlq_mthend=0 and flag_return=1 then Queue_num=1;

else if 	30>=new_dlq_mthend>0 then  Queue_num=1;
else if 	60>=new_dlq_mthend>30 then Queue_num=2;
else if 	90>=new_dlq_mthend>60 then Queue_num=3;
else if 	120>=new_dlq_mthend>90 then Queue_num=4;
else if 	150>=new_dlq_mthend>120 then Queue_num=5;
else if 	180>=new_dlq_mthend>150 then Queue_num=6;
else if 	210>=new_dlq_mthend>180 then Queue_num=7;
else if 	240>=new_dlq_mthend>210 then Queue_num=8;
else if 	270>=new_dlq_mthend>240 then Queue_num=9;
else if 	300>=new_dlq_mthend>270 then Queue_num=10;
else if 	 99999>new_dlq_mthend>300 then Queue_num=11;
else if 			new_dlq_mthend=99999  then Queue_num=-1;
else 		Queue_num=-999;   /*其他情况 */

run;


/*proc freq data=Cash_post_info;*/
/*tables Queue_num/missing;*/
/*run;*/

proc sort data=Cash_post_info  out=Cash_post_info_srt ;
where FLAG_RETURN^=-9;
by memberid New_Bill_mth orderno mob ;
run;

proc sql;
create table Cash_post_info_mthend as
select memberid,  New_Bill_mth, 
		max(FLAG_RETURN) as FLAG_RETURN ,
		max(new_dlq_mthend) as new_dlq_mthend,
		max(Queue_num) as Queue_num


from Cash_post_info_srt
group by memberid ,  New_Bill_mth
order by memberid ,  New_Bill_mth
;
quit;



data CH_ROLL_TAG;
set Cash_post_info_mthend;
by  memberid  New_Bill_mth;
Last_queue=lag(Queue_num);

if first.memberid  then Last_queue=.;

if first.memberid and Queue_num=0 then Roll_over=-1;
else if first.memberid and Queue_num>0 then Roll_over=1;

if not first.memberid then do;
if Queue_num>Last_queue then Roll_over=1;
else if Queue_num=11 then Roll_over=1;
else Roll_over=0;

end;
run;





/* bt */

data Bt_post_info;
set   bt.Bt_post_info_20180801(keep= memberid orderno  Loan_mth  Loan_day  Merchant_type  REPAYDATE_NUM  new_repaydate PAYDAY_NUM 
FLAG_RETURN  new_dlq_mthend  BILL_DAY  queue mob overdueNum   );
New_Bill_mth=  put(new_repaydate,yymmn6.);

if     		 new_dlq_mthend=0 and flag_return^=1 then  Queue_num=0;
else if 	 new_dlq_mthend=0 and flag_return=1 then Queue_num=1;

else if 	30>=new_dlq_mthend>0 then  Queue_num=1;
else if 	60>=new_dlq_mthend>30 then Queue_num=2;
else if 	90>=new_dlq_mthend>60 then Queue_num=3;
else if 	120>=new_dlq_mthend>90 then Queue_num=4;
else if 	150>=new_dlq_mthend>120 then Queue_num=5;
else if 	180>=new_dlq_mthend>150 then Queue_num=6;
else if 	210>=new_dlq_mthend>180 then Queue_num=7;
else if 	240>=new_dlq_mthend>210 then Queue_num=8;
else if 	270>=new_dlq_mthend>240 then Queue_num=9;
else if 	300>=new_dlq_mthend>270 then Queue_num=10;
else if 	 99999>new_dlq_mthend>300 then Queue_num=11;
else if 			new_dlq_mthend=99999  then Queue_num=-1;
else 		Queue_num=-999;   /*其他情况 */

run;


proc sort data= Bt_post_info  out=  Bt_post_info_srt ;
where FLAG_RETURN^=-9;
by memberid New_Bill_mth orderno mob ;
run;

proc sql;
create table Bt_post_info_mthend as
select memberid,  New_Bill_mth, 
		max(FLAG_RETURN) as FLAG_RETURN ,
		max(new_dlq_mthend) as new_dlq_mthend,
		max(Queue_num) as Queue_num


from   Bt_post_info_srt
group by memberid ,  New_Bill_mth
order by memberid ,  New_Bill_mth
;
quit;



data BT_ROLL_TAG;
set Bt_post_info_mthend;
by  memberid  New_Bill_mth;
Last_queue=lag(Queue_num);

if first.memberid  then Last_queue=.;

if first.memberid and Queue_num=0 then Roll_over=-1;
else if first.memberid and Queue_num>0 then Roll_over=1;

if not first.memberid then do;
if Queue_num>Last_queue then Roll_over=1;
else if Queue_num=11 then Roll_over=1;
else Roll_over=0;

end;
run;


data bck.CH_BT_ROLL_TAG_LIST0810_v2;
SET BT_ROLL_TAG(in=A)  Ch_roll_tag(IN=b);
by memberid   New_Bill_mth;
if a THEN Product='BT';
else if b then  Product='CH';
else Product='OO';
run;


proc sql;
 
select COUNT(distinct memberid) as member,Product
FROM bck.CH_BT_ROLL_TAG_LIST0810_v2
group by Product
;
quit;



/*

proc sql;
create table BT_ROLL_TAG_LIST as
select *
FROM BT_ROLL_TAG
WHERE memberid in( select distinct memberid from BT_ROLL_TAG where Roll_over=1)
order by memberid ,  New_Bill_mth
;
quit;

proc sql;
create table CH_ROLL_TAG_LIST as
select *
FROM CH_ROLL_TAG
WHERE memberid in( select distinct memberid from CH_ROLL_TAG where Roll_over=1)
order by memberid ,  New_Bill_mth
;
quit;




data dt.CH_BT_ROLL_TAG_LIST0810;
SET BT_ROLL_TAG_LIST  Ch_roll_tag_list;
by memberid   New_Bill_mth;
run;


