/*宏：REBIN
用途：人工定义变量分组后重新测算WOE和IV

输入输出：
in_dataset:输入数据集
varname：变量名，用空格分隔
default_flag:好坏标识
ranking_adj:以宏形式储存的对变量进行人工分组的代码
woe_out:WOE结果汇总表
iv_out:IV结果汇总表
Log_in:可为空，变量清单
Log_out:当log_in不为空时，log_out不可为空，将变量的IV值汇总到log_in*/
%MACRO REBIN(in_dataset,varname,default_flag,Ranking_adj,woe_out,iv_out,LOG_in,LOG_out);
data sample_adj;
	set &in_dataset.;
	%&Ranking_adj.;
run;

proc delete data=&woe_out. &iv_out.;run;

%let p1=1;
	%do %while(%scan(&varname.,&p1.,' ') ne %str());
		%let V=%scan(&varname.,&p1.,' ');

		PROC SUMMARY DATA=sample_adj MISSING;
			CLASS R_&V. &default_flag.;
			VAR &V.;
			OUTPUT OUT=SUM MAX=MAX;
		RUN;

		PROC TRANSPOSE DATA=SUM(WHERE=(_TYPE_=3)) PREFIX=N_ OUT=WOE(DROP=_NAME_);
			ID &default_flag.;
			BY R_&V.;
			VAR _FREQ_;
		RUN;

		PROC TRANSPOSE DATA=SUM(WHERE=(_TYPE_=1)) PREFIX=ALL_ OUT=ALL_N(KEEP=ALL:);
			ID &default_flag.;
			BY R_&V.;
			VAR _FREQ_;
		RUN;

	DATA WOE (KEEP=R_&V. WOE IV_N N_0 N_1 P_1 P_0 P_ALL) IV(KEEP=VAR_NO IV);
		LENGTH VAR_NO $32.;
		IF _N_=1 THEN SET ALL_N;
		SET WOE END=LAST;

		VAR_NO="&V.";
		IF N_0<=0 THEN P_0=0.001;
		ELSE P_0=N_0/ALL_0;

		IF N_1<=0 THEN P_1=0.001;
		ELSE P_1=N_1/ALL_1;

		P_ALL=sum(N_0,N_1)/sum(ALL_1,ALL_0);
		WOE=LOG(P_0/P_1);
		IV_N=(P_0-P_1)*LOG(P_0/P_1);
		IV+(P_0-P_1)*LOG(P_0/P_1);

		IF LAST THEN OUTPUT IV;
		OUTPUT WOE;
	RUN;


	DATA FMT1;
		LENGTH START $100. END $100. VAR_NO $32.;;
		SET SUM(WHERE=(_TYPE_=2)) END=LAST;
		VAR_NO="&V.";
		START=COMPRESS(round(LAG1(MAX),0.01));
		IF _N_=1 THEN START="LOW";
		END=COMPRESS(round(MAX,0.01));
	/*	SEXCL="Y";*/
	/*	EEXCL="N";*/
	/*	FMTNAME="&V";*/
		
		IF LAST THEN END='HIGH';
		KEEP START END R_&V. VAR_NO;
	RUN;

		DATA FMT;
			MERGE WOE FMT1;
			rename R_&V.=RANK ;
		RUN;

		data FMT;
			set FMT;	
			IF MISSING(END) THEN DO;
				END=START;
				RANK=START;
			END;
			RANK_FINEBIN=COMPRESS(PUT(RANK,Z2.)||".("||START||","||END||"]");
		 	
		RUN;

		PROC APPEND BASE=&woe_out. DATA=FMT FORCE;
		RUN;
		
		PROC APPEND BASE=&IV_OUT. DATA=IV FORCE;
		RUN;
		%let p1=%eval(&p1.+1);
	%end;
	data &woe_out.;
		set &woe_out.;
		format SAS_WOE $200. SAS_RANK $200.;
		if compress(start)="LOW" then do;
			SAS_WOE="IF "||compress(VAR_NO)||"<="||compress(end)||" THEN WOE_"||compress(VAR_NO)||"="||woe||";";
		end;
		else if compress(end)="HIGH" then do;
			SAS_WOE="ELSE IF "||compress(start)||"<"||compress(VAR_NO)||" THEN WOE_"||compress(VAR_NO)||"="||woe||";";
		end;
		else do;
			SAS_WOE="ELSE IF "||compress(start)||"<"||compress(VAR_NO)||"<="||compress(end)||" THEN WOE_"||compress(VAR_NO)||"="||woe||";";
		end;

		if compress(start)="LOW" then do;
			SAS_RANK="IF "||compress(VAR_NO)||"<="||compress(end)||" THEN R_"||compress(VAR_NO)||"="||compress(put(rank,$8.))||";";
		end;
		else if compress(end)="HIGH" then do;
			SAS_RANK="ELSE IF "||compress(start)||"<"||compress(VAR_NO)||" THEN R_"||compress(VAR_NO)||"="||compress(put(rank,$8.))||";";
		end;
		else do;
			SAS_RANK="ELSE IF "||compress(start)||"<"||compress(VAR_NO)||"<="||compress(end)||" THEN R_"||compress(VAR_NO)||"="||compress(put(rank,$8.))||";";
		end;
	run;

		data &iv_out.;
			set &iv_out.;
			woe_var_no=compress("WOE_"||var_no);
		run;
		/*record var performance*/
	%if &LOG_in. ne %str()  %then %do;
	proc sort data=&IV_OUT. out=var_iv;
		by var_no;
	run;

	proc sort data=&LOG_in out=&LOG_out.;
		by var_no;
	run;
	
	data &log_out.;
		set &log_out;
		drop CORSBIN_IV;
	run;

	data &LOG_out.;
		merge &LOG_out.(in=a) var_iv(in=b);
		by var_no;
		if a;
		rename iv=CORSBIN_IV;
		
	run;

	proc sort data=&woe_out.;
		by var_no;
	run;

	proc sort data=&log_out.;
		by var_no;
	run;

	data &woe_out.;
		merge &woe_out.(in=a) &log_out.(in=b keep=var_no label );
		by var_no;
		if a;
	run;

	proc sort data=&woe_out.;
		by var_no RANK;
	run;
		
	%end;
%MEND;

