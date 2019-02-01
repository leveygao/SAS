/*宏:NONstepwise

用途：通过逻辑回归估计模型参数，并输出模型表现、模型参数、变量统计量、评分卡、


输入输出：
in_dataset_train:输入训练集
in_dataset_test：输入测试集
woe_varname：WOE转换后的入模变量名
default_flag：好坏标识
BIN：可为空，评分卡母版
PDO,STD,SODD：分数转换参数
S_MIN,S_MAX：分数转换后最大值最小值限制

model_info：输出包含模型信息的训练集，后续可用于ROC计算
train_score：输出分数折算后的训练集
test_score：输出分数折算后的测试集
model_performance：输出模型表现
model_stat：输出模型系数，当LOG_IN不为空时，会依据LOG_IN中的信息添加变量标签
VIF_rslt：输出入模变量VIF，当LOG_IN不为空时，会依据LOG_IN中的信息添加粗分前后的IV
score_card：当BIN不为空时，输出打分卡
LOG_IN：可为空，变量清单，需包含LABEL、FINEBIN_IV、CORSBIN_IV
LOG_OUT:当LOG_IN不为空时，将变量是否入模记录到LOG_IN中 */
%macro NONstepwise(in_dataset_train,in_dataset_test,woe_varname,default_flag,BIN,PDO,STD,SODD,S_MIN,S_MAX,model_info,train_score,test_score,model_performance,model_stat,VIF_rslt,score_card,LOG_IN,LOG_OUT);


/*在训练集上构建模型*/
ods output ROCassociation=train_roc (keep=rocmodel area SomersD);
ods output ParameterEstimates=model_stat;
PROC LOGISTIC DATA=&in_dataset_train. OUTEST=model_beta outmodel=&model_info. namelen=200;;
        MODEL &default_flag. (event='1')=
&woe_varname.
/RSQ STB PARMLABEL
                                    SELECTION = none
        ;
/*weight wgt;*/
ROC;
RUN;
ods output close;
ods listing;



/*模型验证：在测试集上计算*/
proc logistic inmodel=&model_info.;
score data=&in_dataset_test.  out=to_test_roc ;
run;


ods output ROCassociation=test_roc (keep=rocmodel area SomersD);
proc logistic data =to_test_roc outmodel=test_model;
model &default_flag.(event='1')= P_1;
roc;
run;
ods output close;
ods listing;

/*模型校准*/
PROC TRANSPOSE DATA=model_beta (DROP=_LNLIKE_) OUT=MODEL(WHERE=(&default_flag. ^= .)) ;
RUN;

%score_calc(MODEL,_NAME_,&default_flag.,&in_dataset_train.,&train_score.,&PDO.,&STD.,&SODD.);

%KS_Calc(&train_score.,score_total, &default_flag.,KS_training);
%AR_Calc(&train_score., score_total, ASC,&default_flag.,AR_training);


%score_calc(MODEL,_NAME_,&default_flag.,&in_dataset_test.,&test_score.,&PDO.,&STD.,&SODD.);
%KS_Calc(&test_score.,score_total, &default_flag.,KS_test);
%AR_Calc(&test_score., score_total, ASC,&default_flag.,AR_test);


/*模型表现汇总*/
data model_performance;
set train_roc;
where rocmodel="模型";
format sample $12.;
sample='training';
keep sample area somersD;
run;

data _temp1;
set test_roc;
where rocmodel="模型";
format sample $12.;
sample='test';
keep sample area somersD;
run;

proc append base=model_performance data=_temp1 force;
run;

proc sort data=model_performance;
by sample;
run;

data _temp2;
set ks_training;
format sample $12.;
sample='training';
keep sample ks;
run;

data _temp3;
set ks_test;
format sample $12.;
sample='test';
keep sample ks;
run;

data _temp4;
set ar_training;
format sample $12.;
sample='training';
keep sample ar;
run;

data _temp5;
set ar_test;
format sample $12.;
sample='test';
keep sample ar;
run;

data model_performance;
merge model_performance _temp2 _temp3 _temp4 _temp5;
by sample;
run;

proc delete data=_temp1  _temp2 _temp3 _temp4 _temp5;
run;

proc sql;
create table &model_performance. as select sample, area, KS, AR from model_performance order by sample desc;
quit;

