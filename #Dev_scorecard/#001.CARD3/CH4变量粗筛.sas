/********************************************************************************************************************************************/
/*�Ⱦ�������
��Ҫ�õ�level2��l2_tmp�������߼��⣬����l2_tmp��ŵ�credit_model���ݼ��ڱ��ڳ���ʹ��
/********************************************************************************************************************************************/

data credit_model;
   set l2_tmp.credit_model;
run;
options mautosource sasautos=('C:\level2_tmp',sasautos);
/*CH4�������д�ɸѡ:����Բ�����5%�²�����*/
/*CH4-1 �Զ���ȡ���ͱ����б������������õ��ˡ������ֵ䡱��֪ʶ��
          ��ֵ���͵ı�����Ҫȷ���Ƿ������������������*/
/*
Ŀ���Ƿ�����ֵ������target�����

step1���ҳ����е���ֵ����

step2������spearman��hoff

step3 �ų����ϵ�����Ƚϵ͵�
*/

proc sql noprint;
 select name into :var_num separated by ' '
    from sashelp.vcolumn 
	where libname='WORK' and memname=Upper("credit_model") and type="num" and name~="target" and name~="id";
quit;
/*���е���ֵ�����У�*/
%put &var_num;


/*CH4-4.2 ��ֵ����ʹ�����ϵ����*/
/*�������������õ��ˡ�ODSת���������֪ʶ��*/
ods listing close;
ods output spearmancorr=spearman
           hoeffdingcorr=hoeffding;

proc corr data=Credit_model spearman hoeffding rank;
   var &var_num;
   with target;
run;
ods listing;

/*�������������õ��ˡ�DATA�����顱��֪ʶ��*/
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
/*�ϲ��������ϵ����*/
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


/**�����ĸ�ͼ���ж�ÿ�����ڵı���������*/
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

/*����ѡ��spearman��hoff���ϵ��PֵС��0.1��*/
proc sql noprint;
 select variable into :var_num_ch4 separated by ' ' 
    from Correlations 
	where spvalue<=0.1 or hpvalue<=0.1;
 select count(*) into :var_num_ch4_n 
    from Correlations 
	where spvalue<=0.1 or hpvalue<=0.1;
quit;
/*��ɸ�����ֵ��������б�*/
%put &var_num_ch4;
%put &var_num_ch4_n;

/*method1 ��ձ������ɵ�������ʱ��*/
proc sql noprint;
 select memname into :table_delet separated by ','
    from sashelp.vtable 
	where libname='WORK' and memname not in ("CREDIT_MODEL","CREDIT_ACCESS") ;
drop table &table_delet;
quit;
%let table_delet=;

/*method2 ��ձ������ɵ�������ʱ��*/

/*proc datasets lib=work;*/
/*save credit_model credit_access;*/
/*run;*/



data l2_tmp.Credit_model_ch4;
set Credit_model;
keep id target &var_num_ch4;
run;


*4.2�������֮��;

proc freq data=credit_model;
tables res*target/chisq;
run;

/*�������ָ��ͱ�׼��*/
proc freq data=credit_model;
tables dda*target/measures;
run;

*4.3�����������������֮��;
proc ttest data=credit_model;
class target;
var income;
run;
proc anova data=credit_model;
class target;
model income=target;
run;



/********************************************************************************************************************************************/
/*���׶γɹ��б���Щ�ɹ����Զ�������l2_tmp����Ϊ����
�����&var_num_ch4�д���о���ɸѡ���з�����ֵ�ı����б�
l2_tmp.Credit_model_ch4�Ǳ��´��������ݼ����޳��˲���صı���*/
%put &var_num_ch4;
/********************************************************************************************************************************************/
