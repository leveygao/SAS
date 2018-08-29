

* global macro variables;
%let depv1=develop;
%let depv2=test;
%let depv3=validate;

%macro regsel(outf=t, head=y, foot=y, pin=0.5, pout=0.5, maxn=300);
* using PROC REG to pre-select significant variables;

* OUTF as output text file name;
* HEAD as if include LET statement;
* FOOT as if include ending statement;
* PIN as p-value for entry;
* POUT as p-value for stay;
* MAXN as maximum var numbers included;

* F as input file name;
* DEPVAR as dep var name;
* INDEP as indep var list;

* read in raw var list;
proc reg data=&plib..&fin.(where=(group=1)) outest=t noprint ;
   model &depvar.=&indep. /selection=forward slentry=&pin. slstay=&pout.;
   freq &weight.;

proc transpose data=t out=t;
   var &indep.;
data t;
   file "t.&plib.";
   set t(where=(abs(col1)>0)) end=last;
   if _n_=1 then put '%let var=%str(';
   put _name_;
   if last then put ');';
run;


* read in selected var list;
%include "t.&plib.";
proc reg data=&plib..&fin.(where=(group=1)) covout outest=t noprint ;
   model &depvar.=&var.;
   freq &weight.;
data _null_;
   array x(*) &var.;
   do i=1 to dim(x);
      t=left(trim(i));
      call symput("t",left(trim(i)));
   end;
run;
data t(keep=&var.);
   set t end=last;
   retain _z1-_z&t. 0;
   array x(*) &var.;
   array z(*) _z1-_z&t.;
   if _type_="PARMS" then do;
      do i=1 to &t.;
         if x(i) ne . then z(i)=x(i);
      end;
   end;
   if _n_>2 then do;
      if x(_n_-2) not in (0,.) then z(_n_-2)=(z(_n_-2)*z(_n_-2))/x(_n_-2); else
      z(_n_-2)=0;
   end;
   if last then do;
      do i=1 to &t.;
         x(i)=z(i);
      end;
      output;
   end;
proc transpose data=t out=&plib..t;
   var &var.;
proc sort data=&plib..t;
   by descending col1;
   /*where col1>0;*/   *ADD;
data &plib..t;
   file "&outf..&plib.";
   set &plib..t end=last;
   %if %eval(&head.=y) %then %do;
       if _n_=1 then put '%let var=%str(' @78 " ";
   %end;

   if _n_<=&maxn. then put _name_ @78 " ";

   %if %eval(&foot.=y) %then %do;
       if last then put ');' @78 " ";
   %end;
run;
%mend regsel;

%macro mdldata(seed, x=no, xx=no, xi=no, ifcut=no);
* create modeling data files;

* need F as modeling file name;

* depvar as dependent variables;
* seed as random seed;
* x as linear terms;
* xx as quadratic terms;
* xi as interaction terms;
* ifcut as using linear regression to cut down variables;

%if %eval(&seed.=0) %then %do;
   data _null_;
      file "&fin..txt.&plib.";
      put '%let var=%str(';
      %if %eval(&x.=yes) %then %do i=1 %to &vt.; put "xl&i."; %end;
      %if %eval(&xx.=yes) %then %do i=1 %to &vt.; put "xx&i."; %end;
      %if %eval(&xi.=yes) %then %do i=1 %to &vi.; put "xi&i."; %end;
      put ');';
   run;
%end;

data &plib..&fin.(keep=&id. &depvar. group develop test validate &weight. &extravar. x:)
     %if %eval(&seed.=0) %then %do; &plib..&fin.v(keep=&id. group &weight. &depvar. &var0. &extravar.) %end;
     ;
    %if %eval(&seed.=0) %then %do;
        set &plib..&fin.0(keep=&id. &weight. &depvar. &var0. &extravar.);
    %end; %else
    %do;
        set &plib..&fin.(keep=&id. &depvar. &weight. &extravar. x:);
    %end;

    * start standard sample code;
    length group develop test validate 3;
    group=0;
    develop=.;
    test=.;
    validate=.;
    _t_=ranuni(&seed.);
    drop _t_;

    %if %eval(&seed.=0) %then %do;
        if 0=<_t_<=(14/30)  then group=1; else
        if (14/30)<_t_<=(21/30) then group=2; else
        if (21/30)<_t_<=1.0 then group=3;
    %end; %else
    %if %eval(&seed. ne 0) %then %do;
        if 0=<_t_<=(2/3)  then group=1; else
        if (2/3)<_t_<=1.0 then group=2;
    %end;

    if group=1 then develop =&depvar.;
    if group in (1,2) then test =&depvar.;
    validate=&depvar.;

    label develop ="Develop Sample &depvar."
          test    ="Test Sample &depvar."
          validate="Validate Sample &depvar."
          group="dev/tst/val (4:3:3) sample";

    %if %eval(&seed.=0) %then %do;

        * variable creation;
        array raw(&vt.) &var0.;

        %if %eval(&x.=yes) %then %do;
            * linear terms;
            length xl1-xl&vt. 4;
            array _x(&vt.) xl1-xl&vt.;
            do i=1 to &vt.;
               _x(i)=raw(i);
               if _x(i)=. then _x(i)=0;
            end;
            label %do i=1 %to &vt.;
                     xl&i.="&&indv&i.."
                  %end; ;
        %end;

        %if %eval(&xx.=yes) %then %do;
            * quardratic terms;
            length xx1-xx&vt. 4;
            array _xx(&vt.) xx1-xx&vt.;
            do i=1 to &vt.;
               _xx(i)=raw(i)*raw(i);
               if _xx(i)=. then _xx(i)=0;
            end;
            label %do i=1 %to &vt.;
                     xx&i.="&&indv&i..*&&indv&i.."
                  %end; ;
        %end;

        %if %eval(&xi.=yes) %then %do;
            * interactive terms;
            length xi1-xi&vi. 4;
            array _xi(&vi.) xi1-xi&vi.;
            t=0;
            do i=1 to %eval(&vt.-1);
               do j=i+1 to &vt.;
                  t+1;
                  _xi(t)=raw(i)*raw(j);
                  if _xi(t)=. then _xi(t)=0;
               end;
            end;
            label %let t=0;
                  %do i=1 %to %eval(&vt.-1);
                     %do j=%eval(&i.+1) %to &vt.;
                        %let t=%eval(&t.+1);
                        xi&t.="&&indv&i..*&&indv&j.."
                     %end;
                  %end; ;
        %end;

        if group in (1,2) then output &plib..&fin.; else
        if group in (3) then output &plib..&fin.v;
        run;

        proc freq data=&plib..&fin.(keep=group &weight. &depvar.);
             table group %if %eval((&model. ne reg) and (&model. ne REG)) %then %do; &depvar. %end;;
        proc freq data=&plib..&fin.v(keep=group &weight. &depvar.);
             table group %if %eval((&model. ne reg) and (&model. ne REG)) %then %do; &depvar. %end;;
        %if %eval((&model. eq reg) or (&model. eq REG)) %then %do;
            proc means data=&plib..&fin.(keep=group &weight. &depvar.);
                 class group;
                 var &depvar.;
            proc means data=&plib..&fin.v(keep=group &weight. &depvar.);
                 class group;
                 var &depvar.;
        %end;
    %end;

