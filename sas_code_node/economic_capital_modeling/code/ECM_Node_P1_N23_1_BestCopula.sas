/*** Read global macro variables ***/
%dmcas_fetchDataset(&dm_projectId, &dm_nodedir, ecm_tmp_macrovars);

data _null_;
	set &dm_lib..ecm_tmp_macrovars;
	call symput(trim(name), trim(value));
run;

data _null_;
	set work.nodes(where=(component="sascode" and order=3));
	call symput("fitcopNodeGuid", guid);
run;
%put cop guid = &fitcopNodeGuid;

/* data set name must be all lower-case */
%dmcas_fetchDataset(&fitcopNodeGuid, &dm_nodedir, fitstatscop);

data _null_;
	set &dm_lib..fitStatsCop end=last;
	retain best_crit best_model best_store;
	if _n_=1 then do;
		best_model = Copula;
		best_crit = Criterion;
		best_store = Store;
	end;
	else do;
		if (best_crit > Criterion) then do;
			best_model = Copula;
			best_crit = Criterion;
			best_store = Store;
		end;
	end;
	if (last) then do;
		call symput('ecm_best_copula', best_model);
		call symput('ecm_best_copula_store', best_store);
	end;
run;

%put best copula = &ecm_best_copula;
%put best copula store = &ecm_best_copula_store;

data &dm_lib..ecm_tmp_macrovars;
	set &dm_lib..ecm_tmp_macrovars end=last;
	if (last) then do;
		name = "ecm_best_copula";
		value = "&ecm_best_copula";
		output;
		name = "ecm_best_copula_store";
		value = "&ecm_best_copula_store";
		output;
	end;
	else output;
run;

proc print data=&dm_lib..ecm_tmp_macrovars(where=(name like 'ecm_best_copula%')); 
run;

%dmcas_register(dataset=&dm_lib..ecm_tmp_macrovars);

%exit:
;
