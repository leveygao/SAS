/*宏：SAMPLE_SEPARATE
用途： 将样本按给定比例，以及好坏分布分层抽样形成训练、测试集

输入输出：
in_dataset:输入数据集
default_flag:好坏标识
rate：训练集抽样比例*/
%macro sample_separate(in_dataset,default_flag,rate);

/*样本准备-细分数据抽样*/
		proc sort data=&in_dataset. out=temp;
			by &default_flag.;
		run;

		proc surveyselect data=temp method=srs 
			out=sample_s outall samprate=&rate. seed=123456;
			strata &default_flag.;
		run;

/*训练样本*/
		data &in_dataset._train;
			set sample_s;
			where (&default_flag.=1 or &default_flag.=0) and /*宏变量*/
			       selected=1;
			drop selectionProb samplingWeight;
		run;

/*测试样本*/
		data &in_dataset._test;
			set sample_s;
			where  selected=0;
			if &default_flag. not in (0,1) then &default_flag.=0;
			else &default_flag.=&default_flag.;
			drop selectionProb samplingWeight;
		run;
/*样本统计*/
		proc freq data=sample_s;
		tables selected*&default_flag./missing;
		run;
%mend;