run;

* eliminate binay quadratic terms;
%if %eval(&x.=yes and &xx.=yes and &xi.=no ) %then %do;
    proc means data=&plib..&fin. noprint;
       var xl1-xl&vt. xx1-xx&vt.;
       output out=t mean=xl1-xl&vt. xx1-xx&vt.;
    data _null_;
       set t end=last;

       if last then do;
          length xseq $ 4;
          array xl(&vt.) xl1-xl&vt.;
          array xx(&vt.) xx1-xx&vt.;
          array xn(&vt.) xn1-xn&vt.;
          t=0;
          do i=1 to &vt.;
             xn(i)=(abs(xl(i)-xx(i))>0.1);
             t=t+xn(i);
          end;
          call symput("reduce", t);
          file "&fin..txt.&plib.";
          put '%let var=%str(';
          do i=1 to &vt.;
             xseq=left(trim(put(i, 4.)));
             put 'xl' xseq ;
             if xn(i)=1 then put 'xx' xseq ;
          end;
          put ');';
       end;
    run;
    %if %eval(&reduce. > 0) %then %do;
        %include "&fin..txt.&plib.";
        data &plib..&fin.;
           set &plib..&fin.(keep=&id. &depvar. group develop test validate &weight. &extravar. &var.);
        run;
    %end;
%end;

%if %eval(&ifcut.=yes) %then %do;

    %let nvar=1000;
    %let nmax=100;

    * proc contents data=&plib..&fin. position;
    * proc means data=&plib..&fin.;

    data _null_;
       a=0+ceil(&vi./&nvar.);
       if a=1 then a=0;
       call symput("varstep", a);
    run;

    %if %eval(&varstep.=0 or &xi.=no) %then %do;
       %let indep=%str(x:);
       %regsel;
       data t;
          file "&fin..txt.&plib.";
          infile "t.&plib.";
          input t $ 1-78;
          t=left(trim(t));
          put @1 t;
       run;
    %end;  %else
    %do;
        %let indep=%str(xl:);
        %if %eval(&xx.=yes) %then %let indep=%str(xl: xx:);
        %regsel(outf=t.0, foot=n, maxn=%eval(&nmax.*2));
        %do i=1 %to &varstep.;
            %let st=%eval((&i.-1)*&nvar.+1);
            %let kt=%eval(&i.*&nvar.);
            %if %eval(&i.=&varstep.) %then %let kt=&vi.;
            data _null_;
               file "t.&plib.";
               put '%let var=%str(';
               %do j=&st. %to &kt.;
                   put "xi&j.";
               %end;
               put ');';
            run;
            %include "t.&plib.";
            %let indep=&var.;
            %if %eval(&i.<&varstep.) %then %do;
                %regsel(outf=t.&i., head=n, foot=n, maxn=%eval(&nmax.*1));
            %end; %else
            %if %eval(&i.=&varstep.) %then %do;
                %regsel(outf=t.&i., head=n, maxn=%eval(&nmax.*1));
            %end;
        %end;
        %do i=0 %to &varstep.;
             data t&i.;
                  infile "t.&i..&plib.";
                  input t $ 1-78;
             run;
        %end;
        data t;
             file "t.&plib.";
             set %do i=0 %to &varstep.; t&i. %end;;
             t=left(trim(t));
             put @1 t;
        run;
        %include "t.&plib.";
        %let indep=&var.;
        %regsel(outf=&fin..txt, maxn=%eval(&nmax.*5));
        run;
    %end;

%end;

%mend mdldata;

%macro modelfit(fout, ngroup, mdlstep, vsample=2);

* f  is input data file name;
* fout is output data file name;
* ngroup is # of groups to run model and 1=develop 2=test 3=validate;
* mdlstep is the model indep var set to be used in the current step 1=forwarc 2=backward >2=stepwise 99=rsquuare;
* slin and slout are significant level parameter;

%do group=1 %to &ngroup.;
    proc &model. data=&plib..&fin.
                  (keep=&id. group &depvar. &depv1. &depv2. &depv3. &weight. &&var&mdlstep. &extravar.
                        where=(group<=&vsample.) ) outest=p&fout.
                        %if %eval(&mdlstep.<=10) %then %do; noprint %end;
                  %if %eval(&model.=logistic) %then %do; descending %end; ;
        title "&model. model: file=&fin. var=&mdlstep. group=&group.";
        model &&depv&group. = &&var&mdlstep.
              %if %eval(&mdlstep.=1) %then %do;
                  / selection=forward  stop=20 slentry=&slin. slstay=&slout.
              %end; %else
              %if %eval(&mdlstep.=2) %then %do;
                  / selection=backward stop=20 slentry=&slin. slstay=&slout.
              %end; %else
              %if %eval(&mdlstep.=99) %then %do;
                  / selection=rsquare stop=30
              %end; %else
              %if %eval(&mdlstep.>2) %then %do;
                  / selection=stepwise stop=20 slentry=&slin. slstay=&slout.
              %end;
;
        output out=dd&fout. p=&prob.;
        weight &weight.;
        &ifstment.;
    run;

    proc transpose data=p&fout. out=p&fout.;
       var &&var&mdlstep.;
    proc sort data=p&fout. nodupkey;
       by _name_;
       %if %eval(&model.=reg or &model.=REG) %then %do;
           where col1>.;
       %end; %else
       %if %eval(&model.=logistic) %then %do;
           where &&depv&group.>.;
       %end;
    * proc print data=p&fout. ;
    run;

    %let indata=d&fout.;
    %let indvar=&&var&mdlstep.;
    %let title1=%str(lib=&plib. file=&fin. dep=&depvar.);

    %do valid=1 %to 2;
        %let title1=%str(lib=&plib. file=&fin. dep=&depvar.);
        %let title2=%str(&ifstment. if group=&valid.);
        %let mdldcl=no;
        data &indata.;
             set dd&fout.;
             if group=&valid.;  * 1=develop 2=test 3=validate;
        run;
        %modeleva(n, n);
    %end;

%end;

run;

%mend modelfit;

