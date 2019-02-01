/********************************************************************************************************************************************/
/*�Ⱦ�������
��Ҫ�õ�level2��l2_tmp�������߼��⣬����l2_tmp��ŵ�Credit_model_ch6���ݼ��ڱ��ڳ���ʹ��
/********************************************************************************************************************************************/

proc sql noprint;
 select name into :var_all separated by ' '
    from sashelp.vcolumn 
	where libname=Upper('l2_tmp') and memname=Upper("Credit_model_ch6") and name~="target";
quit;
%put &var_all;

/*ods trace on;*/
ods output ParameterEstimates=beta;
proc logistic data=Credit_model_ch6 des;
   model target=&var_all 
  / selection=backward fast slstay=.001;
run;
/*ods trace off;*/

proc sql noprint;
 select Variable into :var_logit separated by ' '
    from beta 
	where Variable~="Intercept";
quit;
%put &var_logit;

proc logistic data=Credit_model_ch6 des;
   model target=&var_logit;
run;
/*ȫ�Ӽ���*/
proc logistic data=Credit_model_ch6 des;
   model target=&var_logit
   / selection=SCORE best=1;
run;
/*����ع�ϵ��*/
data l2_tmp.Credit_model_ch7 Credit_model_ch7;
set beta;
run;



/********************************************************************************************************************************************/
/*���׶γɹ��б���Щ�ɹ����Զ�������l2_tmp����Ϊ����
l2_tmp.Credit_model_ch7�Ǳ��´��������ݼ�*/
/********************************************************************************************************************************************/


