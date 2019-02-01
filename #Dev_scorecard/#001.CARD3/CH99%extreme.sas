/* Calculation of extreme values for a continuous variable
which are outside the range of NSigmas * STD from t he
mean. */

%macro Extremes1(DSin, VarX, NSigmas, DSout);
/* First, extract XVar to a temp dataset, and keep the
observation number in the original dataset */
data temp;
set &DSin;
ObsNo=_N_;
keep &VarX ObsNo;
run;
/* Calculate the mean and STD using proc univariate */
proc univariate data=temp noprint;
var &VarX;
output out=temp_u STD=VSTD Mean=VMean;
run;
/* Extract upper and lower limits into macro variables */
data _null_;
set temp_u;
call symput('STD', VSTD);
call symput('Mean', VMean);
run;
%let ULimit=%sysevalf(&Mean + &NSigmas * &STD);
%let LLimit=%sysevalf(&Mean - &NSigmas * &STD);
/* Extract extreme observations outside these limits */
data &DSout;
set temp;
if &VarX < &Llimit or &VarX > &ULimit;
run;
/* Clean workspace and finish the macro */
proc datasets library=work nodetails;
delete temp temp_u;
quit;
%mend;

/* Calculation of extreme values for a continuous variable
which are outside the range of NQrange * QRange
from the median. We use the median in place of the mean
as a more robust estimate of the central tendency */
%macro Extremes2(DSin, VarX, NQRange, DSout);

/* First, extract XVar to a temp dataset, and the
observation number of the original dataset */
data temp;
set &DSin;
ObsNo=_N_;
keep &VarX ObsNo;
run;
/* Calculate the median and QRange using proc univariate */
proc univariate data=temp noprint;
var &VarX;
output out=temp_u qrange=vqr mode=vmode;
run;
/* Extract the upper and lower limits into macro variables */
data _null_;
set temp_u;
call symput('QR', vqr);
call symput('Mode', vmode);
run;
%let ULimit=%sysevalf(&Mode + &NQrange * &QR);
%let LLimit=%sysevalf(&Mode - &NQRange * &QR);
/* Extract extreme observations outside these limits */
data &DSout;
set temp;
if &VarX < &Llimit or &VarX > &ULimit;
run;
/* Clean workspace and finish the macro */
proc datasets library=work nodetails;
delete temp temp_u;
quit;
%mend;
