/*��������-����*/
%macro score_calc_nobase(MODEL,CARD,variable,Estimate,sample,sample_set,MAX_TOTAL_SCORE,MIN_TOTAL_SCORE);

proc sql;
	create table woe_tmp2 as
	select  variable, max(WOE*ESTIMATE) as max_wxe, min(WOE*ESTIMATE) as min_wxe
	from &card.
	group by variable
	;
quit;

proc sql;
	select distinct Estimate into :Intercept from &MODEL. where compress(Variable)='Intercept';
	select count(*)-1 into :count_variable from &MODEL.;
	select sum(max_wxe)+&Intercept.,sum(min_wxe)+&Intercept. into :MAX_Y, :MIN_Y from woe_tmp2;
quit;

data TMP;
set &MODEL.(where=(compress(&variable.) ne 'Intercept'));
N+1;
run;

%do i=1 %to &count_variable.;
	proc sql; 
		select &variable. ,&Estimate. into : var_&i., :num_&i. from TMP where N=&i;
	quit;
	%put  &&var_&i.  &&num_&i.;
%end;

%let b=%sysevalf((&MAX_TOTAL_SCORE. - &MIN_TOTAL_SCORE.)/(&MAX_Y.-&MIN_Y.));
%let a=%sysevalf(&MIN_TOTAL_SCORE.+ &b. * &MAX_Y.);
%let c=%sysevalf((&a.-&b. * &Intercept.)/ &count_variable.);


data &card.;
	set  &card.;
	if compress(upcase(variable)) ne "INTERCEPT" then do;
	Score_nb=ROUND(&c. - &b. * WOE*ESTIMATE);
	end;
	else Score_nb=.;
run;

data &sample_set;
set &sample;
	%do i=1 %to &count_variable.;
		score_nb_&&var_&i.=ROUND(&c. - &b. * &&var_&i.*&&num_&i.);
	%end;
	score_noBase=sum(0
				%do i=1 %to &count_variable.;
					,score_nb_&&var_&i.
				%end;);
run;
%mend;
;

%macro score_calc(MODEL,variable,Estimate,sample,sample_set,PDO,STD,SODD);
%let varamount=0;
%let num=0;
%let var='s';

options noprintmsglist;

proc sql;
select count(*) into : varamount from &MODEL;
quit;

data TMP;
set &MODEL;
N+1;
run;

%do i=1 %to &varamount;
	proc sql; 
		select &variable. ,&Estimate. into : var_&i., :num_&i. from TMP where N=&i;
	quit;
/*	%put  &&var_&i.  &&num_&i.;*/
%end;

/*�����������*/
data &sample_set;
set &sample;
	%do i=2 %to &varamount;
		score_&&var_&i.=round(&&var_&i.*(-1)*&&num_&i.*&PDO./log(2),1);
	%end;
	score=sum(0
				%do i=2 %to &varamount;
					,score_&&var_&i.
				%end;);
	score_total=score+&STD.+round(&PDO.*((-1)*&num_1.-log(&SODD.))/log(2),1);
	intercept_n=&STD.+round(&PDO.*((-1)*&num_1.-log(&SODD.))/log(2),1);
run;
%mend;

/*AR KS ��*/
/*****************************�������ֿ�ģ��ʱ�����ؼ�****�汾1.0***2017��2��*PWC****/
/*============================0.ͳ�Ƽ������õ��ĺ�=========================*/
/*-------------------------------������KS��AR����--------------------------*/

/*1.KS����ĺ�*/
/*����������������ȶ��Է����м���������KSֵ*/
/*����˵���� InData-�������ݱ�ÿ������һ�����ݣ��������ֱ����ͺû���ʶ��, Factor-���ֱ�����ͨ��Ϊ��ֽ���򵥱���ֵ��,Default-�û���ǣ�0Ϊ����1Ϊ�ã���KS-��������*/
%MACRO KS_Calc(InData, Factor,Default,KS);

PROC SQL;
	CREATE TABLE &KS
	(
		Factor Char(20),
		Flag Char(100),
		KS Decimal,
		pKS Decimal
	);
QUIT;

DATA Sample;
	SET &InData;
	IF &Factor = NULL THEN &Factor = .;
	KEEP &Default &Factor;
RUN;


ODS OUTPUT KolSmir2Stats = KS_Detail;
PROC NPAR1WAY DATA = Sample EDF;
	CLASS &Default;
	VAR &Factor;
RUN;

DATA _NULL_;
	SET KS_Detail;
	IF Label2 = "D" THEN CALL SYMPUT("KSValue",nValue2);
	IF Label2 = "Pr > KSa" THEN CALL SYMPUT("pValue",nValue2);
RUN;


PROC SQL;
	INSERT INTO &KS
	SET
		Factor = "&Factor",
		KS = &KSValue,
		pKS = &pValue;

	DROP TABLE Sample, KS_Detail;
