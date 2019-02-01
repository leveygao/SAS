data model2; 
set model2; 
inc_sq =income**2; /* squared*/ 
inc_cu =income**3; /* cubed*/ 
inc_sqrt = sgrt (income); /*square root*/ 
inc_curt =income**. 3333; /*cube root*/ 
inc_log = log (max (.0001,income) /*log*/ 
inc_exp = exp (max (.0001,income) /* exponent */

inc_tan = tan(income); /*tangent*/ 
inc_sin = sin(income); /*sine*/ 
inc_cos = cos (income); /*cosine*/

inc_inv = 1/max(.0001,income); /*inverse*/ 
inc_sqi = 1/max(.0001,income**2); /*squared inverse*/ 
inc_cui = 1/max(.0001,income**3); /*cubed inverse*/ 
inc_sqri = 1/max(.0001, sqrt (income)); /*square root inv*/ 
inc_curi = 1/max(.0001,income**.3333); /*cube root inverse*/

inc_logi = 1/max (.0001, log (max (.0001,income))); /*log inverse*/ 
inc_expi = 1/max (.0001, exp (max (.0001,income))); /*exponent inv*/

inc_tani = 1/max(.0001,tan(income) ); /*tangent inverse*/ 
inc_sini = 1/max(.0001, sin(income)); /*sine inverse*/ 
inc_cosi = 1/max(.0001,cos (income)); /*cosine inverse*/ 
run;