%macro modeleva(iftable, ifplot, ifbttm=y);
* need macro indata title1 title2 ifstment depvar indvar mdldcl segcnt and weight;
* data file RESULT has depvar indvar weight prob extravar and possibly mdldcl;
* ifbttm=y if keep all obs as decile cuts;
* ifbttm=n if no bottom obs included in decile cuts;

* The core part of the calculation;

proc sort data=&indata. out=result;
   by descending &prob.;
   &ifstment.;
run;

* weighted observation ;
data _null_;
   set result(keep=&weight.) end=last;
   retain accuwgt 0;
   accuwgt=accuwgt+&weight;  * total > missing records;
   if last then call symput("sumcnt", left(accuwgt));
run;

%let bttm=.;
%let dclcnt=&segcnt.;
%do %while(%eval(&mdldcl=no));
    %let mdldcl=segnum;

    * weighted observation ;
    data _null_;
       set result(keep=&weight. &prob.) end=last;
       retain accuwgt 0 ;
       if &prob.>&bttm. then accuwgt=accuwgt+&weight;  * total > missing records;
       if last then call symput("sumcnt", left(accuwgt));
    run;

    data result;
       set result;
       length &mdldcl. 3;
       retain accuwgt 0;
       if &prob.>&bttm. then do;
          accuwgt=accuwgt+&weight;  * total > missing records;
          * &mdldcl. =int(&dclcnt.*accuwgt/&sumcnt.+0.001);
          &mdldcl. =floor(&dclcnt.*accuwgt/&sumcnt.)+1;
          if &mdldcl.>&dclcnt. then &mdldcl.=&dclcnt.;
       end;
       else if &prob.<=&bttm. then &mdldcl.=&dclcnt.+1;
       drop accuwgt ;
    run;

    %if %eval((&ifbttm. ne y) and (&dclcnt. eq &segcnt.)) %then %do;
       %let dclcnt=%eval(&dclcnt.-1);
       %let mdldcl=no;
       proc means data=result noprint;
          class segnum;
          var &prob.;
          output out=t mean=segval min=segmin max=segmax std=segstd;
       proc sort data=t;
          by descending segnum;
       run;
       data _null_ ;
          set t;
          bottom=ceil(segmax*1000000)/1000000;
          if (segval ne .) and
             (floor(segmin*1000000+0.5)/1000000 = floor(segmax*1000000+0.5)/1000000
              or segstd=0) then call symput("bttm",left(bottom));
       run;

    %end;
%end;


%if %eval(&model.=logistic) %then %do;

    proc summary data=result n mean min max noprint;
       by &mdldcl.;
       var &prob.;
       weight &weight;
       output out=probmean(keep=&mdldcl. p_mean ) mean=p_mean ;
    run;

    proc sort data=probmean(keep=&mdldcl. p_mean );
       by &mdldcl.;
    run;
    proc sort data=result;
       by &depvar;
    run;

    proc freq data=result noprint;
       title"data freq for nrsp and rsp weighted in &segcnt segments";
       tables &mdldcl. / out= datafreq;
       by &depvar;
       weight &weight;
    run;

    data nrsp rsp;
       set datafreq;
       if &depvar = 1 then output rsp;
       else if &depvar = 0 then output nrsp;
    run;
     /********* generate a macro var to record total rsp  *****/

    data _null_;
       set rsp end=last;
       retain accursp 0;
       accursp=accursp+count;
       if last then call symput('TOTrsp', left(accursp));
    run;

     /******** merge nrsp and rsp together to calculate ******/
     /******** hit rate, lorentz curve and gains index  ******/
     /********    and other indexs                      ******/

    proc sort data=nrsp;
       by &mdldcl.;
    run;
    proc sort data=rsp;
       by &mdldcl.;
    run;
    data nrsprsp;
       merge nrsp(rename=(count=nrspcnt percent=nrsppct))
             rsp (rename=(count=rspcnt  percent=rsppct ))
             probmean;
       by &mdldcl.;
       drop &depvar;

    data nrsprsp;
       set nrsprsp;
       retain lorentz cumnpct accursp accunrsp 0;
       array miss nrspcnt nrsppct rspcnt rsppct;
       do over miss;
          if miss = . then miss=0;
       end;

       /*** lorentz curve   ***/
       lorentz=lorentz+rsppct;
       cumnpct=cumnpct+nrsppct;

       /*** ks calculation  ***/
       ks = abs(lorentz-cumnpct);

       /*** gains index     ***/
       accunrsp= accunrsp+nrspcnt;
       accursp = accursp+rspcnt;
       accutot = accunrsp + accursp;
       gainidx = ((accursp/accutot) / (&TOTrsp/&SUMCNT))*100;
       totcnt =  nrspcnt + rspcnt;
       rsprate = rspcnt / totcnt*100;
       cumrrate= (accursp/accutot)*100;

       /*** hit rate        ***/
       hr = accunrsp / accursp;

     label &mdldcl. = 'SEGMENT NUMBER'
           nrspcnt= '# of nrsp'
           nrsppct= 'PERCENT OF nrsp'
           rspcnt = '# of rsp'
           rsppct = 'PERCENT OF rsp'
           accursp= 'CUMULATIVE rsp'
           accunrsp='CUMULATIVE nrsp'
           lorentz= 'LORENTZ CURVE'
           cumnpct= 'CUMULATIVE % nrsp'
           accutot= 'CUMULATIVE TOTAL'
           gainidx= 'GAINS INDEX '
           hr     = 'HIT RATE'
           cumrrate='cumulative rsp rate'
     ;
     * if &mdldcl.>20 then delete;
    run;

    proc print data=nrsprsp;
       title  "&title1.: &title2.";
       title2 "Hit Rate, Lorentz Curve, and Gains Index for equal counts"
              " weighted segment for predicted prob in &indata.";

    *footnote1"The Hit Rate is Defined as Odds Ratio";
    *footnote2"The Weight is &WEIGHT  ";

     label &mdldcl. = 'SEGMENT NUMBER'
           nrspcnt= '# of nrsp'
           nrsppct= 'PERCENT OF nrsp'
           rspcnt = '# of rsp'
           rsppct = 'PERCENT OF rsp'
           accursp= 'CUMULATIVE rsp'
           accunrsp='CUMULATIVE nrsp'
           lorentz= 'LORENTZ CURVE'
           cumnpct= 'CUMULATIVE % nrsp'
           accutot= 'CUMULATIVE TOTAL'
           gainidx= 'GAINS INDEX '
           hr     = 'HIT RATE'
           cumrrate='cumulative rsp rate'
     ;
    run;
    *footnote1;
    *footnote2;
    run;

    %if %eval(&iftable.=y) %then %do;
    * print variable distributions by deciles;

    proc tabulate data=result noseps;
       title "Unweighted decile distribution";
       class &mdldcl. &depvar.;
       table &depvar. all, (&mdldcl. all)*n*f=10.0 / condense rts=25;
    run;

    proc tabulate data=result noseps;
       title  "&title1.: &title2.";
       title2 "Variable distribution by deciles";
       class &mdldcl.;
       var &depvar. &prob. &indvar. ;
       table (&depvar. &prob.)*(mean std min max), (&mdldcl. all)*f=10.8/condense rts=25;
       table (&indvar. )*(mean std min max), (&mdldcl. all)*f=10.5/condense rts=25;
       weight &weight.;
    run;

    %end;

    %if %eval(&ifplot.=y) %then %do;
    * plot;

      goptions reset=global gunit=pct cback=white htitle=6 htext=3 ftext=swissb
               colors=(black) rotate=landscape ; * gaccess=gsasfile gsfmode=append;
    * goptions device=win      TARGET=hpdj560c ;
      goptions device=hpdj560c TARGET=hpdj560c ;

    axis1 minor=none label=("Score Decile") order=(0 to 10 by 1);
    axis2 minor=none label=(a=90 "Lorentz") order=(0 to 100 by 10);
    axis3 minor=none label=("Hit Rate") order=(100 to 300 by 50);
    axis4 minor=none label=(a=90 "Gain Index") order=(100 to 250 by 50);
    axis5 minor=none label=(a=90 "Cumu Resp Rate") order=(0 to 1 by 0.1);
    axis6 minor=none label=("Resp Rate") order=(0 to 1 by 0.1);
    axis7 minor=none label=(a=90 "Predict Resp Rate") order=(0 to 0.01 by 0.001);

    symbol1 interpol=join;

    proc gplot data=nrsprsp;
    plot lorentz*&mdldcl./ frame vaxis=axis2 haxis=axis1 ;
      title  "&title1.: &title2.";
      title2 "Lorentz Curve by Segment for predicted prob in &indata.";
    run;
    proc gplot data=nrsprsp;
     plot lorentz*hr / frame vaxis=axis2 haxis=axis3 ;
      title  "&title1.: &title2.";
      title2 " Lorentz Curve by Hit Rate for predicted prob in &indata.";
    run;
    proc gplot data=nrsprsp;
    plot gainidx*&mdldcl. / frame vaxis=axis4 haxis=axis1 ;
      title  "&title1.: &title2.";
      title2 "Gains Index by Segment for predicted prob in &indata.";
    run;
    title;
    run;
    proc gplot data=nrsprsp;
    plot cumrrate*&mdldcl. / frame vaxis=axis5 haxis=axis1 ;
      title  "&title1.: &title2.";
      title2 "Cumulative RESP Rate by Segment for predicted prob in &indata.";
    run;
    title;
    run;
    proc gplot data=nrsprsp;
    plot p_mean*rsprate / frame vaxis=axis7 haxis=axis6 ;
      title  "&title1.: &title2.";
      title2 "P_HAT vs Actural RESP Rate for predicted prob in &indata.";
    run;
    title;
    run;

    %end;

