%INC  ".\#00.OPTION.SAS";

/* impot */
%inc ".\#01.IMPT_TABLE.sas";

proc datasets library=work kill nolist;
quit;


/* apply */
%inc ".\#02.ApplyInfo.sas";

proc datasets library=work kill nolist;
quit;


/* post */
%inc ".\#03.Post_apply.sas";

proc datasets library=work kill nolist;
quit;




/* post-ct */
%inc ".\#04.Post_apply_ct.sas";

proc datasets library=work kill nolist;
quit;

/* post-ct */
%inc ".\#05.CASH_DLQ_TAG.sas";



%inc ".\#06.Remind.sas";


proc datasets library=work kill nolist;
quit;