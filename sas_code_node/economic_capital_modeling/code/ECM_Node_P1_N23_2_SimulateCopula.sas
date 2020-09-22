/*
%let ecm_user_nCopObs = 10000;
%let ecm_user_copSeed = 123;
*/

/*** Read global macro variables ***/
data _null_;
	set work.nodes(where=(component="sascode" and order=4));
	call symput("bestcopNodeGuid", guid);
run;
%put best cop guid = &bestcopNodeGuid;

%dmcas_fetchDataset(&bestcopNodeGuid, &dm_nodedir, ecm_tmp_macrovars);

data _null_;
	set &dm_lib..ecm_tmp_macrovars;
	call symput(trim(name), trim(value));
run;

proc cas;
	droptable / name="ecm_MarginalProbs", quiet=True;
quit;
	
title "Simulate from &ecm_best_copula copula";
proc ccopula;
	simulate cop / restore=&dm_datalib..&ecm_best_copula_store
	               ndraws=&ecm_user_nCopObs seed=&ecm_user_copSeed
	               outuniform=&dm_datalib..ecm_MarginalProbs(promote=yes);
run;

proc datasets lib=&dm_datalib;
quit;

proc print data=&dm_datalib..ecm_MarginalProbs(obs=10);
run;