%end; %else
%if %eval(&model.=reg or &model.=REG) %then %do;

    proc summary data=result noprint;
       by &mdldcl.;
       var &depvar.;
       freq &weight;
       output out=probmean(keep=&mdldcl. p_sum nseg) sum=p_sum n=nseg;
    run;

    proc sort data=probmean;
       by &mdldcl.;
    run;

    data _null_;
       set probmean end=last;
       by &mdldcl.;
       retain popln totdep 0;
       if _n_=1 then do;
          popln=0;
          totdep=0;
       end;

       popln+nseg;
       totdep+p_sum;

       if last then do;
          call symput("popln", popln);
          call symput("totdep", totdep);
       end;
    run;

    data nrsprsp;
       set probmean(keep=&mdldcl. p_sum nseg) ;    * segment code  sum and size;
       by &mdldcl.;
       retain popln totdep 0;
       if _n_=1 then do;
          popln=0;
          totdep=0;
       end;

       popln+nseg;                                 * running total of size ;
       totdep+p_sum;                               * running total of sum;

       p_sumpct=p_sum/&totdep.*100;                * sum percent;
       cp_sumpct=totdep/&totdep.*100;              * cumu sum percent;

       avgdep=p_sum/nseg;                          * average;
       cavgdep=totdep/popln;                       * cumu average;

       gain=avgdep/(&totdep./&popln.)*100;         * gain;
       cgain=cavgdep/(&totdep./&popln.)*100;       * cumu gain;
    run;

    proc print data=nrsprsp;
       title  "&title1.: &title2.";
       title2 "Gains Index and other measures"
              " weighted segment for predicted prob in &indata.";
       var &mdldcl. nseg popln p_sum p_sumpct totdep cp_sumpct avgdep cavgdep gain cgain ;

     label &mdldcl. = 'SEGMENT NUMBER'
           nseg     = 'Segment size'
           p_sum    = '&depvar. sum'
           popln    = 'Cumu size'
           totdep   = 'Cumu &depvar. sum'
           p_sumpct = 'Sum percent'
           cp_sumpct= 'Cumu Sum percent'
           avgdep   = 'average &depvar.'
           cavgdep  = 'cumu &depvar. average'
           gain     = 'gain index'
           cgain    = 'cumu gain index' ;
    run;

%end;

run;

%mend modeleva;

%macro chklift(f, mdldcl);
* need macro variable mdldcl ne no;

%let indata=&plib..dd;
%let indvar=&id.;
%let title1=%str(lib=&plib. file=&fin. dep=&depvar.);
%let title2=%str(&ifstment. with &prob.);

data &indata.;
     set &f.(keep=&id. &depvar. &weight. &indvar. &extravar. &mdldcl.);
     if &mdldcl.=. then &mdldcl.=-1;
     &prob.=99999-&mdldcl.;
run;
%modeleva(n, n);
run;

%mend chklift;

%macro raw(ifreadraw=yes, ifxx=yes, ifxi=no, ifsubset=yes);
* create raw data files with x: vars;

* create macro variables for VAR;
%let a=%left(%trim(&var0.));
%let s=0;
%let l=%length(&a.);
%let sp=%str( );
%do %until(%eval(&l.=0));

    %let t=%index(&a.,&sp.);
    %if %eval(&t.>0) %then %do;
        %let s=%left(%trim(%eval(&s.+1)));
        %let indv&s.=%substr(&a.,1,%eval(&t.-1));
        %let a=%substr(&a.,%eval(&t.+1),%eval(&l.-&t.));
    %end; %else %do;
        %let s=%left(%trim(%eval(&s.+1)));
        %let indv&s.=%substr(&a.,1, &l.);
        %let a=;
    %end;
    %let l=%length(&a.);
