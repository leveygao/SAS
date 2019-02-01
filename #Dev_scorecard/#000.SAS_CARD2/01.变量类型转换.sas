/*��:VAR_CONVERT
��;�������ݼ����б���ת��Ϊ��ֵ��ʽ��best32���������LABEL

���������
pk:����
in_dataset:�������ݼ�
out_dataset:������ݼ�
labels:��Ϊ�գ��Ժ���ʽ����ĶԱ������label�Ĵ���*/;

%macro var_convert(pk,in_dataset,out_dataset,labels);
/*%let pk=id;*/
/*%let in_dataset=test_sample;*/
/*%let out_dataset=test_sample_out;*/
/*%let labels=WJCF_LABEL;*/
proc contents data=&in_dataset.(drop=&pk.) order=varnum out=_varlist(keep=NAME) ;
run;

proc sql noprint;
	select count(*), NAME into: var_num, :var_list separated by '**' from _varlist;
quit;
%put var_num=&var_num.;

data &out_dataset.;
	 set &in_dataset.;
	 %do i=1 %to &var_num.;
	 	%scan(&var_list.,&i.,'**')_1=input(%scan(&var_list.,&i.,'**'),best32.);
		drop %scan(&var_list.,&i.,'**');
		rename %scan(&var_list.,&i.,'**')_1=%scan(&var_list.,&i.,'**');
	 %end;
run;


%if %length(&labels.) ne 0 %then %do;
data &out_dataset.;
	 set &out_dataset.;
	 label 
	 	%&labels.;
		;
run;
%end;

%mend;


