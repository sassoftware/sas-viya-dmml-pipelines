/*** Read global macro variables ***/
%dmcas_fetchDataset(&dm_projectId, &dm_nodedir, ecm_tmp_macrovars);

data _null_;
	set &dm_lib..ecm_tmp_macrovars;
	call symput(trim(name), trim(value));
run;

data _null_;
	set work.nodes(where=(component="sascode" and order=3));
	call symput("fitcntNodeGuid", guid);
run;
%put cnt guid = &fitcntNodeGuid;

%dmcas_fetchDataset(&fitcntNodeGuid, &dm_nodedir, fitstatscnt);
proc print data=&dm_lib..fitStatsCnt;
run;

proc sort data=&dm_lib..fitStatsCnt;
	by &ecm_byvars;
run;

data &dm_lib..ecm_bestcnt(keep=&ecm_byvars best_cnt_model best_store);
	set &dm_lib..fitStatsCnt;
	by &ecm_byvars;
	retain best_crit best_cnt_model best_store;
	if (first.&ecm_lastByVar) then do;
		best_crit = PropertyValue;
		best_cnt_model = Model;
		best_store = Store;
	end;
	else do;
		if (best_crit > PropertyValue) then do;
			best_crit = PropertyValue;
			best_cnt_model = Model;
			best_store = Store;
		end;
	end;
	if (last.&ecm_lastByVar) then do;
		output;
	end;
run;
proc print; run;

%dmcas_register(dataset=&dm_lib..ecm_bestcnt);
/*
proc print data=DMLIB.DMCAS_REGISTER; run;
*/

data work.ecm_prepcntguid;
	set work.nodes(where=(order=4));
run;
%dmcas_addDataset(&dm_projectId, work, ecm_prepcntguid);

%exit:
;
