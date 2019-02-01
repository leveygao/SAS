/*宏：VAR_CLUS
用途：对完成WOE转换的变量进行变量聚类

in_dataset_woe:输入WOE转换后的数据集
woe_varname：带WOE前缀的变量名，用空格分隔
max_clus：最大聚类组数
varclus_rslt:聚类结果
corr_out：相关性矩阵输出
Log_in:可为空，变量清单,当var_num不为空时，该表中需存有FINEBIN_IV列
Log_out:当log_in不为空时，log_out不可为空，将聚类结果记录到log_in
var_num:可为空，依据IV，每组选取var_num个变量，并记录到log_out*/
%macro VAR_CLUS(in_dataset_woe, woe_varname, max_clus,varclus_rslt,LOG_in,LOG_out,var_num);

data cluster_set;
	set &in_dataset_woe.(keep=&woe_varname);

	/*将数值变量的空值设为0*/
	array num _numeric_;
	do over num;
	if num=. then num=0;
	end;
run;

/*聚类*/
proc varclus data=cluster_set outstat=varclus_rslt maxclusters=&max_clus.;/*参数依据具体使用情况设置*/
	var &woe_varname.;
run;

/*提取聚类结果表格*/
/*提取最大聚类类数*/
proc sql;
	select max(_NCL_) into :ttlclus from varclus_rslt;
quit;

/*保留与聚类类别相关的观测*/
data varclus_rslt;
	set varclus_rslt;
	where _NCL_=&ttlclus. and _TYPE_='SCORE';
	drop _NCL_ _TYPE_;
run;

/*转置聚类结果表，使变量名作为第一列*/
proc transpose data=varclus_rslt name=variable out=varclus_trans;
	ID _NAME_; 
run;

/*新生成一列cluster记录每个变量属于哪一类*/
data &varclus_rslt.(keep=woe_var_no var_no cluster);
	set varclus_trans;
	array clus(*) _numeric_;
	do i=1 to dim(clus);
	if clus(i) ne 0 then cluster=i;
	end;
	
	var_no=substr(variable,5,length(variable)-4);
	rename variable=woe_var_no;
	drop i;
run;

/*record var performance*/
	%if &LOG_in. ne %str()  %then %do;

	proc sort data=&varclus_rslt.(keep=var_no cluster) out=temp_1;
		by var_no;
	run;

	proc sort data=&LOG_in. out=&LOG_out.;
		by var_no;
	run;
	
	data &LOG_out.;
		set &LOG_out.;
		drop cluster clus_slct;
	run;

	data &LOG_out.;
		merge &LOG_out.(in=a) temp_1(in=b);
		by var_no;
		if a;
	run;

	/*取每组聚类中IV最大的变量*/
		%if %scan(&var_num.,1) ne %str() %then %do;
		proc sort data=&LOG_out. ;
			by cluster descending FINEBIN_IV ;
		run;

		data &LOG_out.;
			set &LOG_out.;
			by cluster;
			if first.cluster then n=1;
			else n+1;
			output;
		run;

		data &LOG_out.;
			set &LOG_out.;
			if n<=&var_num. then clus_slct=1;
			else clus_slct=0;
			drop n;
		run;
		proc sort data=&LOG_out.;
			by var_no;
		run;
		%end;
	%end;

%mend;