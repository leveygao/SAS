/*�꣺RENAME
  ��;����ԭ���ݼ�������ת��Ϊvar_1��var_2��var_3...��ʽ���Ӷ�����������ں�����ģ�����г���32λ�������Ҳ�ɶԱ���������������ɢ���Խ����жϡ�

  ���������
  pk:����
  default_flag:�û���ʶ
  in_dataset:�������ݼ�
  out_dataset:������ݼ�
  list�����ԭ���������±������Լ��������͵Ķ�Ӧ��ϵ��
  categorise����Ϊ�գ�����Ϊ�ջ�����ݼ���ǰ1000���۲�ȡֵ���м�⣬�����ִ���35����ͬȡֵ���򽫱�����Ϊ����������1����������Ϊ��ɢ������2����*/
%macro Rename(pk,default_flag,in_dataset,out_dataset,list,categorise);

proc contents data=&in_dataset(drop=&PK. &default_flag.) out=&list.(keep=name type label);run;
data &list.;
	set &list.;
	format cat_type 8.;
	cat_type=type;
	num=_n_;
	var_no=compress("VAR_"||num);
	if  label="'" then label=name;
run;

proc sql;
select count(distinct name) into :var_ctn from &list.;
select name, var_no into :var_name  separated by " ", :var_num  separated by " " from &list.;
quit;

data &out_dataset.;
set &in_dataset.(keep=&PK. &default_flag. &var_name.);

	RENAME
	
		%do i=1 %to &var_ctn.;
			%SCAN(&var_name.,&i)=%SCAN(&var_num.,&i)
		%end;
	;
run;

%if %scan(&categorise.,1," ") ne %str() %then %do;
	proc sql noprint;
		select  compress(var_no) into: varname separated by " " from &list.; 
	quit;

	%let p1=1;
		%do %while(%scan(&varname.,&p1.,' ') ne %str() ) ;
			%let KPVAR=%scan(&varname.,&p1.,' ');
			proc sql;
					select count(distinct &KPVAR.) into: CAT from &out_dataset.(obs=1000);
			quit;

			%if &CAT.<=35 %then %do;
				data &list.;
					set &list.;
					if compress(var_no)="&KPVAR." then cat_type=2;
				run;
			%end;
			%else %do;
				data &list.;
					set &list.;
		 			if compress(var_no)="&KPVAR." then cat_type=1;
				run;
			%end;
			%let p1=%eval(&p1.+1);
			%put &p1.;
		%end;
%end;
%mend;
	