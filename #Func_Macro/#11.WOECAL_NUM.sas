/* bin + woe */
/*******
/*******
  Credit Risk Scorecards: Development and Implementation using SAS
  (c)  Mamdouh Refaat
********/

/*******************************************************/
/* Macro: CalcWOE */
/*******************************************************/
%macro CalcWOE(DsIn, IVVar, DVVar, WOEDS, WOEVar, DSout);
/* Calculating the WOE of an Independent variable IVVar and 
adding it to the data set DSin (producing a different output 
dataset DSout). The merging is done using PROC SQL to avoid 
the need to sort for matched merge. The new woe variable
is called teh WOEVar. The weight of evidence values
are also produced in the dataset WOEDS*/

/* Calculate the frequencies of the categories of the DV in each
of the bins of the IVVAR */

PROC FREQ data =&DsIn noprint;
  tables &IVVar * &DVVar/out=Temp_Freqs;
run;

/* sort them */
proc sort data=Temp_Freqs;
 by &IVVar &DVVar;
run;

/* Sum the Goods and bads and calcualte the WOE for each bin */
Data Temp_WOE1;
 set Temp_Freqs;
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
  GoodDist=C0/&C0T;
  BadDist=C1/&C1T;
  if(GoodDist>0 and BadDist>0)Then   WOE=log(BadDist/GoodDist);
  Else WOE=.;
  
  IV+(BadDist-GoodDist)*WOE ;
  
  
  keep &IVVar WOE IV;
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



/*******************************************************/
/* Macro EqWbinn  */ 
/*******************************************************/
%macro EqWBinn(DSin, XVar, Nb, XBVar, DSout, DSMap);
/* extract max and min values */
	proc sql  noprint; 
		 select  max(&Xvar) into :Vmax from &dsin;
		 select  min(&XVar) into :Vmin from &dsin;
	run;
	quit;

	 /* calcualte the bin size */
	%let Bs = %sysevalf((&Vmax - &Vmin)/&Nb);

	/* Loop on each of the values, create the bin boundaries, 
	   and count the number of values in each bin */
	data &dsout;
	 set &dsin;
	  %do i=1 %to &Nb;
		  %let Bin_U=%sysevalf(&Vmin+&i*&Bs);
		  %let Bin_L=%sysevalf(&Bin_U - &Bs);
		  %if &i=1 %then  %do; 
				IF &Xvar >= &Bin_L and &Xvar <= &Bin_U THEN &XBvar=&i; 
						  %end;
		  %else %if &i>1 %then %do; 
				IF &Xvar > &Bin_L and &Xvar <= &Bin_U THEN &XBvar=&i;  
								 %end;
	  %end;
	run;
	/* Create the binning map and store the bin boundaries */
	proc sql noprint;
	 create table &DSMap (BinMin num, BinMax num, BinNo num);
	  %do i=1 %to &Nb;
		  %let Bin_U=%sysevalf(&Vmin+&i*&Bs);
		  %let Bin_L=%sysevalf(&Bin_U - &Bs);
		  insert into &DSMap values(&Bin_L, &Bin_U, &i);
	  %end;
	quit;
%mend;  




%macro WOE_NUM(INDATA, OUTDATA,WOEDATA, NUM,pk);
PROC CONTENTS DATA= &INDATA. OUT=WORK.CONTENTS(where=(type=1)) NOPRINT;
RUN;
DATA null;
	SET  WORK.CONTENTS;
	WHERE   UPCASE(NAME)^=UPCASE("TARGET") and UPCASE(NAME)^=UPCASE("&pk.");
	CALL SYMPUT(COMPRESS('VAR'||_N_),NAME);

	CALL SYMPUT(COMPRESS('VAR_NAME'||_N_),NAME);
	CALL SYMPUT('N',_N_);

run;
%put &N.;

%do k=1 %to  &n.  ;
%put &&VAR&k.;


%EqWBinn(&INDATA.,  &&VAR&k., &NUM.,  IVVar_&k.I , cc&k.,  Map_&k. );


%CalcWOE(cc&k.,  IVVar_&k.I , target,  WOEDS_&k., WOEVar_&k.I, DSout_&k.);

proc sort data= WOEDS_&k.;
by    IVVar_&k.I;
run;

proc sort data=DSout_&k.;
by &pk.;
run;
		
		
data  VT_&k.;
length VAR_NAME $50.  VAR_CLASS 8.;
/*retain VAR_NAME;*/

set  WOEDS_&k.;
VAR_NAME= "&&VAR_NAME&k.";
VAR_CLASS= IVVar_&k.I ;

DROP IVVar_&k.I ;
run;

PROC SQL;
create table VS_&k. as
select a.*, b.BinMin, b.BinMax
from  VT_&k.    as a left join  Map_&k. as b
	on a.VAR_CLASS=  b.BinNo
order by VAR_CLASS
;
quit;

%end;

/* reconstruct WOE data */
%IF %SYSFUNC(EXIST( &WOEDATA.)) %THEN %DO; /* 删除已有输出data */
			PROC DELETE DATA=  &WOEDATA.;
			RUN;
		%END;
		
data &WOEDATA.  ;
merge DSout_: ;
by &pk.;

keep &pk. WOEVar_:  target;
run;

/* reconstruct output data */
%IF %SYSFUNC(EXIST( &outdata.)) %THEN %DO; /* 删除已有输出data */
			PROC DELETE DATA=  &outdata.;
			RUN;
		%END;
		
		
data  &outdata.;
retain  VAR_NAME   VAR_CLASS BinMin BinMax  WOE;
set VS_: ;
run;


/*

proc datasets library=work nodetails nolist;
 delete T_:   VS_:;
run; quit;
*/



%mend;