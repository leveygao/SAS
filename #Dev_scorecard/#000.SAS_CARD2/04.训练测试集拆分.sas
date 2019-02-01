/*�꣺SAMPLE_SEPARATE
��;�� �������������������Լ��û��ֲ��ֲ�����γ�ѵ�������Լ�

���������
in_dataset:�������ݼ�
default_flag:�û���ʶ
rate��ѵ������������*/
%macro sample_separate(in_dataset,default_flag,rate);

/*����׼��-ϸ�����ݳ���*/
		proc sort data=&in_dataset. out=temp;
			by &default_flag.;
		run;

		proc surveyselect data=temp method=srs 
			out=sample_s outall samprate=&rate. seed=123456;
			strata &default_flag.;
		run;

/*ѵ������*/
		data &in_dataset._train;
			set sample_s;
			where (&default_flag.=1 or &default_flag.=0) and /*�����*/
			       selected=1;
			drop selectionProb samplingWeight;
		run;

/*��������*/
		data &in_dataset._test;
			set sample_s;
			where  selected=0;
			if &default_flag. not in (0,1) then &default_flag.=0;
			else &default_flag.=&default_flag.;
			drop selectionProb samplingWeight;
		run;
/*����ͳ��*/
		proc freq data=sample_s;
		tables selected*&default_flag./missing;
		run;
%mend;

