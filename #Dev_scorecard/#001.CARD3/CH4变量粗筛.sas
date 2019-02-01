/********************************************************************************************************************************************/
/*先决条件：
需要用到level2和l2_tmp这两个逻辑库，其中l2_tmp存放的credit_model数据集在本节程序使用
/********************************************************************************************************************************************/

data credit_model;
   set l2_tmp.credit_model;
run;
options mautosource sasautos=('C:\level2_tmp',sasautos);
/*CH4变量进行粗筛选:相关性不能在5%下不显著*/
/*CH4-1 自动获取解释变量列表（本部分内容用到了“数据字典”的知识）
          数值类型的变量需要确定是分类变量还是连续变量*/
/*
目标是分析数值变量与target相关性

step1，找出所有的数值变量

step2，计算spearman，hoff

step3 排除相关系数都比较低的
*/

proc sql noprint;
 select name into :var_num separated by ' '
    from sashelp.vcolumn 
	where libname='WORK' and memname=Upper("credit_model") and type="num" and name~="target" and name~="id";
quit;
/*所有的数值变量有：*/
%put &var_num;


/*CH4-4.2 数值变量使用相关系数法*/
/*（本部分内容用到了“ODS转向输出”的知识）*/
ods listing close;
ods output spearmancorr=spearman
           hoeffdingcorr=hoeffding;

proc corr data=Credit_model spearman hoeffding rank;
   var &var_num;
   with target;
run;
ods listing;

/*（本部分内容用到了“DATA步数组”的知识）*/
data spearman1(keep=variable scorr spvalue ranksp);
   length variable $ 20;
   set spearman;
   array best(*) best:;
   array r(*) r:;
   array p(*) p:;
   do i=1 to dim(best);
      variable=best(i);
      scorr=r(i);
      spvalue=p(i);
      ranksp=i;
      output;
   end;
run;
data hoeffding1(keep=variable hcorr hpvalue rankho);
   length variable $ 20;
   set hoeffding;
   array best(*) best:;
   array r(*) r:;
   array p(*) p:;
   do i=1 to dim(best);
      variable=best(i);
      hcorr=r(i);
      hpvalue=p(i);
      rankho=i;
      output;
   end;
run;
/*合并两张相关系数表*/
proc sort data=spearman1;
   by variable;
run;
proc sort data=hoeffding1;
   by variable;
run;
data correlations;
   merge spearman1 hoeffding1;
   by variable;
run;


/**构造四格图，判断每个格内的变量显著性*/
proc sql noprint;
   select min(ranksp) into :vref 
   from (select ranksp 
         from correlations 
         having spvalue > .5);
   select min(rankho) into :href 
   from (select rankho
         from correlations
         having hpvalue > .5);
quit;

%put &vref;
%put &href;
proc plot data = correlations;
   plot ranksp*rankho $ variable="*"
        /vref=&vref href=&href ;
run; quit;

/*最终选择spearman或hoff相关系数P值小于0.1的*/
proc sql noprint;
 select variable into :var_num_ch4 separated by ' ' 
    from Correlations 
	where spvalue<=0.1 or hpvalue<=0.1;
 select count(*) into :var_num_ch4_n 
    from Correlations 
	where spvalue<=0.1 or hpvalue<=0.1;
quit;
/*粗筛后的数值变量输出列表：*/
%put &var_num_ch4;
%put &var_num_ch4_n;

/*method1 清空本章生成的所有暂时表*/
proc sql noprint;
 select memname into :table_delet separated by ','
    from sashelp.vtable 
	where libname='WORK' and memname not in ("CREDIT_MODEL","CREDIT_ACCESS") ;
drop table &table_delet;
quit;
%let table_delet=;

/*method2 清空本章生成的所有暂时表*/

/*proc datasets lib=work;*/
/*save credit_model credit_access;*/
/*run;*/



data l2_tmp.Credit_model_ch4;
set Credit_model;
keep id target &var_num_ch4;
run;


*4.2分类变量之间;

proc freq data=credit_model;
tables res*target/chisq;
run;

/*计算关联指标和标准误*/
proc freq data=credit_model;
tables dda*target/measures;
run;

*4.3分类变量与连续变量之间;
proc ttest data=credit_model;
class target;
var income;
run;
proc anova data=credit_model;
class target;
model income=target;
run;



/********************************************************************************************************************************************/
/*本阶段成果列表：这些成果被自动保存在l2_tmp中作为备份
宏变量&var_num_ch4中存放有经过筛选，有分析价值的变量列表
l2_tmp.Credit_model_ch4是本章处理后的数据集，剔除了不相关的变量*/
%put &var_num_ch4;
/********************************************************************************************************************************************/
