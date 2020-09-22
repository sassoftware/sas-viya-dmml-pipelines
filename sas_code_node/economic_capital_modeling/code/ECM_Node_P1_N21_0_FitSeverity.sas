/*
%let ecm_user_sevdists       	= gamma logn weibull;
%let ecm_user_sevDistSlctCrit	= aicc;
%let ecm_user_sevEffects     	= %str(corpKRI1 corpKRI2 cbKRI2 rbKRI1 rbKRI3 corpKRI1*rbKRI3);
%let ecm_user_sevSlctMethod  	= %str();
%let ecm_user_sevEffectSlctCrit	= sbc;
*/

/*** Read global macro variables ***/
%dmcas_fetchDataset(&dm_projectId, &dm_nodedir, ecm_tmp_macrovars);

proc print data=&dm_lib..ecm_tmp_macrovars;
run;

data _null_;
	set &dm_lib..ecm_tmp_macrovars;
	call symput(trim(name), trim(value));
run;

*** Load severity distribution definitions ***;
proc cas;
	loadtable / caslib="samples" path="predef_svrtdist.sashdat"
	            casout="sevdists";
	droptable / name="ecm_sevStore", quiet=True;
quit;
	
*** Fit severity models ***;
title 'Fit severity models';
proc sevselect data=&dm_data store=&dm_datalib..ecm_sevStore(promote=yes)
               covout print=(allfitstats) crit=&ecm_user_sevDistSlctCrit;
	by &ecm_byvars;
	loss &ecm_sev_target;
	dist &ecm_user_sevdists / INFUNCDEF="sevdists";
	%if "%trim(%left(&ecm_user_sevEffects))" ne "" %then %do;
		%if "%trim(%left(&ecm_classInput))" ne "" %then %do;
	   		class &ecm_classInput;
		%end;
		scalemodel &ecm_user_sevEffects;
		%if "%trim(%left(&ecm_user_sevSlctMethod))" ne "" %then %do;
			selection method=&ecm_user_sevSlctMethod.(select=&ecm_user_sevEffectSlctCrit.);
		%end;
	%end;
	ods output AllFitStatistics=&dm_lib..fitStatsSev;
run;

proc datasets lib=&dm_datalib;
quit;

%dmcas_register(dataset=&dm_lib..fitStatsSev);

proc print data=&dm_lib..DMCAS_REGISTER;
run;

proc print data=&dm_lib..ecm_tmp_macrovars;
run;

proc print data=&dm_lib..fitStatsSev;
run;

%exit:
;
