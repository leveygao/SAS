/*==================WOE ORDINAL===================*/


************选出字符变量（除了TARGET) 输出变量WOE表&&原表观测WOE BY 主键***************	   ;
%macro WOE_ORDN(INDATA, OUTDATA,	WOEDATA, PK);
PROC CONTENTS DATA= &INDATA. OUT=WORK.CONTENTS(where=(type=2)) NOPRINT;
RUN;
DATA null;
	SET  WORK.CONTENTS;
	WHERE   UPCASE(NAME)^=UPCASE("TARGET") and UPCASE(NAME)^=UPCASE("&pk.");
	CALL SYMPUT(COMPRESS('VAR'||_N_),NAME);

	CALL SYMPUT(COMPRESS('VAR_NAME'||_N_),NAME);
	CALL SYMPUT('N',_N_);

run;
%put &N.;

%do i=1 %to &n.;
/*%put &&VAR&i.;
%LET Variable_name&i.= &&VAR&i.;
%PUT &&Variable_name&i. ;*/

%macro CalcWOE(DsIn, IVVar, DVVar, WOEDS, WOEVar, DSout);
/* Calculating the WOE of an Independent variable IVVar and 
adding it to the data set DSin (producing a different output 
dataset DSout). The merging is done using PROC SQL to avoid 
the need to sort for matched merge. The new woe variable
is called teh WOEVar. The weight of evidence values
are also produced in the dataset WOEDS*/

/* Calculate the frequencies of the categories of the DV in each
of the bins of the IVVAR */

PROC FREQ data =&DsIn  noprint;
  tables &IVVar * &DVVar/out=Temp_Freqs;
run;

/* sort them */
proc sort data=Temp_Freqs;
 by &IVVar &DVVar;
run;

/* Sum the Goods and bads and calcualte the WOE for each bin */
Data Temp_WOE1;
 set Temp_Freqs
 ;
 retain C1 C0 C1T 0 C0T 0;
 by &IVVar &DVVar;
 if first.&IVVar then do;
      C0=Count;
	  C0T=C0T+C0;
	  end;
 if last.&IVVar then do;
       C1=Count;
	   C1T=C1T+C1;
	   end;
 
 if last.&IVVar then output;
 drop Count PERCENT &DVVar;
call symput ("C0T", C0T);
call symput ("C1T", C1T);
run;

/* summarize the WOE values ina woe map */ 
Data &WOEDs;
 set Temp_WOE1;
  C1T=&C1T.;
  C0T=&C0T.;
  
  GoodDist=C0/&C0T;
  BadDist=C1/&C1T;
  if(GoodDist>0 and BadDist>0)Then   WOE=log(BadDist/GoodDist);
  Else WOE=.;
  
  if not missing(WOE) then   IV= (C1/&C1T. - C0/&C0T.)*WOE ;
  else IV=.;
  
  DROP GoodDist  BadDist;
 /* keep &IVVar WOE; */
run;

proc sort data=&WOEDs;
 by WOE;
 run;

/* Match the maps with the values and create the output
dataset */
proc sql noprint;
	create table &dsout as 
	select a.* , b.woe as &WOEvar from &dsin a, &woeds b where a.&IvVar=b.&IvVar; 
quit;

/* Clean the workspace */
proc datasets library=work nodetails nolist;
 delete Temp_Freqs Temp_WOE1;
run; quit;




%mend;



%CalcWOE(&indata.,   &&var&i. ,  target,  Dvar_&i.I, Woevar_&i.I, Otable_&i.);

proc sort data=	Otable_&i.  ;
by &pk.;	run;



/* keep woe obs by pk*/
%IF %SYSFUNC(EXIST( &WOEDATA.)) %THEN %DO; /* 删除已有输出data */
			PROC DELETE DATA=  &WOEDATA.;
			RUN;
	%END;

data &WOEDATA.  ;
merge Otable: ;
by &pk.;

keep &pk. Woevar:  target;
run;



/* reconstruct output data */
data  Dtable_&i.;
length VAR_NAME $50.  VAR_CLASS $50.;
retain VAR_NAME;

set  Dvar_&i.I;
VAR_NAME= "&&VAR_NAME&i.";
VAR_CLASS=  &&var&i.;

DROP &&var&i.;
keep VAR_NAME VAR_CLASS  WOE IV  C1  C0  C1T C0T;
run;

%end;

%IF %SYSFUNC(EXIST( &outdata.)) %THEN %DO; /* 删除已有输出data */
			PROC DELETE DATA=  &outdata.;
			RUN;
		%END;




data &outdata.;
set Dtable_: ;
run;

/*
proc datasets library=work nodetails nolist;
 delete D_:  O_:;
run; quit;

proc sql;
create table  &outdata. as
select *,
sum(IV) as IV_SUM
from &outdata.
group by VAR_NAME
order by VAR_NAME, WOE
;
quit;
*/

%mend;
					
					


		
					
					
					
					
					
					

			
			
			
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
