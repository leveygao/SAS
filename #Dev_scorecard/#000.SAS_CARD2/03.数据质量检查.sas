/*宏：Quality_Check
用途：依据RENAME宏中对变量连续或离散的判断对变量进行分类数据质量检查
		离散变量：集中度、缺失度、变量分布
		连续变量：缺失度、零值度、分位点

输入输出：
in_dataset:输入数据集
list:由RENAME宏生成的变量清单
num_stat:连续变量的数据质量检查结果
char_dist:离散变量的分布统计结果
char_stat:离散变量的数据质量检查结果
LOG：将连续变量的缺失度、零值度和离散变量的缺失度、集中度汇总到list*/;

%macro Numeric_Var(dsn,VarNames,Numeric_stat);/*数据集，待分析变量清单（支持对“数值型变量”和“存储为字符型的数值型变量”的分析，输入值不区分大小写，变量清单请以空格分隔）*/ 
/*若字段清单非空，执行后续分析*/
%if %length(&VarNames.) gt 0 %then %do;
	%let Varlist_NUM=;
	%let Varlist_CHAR=;
	%let Varlist_CHAR_=;
	%let VarNames_comma=;

	/*将待分析变量清单中“空格”替换为“逗号”，生成新的宏变量“VarNames_comma”*/
	%let counter1=2;
	%let VarNames_comma="%scan(&VarNames.,1)";
	%do %while(%scan(&VarNames.,&counter1.) ne %str());
		%let _var="%scan(&VarNames.,&counter1.)";
		%let VarNames_comma=&VarNames_comma.,&_var.;
		%let counter1=%eval(&counter1.+1);
	%end;


	/*将待分析变量清单中，依据在原数据集中储存的类型，分为“Varlist_NUM”和“Varlist_CHAR”两个子清单*/
	/*依据子清单“Varlist_CHAR”，生成子清单副本“Varlist_CHAR_”用以后续字段类型转置*/
	proc contents data=&dsn. out=_varlist noprint;
	run;

	proc sql noprint;
		select name into: Varlist_NUM separated by " "
			from _varlist
			where upcase(name) in (%upcase(&VarNames_comma.)) and type=1;
		select name into: Varlist_CHAR separated by " "
			from _varlist
			where upcase(name) in (%upcase(&VarNames_comma.)) and type=2;
		select compress(name || "_") into: Varlist_CHAR_ separated by " "
			from _varlist
			where upcase(name) in (%upcase(&VarNames_comma.)) and type=2;
	quit;

	/*从原数据集中提取待分析变量，生成待分析样本数据集“SAMPLE”*/
	data sample;
		set &dsn.
			(
				keep=
				%if %length(&Varlist_NUM.) ne 0 %then %do;
					&Varlist_NUM. 
				%end;

				%if %length(&Varlist_CHAR.) ne 0 %then %do;
					&Varlist_CHAR. 
					rename=
					(
						%let counter2=1;
						%do %while(%scan(&Varlist_CHAR.,&counter2.) ne %str());
							%scan(&Varlist_CHAR.,&counter2.)=%scan(&Varlist_CHAR_.,&counter2.)
							
							%let counter2=%eval(&counter2.+1);
						%end;
					)
				%end;
			);
		/*对样本数据集“SAMPLE”中，“存储为字符型的数值型变量”转换为按数值型存储*/
		%let counter3=1;
		%do %while(%scan(&Varlist_CHAR.,&counter3.) ne %str());
			%scan(&Varlist_CHAR.,&counter3.)=input(%scan(&Varlist_CHAR_.,&counter3.),comma32.);
			%let counter3=%eval(&counter3.+1);	
		%end;
		%if %length(&Varlist_CHAR_.) %then %do;
			drop  &Varlist_CHAR_.;
		%end;
	run;

	
	/*构建数组，分别用于标识缺失、负值、零值、正值*/
	proc sql noprint; 
		select compress(name) into: list0 separated by " " 
			from _varlist where upcase(name) in (%upcase(&VarNames_comma.)); 
		select compress(name || "__1") into: list1 separated by " " 
			from _varlist where upcase(name) in (%upcase(&VarNames_comma.)); 
		select compress(name || "__2") into: list2 separated by " " 
			from _varlist where upcase(name) in (%upcase(&VarNames_comma.)); 
		select compress(name || "__3") into: list3 separated by " " 
			from _varlist where upcase(name) in (%upcase(&VarNames_comma.)); 
		select compress(name || "__4") into: list4 separated by " " 
			from _varlist where upcase(name) in (%upcase(&VarNames_comma.)); 
	quit;

	%put &list0. &list1. &list2. &list3. &list4.;

	data _tmp1;
		set work.sample;
		array varlist &list0.;
		array list1 &list1.;
		array list2 &list2.;
		array list3 &list3.;
		array list4 &list4.;
		do i=1 to dim(varlist);
			list1(i)=(varlist(i)=.);
			list2(i)=(.<varlist(i)<0);
			list3(i)=(varlist(i)=0);
			list4(i)=(varlist(i)>0);
		end;
	run;

	/*统计各个字段的分布*/
	proc means data=_tmp1 noprint;
		var &varnames. &list1. &list2. &list3. &list4.;
		output out=_tmp2 n= nmiss= min= max= mean= stddev= sum=
						p1= p5= p10= p25= p50= p75= p90= p95= p99= /autoname;
	run;

	/*整理统计结果*/
	data &Numeric_stat.;
		set _tmp2;
		length LibName $50. DsName $50. VarName $50.;

		%let i=1;
		%do %while(%scan(&VarNames,&i) ne %str( ));
		%let var=%scan(&VarNames,&i);
		%let i=%eval(&i+1);
