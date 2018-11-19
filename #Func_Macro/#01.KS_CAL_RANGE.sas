/**data数据源，varx排序变量，status分类变量，data1切分后的变量，Mks最大ks值,M分组组数   **/
%macro KS(data, varx, status,  data1, Mks,M);

proc sort data=&data;
by &varx;
run;

proc sql noprint;
 select sum(&status) into:P from &data;
 select count(*) into :Ntot from &data;
 quit;
 %let N=%eval(&Ntot-&P); 
 
 %put &p.;
 %put &Ntot.;
 %put &N.;
 

data &data1;
set &data nobs=NN;
by &varx;
retain tile 1  totP  0 totN 0;
Tile_size=ceil(NN/&M.);

if &status=1 then totP=totP+&status;
else totN=totN+1;

Pper=totP/&P;
Nper=totN/&N;

if _N_ = Tile*Tile_Size then 
  do;
  SumResp=1;
  output;
   if Tile <&M. then  
       do;
         Tile=Tile+1;
		 SumResp=0;
	   end;
  end;	
 
if _N_=NN  then do;
SumResp=1;
/* output; */
end;

/*keep Tile Pper Nper;*/
run;


data temp;
	 Tile=0;
	 Pper=0;
	 NPer=0;
run;

Data &data1;
  set temp &data1;
  
  
  
  

 
run;

 

data &data1;
	set &data1;
	Tilepct=Tile/&M.;
	lagP= lag(totP);
	
	label Pper='Percent of Positives';
	label NPer ='Percent of Negatives';
	label Tile ='Percent of population';

	
	KS=  abs(NPer-PPer) ;
	
	
	if tile=1 and missing(lagP)  then  Prate= (totp ) / Tile_size ;
	else Prate= (totp-lagP) / Tile_size;
	
keep Tilepct &varx  Pper Nper Tile_size KS Prate  totp totn
;
format tilepct percent9.2   Pper percent9.4  Nper percent9.4    Prate percent9.2   ks  percent9.5;
run;

data &data1;
retain Tile_size &varx Pper Nper Tilepct   KS;
set &data1;

rename Pper=Bad Nper=Good;
run;


proc sql noprint;
 select max(KS) into :&Mks 
 from &data1;
run; quit;

proc sql ;
create table &data1. as
 select a.*,max(KS) as Max_KS format comma9.3
 from &data1 as a
 ;
quit;



proc sort data=  &data1  ;
by descending Tilepct;
run;

data   &data1 ;
set   &data1  ;
lagxvar=lag( &varx);

 &varx._range= cats("[", &varx,",",lagxvar,")");

drop lagxvar  &varx ;
run;

proc sort data=  &data1;
by  Tilepct;
run;







proc datasets library=work nodetails nolist;
 delete temp ;
run;
quit;

%mend;



%macro PlotKS(data1);


 symbol1 value=dot color=red   interpol=join  height=1;
 legend1 position=top;
 symbol2 value=dot color=blue  interpol=join  height=1;
 symbol3 value=dot color=green interpol=join  height=1;

proc gplot data=&data1;

  plot( Good Bad KS)*Tilepct / overlay legend=legend1;
 run;
quit;
 
	goptions reset=all;
%mend;