%end;
%let vt=%left(%trim(&s.));
%let vi=%left(%trim(%eval(&s.*(&s.-1)/2)));

run;

%if %eval(&ifreadraw.=yes) %then %rawdata;                   * raw data load;
%mdldata(0, x=yes, xx=&ifxx., xi=&ifxi., ifcut=&ifsubset.);  * create x: var;
run;

%mend raw;

%macro model(tloop, varstep=1, slin=0.5, slout=0.5);
* fit model for TLOOP times;

%do loop=1 %to &tloop.;
    %mdldata(&loop.);
    %modelfit(t&loop., 1, &varstep.);
%end;

data t;
    merge %do loop=1 %to &tloop.;
              pt&loop.(in=t&loop. rename=(%if %eval(&model.=reg or &model.=REG) %then %do;
                          col1
                       %end; %else %do; develop %end;
                       =ift&loop.)) %end;;
    by _name_;

    t=0;
    %do loop=1 %to &tloop.;
        ift&loop.=(ift&loop.>.);
        if ift&loop. then t=t+1;
    %end;
run;

proc sort data=t;
   by descending t;
proc print data=t;
run;

%mend model;

%macro fnlresp(mdlstep, vsample=2, ifkeepbm=y);
* final response model;
* vsample develop=1 test=2 validate=3;
* ifkeepbm=y keep all obs;
* ifkeepbm=n remove bottom missing data in deccut;

%let indata=%str(&plib..&fin.r);
%let title1=%str(Final Model: lib=&plib. file=&fin. dep=&depvar.);
%let title2=%str(Develop vs Test);
%let indvar=%str(&&var&mdlstep.);
%let mdldcl=no;


data ffnl(keep=&id. &depvar. develop test validate group &weight. &indvar. &extravar.);
    set &plib..&fin. %if %eval(&vsample.=3) %then %do; &plib..&fin.v %end;;

    length develop test validate 4;
    develop=.;
    test=.;
    validate=.;
    if group=1 then develop=&depvar.; else
    if group=2 then test=&depvar.; else
    if group=3 then validate=&depvar.;
run;

%let group=%eval(&vsample.-1); * develop as default;

proc &model. data=ffnl(keep=&id. &depvar. &&depv&group. group &weight. &indvar. &extravar.
                                    where=(group<=&vsample.) ) outest=&plib..&fin.p
             %if %eval(&model.=logistic) %then %do; descending %end; ;
    title "&title1.";
    TITLE2 "&title2.: model &&depv&group.";
    model &&depv&group. = &&var&mdlstep.;
    output out=&indata. p=&prob.;
    weight &weight.;
    &ifstment.;
run;

* develop and test and validate;
%let ff=%str(&plib..&fin.r);
%let indata=dd;
%do valid=1 %to &vsample.;
    %let title1=%str(lib=&plib. file=&fin. dep=&depvar.);
    %let title2=%str(&ifstment. if group=&valid.);
    %let mdldcl=no;
    data &indata.;
         set &ff.(keep=&id. &depvar. &&depv&group. group &prob. &weight. &indvar. &extravar.);
         if group=&valid.;  * 1=develop 2=test 3=validate;
    run;
    %modeleva(n, n, ifbttm=&ifkeepbm.);
%end;

* combined;
%let indata=%str(&plib..&fin.r);
%let title1=%str(Final Model:lib=&plib. file=&fin. dep=&depvar.);
%let title2=%str(combined sample);
%let indvar=%str(&&var&mdlstep..);
%let mdldcl=no;

proc &model. data=ffnl (keep=&id. &depvar. group &weight. &indvar. &extravar.
                                   where=(group<=&vsample.) ) outest=&plib..&fin.p
             %if %eval(&model.=logistic) %then %do; descending %end; ;
    title "&title1.";
    TITLE2 "&title2.: model &depvar.";
    model &depvar. = &&var&mdlstep.;
    output out=&indata. p=&prob.;
    weight &weight.;
    &ifstment.;
run;

data result;
   set &indata. (keep=&id. group &depvar. &prob. &weight. &indvar. &extravar. );
run;

%modeleva(y, n, ifbttm=&ifkeepbm.);
%mdlscr(&plib..&fin.p, &depvar.scr, &depvar.dcl);

proc sort data=&indata.(keep=&id. group &depvar. &prob. &weight. rename=(&prob.=&depvar.scr)) nodupkey;
   by &id.;
proc sort data=result(keep=&id. segnum rename=(segnum=&depvar.dcl)) out=t nodupkey;
   by &id.;
data &plib..&fin.r(keep=&id. group &depvar. &depvar.scr &depvar.dcl &weight.);
   merge &indata. t;
   by &id.;
run;

%mend fnlresp;

%macro mdlscr(outest, score, decile);
* print model variables and scores;
* need macro variable smp to select population;

proc transpose data=&outest. out=t;
run;

data t;
  set t;

  %if %eval(&model.=logistic) %then %do;
      if estimate=. then estimate=&depvar.;
      if estimate=. then estimate=develop;
      if estimate=. then estimate=test;
  %end; %else
  %if %eval(&model.=reg or &model.=REG) %then %do;
      if estimate=. then estimate=col1;
  %end;
  if estimate>. ;
run;

* raw var list;
data rawvar(keep=varlist);
   set t(rename=(_label_=varlist));
   if _name_ not in ("_LNLIKE_", "INTERCEP", "Intercept", "_RMSE_", "&depvar." );

   length hold $ 62;
   varlist=left(trim(varlist));
   t=index(varlist,"*");
   if t>0 then do;
      hold=left(trim(varlist));
      l=length(hold);
      varlist=substr(hold,1,t-1); output;
      varlist=substr(hold,t+1,l-t); output;
   end; else
   if t=0 then output;
proc sort data=rawvar out=rawvar nodupkey;
   by varlist;
data _null_;
   file "t0&outest..&plib.";
   set rawvar end=last;
   if _n_=1 then put @5 '%let varscr=%str(' @79 ".";
   put @10 varlist @79 "." ;
   if last then put ");" @79 "." / @79 ".";

* assignment statement;
data _null_;
   file "t1&outest..&plib.";
   set t end=last;
   if _n_=1 then put @5 '%let scrcode=%str(' @79 ".";
   if _name_ not in ("_LNLIKE_", "INTERCEP", "Intercept", "_RMSE_", "&depvar." ) then do;
      put @5 _name_ $ 8. " = " _label_ $ 65. @77 ";" @79 ".";
   end;
   if last then put @79 "." / @79 ".";