/*		LibName = "&lib.";*/
		DsName = "&dsn.";
		VarName = "&var.";
	/*	ValidObs = &var._n;*/
	/*	MissObs = &var._nmiss;*/
		Obs = sum(&var._n,&var._nmiss);
		MissObs = &var.__1_sum;
		NegaObs = &var.__2_sum;
		ZeroObs = &var.__3_sum;
		PosiObs = &var.__4_sum;	
		MissRatio = &var.__1_sum/Obs;
		NegaRatio = &var.__2_sum/Obs;
		ZeroRatio = &var.__3_sum/Obs;
		MinValue = &var._min; 
		MaxValue = &var._max;
		MeanValue = &var._mean;
		StdDev = &var._stddev;
		p1 = &var._p1;
		p5 = &var._p5;
		p10 = &var._p10;
		p25 = &var._p25;
		p50 = &var._p50;
		p75 = &var._p75;
		p90 = &var._p90;
		p95 = &var._p95;
		p99 = &var._p99;
		output;
		%end;

		keep LibName DsName VarName Obs Missobs ZeroObs NegaObs MissRatio ZeroRatio NegaRatio 
			 MinValue MaxValue MeanValue StdDev P1 P5 P10 P25 P50 P75 P90 P95 P99;

	run;

%end;

proc datasets lib=work nolist;
	delete sample _varlist _tmp1 _tmp2;
run;
%mend Numeric_Var;

/*2.2分类字符型变量分析（宏）*/
/*分类字符型变量统计及分布*/;

%macro ClassChar_Var(dsn,VarNames,ClassChar_stat,ClassChar_dist);/*数据集，待分析变量清单（输入值不区分大小写，变量清单请以空格分隔）*/ 
/*若字段清单非空，执行后续分析*/
%if %length(&VarNames.) gt 0 %then %do;

	proc contents data=&dsn. out=sample_type noprint;
	run;

	%let counter1=1;
	%do %while (%scan(&VarNames.,&counter1.) ne %str());
		%let var=%scan(&VarNames.,&counter1.);

		/*通过循环对表中所有分类字符型变量进行频数统计*/	

		/*取得包含变量类型信息的宏变量_sample_vartype，用以后续缺失值统计时，对不同类型字段的缺失值进行不同处理*/
		proc sql noprint;
			select type into: _sample_vartype
				from sample_type
				where upcase(name)="%upcase(&var.)";
		quit;
			

	%put &_sample_vartype.;
	
		proc freq data=&dsn. noprint;
			tables &var./missing list nocum out=_tmpdist;
		run;

		/*在表中补充变量：LibName，DsName，VarName*/

		data _tmpdist;
			length LibName $50 DsName $50 VarName $50 VarValue $50;
			set _tmpdist;
