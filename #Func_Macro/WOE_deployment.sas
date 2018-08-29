data x.xx;
	set ce.m_lf_1;

	if   age<=49 then w_age = 0.0870743514;
	else if age <= 54 then w_city_month = -0.260463278;
	else if age< = 60 then w_city_month = -1.038584986;

    if gender = 0 then W_gender =0.1064165402 ;
	else W_gender= -0.268160718; 

	if show_first_name = 781 then W_hangye = 0.3741735289;
	else if show_first_name in (775,782) then W_hangye = 0.2775909224;
	else if show_first_name in (773,776,784,783) then W_hangye = 0.1283596867;
	else W_hangye = -0.422628237;

	if missing(ir_m1_id_x_cell_cnt) then w_ir_m1_id_x_cell_cnt=-0.133273485 ;
	else if ir_m1_id_x_cell_cnt  = 0  then w_ir_m1_id_x_cell_cnt = -1.398867871;
	else if ir_m1_id_x_cell_cnt  = 1 then w_ir_m1_id_x_cell_cnt = 0.2938006953;
	else w_ir_m1_id_x_cell_cnt = 1.1601467507;

	
	if unit_type = 4 then W_unit_type = -1.045588516;
	else if unit_type in (5,2) then W_unit_type = -0.336096247;
	else if unit_type in (9,3,6,10) then W_unit_type = 0.111276866;
	else W_unit_type = 0.8905157099;

	if missing(ir_id_inlistwith_cell) then w_ir_id_inlistwith_cell =-0.264547134 ;
	else if ir_id_inlistwith_cell = 0 then w_ir_id_inlistwith_cell = 1.7692685224;
	else if ir_id_inlistwith_cell = 1 then w_ir_id_inlistwith_cell = -0.022266639;

 	if missing(ir_id_is_reabnormal) then w_ir_id_inlistwith_cell =-0.264547134 ;
	else if ir_id_is_reabnormal = 0 then w_ir_id_inlistwith_cell = 0.2531496274;
	else if ir_id_is_reabnormal = 1 then w_ir_id_inlistwith_cell = 1.9333366389;

	if missing(td_largConFinQry_2y) then w_td_largConFinQry_2y =0.0365738607 ;
	else if td_largConFinQry_2y = 0 then w_td_largConFinQry_2y = -0.263197569;
	else if td_largConFinQry_2y = 1 then w_td_largConFinQry_2y = 0.0663537484;
	else w_td_largConFinQry_2y = 1.2524595509;


	p_w_age = 0.8155;
	p_w_gender = 0.8269;
	p_w_hangye = 0.8074;
	p_W_ir_id_inlistwith_cell = 0.8700;
	p_W_ir_id_is_reabnormal=0.2592;
	p_W_ir_m1_id_x_cell_cnt=0.4036;
	p_W_td_largConFinQry_2y=0.5076;
	p_W_unit_type=0.8584;



	Intercept = -1.9371;
    
	z_w_age = w_age*p_w_age;
	z_W_gender = W_gender*p_W_gender;
	z_W_hangye = W_hangye*p_W_hangye;
	z_w_ir_id_inlistwith_cell = w_ir_id_inlistwith_cell*p_w_ir_id_inlistwith_cell;
	z_W_ir_id_is_reabnormal = W_ir_id_is_reabnormal*p_W_ir_id_is_reabnormal;
	z_W_td_largConFinQry_2y = W_td_largConFinQry_2y*p_W_td_largConFinQry_2y;
	z_unit_type = w_unit_type * p_w_unit_type;

run;
data x.xx1;
	set x.xx;
	a_sum=sum(of z_:);
run;
data x.xx2;
	set x.xx1;
	odds=a_sum+Intercept;
	e_odds=exp(odds);
	phat=e_odds/(1+e_odds);
	cs=log(phat/(1-phat));
	score=MIN(MAX(300-ROUND(cs/Log(2)*50,1),0),1000);
run;