QUIT;


/*DATA &KS;*/
/*SET &KS;*/
/*FORMAT KS_FLAG $40.;*/
/*IF KS>=0.2 THEN KS_FLAG="�ɽ���";*/
/*ELSE IF KS>=0.1 THEN KS_FLAG="�ɽ��ܣ���ע��";*/
/*ELSE KS_FLAG="���ɽ���";*/
/*RUN;*/

%MEND;


/************************************************************************************************/
/*2.AR����ĺ�*/
/*���������������м���������ARֵ*/
/*����˵���� InData-�������ݱ�ÿ������һ�����ݣ��������ֱ����ͺû���ʶ��, Factor-���ֱ�����ͨ��Ϊ��ֽ���򵥱���ֵ��,Default-�û���ǣ�0Ϊ����1Ϊ�ã���ORDER-FACTOR��DEFAULT����������ԣ�����أ�ASC������أ�DESC����KS-��������*/
%MACRO AR_Calc(InData, Factor, Order,Default,AR);
PROC SQL;
	CREATE TABLE &AR
	(
		Factor Char(20),
		Order Char(5),
		Flag Char(100),
		AR Decimal
	);
QUIT;

DATA Sample;
	SET &InData;
	IF &Factor = NULL THEN &Factor = .;
	KEEP &Default &Factor;
RUN;

ODS OUTPUT MEASURES = AR_Detail;
PROC FREQ DATA = Sample;
	TABLES &Default * &Factor / MEASURES;
RUN; QUIT;

/*��SAS9.2��ǰ�汾ע���Somers' Dֵ�����û�ΪSomers D C|R*/

DATA _NULL_;
	SET AR_Detail;
	IF Statistic = "Somers' D C|R" AND "&Order" = "ASC" THEN CALL SYMPUT('ARValue', -Value);
	IF Statistic = "Somers' D C|R" AND "&Order" = "DESC" THEN CALL SYMPUT('ARValue', Value);
RUN;

PROC SQL;
	INSERT INTO &AR
	SET
		Factor = "&Factor",
		Order = "&Order",
		AR = &ARValue;

	DROP TABLE AR_Detail, Sample;
QUIT;

/**/
/*DATA &AR;*/
/*SET &AR;*/
/*FORMAT AR_FLAG $40.;*/
/*IF AR>=0.3 THEN AR_FLAG="�ɽ���";*/
/*ELSE IF AR>=0.2 THEN AR_FLAG="�ɽ��ܣ���ע��";*/
/*ELSE AR_FLAG="���ɽ���";*/
/*RUN;*/

%MEND;

%macro PSI_CALC(Indata, flag, Outdata);/*Indata-�������ݼ���flag-�����������������ֶΣ�ȡֵ0/1��Outdata-������ݼ�*/

proc delete data=&outdata;
run;

/*���ɱ����б�*/
proc contents data=&Indata (drop=&flag) out=var_list;
run;

data var_list;
set var_list;
var_id+1;
keep var_id name;
run;
/*�����������*/
proc sql;
select count(1) into :var_num from var_list;
quit;
/*����һ*/
data Intable1;
set &Indata;
where &flag=0;
drop &flag;
run;
/*������*/
data Intable2;
set &Indata;
where &flag=1;
drop &flag;
run;

%do j=1 %to &var_num;
/*ѡ�����*/
proc sql;
select NAME into: var_name from var_list where var_id=&j;
quit;

/*����һ*/
PROC FREQ
	DATA = Intable1(KEEP = &var_name);
	TABLE &var_name / NOROW NOCOL missing noprint
	OUT =  FREQ1;
RUN;
/*������*/
PROC FREQ
	DATA = Intable2(KEEP =&var_name);
	TABLE &var_name / NOROW NOCOL missing noprint
	OUT =  FREQ2;
RUN;

DATA FREQDATA;
	MERGE FREQ1(RENAME = (&var_name=Segment COUNT=CNT1 PERCENT=PRCT1))
		FREQ2(RENAME = (&var_name=Segment COUNT=CNT2 PERCENT=PRCT2));
	BY Segment;
RUN;

/*PSI����*/
data FREQDATA;
set FREQDATA;
SinglePSI = (PRCT1/100-PRCT2/100)*log(PRCT1/PRCT2);
run;

PROC SQL;
create table RsltPSI as SELECT 
  "&var_name" as variable,
  COUNT(Segment) as CntSegment, 
  SUM(CNT1) as CntSample1, 
  SUM(CNT2) as CntSample2, 
  SUM(SinglePSI) as PSI
FROM  FREQDATA;
QUIT;

/*���ܽ��*/
	
proc append base=&outdata data=RsltPSI force;
run;

%end;
%mend;