* Label statement;
data _null_;
   file "t2&outest..&plib.";
   set t end=last;
   if _n_=1 then put @5 "label" @79 ".";
   if _name_ not in ("_LNLIKE_", "INTERCEP", "Intercept", "_RMSE_", "&depvar.") then do;
      put @5 _name_ $ 8. " = '" _label_ $ 65. @77 "'" @79 ".";
   end;
   if last then put @5 ";" @79 "." / @79 ".";

* Scoring statement;
data _null_;
   file "t3&outest..&plib.";
   set t end=last;
   if _name_ not in ("_LNLIKE_", "_RMSE_", "&depvar.") then do;
      if _name_ in ("INTERCEP", "Intercept") then do;
         put @5 "length xbeta &score. 8 &decile. 3 ;" @79 ".";
         put @5 "xbeta = " +3 "(" estimate 25.20 ") " @@;
      end; else
      do;
         put "+" @79 ".";
         put @5 _name_ $ 8. " * (" estimate 25.20 ") " @@;
      end;
   end;
   if last then do;
      put @79 "."/ @5 ";" @79 ".";
      %if %eval(&model.=logistic) %then %do;
          put @5 "&score.=exp(xbeta)/(1+exp(xbeta));" @79 "." / @79 ".";
      %end;  %else;
      %if %eval(&model.=reg or &model.=REG) %then %do;
          put @5 "&score.=xbeta;" @79 "." / @79 ".";
      %end;
      put @5 "&prob. =&score.;" @79 "." / @79 ".";
   end;

/***
data _null_;
   file "t3&outest..&plib.";
   set t end=last;
   if _name_ not in ("_LNLIKE_", "_RMSE_", "&depvar.") then do;
      if _name_ in ("INTERCEP", "Intercept") then do;
         put @5 "length xbeta &score. 8 &decile. 3 ;" @79 ".";
         put @5 "xbeta = " +3 "(" estimate 25.20 ") +" @79 ".";
      end; else
      do;
         if last then put @5 _name_ $ 8. " * (" estimate 25.20 ") " @79 "."; else
         put @5 _name_ $ 8. " * (" estimate 25.20 ") +" @79 ".";
      end;
   end;
   if last then do;
      put @5 ";" @79 ".";
      %if %eval(&model.=logistic) %then %do;
          put @5 "&score.=exp(xbeta)/(1+exp(xbeta));" @79 "." / @79 ".";
      %end;  %else;
      %if %eval(&model.=reg or &model.=REG) %then %do;
          put @5 "&score.=xbeta;" @79 "." / @79 ".";
      %end;
      put @5 "&prob. =&score.;" @79 "." / @79 ".";
   end;
***/

* Decile statement;
%if %eval(&mdldcl.=no) %then %let mdldcl=segnum;
proc means data=result(keep=&mdldcl. &prob.) noprint;
   class &mdldcl.;
   var &prob.;
   output out=t max=&prob.;
proc sort data=t(where=(&mdldcl.>.)) nodupkey;
   by &mdldcl.;
data t;
   set t;
   by &mdldcl.;
   &prob.=ceil(&prob.*10000000)/10000000;
data _null_;
   file "t4&outest..&plib.";
   set t end=last;
   by &mdldcl.;
   lastmax=lag(&prob.);
   %if %eval(&model.=logistic) %then %do;
       if _n_=2 then do;
           t=_n_-1;
           put "if " &prob. 16.14 "<&score.<=1.00000000000000 then &decile.=" t 2. "; else" @79 ".";
       end; else
       if _n_>2 then do;
           t=_n_-1;
           put "if " &prob. 16.14 "<&score.<=" lastmax 16.14 " then &decile.=" t 2. "; else" @79 ".";
       end;
       if last then do;
           t=_n_;
           put "if                  &score.<=" &prob. 16.14 " then &decile.=" t 2. ";" @79 ".";
           put @79 "." / @79 ".";
       end;
   %end;  %else;
   %if %eval(&model.=reg or &model.=REG) %then %do;
       if _n_=2 then do;
           t=_n_-1;
           put "if " &prob. 16.14 "<&score.                   then &decile.=" t 2. "; else" @79 ".";
       end; else
       if _n_>2 then do;
           t=_n_-1;
           put "if " &prob. 16.14 "<&score.<=" lastmax 16.14 " then &decile.=" t 2. "; else" @79 ".";
       end;
       if last then do;
           t=_n_;
           put "if                   &score.<=" &prob. 16.14 " then &decile.=" t 2. ";" @79 ".";
           put @79 "." / @79 ".";
       end;
   %end;
   if last then put ");" @79 "." / @79 ".";
run;

%do i=0 %to 4;
    data t&i.;
      infile "t&i.&outest..&plib.";
      input t $ 1-78;
    run;
%end;
data t;
   file "&fin..scr.&plib.";
   set t0 t1 t2 t3 t4;
   put @1 t;
run;
proc print data=t noobs;
run;

%mend mdlscr;

%macro fnlscr(ifrecut=n, ifkeepbm=y, valid=y);
* create final scored file;

* scoring code from MDLSCR;
* load from "&fin..scr.&plib.";
%include "&fin..scr.&plib.";

%let indata=&plib..&fin.scr;
%let indvar=&varscr.;
%let mdldcl=&depvar.dcl;
%let title1=%str(lib=&plib. valid=&valid. dep=&depvar.);
%let title2=%str(&ifstment. with &prob.);

run;

data &indata. (keep=&id. &weight. &prob. &depvar. &depvar.scr &depvar.dcl &extravar.);
    %if %eval(&valid.=y) %then %do;
       * score the validation sample where group=3;
       set &plib..&fin.v(keep=&var0. &depvar. &id. &weight. &extravar.);
    %end;
    %else %do;
       * the entire sample;
       set &plib..&fin.0(keep=&var0. &depvar. &id. &weight. &extravar.);
    %end;

    * processing;

    * scoring code;
    &scrcode.;

    length &depvar.dcl 3;
    label &depvar.dcl="&depvar. Score decile";

run;

proc sort data=&indata.(keep=&id. &depvar. &weight. &prob. &depvar.scr &depvar.dcl &extravar.) out=&indata. nodupkey;
   by &id.;
run;


%if %eval(&ifrecut.=y) %then %do;
    %let mdldcl=no;
    %deccut(&indata, t.t, ifbttm=&ifkeepbm.);
%end;

%modeleva(n, n, ifbttm=&ifkeepbm.);
run;

/***
data &plib..&fin.;
   update &plib..&fin. t;
   by &id.;
***/
run;

%mend fnlscr;

%macro deccut(f, outtext, ifbttm=);
* create decile cut algorithm;
* need macro var ID PROB WEIGHT DEPVAR IFSTMENT;

%let score=&depvar.scr;
%let decile=&depvar.dcl;

