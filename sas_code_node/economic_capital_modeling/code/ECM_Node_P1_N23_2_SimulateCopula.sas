/* Specify a positive number for ecm_user_nCopObs_node and ecm_user_copSeed_node to override 
   the values of ecm_user_nCopObs and ecm_user_copSeed that are read from the Modeling 
   Settings Node. This is useful if you want to change the size of joint probability sample 
   or generate different sample of the same size after all modeling nodes have been run. */
%let ecm_user_nCopObs_node=-1;
%let ecm_user_copSeed_node=-1;

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

%if &ecm_user_nCopObs_node > 0 %then
	%let ecm_user_nCopObs = ecm_user_nCopObs_node;
%if &ecm_user_copSeed_node > 0 %then
	%let ecm_user_copSeed = ecm_user_copSeed_node;

proc cas;
	droptable / name="ecm_MarginalProbs", quiet=True;
quit;
	
title "Simulate from &ecm_best_copula copula";
proc ccopula;
	simulate cop / restore=&dm_datalib..&ecm_best_copula_store
	               ndraws=&ecm_user_nCopObs seed=&ecm_user_copSeed
	               outuniform=&dm_datalib..ecm_MarginalProbs(promote=yes);
run;

title 'Data sets on the CAS server';
proc datasets lib=&dm_datalib;
quit;

title 'First Few Observations of the Simulated Joint Probability Table';
proc print data=&dm_datalib..ecm_MarginalProbs(obs=10);
run;
