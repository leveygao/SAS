
/********************************************************************************************************************************************/
/*�Ⱦ�������
��Ҫ�õ�level2��l2_tmp�������߼��⣬����level2�����Credit_old���ݼ������ڽ�ģ��l2_tmp���ڴ�Ž�ģ�����е���ʱ�ɹ�
/********************************************************************************************************************************************/

/*3.1����Ԥ����*/

/*3.1.1�����ظ���¼*/
/*   ������ȡ������Ҫ������*/
data Credit_old_temp;
  set level2.Credit_old;
run;
/*method1:ʹ��SORT�����޳�ID�ظ�����*/
proc sort data= credit_old_temp
	out=credit_old
	dupout=credit_old_dup
	nodupkey;
	by id;
run;
/*method2:ʹ��SORT�����޳��ظ���*/
proc sort data= credit_old_temp
	out=credit_old
	dupout=credit_old_dup
	nodups;
	by _all_;
run;
/*method3:ʹ��data/first/last�޳��ظ���*/
proc sort data=credit_old_temp;
by id;
run;

data credit_old credit_old_dup;
set credit_old_temp;
by id;
if first.id  then output credit_old;
else output credit_old_dup;
run;

/*3.1.2 �ַ������ر���*/
/*method1:��ȡ���е��ַ�����*/
proc sql  ;
select name
    from sashelp.vcolumn 
	where libname='WORK' and memname=Upper("Credit_old") and type="char" and name~="target";
quit;
%let Rows=&SQLOBS.;
%put &Rows;
proc sql  noprint;
select name into :char1-:char&Rows
    from sashelp.vcolumn 
	where libname='WORK' and memname=Upper("Credit_old") and type="char" and name~="target";
quit;
%put &char1 &&char&Rows;
%put _user_;
/*method2:��ȡ���е��ַ�����*/

data _null_;
set sashelp.vcolumn end=last;
where libname='WORK' and memname=Upper("Credit_old") and type="char" and name~="target";
call symput("char"||left(_n_),compress(name));
/*call symput("char"||left(_n_),name);�Ƚ������������*/
if last then call symput("rows",_n_);
run;
%put &char1 &&char&Rows;
%put _user_;

/*���ÿһ���ַ��������±���*/
%Macro replace_char(old_table);
%do i=1 %to &Rows;
proc sql ;
	create table  &&char&i as
		select distinct &&char&i
    from &old_table;
quit;
data char2num_&&char&i l2_tmp.char2num_&&char&i;
	set &&char&i;
    cd=_N_;
run;
proc sql;
  create table   &old_table as
     select a.*,b.cd as &&char&i.._cd
	 from &old_table as a
	    left join char2num_&&char&i as b on a.&&char&i=b.&&char&i;
quit;
%end;
%mend replace_char;
%replace_char(Credit_old);

/*��resΪ��,�������뷽ʽ����*/

data temp;
set credit_old;
res_cd1=1*(res="R")+2*(res="S")+3*(res="U");
run;

proc format;
invalue $res_f 
"R"=1
"S"=2
"U"=3;
run;


data temp1;
set credit_old;
res_cd1=0+input(res,$res_f.);
run;


/*3.2  ���ȳ���*/
data Credit_develop;
	set Credit_old;
run;

proc freq data=Credit_develop;
   tables Target;
run;

/*3.3  ����ѵ��������֤��*/
proc sort data=Credit_develop;
	by target;
run;
/*Ϊ�˶�ģ�ͽ����һ����������ۣ���Ҫ�����ݼ����Ϊѵ��������֤��*/
proc surveyselect noprint
                  data = Credit_develop 
                  samprate=.7 
                  out=Credit_develop_ALL
                  seed=12345
                  outall;
   strata target;
run;

data credit_model credit_access l2_tmp.credit_model l2_tmp.credit_access ;
	set Credit_develop_ALL;
	if selected=1 then output credit_model l2_tmp.credit_model;
	else output credit_access l2_tmp.credit_access;
	drop selected  SelectionProb SamplingWeight;
run;

/********************************************************************************************************************************************/
/*���׶γɹ��б���Щ�ɹ����Զ�������l2_tmp����Ϊ����
Credit_model���ݼ�Ϊ������ģʱ��ѵ�����ݼ�
Credit_access���ݼ�Ϊ������ģʱ����֤���ݼ�
Char2num_Res��Char2num_BranchΪ������������ı���������ݿ���Ҳ��Ϊά��������ģ��ʹ��ʱ���������ֶα������±������ô�*/
/********************************************************************************************************************************************/
