/*宏：RENAME
  用途：将原数据集变量名转换为var_1、var_2、var_3...形式，从而避免变量名在后续建模过程中超过32位的情况。也可对变量是连续还是离散属性进行判断。

  输入输出：
  pk:主键
  default_flag:好坏标识
  in_dataset:输入数据集
  out_dataset:输出数据集
  list：输出原变量名与新变量名以及变量类型的对应关系表
  categorise：可为空，若不为空会对数据集的前1000条观测取值进行检测，若出现大于35个不同取值，则将变量视为连续变量（1），否则视为离散变量（2）。*/
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
	