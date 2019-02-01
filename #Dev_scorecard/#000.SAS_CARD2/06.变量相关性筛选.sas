/*options mprint=yes;*/
/*�꣺CORR_SLCT
��;��������Ըߵı�����ɸѡ��IV�ϸߵı���

in_dataset_woe:����WOEת��������ݼ�
woe_varname����WOEǰ׺�ı��������ÿո�ָ�
criteria�������ɸѡ����
var_iv:������IV�б�
corr_out������Ծ������
var_slct:ͨ�������ɸѡ�ı����б�
Log_in:��Ϊ�գ������嵥
Log_out:��log_in��Ϊ��ʱ��log_out����Ϊ�գ���ͨ��ɸѡ�ı�����¼��log_in*/
%macro corr_slct(in_dataset_woe,woe_varname,criteria,var_iv,corr_out,var_slct,log_in,log_out);

%let corr_n=%sysfunc(countw(&woe_varname.," "));

proc corr data=&in_dataset_woe. outp=&corr_out. pearson;/*�������ϵ��������*/
var
&woe_varname.
;
run;

data &corr_out.;/*���ϵ�������*/
	set &corr_out.;
	keep _NAME_ _numeric_;
	where _NAME_ ne "";
run; 

/*���������ϵ�����������ϵ��С��XXX�ģ������ϵ�����ڵ���XXX�������*/

proc delete data=high_corr_var;
run;

%let k=&corr_n;
data corr_gt06;
	set &corr_out.;
	format grp1-grp&k. $8.
	       id1-id&k. $8.;

	array variable(*) _numeric_;
	array grp(*) grp1-grp&k.;
	array id(*) id1-id&k.;

	do i=1 to dim(variable);
		if i>_N_ then variable(i)=.;
		if abs(variable(i))>&criteria. then grp(i)=put(i,$8.);
		if variable(i)=1 and i=_N_ then id(i)=put(i,$8.);
	end;
	drop i;
run;

%do i=1 %to &corr_n;

	data corr&i.;
		set corr_gt06;
		where compress(grp&i.)=compress("&i.");
		keep _name_ grp&i. id&i.;
		rename grp&i.=group
		       id&i.=var_id;
	run;

	proc append base=high_corr_var data=corr&i. force;
	run;

	proc delete data=corr&i.;
%end;


/*�������Գ�һ��ĸ�����Ա���*/
proc sql;/*������Щ��ɸѡ�ı���*/
	create table high_corr_var2 as 
		select a._name_, a.group, a.var_id from 
			(select * from high_corr_var a 
				left join 
				(select _name_, group,count(*) as ctn from high_corr_var group by group) b
				on a._name_=b._name_ and a.group=b.group) 
		where ctn>1;

/*������Ըߵı������ݴַֺ��IVɸѡ*/
	create table high_corr_var_iv1 as 
		select a._name_, a.group, a.var_id, b.iv from
			high_corr_var2 a left join &var_iv. b
			on a._name_=compress("WOE_"||b.var_no);
quit;


proc delete data=high_corr_var_slct high_corr_var_non_slct;
run;


proc sort data=high_corr_var_iv1;
by group IV;
run;

data high_corr_var_iv1;
	set high_corr_var_iv1;
	by group;
	retain seq;
	if _n_=1 then seq=0;
	if first.group then do;
		seq=seq+1;
		IV_order=1;
	end;
	else IV_order+1;
	output;
run;

proc sql;
select max(seq) into :n_grp from high_corr_var_iv1;
quit;

%do i=1 %to &n_grp;


 proc sql;
 select max(iv_order) into :max_iv from high_corr_var_iv&i. where seq=&i;
 quit;

 data slct;
 set high_corr_var_iv&i.;
 where seq=&i. and iv_order=&max_iv.;
 run;

 proc sort data=slct nodupkey;
 by group;
 run;

 proc append base=high_corr_var_slct data=slct force;/*�������ı���*/
 run;

 proc sql;
 select group, var_id into :grp_n, :var_id_n from slct;
 quit;

	 %if &grp_n.=&var_id_n. %then %do;

		 data non_slct;
			 set high_corr_var_iv&i.;
			 where seq=&i. and group ne var_id;
		 run;
	%end;

	%else %if &grp_n. ne &var_id_n. %then %do;

		 data non_slct;
			 set high_corr_var_iv&i.;
			 where seq=&i. and group=var_id;
		 run;
	%end;

 proc append base=high_corr_var_non_slct data=non_slct force;/*��ɾ���ı���*/
 run;

 %let k=%eval(&i+1);
proc sql;
	create table high_corr_var_iv&k as 
		select * from high_corr_var_iv&i. 
	where _name_ not in (select _name_ from non_slct);
quit;

%end;


/*���ܴ���ģ��������ȥ��һ���б�ɾ���ı�����ȥ��*/
proc sql;
create table &var_slct. as 
select distinct _name_ as woe_var_no,substr(woe_var_no,5,length(woe_var_no)-4) as var_no from high_corr_var where _name_ not in (select distinct _name_ from  high_corr_var_non_slct);
quit;

/*record var performance*/
	%if &LOG_in. ne %str()  %then %do;
		proc sort data=&var_slct.;
			by woe_var_no;
		run;

		data _temp;
			set &LOG_IN.;
			woe_var_no=compress("WOE_"||var_no);
			drop corr_slct;
		run;

		proc sort data=_temp;
		by woe_var_no;
		run;

		data _temp;
		merge _temp(in=a)
		      &var_slct.(in=b keep=woe_var_no);
			by woe_var_no;
			if a;
			if a and b then corr_slct=1;
			if a and not b then corr_slct=0;
		run;

		data &LOG_OUT.;
			set _temp;
			drop woe_var_no;
		run;

		proc delete data=_temp;
		run;
		
	%end;

%mend;

