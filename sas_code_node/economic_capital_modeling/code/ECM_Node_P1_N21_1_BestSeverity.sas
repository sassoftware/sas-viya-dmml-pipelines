/*** Read global macro variables ***/
%dmcas_fetchDataset(&dm_projectId, &dm_nodedir, ecm_tmp_macrovars);

/* proc print data=&dm_lib..ecm_tmp_macrovars; run; */

data _null_;
	set &dm_lib..ecm_tmp_macrovars;
	call symput(trim(name), trim(value));
run;

/* the data set name must be all lowercase during fetch because that is 
   how %dmcas_register saves it */
/* proc print data=work.NODES; run; */

data _null_;
	set work.nodes(where=(component="sascode" and order=3));
	call symput("fitsevNodeGuid", guid);
	stop;
run;

%dmcas_fetchDataset(&fitsevNodeGuid, &dm_nodedir, fitstatssev);
proc print data=&dm_lib..fitstatssev;

proc sort data=&dm_lib..fitstatssev;
	by &ecm_byvars;
run;

data &dm_lib..ecm_bestsev(keep=&ecm_byvars best_sev_model);
	set &dm_lib..fitstatssev;
	by &ecm_byvars;
	length best_sev_model $32.;
	retain best_sev_model best_n default_best best_tie;
	if (first.&ecm_lastByVar) then do;
		best_n = 0;
		best_tie = 0;
	end;
	n = Neg2LogLike_Sel + AIC_Sel + AICC_Sel + BIC_Sel;
	%if "%trim(%left(&ecm_user_sevEffects))" eq "" %then %do;
		n = n + KS_Sel + AD_Sel + CvM_Sel;
	%end;
	if (n > best_n) then do;
		best_n = n;
		best_sev_model = _MODEL_;
		best_tie = 0;
	end;
	else if (n = best_n) then do;
	    best_tie = 1;
	end;
	if (&ecm_user_sevDistSlctCrit._Sel = 1) then default_best = _MODEL_;
	if (last.&ecm_lastByVar) then do;
		if (best_tie = 1) then best_sev_model = default_best;
		output;
	end;
run;

proc print; run;

%dmcas_register(dataset=&dm_lib..ecm_bestsev);
/*
proc print data=DMLIB.DMCAS_REGISTER; run;
*/

data work.ecm_prepsevguid;
	set work.nodes(where=(order=4));
run;
%dmcas_addDataset(&dm_projectId, work, ecm_prepsevguid);

%exit:
;
