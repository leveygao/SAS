%inc ".\#00.OPTION.SAS";


filename   jfport ".\csv\Cash_JF07.csv"   encoding='utf-8';

data bck.jfbigdata_07   ;
     infile    jfport   firstobs=2
	 dlm=","  MISSOVER      dsd   ;
 

 
informat refbizid best32. ;
informat memberid $32. ;
informat mtruename $11. ;
informat msurname $2. ;
informat cardtype $6. ;
informat identitycard $64. ;
informat iclocation $11. ;
informat passengernamelist $97. ;
informat passengersurnamelist $29. ;
informat nationality $4. ;
informat cardnolist $909. ;
informat psiclocationlist $9. ;
informat mobilenumber $1. ;
informat mbsegment best32. ;
informat mobilecityid best32. ;
informat phonetype $18. ;
informat psmobilelist $65. ;
informat psmbsegmentlist $7. ;
informat psmblocationlist $4. ;
informat psphonetypelist $26. ;
informat fuemastreetaddresslist $1. ;
informat fuemaprovincelist $4. ;
informat fuebilladdresslist $1. ;
informat fuebillprovincelist $1. ;
informat morderlinkermancout best32. ;
informat fuelinkmancount best32. ;
informat fuelinkernamesurnamelist $8. ;
informat fuelinkernamelist $27. ;
informat fuelinkermancertnolist $1. ;
informat fuelinkermancertnocount $1. ;
informat fuelinkermanprvnamelist $1. ;
informat fuelinkermanprvnamecount $1. ;
informat fuelinkermanmobilelist $1. ;
informat fuelinkermanmobilecount $1. ;
informat fuelinkermbprvnamelist $1. ;
informat fuelinkermbprvnamecount $1. ;
informat deviceidlist $201. ;
informat firstdeviceidofcity $9. ;
informat deviceidofcitylist $34. ;
informat device_membercounts best32. ;
informat devicefacturerlist $18. ;
informat devicenamelist $38. ;
informat hfueloginlist $1. ;
informat hfuepaydatelist $7. ;
informat mregtime anydtdtm40. ;
informat mregisterip $15. ;
informat registeripofprovice $4. ;
informat registerplatformname $3. ;
informat m_cooperateuserdesc $1. ;
informat lastupdatepwd anydtdtm40. ;
informat lastmonthupdatepwdtimes best32. ;
informat firstlogindate anydtdtm40. ;
informat visitrateofday best32. ;
informat visitrateofmonth best32. ;
informat visittimeofevery best32. ;
informat visittimeofday best32. ;
informat avgpagestoptime best32. ;
informat avgvisitpageofday best32. ;
informat fueiploginlist $78. ;
informat fuemacloginlist $32. ;
informat fueipofprovicelist $9. ;
informat fueipcounts best32. ;
informat maxintervalday best32. ;
informat minintervalminute best32. ;
informat membercountofip best32. ;
informat wechatpaytimes best32. ;
informat alipayaccounts best32. ;
informat wechataccounts best32. ;
informat alipaytimes best32. ;
informat debitcardpaytimes best32. ;
informat isfingeropen_member best32. ;
informat avgpaytime best32. ;
informat bigconsumeamount best32. ;
informat smallconsumeamount best32. ;
informat avgconsumeamount best32. ;
informat maxconsumeamount best32. ;
informat minconsumeamount best32. ;
informat ordersuccessrate best32. ;
informat quartersusconsumetimes $1. ;
informat quartersusrefundtimes $1. ;
informat halfyearsusconsumetimes $1. ;
informat halfyearsusrefundtimes $1. ;
informat monthsusconsumetimes $1. ;
informat monthconsumetimes $1. ;
informat longconsumeintervaldays best32. ;
informat shortconsumeinterval best32. ;
informat abroad_consumetimes best32. ;
informat tourism_consumetimes best32. ;
informat cruise_consumetimes best32. ;
informat shorttour_consumetimes best32. ;
informat scenery_consumetimes best32. ;
informat scenery_tickettimes best32. ;
informat abroad_quarterconsumetimes $1. ;
informat domestic_desttimes best32. ;
informat domestic_destprovince $4. ;
informat domestic_destprovincetimes best32. ;
informat overseas_destcountry $1. ;
informat overseas_desttimes $1. ;
informat train_consumetimes best32. ;
informat train_selfconsumetimes best32. ;
informat train_manyconsumetimes best32. ;
informat train_departcitylist $158. ;
informat train_destcitylist $158. ;
informat train_departcitylistoften $49. ;
informat train_destcitylistoften $44. ;
informat train_avgtrainprice best32. ;
informat train_firstbusiclasstimes best32. ;
informat fly_consumetimes best32. ;
informat fly_departcitylistoften $4. ;
informat fly_destcitylistoften $4. ;
informat fly_departcitylist $32. ;
informat fly_destcitylist $19. ;
informat fly_firstbusiclasstimes $1. ;
informat fly_selfconsumetimes best32. ;
informat fly_manyconsumetimes best32. ;
informat fly_avgtrainprice best32. ;
informat flyint_consumetimes $1. ;
informat flyint_departcitylistoften $1. ;
informat flyint_destcitylistoften $1. ;
informat flyint_departcitylist $1. ;
informat flyint_destcitylist $1. ;
informat flyint_firstbusiclasstimes $1. ;
informat flyint_selfconsumetimes $1. ;
informat flyint_manyconsumetimes $1. ;
informat flyint_avgtrainprice $1. ;
informat bus_consumetimes best32. ;
informat bus_departcitylistoften $1. ;
informat bus_destcitylistoften $1. ;
informat bus_departcitylist $9. ;
informat bus_destcitylist $9. ;
informat bus_selfconsumetimes best32. ;
informat bus_manyconsumetimes best32. ;
informat bus_avgtrainprice best32. ;
informat createtime best32. ;
informat day best32. ;


 
input

