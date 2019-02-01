/* Add the decision variable    */
/* (based on the profit matrix) */
/* and calculate profit         */ 
/*设置基准概率、利润函数和损失函数*/



title "Sensit v.s. Specif";
proc sgplot data=l2_tmp.roc;
   series y=avg_SESP x=depth;
   series y=specif x=depth;
   series y=_SENSIT_ x=depth;
   refline .32 / axis=x;
   yaxis label="% ";
run;


/*不使用******************************************************************************************/
%let pi1=0.05;
%let profit=99;
%let loss=1;
/* Investigate the true positive and */
/* false positive rates              */
data roc;
   set l2_tmp.roc;
   AveProf = &profit.*tn - &loss.*fn;
run;

title "Average Profit Against Depth";
proc sgplot data=roc;
   series y=aveProf x=depth;
   yaxis label="Average Profit";
run;

title "Average Profit Against Cutoff";
proc sgplot data=roc;
   where cutoff le 0.90;
   refline .01 / axis=x;
   series y=aveProf x=cutoff;
   yaxis label="Average Profit";
run;


/*分组分析*/
proc sql noprint;
   select mean(target) into :rho1 from l2_tmp.credit_model;
quit;
%put &rho1;
data predict;
   set l2_tmp.predict;
   sampwt = (&pi1/&rho1)*(target) 
            + ((1-&pi1)/(1-&rho1))*(1-target);
   decision = (p_1 > 0.05);
   profit = decision*target*&profit
            - decision*(1-target)*&loss;
run;

/* Calculate total and average profit */
proc means data=predict sum mean;
   weight sampwt;
   var profit;
run;


