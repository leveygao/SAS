
/********************************************************************************************************************************************/
/*先决条件：
需要用到level2和l2_tmp这两个逻辑库，其中level2存放有Credit_old数据集，用于建模。l2_tmp用于存放建模过程中的临时成果
/********************************************************************************************************************************************/

/*3.1数据预处理*/

/*3.1.1消除重复记录*/
/*   首先提取分析需要的数据*/
data Credit_old_temp;
  set level2.Credit_old;
run;
/*method1:使用SORT过程剔除ID重复的行*/
proc sort data= credit_old_temp
	out=credit_old
	dupout=credit_old_dup
	nodupkey;
	by id;
run;
/*method2:使用SORT过程剔除重复行*/
proc sort data= credit_old_temp
	out=credit_old
	dupout=credit_old_dup
	nodups;
	by _all_;
run;
/*method3:使用data/first/last剔除重复行*/
proc sort data=credit_old_temp;
by id;
run;

data credit_old credit_old_dup;
set credit_old_temp;
by id;
if first.id  then output credit_old;
else output credit_old_dup;
run;

/*3.1.2 字符变量重编码*/
/*method1:获取所有的字符变量*/
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
/*method2:获取所有的字符变量*/

data _null_;
set sashelp.vcolumn end=last;
where libname='WORK' and memname=Upper("Credit_old") and type="char" and name~="target";
call symput("char"||left(_n_),compress(name));
/*call symput("char"||left(_n_),name);比较与上面的区别*/
if last then call symput("rows",_n_);
run;
%put &char1 &&char&Rows;
%put _user_;

/*针对每一个字符变量重新编码*/
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

/*以res为例,其它编码方式介绍*/

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


/*3.2  过度抽样*/
data Credit_develop;
	set Credit_old;
run;

proc freq data=Credit_develop;
   tables Target;
run;

/*3.3  构造训练集和验证集*/
proc sort data=Credit_develop;
	by target;
run;
/*为了对模型结果有一个合理的评价，需要将数据集拆分为训练集和验证集*/
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
/*本阶段成果列表：这些成果被自动保存在l2_tmp中作为备份
Credit_model数据集为将来建模时的训练数据集
Credit_access数据集为将来建模时的验证数据集
Char2num_Res、Char2num_Branch为两个分类变量的编码表，在数据库中也称为维表，将来在模型使用时对新数据字段变量重新编码有用处*/
/********************************************************************************************************************************************/