/*			LibName="&lib.";*/
			DsName="&dsn.";
			VarName="&var.";
			VarValue=compress(&var.);
			Count=Count;
			Percent=Percent/100;
			drop &var;
			format percent percent10.2;
		run;

		/*整理最高、最低占比分类信息*/
		proc sql noprint;

			create table _tmp0 as
			select distinct LibName,DsName,VarName
			from _tmpdist;

			create table _tmp1 as
			select sum(Count) as Obs,count(VarValue) as ClassCnt
			from _tmpdist;

			%if &_sample_vartype.=2 %then %do;

			create table _tmp2 as
			select Count+0 as MissObs,Percent+0 as MissRatio
			from _tmpdist
			where VarValue="";

			create table _tmp3 as
			select VarValue as HighPrctCls,Percent as HighPrct
			from _tmpdist
			where VarValue^=""
			having Count=max(Count);

			select HighPrctCls,mean(HighPrct)
				into :HighPrctCls separated by ",", :HighPrct
			from _tmp3;

			create table _tmp4 as
			select VarValue as LowPrctCls,Percent as LowPrct
			from _tmpdist
			where VarValue^=""
			having Count=min(Count);

			select LowPrctCls,mean(LowPrct)
				into :LowPrctCls separated by ",", :LowPrct
			from _tmp4;
			
			%end;

			%else %if &_sample_vartype.=1 %then %do;

			create table _tmp2 as
			select Count+0 as MissObs,Percent+0 as MissRatio
			from _tmpdist
			where VarValue=".";

			create table _tmp3 as
			select VarValue as HighPrctCls,Percent as HighPrct
			from _tmpdist
			where VarValue^="."
			having Count=max(Count);

			select HighPrctCls,mean(HighPrct)
				into :HighPrctCls separated by ",", :HighPrct
			from _tmp3;

			create table _tmp4 as
			select VarValue as LowPrctCls,Percent as LowPrct
			from _tmpdist
			where VarValue^="."
			having Count=min(Count);

			select LowPrctCls,mean(LowPrct)
				into :LowPrctCls separated by ",", :LowPrct
			from _tmp4;
			
			%end;

		quit;
		
		data _tmp;
			merge _tmp0 _tmp1 _tmp2;
			HighPrctCls="&HighPrctCls";
			HighPrct=&HighPrct.;
			LowPrctCls="&LowPrctCls";
			LowPrct=&LowPrct.;
			if MissObs=. then MissObs=0;
			if MissRatio=. then MissRatio=0;
		run;

		/*建立base表*/

		%if &counter1.=1 %then %do;

			data &ClassChar_stat.;
				length LibName $50 DsName $50 VarName $50 Obs 8. ClassCnt 8. MissObs 8. MissRatio 8. 
					   HighPrctCls $32767 HighPrct 8. LowPrctCls $32767 LowPrct 8.;
				set _tmp;
				format MissRatio percent10.2 HighPrct percent10.2 LowPrct percent10.2;
			run;
			data &ClassChar_dist.;
				set _tmpdist;
			run;

		%end;

		/*把频数统计结果与base表进行append*/

		%else %do;
			proc append base=&ClassChar_stat. data=_tmp force nowarn;run;
			proc append base=&ClassChar_dist. data=_tmpdist force nowarn;run;
		%end;
		%let counter1=%eval(&counter1.+1);
	%end;


	proc datasets lib=work nolist; 
		delete _tmp: ;
	run;

%end;

proc datasets lib=work nolist; 
	delete sample sample_type;
run;

%mend ClassChar_var;

/*2.3数值与字符变量数据质量检查（宏）*/
%macro Quality_Check(in_dataset,list,num_stat,char_dist,char_stat,LOG);

proc delete data=&num_stat. &char_dist. &char_stat.;run;


proc sql noprint;
	select var_no into: char_var separated by " " from &list. where cat_type=2;
	select var_no into: num_var separated by " " from &list. where cat_type=1;
quit;
%Numeric_var(&in_dataset.,&num_var.,&num_stat.);
%ClassChar_Var(&in_dataset.,&char_var.,&char_stat.,&char_dist.);

%if  %scan(&log.,1) ne %str() %then %do;
	proc sort data=&list. out=&log.;
		by var_no;
	run;
	
	proc sort data=&char_stat.;
		by Varname;
	run;

	proc sort data=&num_stat.;
		by Varname;
	run;

	data &log.;
		merge &log.(in=a) 
		&char_stat.(keep=varname missratio highprct rename=(varname=var_no Highprct=Concnt))
		&num_stat.(keep=varname missratio STDDEV rename=(varname=var_no ))
		;
		by var_no;
		if a;
	run;
%end;
%mend;