%INC  ".\#00.OPTION.SAS";
options user=work;


	




	
/* FinalApply */
%LET INST_VAR= refBizId memberId name identityNo  loanAmount  loanTermAmount  loanTermUnit loanMethod
				conclusion  memberlevel  creditLine  dataRate extParams riskRuleType crtTime  updTime
				applyTime  applyBankNo  applyMobile  contactName1  contactMobile1  contactRelation1 contactName2  contactMobile2  contactRelation2
				jobType  homeAddressProvince  homeAddressCity homeAddressDistrict  companyAddressProvince  companyAddressCity companyAddressDistrict   
				creditChannel   creditResult   creditRespCode  cardType sumCreditLine  

	;
%PUT &INST_VAR;


data   bck.CashFstAudit_&tday.;
set Fq_rcs.CashCreditApply(keep=refBizId memberId crtTime  updTime  extParams  riskruletype  applyBankNo );
/*where riskruletype='biz-fq-rcs.CashFstAudit'; */
where riskRuleType in ('biz-fq-rcs.CashFstAudit','biz-fq-rcs.memberLevelGrant') ;   /*   and not missing(applyBankNo);   sh   */


length ZMscore1 $15. 	ZMscore 8.;
if index(extParams,"zmCreditScore")>0 then ZMscore1=substr(extParams,index(extParams,"zmCreditScore")+14,3);
else ZMscore1=".";

if compress(ZMscore1) not in("N/A","null","nul",".","0,","0") then  ZMscore=compress(ZMscore1,,'kdp')+0; else ZMscore=.;


keep refBizId memberId crtTime  updTime  ZMscore1  ZMscore ;

run;



data   bck.CashCreditApply_&tday.;
set Fq_rcs.CashCreditApply(keep=&INST_VAR.);
where riskruletype='biz-fq-rcs.afterCashCreditGrantNotify';

drop   extParams;

run;


PROC CONTENTS DATA=	bck.CashCreditApply_&tday.;
TITLE  "========================APPLY==========================";
RUN;
 	

	
	
	

/*  ORDER */

%LET ODR_VAR= MEMBERID  orderno	  transNo  dueLoanAmt realLoanAmt  acctTempId
				orderState  orderStatus  orderType  repaymentPeriod  periodType
				bankName      successTime  successLogicDate   
				crtTime  updTime	remittanceType
	;
%PUT &ODR_VAR;
DATA bck.CashOrderInfo_&TDAY.;
	SET 	Ins.CashOrderInfo(keep= &ODR_VAR. 
							WHERE=( orderType=1    ))		;
							UPDATE_DAY="&TDAY.";

	RUN;
PROC CONTENTS DATA= bck.CashOrderInfo_&TDAY.;
TITLE  "========================ORDER==========================";
RUN;
	
	

/* REPAY  */
DATA bck.RepaySchedule_&TDAY.;
	SET ins.RepaySchedule	( 
							WHERE=( orderType=1    ))	;
	
							UPDATE_DAY="&TDAY.";

	RUN;
PROC CONTENTS DATA= bck.RepaySchedule_&TDAY.;
TITLE  "========================REPAY==========================";
RUN;	

	
	
/* Loan_bill*/
DATA  bck.LoanBill_&TDAY.;
	SET  INS.LoanBill ( 
							WHERE=( orderType=1    ));
						UPDATE_DAY="&TDAY.";
	
	RUN;

	
