/*soh***************************************************************************************************************************
* CODE NAME                  : <��չ�����>
* DATE             			: 20180511
* PROGRAMMER       			: Wei Xin 
* VERTION		   			��1.0
* TYPE						:Macro
* SOFTWARE/VERTION 			: sas/version 9.4 



��ע��

����xls��ʽ��񣬿��Ե���ͳһ·������Ķ����񣬰����ļ�˳��������work����������Ӧ��data

importxls(dir=����·��,out=������ݼ�����);



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