proc sort data=&f. out=result(keep=&id. &prob. &weight.);
   by descending &prob.;
   &ifstment.;
run;

* weighted observation ;
data _null_;
   set result(keep=&weight.) end=last;
   retain accuwgt 0;
   accuwgt=accuwgt+&weight;  * total > missing records;
   if last then call symput("sumcnt", left(accuwgt));
run;

%let bttm=.;
%let dclcnt=&segcnt.;
%do %while(%eval(&mdldcl=no));
    %let mdldcl=segnum;

    * weighted observation ;
    data _null_;
       set result(keep=&weight. &prob.) end=last;
       retain accuwgt 0;
       if &prob.>&bttm. then accuwgt=accuwgt+&weight;  * total > missing records;
       if last then call symput("sumcnt", left(accuwgt));
    run;

    data result;
       set result;
       length &mdldcl. 3;
       retain accuwgt 0;
       if &prob.>&bttm. then do;
          accuwgt=accuwgt+&weight;  * total > missing records;
          * &mdldcl. =int(&dclcnt.*accuwgt/&sumcnt.+0.001);
          &mdldcl. =floor(&dclcnt.*accuwgt/&sumcnt.)+1;
          if &mdldcl.>&dclcnt. then &mdldcl.=&dclcnt.;
       end;
       else if &prob.<=&bttm. then &mdldcl.=&dclcnt.+1;
       drop accuwgt ;
    run;

    %if %eval((&ifbttm. ne y) and (&dclcnt. eq &segcnt.)) %then %do;
       %let dclcnt=%eval(&dclcnt.-1);
       %let mdldcl=no;
       proc means data=result noprint;
          class segnum;
          var &prob.;
          output out=t mean=segval min=segmin max=segmax;
       proc sort data=t;
          by descending segnum;
       data _null_;
          set t;
          if (segval ne .) and (segmin=segmax) then call symput("bttm",left(segmax));
       run;
    %end;
%end;

proc means data=result(keep=&mdldcl. &prob.) noprint;
   class &mdldcl.;
   var &prob.;
   output out=t max=&prob.;
proc sort data=t(where=(&mdldcl.>.)) nodupkey;
   by &mdldcl.;
data _null_;
   file "&outtext..&plib.";
   set t end=last;
   by &mdldcl.;
   lastmax=lag(&prob.);
       if _n_=2 then do;
           t=_n_-1;
           put "if " &prob. 18.16 "<&score.                     then &decile.=" t 2. "; else" @79 ".";
       end; else
       if _n_>2 then do;
           t=_n_-1;
           put "if " &prob. 18.16 "<&score.<=" lastmax 18.16 " then &decile.=" t 2. "; else" @79 ".";
       end;
       if last then do;
           t=_n_;
           put "if                   < &score.<=" &prob. 18.16 " then &decile.=" t 2. ";" @79 ".";
           put @79 "." / @79 ".";
       end;
run;

* end of new decile cuts;

%mend deccut;

%macro charcode(fin, fout, pctsub=1, pctkeep=5, fwt=);
* create SAS code to convert character variables;

* pctsub is 0-1 percent to be used in categorical calculation;
* pctkeep is xx% percent of threshold to dichotoumise;
* fwt is weight statement;

* maximum category allowed;
%let maxcat=50;

proc contents data=&fin. noprint out=t(keep=varnum name type);
proc sort data=t(where=(type=1)) out=tn;
   by varnum;
proc sort data=t(where=(type=2)) out=tc;
   by varnum;
data _null_;
   set tc(where=( left(trim(upcase(name))) not in ("RESP") ) ) end=last;
   retain t 0;
   t+1;
   if last then call symput("ct", left(trim(t)));   * total # of char variables;
run;

data _null_;
   set tc;
   %do j=1 %to &ct.;
       if _n_=&j. then call symput("indv&j.", left(trim(name))); else
   %end; ;
run;

* use a sample for all code generating process;
data _raw;
   set &fin.(keep=%do i=1 %to &ct.; &&indv&i.. %end; &fwt.);
   if ranuni(1)<=&pctsub.;
run;

%do i=1 %to &ct.;

    proc freq data=_raw noprint;
       table &&indv&i../out=t missing;
       %if %eval(&fwt. ne ) %then %do; weight &fwt.; %end; * weight statement;
    data _null_;
       set t end=last;
       if last then call symput("ct&i", left(trim(_n_))); * total # of categories for ith char var;
    run;
    %if %eval(&&ct&i.<=&maxcat.) %then %do;
        data _null_;
           set t end=last;
           &&indv&i..=left(trim(&&indv&i..));
           %do j=1 %to &&ct&i.;
               if _n_=&j. then do;
                  call symput("vl&i._&j.", &&indv&i..);
                  call symput("pt&i._&j.", percent);
               end; else
           %end; ;
        run;
    %end;

%end;

* length statement;
data _null_;
   file "t.1.&plib.";
   put "length " @79 ".";
   %do i=1 %to &ct.;
       %if %eval(&&ct&i.>1 and &&ct&i.<=&maxcat.) %then %do j=2 %to &&ct&i..;
           %if %eval(("&&vl&i._&j" eq "Y") or ("&&vl&i._&j" eq "y") or
                     (&&pt&i._&j>=&pctkeep.) or (&&ct&i.=2)) %then %do;
               put "vl&i._&j " @79 ".";
           %end;
       %end;
   %end;
   put "3 ;" @79 "." / @79 "." / @79 "." ;
run;

* assignment statement;
data _null_;
   file "t.2.&plib.";
   %do i=1 %to &ct.;
       %if %eval(&&ct&i.>1 and &&ct&i.<=&maxcat.) %then %do j=2 %to &&ct&i..;
           %if %eval(("&&vl&i._&j" eq "Y") or ("&&vl&i._&j" eq "y") or
                     (&&pt&i._&j>=&pctkeep.) or (&&ct&i.=2)) %then %do;
               put "vl&i._&j=(left(trim(&&indv&i..))=" 'left(trim("' "&&vl&i._&j" '"' ")));" @79 ".";
           %end;
       %end;
   %end;
   put @79 "." / @79 "." / @79 "." ;
run;

* label statement;
data _null_;
   file "t.3.&plib.";
   put "label" @79 ".";
   %do i=1 %to &ct.;
       %if %eval(&&ct&i.>1 and &&ct&i.<=&maxcat.) %then %do j=2 %to &&ct&i..;
           %if %eval(("&&vl&i._&j" eq "Y") or ("&&vl&i._&j" eq "y") or
                     (&&pt&i._&j>=&pctkeep.) or (&&ct&i.=2)) %then %do;
               put "vl&i._&j=" '"' "if &&indv&i..=&&vl&i._&j(yes=1)" '"' @79 ".";
           %end;
       %end;
   %end;
   put ";" @79 "." / @79 "." / ');' @79 "." ;
