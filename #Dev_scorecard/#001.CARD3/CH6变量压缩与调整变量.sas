/********************************************************************************************************************************************/
/*先觉条件：
需要用到level2和l2_tmp这两个逻辑库，其中l2_tmp存放的Credit_model_ch5数据集在本节程序使用
%put &var_class;/*经过粗筛的所有分类变量列表：*/
%put &var_scale;/*经过粗筛的所有连续变量列表：*/

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
/********************************************************************************************************************************************/
data Credit_model_CH5;
set l2_tmp.Credit_model_CH5;
run;
data Credit_access;
set l2_tmp.Credit_access;
run;

/*CH6-2分类变量压缩-WOE方法*/
/*将分类变量的宏变量存入宏变量数组*/
data var_class(keep=&var_class);
set Credit_model_ch5;
stop;
run;
proc sql;
select name from sashelp.vcolumn
where libname=upper("WORK") and memname=upper("var_class") ;
%let Rows=&SQLOBS;
select name
into :name1-:name&Rows
from sashelp.vcolumn
where libname=upper("WORK") and memname=upper("var_class") ;
quit;

%Macro putall;/*这段宏是检验宏数组是否正确*/
%do i=1 %to &Rows;
%put &&name&i;
%end;
%mend putall;
%putall
/*******************************************************/
/* Macro: CalcWOE */
/*取自《信用风险评分卡研究_基于SAS的开发与实施》*/
/*******************************************************/
%macro CalcWOE(DsIn, IVVar, DVVar, WOEDS, WOEVar, DSout,DACCESS);
/* Calculating the WOE of an Independent variable IVVar and 
adding it to the data set DSin (producing a different output 
dataset DSout). The merging is done using PROC SQL to avoid 
the need to sort for matched merge. The new woe variable
is called teh WOEVar. The weight of evidence values
are also produced in the dataset WOEDS*/

/* Calculate the frequencies of the categories of the DV in each
of the bins of the IVVAR */

PROC FREQ data =&DsIn noprint;
  tables &IVVar * &DVVar/out=Temp_Freqs;
run;

/* sort them */
proc sort data=Temp_Freqs;
 by &IVVar &DVVar;
run;

/* Sum the Goods and bads and calcualte the WOE for each bin */
Data Temp_WOE1;
 set Temp_Freqs;
 retain C1 C0 C1T 0 C0T 0;
 by &IVVar &DVVar;
 if first.&IVVar then do;
      C0=Count;
	  C0T=C0T+C0;
	  end;
 if last.&IVVar then do;
       C1=Count;
	   C1T=C1T+C1;
	   end;
 
 if last.&IVVar then output;
 drop Count PERCENT &DVVar;
call symput ("C0T", C0T);
call symput ("C1T", C1T);
run;

/* summarize the WOE values ina woe map */ 
Data &WOEDs;
 set Temp_WOE1;
  GoodDist=C0/&C0T;
  BadDist=C1/&C1T;
  if(GoodDist>0 and BadDist>0)Then   WOE=log(BadDist/GoodDist);
  Else WOE=.;
  keep &IVVar WOE;
run;

proc sort data=&WOEDs;
 by WOE;
 run;

/* Match the maps with the values and create the output
dataset */
proc sql noprint;
	create table &dsout as 
	select a.* , b.woe as &WOEvar from &dsin a, &woeds b where a.&IvVar=b.&IvVar; 
quit;
proc sql noprint;
	create table &DACCESS as 
	select a.* , b.woe as &WOEvar from &DACCESS a, &woeds b where a.&IvVar=b.&IvVar; 
quit;

/* Clean the workspace */
proc datasets library=work nodetails nolist;
 delete Temp_Freqs Temp_WOE1;
run; quit;
%mend;

%Macro Class2scal;
%do i=1 %to &Rows;
%CalcWOE(Credit_model_ch5,&&&name&i, target, WOEDS_&&name&i, WOE_&&name&i, Credit_model_ch5,Credit_access);
data l2_tmp.WOEDS_&&name&i;
set WOEDS_&&name&i;
run;
proc datasets library=work nodetails nolist;
 delete WOEDS_&&name&i;
