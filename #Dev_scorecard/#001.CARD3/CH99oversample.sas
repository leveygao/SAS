data test;
i=1;
do j=1 to 2000;
x1=rannor(323);
output;
end;
i=0;
do j=1 to 20000;
x1=rannor(33);
output;
end;
drop j;
run;

*�ֲ㲻�ȱ���������rate��n������Ը����ݼ�;
proc surveyselect data=test
method=sys rate=(1,0.1) out=out1;
strata descending i ;
run;

proc surveyselect data=test
method=sys n=(2000,2000) out=out1;
strata descending i ;
run;



