/********************************************************************************************************************************************/
/*�Ⱦ�������
��Ҫ�õ�level2��l2_tmp�������߼��⣬����l2_tmp��ŵ�Credit_access_ch6,Credit_model_ch7 ���ݼ��ڱ��ڳ���ʹ��
/********************************************************************************************************************************************/
/*����ѵ�����ݵõ��ı�������ģ����֤*/
%let pi1=0.05;
/*9.1.1 ���������ݼ����д���*/
data Credit_access;
  set l2_tmp.Credit_access_ch6;
run;




/*9.1.2���������ݼ����*/
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
/*���ļ����б�������*/
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
/**��ȡROCͼ��GAINͼ����Ҫ��ͳ����**/
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
   label specif="�����"
         avg_SESP="����Ⱥ������Ⱦ�ֵ";
run;


/* ROCͼ*/

axis order=(0 to 1 by .1) label=none length=4in;
symbol i=join v=none c=black;
symbol2 i=join v=none c=black;
proc gplot data = roc;
title "ROC Curve for the Validation Data Set";
plot _SENSIT_*_1MSPEC_ _1MSPEC_*_1MSPEC_
     / overlay vaxis=axis haxis=axis;
run; quit;

/*liftͼ */
symbol i=join v=none c=black;
proc gplot data=roc;
title "Lift Chart for Validation Data";
plot lift*depth;
run; quit;
