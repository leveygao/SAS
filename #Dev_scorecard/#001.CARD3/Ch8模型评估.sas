/********************************************************************************************************************************************/
/*先觉条件：
需要用到level2和l2_tmp这两个逻辑库，其中l2_tmp存放的Credit_access_ch6,Credit_model_ch7 数据集在本节程序使用
/********************************************************************************************************************************************/
/*利用训练数据得到的变量进行模型验证*/
%let pi1=0.05;
/*9.1.1 对评估数据集进行处理*/
data Credit_access;
  set l2_tmp.Credit_access_ch6;
run;




/*9.1.2对评估数据集打分*/
proc sql noprint;
 select Variable into :var separated by ' '
    from l2_tmp.Credit_model_ch7 
	where Variable~="Intercept";
quit;
%put &var;


proc logistic data=l2_tmp.Credit_model_ch6 des;
   model target=&var;
   score data=Credit_access  outroc=roc out=predict;
run;
/*在文件夹中备份数据*/
data l2_tmp.predict;
   set predict;
run;
/*
proc logistic data=predict des;
   model target=p_1;
run;
proc logistic data=l2_tmp.Credit_model_ch6 des;
   model target=&var;
run;
proc print data=roc(obs=25);
   var _prob_ _sensit_ _1mspec_;
run;
*/
/**获取ROC图和GAIN图所需要的统计量**/
data roc l2_tmp.roc;
   set roc;
   cutoff=_PROB_;
   specif=1-_1MSPEC_;
   tp=&pi1*_SENSIT_;
   fn=&pi1*(1-_SENSIT_);
   tn=(1-&pi1)*specif;
   fp=(1-&pi1)*_1MSPEC_;
   depth=tp+fp;
   pospv=tp/depth;
   negpv=tn/(1-depth);
   acc=tp+tn;
   lift=pospv/&pi1;
   avg_SESP=mean(specif,_SENSIT_)   ;
   label specif="特异度"
         avg_SESP="特异度和灵敏度均值";
run;


/* ROC图*/

axis order=(0 to 1 by .1) label=none length=4in;
symbol i=join v=none c=black;
symbol2 i=join v=none c=black;
proc gplot data = roc;
title "ROC Curve for the Validation Data Set";
plot _SENSIT_*_1MSPEC_ _1MSPEC_*_1MSPEC_
     / overlay vaxis=axis haxis=axis;
run; quit;

/*lift图 */
symbol i=join v=none c=black;
proc gplot data=roc;
title "Lift Chart for Validation Data";
plot lift*depth;
run; quit;
