/*soh***************************************************************************************************************************
* CODE NAME                  : <扩展随机表>
* DATE             			: 20180511
* PROGRAMMER       			: Wei Xin 
* VERTION		   			：1.0
* TYPE						:Macro
* SOFTWARE/VERTION 			: sas/version 9.4 



备注：

导入xls格式表格，可以导入统一路径下面的多个表格，按照文件顺序排序，在work下面生成相应的data

importxls(dir=输入路径,out=输出数据集名称);



*********************************************************************************************************************************/;

%macro importxls(DIR=,OUT=);

filename tmp pipe "dir &dir. /s /b";

data test;
  infile tmp dlm="?";  
  length buff $2000;
  input buff $;
  fname=scan(buff,countw(buff,"\"),"\");
  if index(upcase(fname),".XLS")>0 then 
    call execute(cats('proc import datafile="',buff,'" replace out=&OUT.',put(_n_,best.),'; run;'));

run;

%mend importxls;


