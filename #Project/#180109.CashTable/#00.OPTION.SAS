OPTIONS NOCENTER LS=MAX PS=MAX COMPRESS=YES;

LIBNAME DT ".\DATA";
libname bck ".\bck";

%LET TDAY=20181118 ;


	



/* LIBNAME PRODUCTION */

libname fq_rcs odbc dsn='tcbiz_fq_rcs' uid='tcjinfu_select_information' pwd='AaP9ru6=pmqh^O4lP#a19yiW6Kk' 
dbmax_text=32767 ;

libname fq_data  odbc dsn='tcbiz_fq_rcs_data' uid='tcjinfu_select_information' pwd='AaP9ru6=pmqh^O4lP#a19yiW6Kk' 
dbmax_text=32767 ;


libname ins odbc dsn='tcbiz_ins' uid='tcjinfu_select_information' pwd='AaP9ru6=pmqh^O4lP#a19yiW6Kk' 
dbmax_text=32767 ;


libname ins_mas  odbc dsn='tcbiz_ins_mas' uid='tcjinfu_select_information' pwd='AaP9ru6=pmqh^O4lP#a19yiW6Kk' 
dbmax_text=32767 ;

libname rcs_cms  odbc dsn='tcbiz_rcs_cms' uid='tcjinfu_select_information' pwd='AaP9ru6=pmqh^O4lP#a19yiW6Kk' 
dbmax_text=32767 ;


libname member   odbc dsn='tcbiz_member' uid='tcjinfu_select_information' pwd='AaP9ru6=pmqh^O4lP#a19yiW6Kk' 
dbmax_text=32767 ;



libname bitc   odbc dsn='tcbiz_bi_tc' uid='tcjinfu_select_information' pwd='AaP9ru6=pmqh^O4lP#a19yiW6Kk' 
dbmax_text=32767 ;
