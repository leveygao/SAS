/********************************************************************************************************************************************/
/*先决条件：
需要用到level2和l2_tmp这两个逻辑库，其中l2_tmp存放的Credit_model_ch6数据集在本节程序使用
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
/*全子集法*/
proc logistic data=Credit_model_ch6 des;
   model target=&var_logit
   / selection=SCORE best=1;
run;
/*保存回归系数*/
data l2_tmp.Credit_model_ch7 Credit_model_ch7;
set beta;
run;



/********************************************************************************************************************************************/
/*本阶段成果列表：这些成果被自动保存在l2_tmp中作为备份
l2_tmp.Credit_model_ch7是本章处理后的数据集*/
/********************************************************************************************************************************************/