run; quit;
%end;
%mend Class2scal;
%Class2scal




/*CH6-2连续变量压缩*/
data var_list(keep=target  &var_scale woe_:);
set Credit_model_ch5;
stop;
run;
proc sql;
 select name into :var_list separated by ' '
    from sashelp.vcolumn 
	where libname='WORK' and memname=Upper("Var_list") and name~="target";
quit;

/*使用变量聚类:主成分分析法*/
/*
ods trace on/listing;

proc varclus data=Credit_model_CH5 
             maxeigen=.7
             outtree=fortree 
             short;
   var &var_scale;
run;

ods trace off;
*/
ods listing close;
ods output clusterquality=summary
           rsquare=clusters;

proc varclus data=Credit_model_CH5 
             maxeigen=.7
             outtree=fortree 
             short;
   var &var_list;
run;
ods listing;


data _null_;
   set summary;
   call symput('nvar',compress(NumberOfClusters));
run;

data clusters_&nvar;
	set clusters;
	where NumberOfClusters=&nvar;
run;
/*
proc print data=clusters;
   where NumberOfClusters=&nvar;
   id cluster;
   var Variable RSquareRatio VariableLabel;
run;


axis1 value=(font = tahoma rotate=0 height=.8) 
      label=(font = tahoma angle=90 height=2);
axis2 order=(0 to 6 by 2);

proc tree data=fortree 
          horizontal 
          vaxis=axis1 
          haxis=axis2;
   height _MAXEIG_;
run;
*/
/*每组选择一个代表变量*/
/*应该结合业务在每个组中选择最有预测能力的变量,但是本例中仅根据1-R方，先择该值最小的变量*/
data var_select;
set clusters_&nvar;
  retain Cluster1;
  if Cluster~="" then Cluster1=Cluster;
run;

proc sort data=var_select;
  by Cluster1 RSquareRatio;
run;

data var_selected(where=(row=1));
set var_select;
  if first.Cluster1 then row=1;
  else row+1;
  by Cluster1;
run;

proc sql;
 select Variable into :var_list_ch6 separated by ' '
    from Var_selected;
quit;

%put &var_list_ch6;

data l2_tmp.Credit_model_ch6 Credit_model_ch6;
set Credit_model_ch5;
 keep target &var_list_ch6;
run;
data l2_tmp.Credit_access_ch6;
set Credit_access;
run;



/*CH6-3 制作经验logit曲线*/

/*第一步:对变量进行RANK分组*/
%let var=CRScore;

proc rank data=Credit_model_ch6 groups=100 out=out;
   var &var;
   ranks bin;
run;

/*第二步:对每一组计算该变量的平均值;响应事件数和总事件数**/

/*数据集BINS 包含:          */
/* target = 每个BIN里面响应事件数 */
/* _FREQ_ =每个BIN里面总事件数 */
/* DDABAL =每个BIN里面DDABAL平均值 */

proc means data=out noprint nway;
   class bin;
   var  target &var;
   output out=bins sum(target)= target mean(&var)=&var;
run;

/*第三步:根据公式计算 empirical logit */ 
data bins;
   set bins;
   elogit=log((target+(sqrt(_FREQ_ )/2))/
          ( _FREQ_ -target+(sqrt(_FREQ_ )/2)));
run;


/*第四步:画LOGIT与原变量平均值;LOGIT与BIN变量的线图*/
symbol i=join c=blue v=star;
proc gplot data = bins;
title "Empirical Logit against &var";
plot elogit * &var;
run;
title "Empirical Logit against Binned &var";
plot elogit * bin;
run;quit;



/********************************************************************************************************************************************/
/*本阶段成果列表：这些成果被自动保存在l2_tmp中作为备份
l2_tmp.Credit_model_ch6是本章处理后的数据集，进行了变量压缩
l2_tmp.Credit_access_ch6将来用于评估*/
/********************************************************************************************************************************************/
