%inc ".\#00.OPTION.SAS";


proc sort data= bck.CH_BT_ROLL_TAG_LIST0810_v2 out=CH_BT_ROLL_TAG_LIST0810_v2;
by memberid   New_Bill_mth  Product;
run;

/* 100049700 */


proc sql;
create table bck.CH_BT_ROLL_TAG_LIST0810_v2_ndp as

select memberId,New_Bill_mth ,
  		max(FLAG_RETURN) as  FLAG_RETURN,
		max(new_dlq_mthend) as  new_dlq_mthend,
		max(Queue_num) as  Queue_num, 
		max(Last_queue) as Last_queue,
		max(Roll_over) as Roll_over


FROM  CH_BT_ROLL_TAG_LIST0810_v2
group by memberId,New_Bill_mth 
order by memberId,New_Bill_mth 

;
quit;


/*
proc sort data= CH_BT_ROLL_TAG_LIST_fin out=dt.CH_BT_ROLL_TAG_LIST_fin nodupkey;
by memberid   New_Bill_mth   ;
run;