run;

* numerical variables;
data _null_;
   file "t.4.&plib.";
   set tn end=last;
   if _n_=1 then put '%let dummy=%str(' @79 "." / "/*** numeric variables " @79 ".";
   put name @79 ".";
   if last then put "***/" @79 "." / @79 "." / @79 "." ;
run;

* character variables;
data _null_;
   file "t.5.&plib.";
   set tc end=last;
   if _n_=1 then put "/*** character variables " @79 ".";
   put name @79 ".";
   if last then put "***/" @79 "." / @79 "." / @79 "." ;
run;

%do i=1 %to 5;
data t&i.;
   infile "t.&i..&plib.";
   input t $ 1-78;
%end;

data t;
   file "&fout..&plib.";
   set t4 t5 t1 t2 t3;
   put t;
run;

proc contents data=&fin. position;
proc print data=t noobs;
   var t;
run;

%mend charcode;

%macro readt(f);
* sort regpression output based on t-value;

data _t_;
   infile "&f..&plib.";
   length xvar $ 6 xlabel $ 20 df 3 est se tvalue pvalue $ 8;
   input xvar $ xlabel $ df est se tvalue pvalue $;
   if upcase(left(trim(xlabel))) ne "INTERCEPT";
   t=abs(tvalue);
proc sort data=_t_;
   by descending t xvar;
* proc print data=_t_;
*    var xvar t ;
run;
%mend readt;

%macro readtl(f);
* sort logistic regpression output based on chisq-value;

data _t_;
   infile "&f..&plib.";
   length xvar $ 9 df 3 est se chsq2 8 pvalue $ 8 ;
   input xvar $ df est se chsq2 pvalue $;
   retain mdl 0;
   if upcase(left(trim(xvar))) eq "INTERCEPT" then mdl+1;
   if upcase(left(trim(xvar))) ne "INTERCEPT" ;
proc sort data=_t_;
   by mdl descending chsq2 ;
* proc print data=_t_;
*    var xvar chsq2 mdl ;
*    by mdl;
run;
%mend readtl;

%macro decile(f, mdlscr, mdldcl, depname, segcnt=10, wtvar=no);
* re-cut evenly distributed deciles after standard scoring process;

proc sort data=&f.(keep=&id. &mdlscr. %if %eval(&wtvar. ne no) %then %do; &wtvar. %end;) out=t;
   by descending &mdlscr.;
run;

* weighted observation ;
data _null_;
   set t end=last;
   retain accuwgt 0;
   %if %eval(&wtvar. ne no) %then %do;
      accuwgt=accuwgt+&wtvar. ;
   %end; %else %do;
      accuwgt=accuwgt+1;
   %end;
   if last then call symput('SUMCNT', left(accuwgt));
run;

data t(keep=&id. &mdldcl. &mdlscr. ) ;
   set t;
   length &mdldcl. 3;
   retain accuwgt 0;
   %if %eval(&wtvar. ne no) %then %do;
      accuwgt=accuwgt+&wtvar. ;
   %end; %else %do;
      accuwgt=accuwgt+1;
   %end;
   &mdldcl.=floor(&segcnt.*accuwgt/&sumcnt.)+1;
   if &mdldcl.>&segcnt. then &mdldcl.=&segcnt.;
run;

proc sort data=t nodupkey;
   by &id.;
run;

data &f.;
   merge &f.(in=a drop=&mdldcl.) t(in=b keep=&id. &mdldcl.);
   by &id.;
   if a and b;
run;

* Decile statement;

proc means data=t(keep=&mdldcl. &mdlscr.) ;
   class &mdldcl.;
   var &mdlscr.;
   output out=t max=&mdlscr.;
proc sort data=t(where=(&mdldcl.>.)) nodupkey;
   by &mdldcl.;
data _null_;
   file "t.t.&plib.";
   set t end=last;
   by &mdldcl.;
   lastmax=lag(&mdlscr.);

       if _n_=2 then do;
           t=_n_-1;
           put "if " &mdlscr. 16.14 "<&depname.scr                   then &depname.dcl=" t 2. "; else" @79 ".";
       end; else
       if _n_>2 then do;
           t=_n_-1;
           put "if " &mdlscr. 16.14 "<&depname.scr<=" lastmax 16.14 " then &depname.dcl=" t 2. "; else" @79 ".";
       end;
       if last then do;
           t=_n_;
           put "if                   &depname.scr<=" &mdlscr. 16.14 " then &depname.dcl=" t 2. ";" @79 ".";
           put @79 "." / @79 ".";
       end;

   if last then put ");" @79 "." / @79 ".";
run;

data t;
   infile "t.t.&plib.";
   input t $ 1-78;
proc print data=t noobs;
run;

%mend decile;

%macro get_var0(cv);                * Create pre-selected variable list (var0) ;
* CV The coefficient of variation defined as the ratio of the standard deviation to the mean expressed as a percentage;

data &plib..&fin.;
   set &plib..&dset.;
   &depvar.=&ifindep.;
 * drop  aggctdel:;
run;

proc contents data=&plib..&fin.(drop=&depvar.) noprint out=t(keep=name varnum type);

data _null_;
    file outf;
    set t (where=(type=1));
    length _ $ 1;
    _=substr(name, length(name), 1);
    if 1 /*_ not in ("3")*/ then put name ' '@;

run;

proc means data=&plib..&fin.(drop=&depvar.) noprint;
    var %include outf;;
    output out=t1 cv=;
run;

proc transpose data=t1 out=t;
    var %include outf;;
run;

data t;
    set t;
    /*drop _label_;*/
    /*if col1>&cv. ;*/
run;
data t;
    set t end=last;
    file outf;
    if _n_=1 then put '%let var0=%str(';
    if left(trim(_name_)) ne left(trim("&depvar.")) then put _name_;
    if last then put ');';
run;

%include outf;

/*
proc corr data=&plib..&fin. noprint outp=t;
    var &depvar.;
    with &var0.;
run;
proc sort data=t(where=(_type_="CORR" and &depvar.>.)) out=t;
    by descending &depvar.;
run;
data t;
    set t end=last;
    file outf;
    if _n_=1 then put '%let var0=%str(';
    put _name_;
    if last then put ');';
run;
*/

* proc print data=t;
* run;

%mend get_var0;

%macro calccorr;

proc contents data=&plib..&fin. ;
run;

proc corr data=&plib..&fin. noprint outp=t;
    var &depvar.;
    with &var.;
run;
proc print data=t;
run;
%mend calccorr;
