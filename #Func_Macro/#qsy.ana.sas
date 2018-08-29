options ls=250 ps=500 sortsize=max sumsize=max bufno=20 nonumber nocenter nodate replace;
OPTION SPOOL;
  options source notes  Nomlogic mprint symbolgen=N ;
* option nosource symbolgen=n noerrorabend;
* options mprint notes;
options ovp compress=no ;
options formchar='|-+++++++++++=|-/\<>*';
options noxwait noxsync ;
OPTIONS COMPRESS=YES;
run;

* set options and invoke Excel using DDE;
options noxwait noxsync ;

libname test ".";

%include "model.sas";  * macros used for modeling;
filename outf "var2.txt";

%macro rawdata;

data &plib..&fin.0(keep=&var0. &depvar. &id. &weight. &extravar.);
   set &plib..&fin.;

*   if ranuni(1)<=0.5;

   length &weight. 3 &depvar. 4;
   retain &weight. 1;
/*   &id.=_n_;*/
   &depvar.=(&ifindep.);
   array x _numeric_;
   do over x;
      if x=. then x=0;
   end;
run;
%mend rawdata;


%macro modeling;
* these settings are for model;

*%get_var0(0);                                     * Create pre-selected variable list (var0) ; 
* macro get_var0(cv);
* CV The coefficient of variation defined as the ratio of the standard deviation to the mean expressed as a percentage;
run;

%include outf;                                    * load pre-selected variable list from get_var0;
run;
*%raw(ifreadraw=yes, ifxx=NO, ifxi=NO, ifsubset=yes);      * get data file;
%include "&fin..txt.&plib.";

%let var1=&var.;
*%model(50);                                      * fit preliminary model many times;
%model(50, varstep=2);                           * fit fine-tune model many times;
*%model(50, varstep=2);                           * fit fine-tune model many times;
* %model(5, varstep=4);                           * fit fine-tune model many times;

*%fnlresp(1);                                    * final model evaluation and scoring code;
* macro fnlresp(mdlstep, vsample=2, ifkeepbm=y);
* mdlstep is the model indep var set to be used in the current step;
* vsample develop=1 test=2 validate=3;
* ifkeepbm=y keep all obs;
* ifkeepbm=n remove bottom missing data in deccut;
*%calccorr;                                      * calculate correlation coefficients; 

*%fnlscr;                                        * generate final scored file; 
* macro fnlscr(ifrecut=n, ifkeepbm=y, valid=y);
* scoring code from MDLSCR;
* load from "&fin..scr.&plib.";


%mend modeling;

/***************the real process***********************************************/

%let dset=M;                                  * raw data file;
%let fin=M1;                                      * working file;
libname dml ".";                             * working directory;
%let plib=dml;                                     * data lib;
%let ifstment=%str();                              * data selection;
%let id=SD_APP_SEQ;                          * unique ID key;
%let prob=prdval;                                  * default predict value;
%let segcnt=10;                                    * default decile cuts;
%let extravar=%str();                              * extra variables to keep;
%let weight=wt;                                    * weight var;

%let fin=dset;                                     * working data;
%let model=logistic;                               * model type;
%let depvar=TGT;                                  * dep var;
%let wstat=%str();                                 * where statment in macro rawdata ;
%let ifindep=%str(TGT=1);                         * define dep var;


%let var1=%str(x:);
%let var2=%str(
xl20
xl55
xl6
xl65
xl67
xl71
xl74
xl25
xl44
xl72
xl73
xl60
xl15
xl47
xl12
xl41
xl57
xl14
xl70
xl21
xl53
xl26
xl29
xl69
xl39
xl11
xl19
xl27

);

%let var3=%str(
xi1737
xi262 
xl66  
xx66  
xl62  
);

%let var4=%str(
xi1737
xi262 
xl66  
xx66  
);

%modeling;

* %calccorr;

run;
