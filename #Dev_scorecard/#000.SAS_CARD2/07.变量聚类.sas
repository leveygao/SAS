/*�꣺VAR_CLUS
��;�������WOEת���ı������б�������

in_dataset_woe:����WOEת��������ݼ�
woe_varname����WOEǰ׺�ı��������ÿո�ָ�
max_clus������������
varclus_rslt:������
corr_out������Ծ������
Log_in:��Ϊ�գ������嵥,��var_num��Ϊ��ʱ���ñ��������FINEBIN_IV��
Log_out:��log_in��Ϊ��ʱ��log_out����Ϊ�գ�����������¼��log_in
var_num:��Ϊ�գ�����IV��ÿ��ѡȡvar_num������������¼��log_out*/
%macro VAR_CLUS(in_dataset_woe, woe_varname, max_clus,varclus_rslt,LOG_in,LOG_out,var_num);

data cluster_set;
	set &in_dataset_woe.(keep=&woe_varname);

	/*����ֵ�����Ŀ�ֵ��Ϊ0*/
	array num _numeric_;
	do over num;
	if num=. then num=0;
	end;
run;

/*����*/
proc varclus data=cluster_set outstat=varclus_rslt maxclusters=&max_clus.;/*�������ݾ���ʹ���������*/
	var &woe_varname.;
run;

/*��ȡ���������*/
/*��ȡ����������*/
proc sql;
	select max(_NCL_) into :ttlclus from varclus_rslt;
quit;

/*��������������صĹ۲�*/
data varclus_rslt;
	set varclus_rslt;
	where _NCL_=&ttlclus. and _TYPE_='SCORE';
	drop _NCL_ _TYPE_;
run;

/*ת�þ�������ʹ��������Ϊ��һ��*/
proc transpose data=varclus_rslt name=variable out=varclus_trans;
	ID _NAME_; 
run;

/*������һ��cluster��¼ÿ������������һ��*/
data &varclus_rslt.(keep=woe_var_no var_no cluster);
	set varclus_trans;
	array clus(*) _numeric_;
	do i=1 to dim(clus);
	if clus(i) ne 0 then cluster=i;
	end;
	
	var_no=substr(variable,5,length(variable)-4);
	rename variable=woe_var_no;
	drop i;
run;

/*record var performance*/
	%if &LOG_in. ne %str()  %then %do;

	proc sort data=&varclus_rslt.(keep=var_no cluster) out=temp_1;
		by var_no;
	run;

	proc sort data=&LOG_in. out=&LOG_out.;
		by var_no;
	run;
	
	data &LOG_out.;
		set &LOG_out.;
		drop cluster clus_slct;
	run;

	data &LOG_out.;
		merge &LOG_out.(in=a) temp_1(in=b);
		by var_no;
		if a;
	run;

	/*ȡÿ�������IV���ı���*/
		%if %scan(&var_num.,1) ne %str() %then %do;
		proc sort data=&LOG_out. ;
			by cluster descending FINEBIN_IV ;
		run;

		data &LOG_out.;
			set &LOG_out.;
			by cluster;
			if first.cluster then n=1;
			else n+1;
			output;
		run;

		data &LOG_out.;
			set &LOG_out.;
			if n<=&var_num. then clus_slct=1;
			else clus_slct=0;
			drop n;
		run;
		proc sort data=&LOG_out.;
			by var_no;
		run;
		%end;
	%end;

%mend;