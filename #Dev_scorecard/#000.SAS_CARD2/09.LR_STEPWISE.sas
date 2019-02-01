options mprint obs=max;
/*宏：STEPWISE
用途：用stepwise、forward或backward的方式逐步踢出变量系数为正的变量

输入输出：
in_dataset_woe:输入WOE转换后的数据集
woe_varname：带WOE前缀的变量名，用空格分隔
default_flag:好坏标识
outdsn：输出数据集的前缀*/
%macro stepwise(in_dataset_woe,woe_varname,default_flag,outlib,outdsn,selection,weight);
	%let stop=N;
	%let i=1;
	proc delete data=&outlib..&outdsn._est;
	run;

	proc contents data=&in_dataset_woe.(keep=&woe_varname.) out=temp_xvarlist;
	run;

	%do %while (&stop ne Y);
		Ods Output ParameterEstimates=ParameterEstimates;
			proc logistic data=&in_dataset_woe. namelen=200;
				model &default_flag.(event="1")=&woe_varname./rsq stb parmlabel sle=0.05 sls=0.05 selection=&selection.;
				%if %length(&weight.)>0 %then %do;
					weight &weight.;
				%end;
			run;quit;
		Ods Output close;

		proc sql noprint;
			select count(*),compress("'"||variable||"'") into: posiCount, : posiVarlist separated by ","
				from ParameterEstimates
				where estimate>0 and upcase(variable) ne "INTERCEPT";
		quit;

		%put posiCount = &posiCount.;
		%put posiVarlist = &posiVarlist.;

		data ParameterEstimates;
			set ParameterEstimates;
			if upcase(variable) = "INTERCEPT" and _n_ ne 1 then delete;
		run;

		data temp_output_PmtEst;
			length variable $2000;
			do i=
				%if &i.=1 %then %do;
					1
				%end;
				%else %do;
					0
				%end;
				to 2;
			if i=0 then variable=" ";
			if i=1 then variable="regression times: &i.";
			if i=2 then variable="input variable list: &woe_varname.";
			output;
			end;
			drop i;	
		run;

		data temp_output_PmtEst;
			set temp_output_PmtEst ParameterEstimates;
		run;
		
		proc append base=&outlib..&outdsn._est data=temp_output_PmtEst force nowarn;
		run;

		%if &posiCount.>0 %then %do;
			data temp_xvarlist;
				set temp_xvarlist(where=(name not in (&posiVarlist.)));
			run;
			
			proc sql noprint;
				select name into: woe_varname separated by " "
					from temp_xvarlist;
			quit;
		%end;

		%else %if  &posiCount.=0 %then %do;
			%let stop=Y;
			proc sql noprint;
				select variable into: woe_varname separated by " "
					from ParameterEstimates
					where upcase(variable) ne "INTERCEPT";
			quit;
		%end; 

		%let i=%eval(&i.+1);
	%end;
	Ods Output	ParameterEstimates=&outlib..&outdsn._vif;
	proc reg data=&in_dataset_woe. outvif;
		model &default_flag.=&woe_varname./vif;
	run;quit;
	Ods Output close;

	Ods Output ROCAssociation=&outlib..&outdsn._roc;
	proc logistic data=&in_dataset_woe. namelen=200;
		model &default_flag.(event="1")=&woe_varname./rsq stb parmlabel sle=0.05 sls=0.05;
		roc;
	run;quit;
	Ods Output close;

	proc datasets lib=work;
		delete temp_xvarlist temp_output_PmtEst ParameterEstimates ROCAssociation;
	run;
%mend stepwise;







