/*==================WOE BIN====================*/
%MACRO WOE_PRINT(INDATA,OUTDATA,COUNT);
PROC CONTENTS DATA= &INDATA. OUT=WORK.CONTENTS NOPRINT;
RUN;

************选出数值变量（除了TARGET)***************	   ;
DATA _NULL_;
	SET  WORK.CONTENTS;
	WHERE TYPE=1 AND UPCASE(NAME)^=UPCASE("TARGET");
	CALL SYMPUT(COMPRESS('VAR'||_N_),NAME);
	CALL SYMPUT(COMPRESS('FMT'||_N_),COMPRESS(UPCASE(NAME)||'.'));
	CALL SYMPUT('N',_N_);

RUN;

************将数值型变量等分为COUNT份***************	   ;

	%DO I=1 %TO &N.;
		PROC SORT DATA= &INDATA.(KEEP= &&VAR&I.) OUT=WORK.&&VAR&I.;
			BY &&VAR&I.;
		RUN;
			
		DATA WORK.A&&VAR&I;   /*计算每个变量的组号*/
			SET WORK.&&VAR&I NOBS=OBS;
			NUM=CEIL(OBS/&COUNT.);
			GROUP=CEIL(_N_/NUM);
		RUN;
		
		PROC SQL;			  /*找出每个组的最小值*/
			CREATE TABLE WORK.B&&VAR&I AS   
			SELECT GROUP	
					,MIN(&&VAR&I) AS &&VAR&I
					FROM WORK.A&&VAR&I
					GROUP BY GROUP
					;
					
				CREATE TABLE WORK.MAX AS   /*找出每个组的最大值*/
					SELECT MAX(&&VAR&I)+0.01 AS &&VAR&I
					FROM WORK.A&&VAR&I;
					
		QUIT;
		
		PROC SORT DATA=WORK.B&&VAR&I NODUPKEY;    /*去重找出的最小值*/
			BY &&VAR&I;
		RUN;
		PROC SORT DATA=WORK.B&&VAR&I;
			BY GROUP;
		RUN;
			
		DATA WORK.C&&VAR&I;
			SET WORK.B&&VAR&I(KEEP=&&VAR&I) WORK.MAX;
			IF _N_=1 THEN &&VAR&I=&&VAR&I-0.01;
			LENGTH N $2.;
			IF _N_ ^=1 THEN DO;
				A=_N_-2;
				IF A<=9 THEN N=COMPRESS("O"||A);
				ELSE N=PUT(A,$2.);
			END;
			DROP A;
		RUN;
		
	%END;


***************将数值型变量转化成区间变量***********;
	%DO I=1 %TO &N.;

		DATA WORK.D&&VAR&I;
			SET WORK.C&&VAR&I END=LAST;
			LENGTH LABEL $40.;
			FMTNAME="&&VAR&I";
			TYPE="N";
			
			START=LAG(&&VAR&I);
			END=&&VAR&I;
			
			SEXCL="N";
			EEXCL="Y";
			
			LABEL=COMPRESS(N||".["||ROUND(START,.01)||","||ROUND(END,.01)||")");
			
			IF START^=.;
			DROP &&VAR&I N;
		
		RUN;	
		
		PROC FORMAT CNTLIN=WORK.D&&VAR&I CNTLOUT=WORK.FORMAT; /*每循环一次会放入work.format*/
			RUN;
		
	%END;

		DATA WORK.E;  /*对每个变量根据上面的格式打标签分组*/
		SET &INDATA.;
		%DO I=1 %TO &N.;
			F_&&VAR&I=PUT(&&VAR&I,&&FMT&I);
			
			DROP &&VAR&I;
			RENAME F_&&VAR&I=&&VAR&I;
		%END;
		RUN;
		
		
******************根据区间计算WOE*****************;		
		%DO I=1 %TO &N.;
			
			PROC SQL;
			CREATE TABLE WORK.F AS
				SELECT  &&VAR&I
					,SUM(CASE WHEN TARGET=0 THEN 1 ELSE 0 END) AS GOOD_COUNT
					,SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END) AS BAD_COUNT
					
				FROM WORK.E
				GROUP BY &&VAR&I
				;
				
			QUIT;
			
			PROC SQL;
				CREATE TABLE WORK.F1 AS 
					SELECT SUM(GOOD_COUNT) AS GOOD_TOTAL
						,SUM(BAD_COUNT) AS BAD_TOTAL
					FROM WORK.F
					;
			QUIT;

			DATA WORK.F2; 
				IF _N_=1 THEN SET WORK.F1; 
				/* 横向合并， 放入这个数据集的仅有的一个观测 ，一直存在直到下面的数据集结束 */
				SET WORK.F  END=LAST;
				CNT=SUM(GOOD_TOTAL,BAD_TOTAL);
				P_0=GOOD_COUNT/GOOD_TOTAL;
				P_1=BAD_COUNT/BAD_TOTAL;
				
				IF P_1=0 THEN WOE=.;
				ELSE WOE=LOG(P_1/P_0);
				IV+(P_1-P_0)*WOE ;    /* IV*/
				
				DROP CNT GOOD_TOTAL BAD_TOTAL;
			RUN;		
			
			PROC SQL;
				CREATE TABLE WORK.F&&VAR&I AS
				SELECT A.*,B.*
				
				FROM WORK.F2 as A
					LEFT JOIN WORK.FORMAT(WHERE=(UPCASE(FMTNAME)=UPCASE("&&VAR&I"))) as B
					ON A.&&VAR&I = B.LABEL;
					
			QUIT;
		%END;

		%IF %SYSFUNC(EXIST(&OUTDATA.)) %THEN %DO; /* 删除已有输出data */
			PROC DELETE DATA=&OUTDATA.;
			RUN;
		%END;

			%DO I=1 %TO &N.;
				PROC SQL;
					CREATE TABLE G&I. AS
					SELECT 
					"&&VAR&I." AS VAR LENGTH=40, 
					START, 
					END, 
					WOE, 
					GOOD_COUNT, 
					BAD_COUNT,
					LABEL, 
					IV 
					/*,sum(IV) as IV_SUM  */
					
					
					FROM WORK.F&&VAR&I 
					group by VAR
					order by VAR, LABEL,WOE
					;
				QUIT;
				
				
				
				PROC APPEND BASE=&OUTDATA. DATA=G&I. FORCE;
				RUN;
				
			%END;


%MEND;
			
					
					
					


		
					
					
					
					
					
					

			
			
			
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