refbizid $
memberid $
mtruename $
msurname $
cardtype $
identitycard $
iclocation $
passengernamelist $
passengersurnamelist $
nationality $
cardnolist $
psiclocationlist $
mobilenumber $
mbsegment
mobilecityid
phonetype $
psmobilelist $
psmbsegmentlist $
psmblocationlist $
psphonetypelist $
fuemastreetaddresslist $
fuemaprovincelist $
fuebilladdresslist $
fuebillprovincelist $
morderlinkermancout
fuelinkmancount
fuelinkernamesurnamelist $
fuelinkernamelist $
fuelinkermancertnolist $
fuelinkermancertnocount $
fuelinkermanprvnamelist $
fuelinkermanprvnamecount $
fuelinkermanmobilelist $
fuelinkermanmobilecount $
fuelinkermbprvnamelist $
fuelinkermbprvnamecount $
deviceidlist $
firstdeviceidofcity $
deviceidofcitylist $
device_membercounts
devicefacturerlist $
devicenamelist $
hfueloginlist $
hfuepaydatelist $
mregtime
mregisterip $
registeripofprovice $
registerplatformname $
m_cooperateuserdesc $
lastupdatepwd
lastmonthupdatepwdtimes
firstlogindate
visitrateofday
visitrateofmonth
visittimeofevery
visittimeofday
avgpagestoptime
avgvisitpageofday
fueiploginlist $
fuemacloginlist $
fueipofprovicelist $
fueipcounts
maxintervalday
minintervalminute
membercountofip
wechatpaytimes
alipayaccounts
wechataccounts
alipaytimes
debitcardpaytimes
isfingeropen_member
avgpaytime
bigconsumeamount
smallconsumeamount
avgconsumeamount
maxconsumeamount
minconsumeamount
ordersuccessrate
quartersusconsumetimes $
quartersusrefundtimes $
halfyearsusconsumetimes $
halfyearsusrefundtimes $
monthsusconsumetimes $
monthconsumetimes $
longconsumeintervaldays
shortconsumeinterval
abroad_consumetimes
tourism_consumetimes
cruise_consumetimes
shorttour_consumetimes
scenery_consumetimes
scenery_tickettimes
abroad_quarterconsumetimes $
domestic_desttimes
domestic_destprovince $
domestic_destprovincetimes
overseas_destcountry $
overseas_desttimes $
train_consumetimes
train_selfconsumetimes
train_manyconsumetimes
train_departcitylist $
train_destcitylist $
train_departcitylistoften $
train_destcitylistoften $
train_avgtrainprice
train_firstbusiclasstimes
fly_consumetimes
fly_departcitylistoften $
fly_destcitylistoften $
fly_departcitylist $
fly_destcitylist $
fly_firstbusiclasstimes $
fly_selfconsumetimes
fly_manyconsumetimes
fly_avgtrainprice
flyint_consumetimes $
flyint_departcitylistoften $
flyint_destcitylistoften $
flyint_departcitylist $
flyint_destcitylist $
flyint_firstbusiclasstimes $
flyint_selfconsumetimes $
flyint_manyconsumetimes $
flyint_avgtrainprice $
bus_consumetimes
bus_departcitylistoften $
bus_destcitylistoften $
bus_departcitylist $
bus_destcitylist $
bus_selfconsumetimes
bus_manyconsumetimes
bus_avgtrainprice
createtime
day


	 ;

/*	 informat mobile  dollar11.2     ;*/
run;

proc contents data=   bck.jfbigdata_07   ;
run;


/*
proc import file= '.\tag_360\uni_tag_0822.csv'
out= tag
dbms=csv replace;
run;

