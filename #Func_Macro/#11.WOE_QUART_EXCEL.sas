/**indata数据源，qp分位数(25,50,75,mean)**/
%macro wqt(indata,  outdata,	qp);


proc means data= &indata.  max min mean p10 p25 p50 p75 p99 ;
var IV;
output out= mean_table max=max min=min mean=mean p10=p10 p25=p25 p50=p50 p75= p75 p99=p99  ;
run;

/* 分位数宏 */
proc sql noprint;
select  p10,p25,p50,p75,p99, mean , min,max
into: ivp10 separated by ",", 
: ivp25 separated by ",", 
: ivp50 separated by ",", 
: ivp75 separated by ",", 
: ivp99 separated by ",", 
: ivpmean separated by "," ,
: ivpmin separated by "," ,
: ivpmax separated by "," 


from mean_table;
quit;

%put "&ivp25.";
%put "&ivp50.";
%put "&ivp75.";
%put "&ivpmean.";
%put "&ivpmax.";


proc sql;
create table IV_QT_TABLE as
select *
	
from  &indata.
where VAR in (
select distinct var from  &indata. where iv>= (&&ivp&qp.)  /*  取分箱变量的IV在X分位以上 */
)
;    
quit;




proc sql;
create table IV_vartable as
select distinct var 
from IV_QT_TABLE
;
quit;


/* 筛选变量 */
proc sql;
create table outdata1 as
select  *

from &indata.   
where var in(select
distinct var from  IV_vartable)
;
quit;


data &outdata.;
set outdata1;
length Quarter_Pct $8.;
Quarter_Pct="&qp.";
IV_QP=&&ivp&qp. ;
run;


PROC EXPORT DATA= &outdata.
            OUTFILE= ".\&outdata._table.xlsx" 
            DBMS=EXCEL REPLACE;
     SHEET="&outdata._&qp."; 
RUN;




/* woe transpose*/
data transpose1;
set &outdata.(keep=var woe label iv);
length   c 8.  a $8.  b $8.;
a= compress(substr(label,1,1));
b= compress(substr(label,2,1));

if compress(a)="O" then c=b+0;
 else  c=a*10+b;

run;


proc sort data=transpose1  ;
by var c;
run;

proc transpose  data=	transpose1(drop=c)
out=transpose2 (drop=  _LABEL_) prefix=GROUP_;
by var;
var label woe iv;
run;


PROC EXPORT DATA= transpose2
            OUTFILE= ".\&outdata._trs.xlsx" 
            DBMS=EXCEL REPLACE;
     SHEET="&outdata._trs"; 
RUN;

%MEND;