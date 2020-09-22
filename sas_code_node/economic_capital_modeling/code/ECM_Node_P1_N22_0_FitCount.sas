/*
%let ecm_user_cntDists       = %str(poisson negbin(p=2));
%let ecm_user_cntDistSlctCrit= AIC;
%let ecm_user_cntEffects     = %str(corpKRI1 corpKRI2 cbKRI1 cbKRI2 cbKRI3 cbKRI2*cbKRI3 rbKRI1 rbKRI2);
%let ecm_user_cntSlctMethod  = %str();
%let ecm_user_cntSlctCrit    = sbc;
*/

/*** Read global macro variables ***/
%dmcas_fetchDataset(&dm_projectId, &dm_nodedir, ecm_tmp_macrovars);

data _null_;
	set &dm_lib..ecm_tmp_macrovars;
	call symput(trim(name), trim(value));
run;

*** Fit count models ***;
%let ecm_user_cntDists=%trim(%left(&ecm_user_cntDists));

%local i;
%let i=1;
%local dist;
%do %until ("&dist" eq "");
	%let dist = %scan(&ecm_user_cntDists, &i, " ");
	%if ("&dist" ne "") %then %do;
		%local distlist&i;
		%let distlist&i = &dist;
		proc cas;
			droptable / name="ecm_cntStore&i", quiet=True;
		quit;
		title "Fit &dist model";
		proc cntselect data=&dm_datalib..&ecm_countTable 
			           store=&dm_datalib..ecm_cntStore&i.(promote=yes);
		   by &ecm_byvars;
		   %if "%trim(%left(&ecm_classInput))" ne "" %then %do;
		   		class &ecm_classInput;
		   %end;
		   model &ecm_freq_target= &ecm_user_cntEffects / dist=&dist;
		   %if "%trim(%left(&ecm_user_cntSlctMethod))" ne "" %then %do;
		   		selection method=&ecm_user_cntSlctMethod.(select=&ecm_user_cntSlctCrit.);
		   %end;
		   ods output FitModelSummary=&dm_lib..fitCnt&i;
		run;
		%let i = %eval(&i + 1);
	%end;
%end;
%local ndist;
%let ndist=%eval(&i - 1);
%put number of count distributions = &ndist;

data &dm_lib..fitStatsCnt(keep=&ecm_byvars Model Store PropertyValue);
	length Model $32;
	length Store $64;
	%do i=1 %to &ndist;
		%let dist=&&distlist&i;
		set &dm_lib..fitCnt&i (keep=&ecm_byvars Property PropertyValue 
			where=(upcase(Property)=upcase("&ecm_user_cntDistSlctCrit")));
		Model="&dist";
		Store="ecm_cntStore&i.";
		output;
	%end;
run;
proc print; run;

%dmcas_register(dataset=&dm_lib..fitStatsCnt);

%exit:
;
