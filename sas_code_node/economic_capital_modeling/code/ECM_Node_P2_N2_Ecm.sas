/*** Get macro variables ***/
%dmcas_fetchDataset(&dm_projectId, &dm_nodedir, ecm_tmp_macrovars);
data _null_;
	set &dm_lib..ecm_tmp_macrovars;
	call symput(trim(name), trim(value));
run;

data _null_;
    set work.nodes(where=(component="sascode" and order=1));
    call symput("simSettingsNodeGuid", guid);
    stop;
run;
%put settings node guid = &simSettingsNodeGuid;

%dmcas_fetchDataset(&simSettingsNodeGuid, &dm_nodedir, ecm_user_sim_settings);

data _null_;
    set &dm_lib..ecm_user_sim_settings;
    call symput(trim(name), value);
run;

data _null_;
	set work.nodes(where=(component="sascode" and order=2));
	call symput("cdmNodeGuid", guid);
	stop;
run;
%put cdm guid = &cdmNodeGuid;
%dmcas_fetchDataset(&cdmNodeGuid, &dm_nodedir, ecm_cdm_macrovars);
data _null_;
	set &dm_lib..ecm_cdm_macrovars;
	call symput(trim(name), trim(value));
run;

title 'Simulate ECM';
%let ecmOutsumStmt=%str(
    outsum out=&dm_datalib..ecm_tlSumm mean stddev skew kurtosis qrange=iqr 
        pctlpts=&ecm_user_varLevels pctlpre=VaR
        tvarpts=&ecm_user_tvarLevels pctlpre=TVaR;
);

proc ecm data=&dm_datalib..ecm_MarginalProbs edfaccuracy=&ecm_user_edfAccuracy print=all;
	%do igrp=1 %to &ecm_nByGrp;
    	marginal Marginal&igrp: data=&dm_datalib..ecm_margsample&igrp samplevar=Marginal&igrp drawId=0;
	%end;
    &ecmOutsumStmt;
    ods output TVaR=&dm_lib..TVaR;
run;

title 'Final ECM Estimates of Single Marginal Combination';
proc print data=&dm_lib..TVaR;
run;
proc print data=&dm_datalib..ecm_tlSumm;
run;

%if &ecm_cdmNPerturb > 0 %then %do;
	data &dm_lib..allecmstats;
		set &dm_datalib..ecm_tlSumm;
	run;
	%do igrp=1 %to %eval(&ecm_nByGrp-1);
		%let drawId&igrp = 0;
	%end;
	%let drawId&ecm_nByGrp = 1;

	%do ncombo=2 %to &ecm_user_nTotalLossSamples;
		title "Simulate ECM for Marginal Combination &ncombo";
		proc ecm data=&dm_datalib..ecm_MarginalProbs edfaccuracy=&ecm_user_edfAccuracy noprint;
			%do igrp=1 %to &ecm_nByGrp;
		    	marginal Marginal&igrp: data=&dm_datalib..ecm_margsample&igrp 
										samplevar=Marginal&igrp drawId=&&drawId&igrp;
			%end;
			&ecmOutsumStmt;
		run;

        /* need to make a client-local copy first before appending to
           avoid the error related to varchar */
        data work.tlSumm;
			set &dm_datalib..ecm_tlSumm;
		run;
		proc datasets library=&dm_lib nolist;
			append base=allecmstats data=work.tlSumm;
		run;

		%do igrp=&ecm_nByGrp %to 1 %by -1;
			%let drawId&igrp = %eval(&&drawId&igrp + 1);
			%if &&drawId&igrp > &ecm_cdmNPerturb %then %do;
				%let drawId&igrp = 0;
			%end;
			%else %do;
				%goto nextCombo;
			%end;
		%end;
		%nextCombo:
	    ;
	%end;

    title "Final ECM Estimates of All Marginal Combinations";
    proc print data=&dm_lib..allecmstats; run;
    
	title 'Location and Dispersion Estimates of Risk Measures';
	proc means data=&dm_lib..allecmstats(rename=(VaR50=Median)) 
				n mean std median qrange;
		var Mean Median VaR95 TVaR95 VaR97_5 TVaR97_5 VaR99_5 TVaR99_5;
	quit;
%end;

%exit:
;