data model_stat;
 set model_stat;
  obs=_N_;
 run;
 
proc sort data=model_stat;
by variable obs;
run;


data &model_stat.;
set model_stat;
by variable;
if first.variable;
drop label;
run;

/*VIF检测*/
proc sql;
 select variable into : inmodel_var separated by " " from &model_stat. where variable ne 'Intercept';
 quit;

%put &inmodel_var.;

ods listing close;
ods output  ParameterEstimates=Model_VIF_train;
proc reg data=&in_dataset_train.;
        MODEL &default_flag. =
&inmodel_var.

/VIF;
run;
ods listing ;
quit;

ods listing close;
ods output  ParameterEstimates=Model_VIF_test;
proc reg data=&in_dataset_test.;
        MODEL &default_flag. =
&inmodel_var.
/VIF;
run;
ods listing;
quit;


proc sql;
create table &VIF_rslt. as select a.variable, a.VarianceInflation as vif_train, b.VarianceInflation as vif_test from 
model_vif_train a, model_vif_test b where a.variable=b.variable order by variable;
quit;





%if &BIN. ne %str()  %then %do;
/*生成打分卡*/

	proc sql;
	create table &score_card. as select a.variable, b.var_no,b.label, b.RANK_FINEBIN, a.estimate, b.WOE, b.N_1, b.N_0, b.start, b.end from &model_stat. a 
	left join &BIN. b on a.variable=compress("WOE_"||b.var_no) 
		order by var_no, RANK_FINEBIN;
	quit;

	data &score_card.;
	set &score_card.;
	format score 8.;
	if variable='Intercept' then score=&STD.+round(&PDO.*((-1)*estimate-log(&SODD))/log(2),1);
	else score=round(WOE*(-1)*estimate*&PDO./log(2),1);
	run;

	%score_calc_nobase(&model_stat.,&score_card.,variable,Estimate,&train_score.,&train_score.,&S_MAX.,&S_MIN.);
	%score_calc_nobase(&model_stat.,&score_card.,variable,Estimate,&test_score.,&test_score.,&S_MAX.,&S_MIN.);

	data &score_card.;
		set &score_card.;
		format SAS_SCR $200. ;
		if var_no ne " " then do;
		if compress(start)="LOW" then do;
			SAS_SCR="IF "||compress(VAR_NO)||"<="||compress(end)||" THEN SCR_"||compress(VAR_NO)||"="||compress(score_nb)||";";
		end;
		else if compress(end)="HIGH" then do;
			SAS_SCR="ELSE IF "||compress(start)||"<"||compress(VAR_NO)||" THEN SCR_"||compress(VAR_NO)||"="||compress(score_nb)||";";
		end;
		else do;
			SAS_SCR="ELSE IF "||compress(start)||"<"||compress(VAR_NO)||"<="||compress(end)||" THEN SCR_"||compress(VAR_NO)||"="||compress(score_nb)||";";
		end;
		end;
	run;
%end;

%if &LOG_in. ne %str()  %then %do;

data _temp;
set &LOG_IN.;
format _name_ $40.;
_name_=compress("WOE_"||var_no);
drop model_slct;
run;

data _temp;
merge _temp(in=a)
      &model_stat.(in=b keep=variable rename=(variable=_name_));
by _name_;
if a;
if a and b then model_slct=1;
if a and not b then model_slct=0;
run;

data _model_stat;
set &model_stat.;
run;

proc sql;
create table &model_stat. as select a.*, b.label,b.name from 
_model_stat a left join _temp b on compress(a.variable)=compress(b._name_ ) order by obs;
quit;


data &LOG_OUT.;
set _temp;
drop _name_;
run;

proc sql;
create table var_stat as select _name_, label, FINEBIN_IV,CORSBIN_IV  from _temp where model_slct=1;
quit;

data _VIF_rslt;
set &VIF_rslt.;
run; 

proc sql;
create table &VIF_rslt. as select a.variable, b.label, a.VIF_train, a.VIF_test,
b.finebin_iv, b.corsbin_iv
from &VIF_rslt. a left join var_stat b on a.variable=b._name_ ;
quit;

proc sort data=&model_stat.;
by obs;
run;

proc delete data=_temp;
run;
%end;

%mend;



