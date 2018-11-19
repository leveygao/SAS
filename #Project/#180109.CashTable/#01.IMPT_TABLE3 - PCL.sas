%INC  ".\#00.OPTION.SAS";
options user=work;

	

/* CashCredit_orderInfo_daily*/
DATA   bck.Cash_orderInfo_daily_&TDAY.   ;
	SET  Bitc.CashCredit_orderInfo_daily  ;
						UPDATE_DAY="&TDAY.";
	
	RUN;
	



