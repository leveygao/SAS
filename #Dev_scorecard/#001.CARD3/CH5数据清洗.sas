/********************************************************************************************************************************************/
/*先决条件：
需要用到level2和l2_tmp这两个逻辑库，其中l2_tmp存放的Credit_model_ch4数据集在本节程序使用
/********************************************************************************************************************************************/

/*CH5-1发现数据错误一般是通过数据探索的方式，*/
/*连续变量使用MEAN方法，分类变量使用FREQ方法*/
/*区分变量的度量类型*/
/*（本部分内容用到了“ODS转向输出”的知识）*/
data credit_model;
set l2_tmp.Credit_model_ch4;
run;
proc sql noprint;
 select name into :var_num separated by ' '
    from sashelp.vcolumn 
	where libname='WORK' and memname=Upper("credit_model") and type="num" and name~="target" and name~="id";
quit;
ods output NLevels=NLevels;
proc freq data=Credit_model NLEVELS ;
 tables &var_num/noprint;
run;
/*本例中武断的认为水平数超过10的都属于连续变量，一般在变量粗筛的阶段不进行细致的设置*/
proc sql;
 select TableVar into :var_scale separated by ' '
    from NLevels 
	where NNonMissLevels>10 and upper(substr(TableVar,length(TableVar)-2))~="_CD";
 select TableVar into :var_class separated by ' '
    from NLevels 
	where NNonMissLevels<=10 or upper(substr(TableVar,length(TableVar)-2))="_CD";
quit;
/*目前的连续变量有：*/
%put &var_scale;
/*目前的分类变量有：*/
%put &var_class;

/*对连续变量进行描述*/
proc means data=Credit_model n nmiss mean median mode min max;
   var &var_scale;
run;
/*对分类变量进行描述*/
proc freq data=Credit_model;
   tables &var_class;
run;


/*CH5-2处理缺失值*/
/*连续变量用中位数填补*/
proc stdize data=Credit_model 
            reponly 
            method=median 
            out=Credit_model_CH5_s2(keep=target &var_scale &var_class);
   var &var_scale;
run;
%put &var_scale;
%put &var_class;
/*分类变量用众数替代*/
/*这个比较麻烦，只能编程处理*/
ods output Summary=Summary;
proc means data=Credit_model mode;
   var &var_class;
run;

proc transpose data=Summary out=Summary_t;
run;
data Summary_t_1(keep=var mode);
   set Summary_t;
   var=substr(_NAME_,1,index(_NAME_,"_Mode")-1);
   mode=col1;
run;

proc sql  ;
select var
    from Summary_t_1 ;
quit;
%let Rows=&SQLOBS;
proc sql  noprint;
select var into :var1-:var&Rows
   from Summary_t_1;
select mode into :mode1-:mode&Rows
   from Summary_t_1;
quit;
/*%put &var1;%put &mode1;*/
/*针对每一个字符变量重新编码*/
%Macro imput_class;
%do i=1 %to &Rows;
data Credit_model_CH5_s2;
	set Credit_model_CH5_s2;
	if &&var&i=. then &&var&i=&&mode&i;
%end;
%mend imput_class;
%imput_class


/*CH5-3处理离群值*/
/*有两步：1、单变量离群值替换；2、多变量离群值删除*/
/*一般分析只做第一步，建议进行第二步*/
/*第一步:1、单变量离群值替换*/
%let lib=WORK;
%let table=Credit_model_CH5_s3; 
%let in=Credit_model_CH5_s2;
data &table;
set &in;
run;

%macro vr(v);
proc means data=&table n nmiss mean median mode min p1 p99 max std skewness ;
var &v.;
output out=var p1=p1 p99=p99;
run;
data _null_;
set var end=last;
call symputx('min',p1);
call symputx('max',p99);
run;
data &table;
set &table;
if &v.>=&max. then &v.=&max.;
if &v.<=&min. then &v.=&min.;
run;
%mend vr;


proc sql;
select name from sashelp.vcolumn
where libname=upper("&lib") and type='num' and memname=upper("&table") and name~="target" and name~="id";
%let Rows=&SQLOBS;
select name
into :name1-:name&Rows
from sashelp.vcolumn
where libname=upper("&lib") and type='num' and memname=upper("&table")  and name~="target" and name~="id";
quit;

%Macro WINSORIZE;
%do i=1 %to &Rows;
%vr(&&name&i);
%end;
%mend WINSORIZE;
%WINSORIZE

/*第二步:2、多变量离群值删除*/
/*proc stdize data=Credit_model_ch5_s3 method=std*/
/*out=Credit_model_ch5_s3_0;*/
/*var &var_num_ch4;*/
/*run;*/

proc fastclus data=credit_model_ch5_s3
	maxc=8
	maxiter=1
	replace=full
	out=work.credit_model_ch5_s3_1	;
	var &var_num;
run;

proc freq data=Credit_model_ch5_s3_1;
table CLUSTER;
run;
proc sql;
create table Credit_model_ch5_s3_2 as 
  select *,count(*) as freq
  from Credit_model_ch5_s3_1 as a
  group by CLUSTER;
 create table Credit_model_ch5_s3_3 as 
  select *,freq/count(*) as percent
  from Credit_model_ch5_s3_2 as a;
quit;
data Credit_model_ch5;
	set Credit_model_ch5_s3_3;
 	where percent>=0.01;
run;

proc freq data=Credit_model_ch5;
table CLUSTER;
run;
/*清空本章生成的所有暂时表*/
proc sql noprint;
 select memname into :table_delet separated by ','
    from sashelp.vtable 
	where libname='WORK' and memname not in ("CREDIT_MODEL","CREDIT_ACCESS","CREDIT_MODEL_CH5") ;
drop table &table_delet;
quit;
%let table_delet=;

/*本步骤最终输出结果：粗筛后的变量输出列表：*/
data l2_tmp.Credit_model_CH5(drop=CLUSTER DISTANCE freq percent);
set Credit_model_CH5;
run;

/********************************************************************************************************************************************/
/*本阶段成果列表：这些成果被自动保存在l2_tmp中作为备份
l2_tmp.Credit_model_ch5是本章处理后的数据集，进行了数据清洗*/
/********************************************************************************************************************************************/
