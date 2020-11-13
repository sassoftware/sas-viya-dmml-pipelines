/*** Read user settings ***/
data _null_;
	set work.nodes(where=(component="sascode" and order=1));
	call symput("settingsNodeGuid", guid);
	stop;
run;
%put settings node guid = &settingsNodeGuid;

%dmcas_fetchDataset(&settingsNodeGuid, &dm_nodedir, ecm_user_settings);

/*
proc print data=work.NODES; run;
proc print data=&dm_lib..ecm_user_settings; run;
*/

data _null_;
	set &dm_lib..ecm_user_settings;
	call symput(trim(name), value);
run;

/*** Internal, project-wide macro variables ***/
%let ecm_countTable       = ecm_LossCounts;
%let ecm_freq_target      = ecm_numloss;
%let ecm_matchedLossTable = ecm_MatchedLosses;
%let ecm_ByGrpInfoDS	  = ecm_ByGrpInfo;

/* 
proc print data=&dm_metadata; run; 
%put =============== All Macros ================;
%put _all_;
*/

%let debugThis = 1;

/*** Get target variable name ***/
* NOTE: cannot use %dm_dec_target because it gives an n-literal name that cannot be used in action call from PROC CAS;
%dmcas_varmacro(name=dm_targetPlain, metadata=&dm_metadata, key=NAME, where=(ROLE='TARGET'), 
                nummacro=dm_num_targetPlain, quote=N, comma=N);
%if "&debugThis" ne "" %then %do;
	%put n_target = &dm_num_targetPlain;
	%put target = %dm_targetPlain;
%end;

%let ecm_sev_target = %scan(%dm_targetPlain, 1);

/*** Get interval input variable names ***/
%dmcas_varmacro(name=dm_interval_inputNoQ, metadata=&dm_metadata, key=NAME, where=(ROLE='INPUT' and LEVEL = 'INTERVAL'),
                nummacro=dm_num_interval_inputNoQ, quote=N, comma=N); 	   
%if "&debugThis" ne "" %then %do;
	%put num interval input = &dm_num_interval_inputNoQ;
	%put interval input = %dm_interval_inputNoQ;
%end;

%let ecm_intervalInput = %dm_interval_inputNoQ;

/*** Get CLASS input variable names ***/
%dmcas_varmacro(name=dm_class_inputNoQ, metadata=&dm_metadata, key=NAME, where=(ROLE='INPUT' and LEVEL NE 'INTERVAL'), 
                nummacro=dm_num_class_inputNoQ, quote=N, comma=N); 	  
%if "&debugThis" ne "" %then %do;
	%put num class input = &dm_num_class_inputNoQ;
	%put class input = %dm_class_inputNoQ;
%end;

%let ecm_classInput = %dm_class_inputNoQ;

/*** Get BY variable names from SEGMENT roles ***/
* cannot use %dm_segment because it gives an n-literal name;
** Get unquoted list without n-literals for use with PROCs;
%dmcas_varmacro(name=dm_segmentPlain, metadata=&dm_metadata, key=NAME, where=(ROLE='SEGMENT'), 
                nummacro=ecm_nbyvars, quote=N, comma=N);
** Get quoted list for use with actions;
%dmcas_varmacro(name=dm_segmentPlainQL, metadata=&dm_metadata, key=NAME, where=(ROLE='SEGMENT'), 
                nummacro=dm_num_segmentPlainQL, quote=Y, comma=Y);
%let ecm_byvars = %dm_segmentPlain;
%let ecm_byvars_csqlist = %dm_segmentPlainQL;

%if "&debugThis" ne "" %then %do;
	%put num segment = &ecm_nbyvars;
	%put segment = &ecm_byvars;
	%put num segment ql = &dm_num_segmentPlainQL;
	%put segment ql = &ecm_byvars_csqlist;
%end;

%local i joinCondition;
%do i=1 %to &ecm_nbyvars;
	%local ecm_byvar&i;
	%let ecm_byvar&i = %scan(&ecm_byvars, &i, " ");
	%put BY variable &i : &&ecm_byvar&i;
	%if &i=1 %then
		%let joinCondition=%str(ta.&&ecm_byvar&i=tb.&&ecm_byvar&i);
	%else
		%let joinCondition=%str( and ta.&&ecm_byvar&i=tb.&&ecm_byvar&i);
%end;
%let ecm_lastByVar = &&ecm_byvar&ecm_nbyvars;

/*** Get time id variable name ***/
%dmcas_varmacro(name=dm_timeidPlain, metadata=&dm_metadata, key=NAME, where=(ROLE='TIMEID'), 
                nummacro=dm_num_timeidPlain, quote=N, comma=N);
%if "&debugThis" ne "" %then %do;
	%put n_time = &dm_num_timeidPlain;
	%put time = %dm_timeidPlain;
%end;

%local local_timeid;
%let local_timeid = %scan(%dm_timeidPlain, 1);

%if "&debugThis" ne "" %then %do;
	%put target: &ecm_sev_target;
	%put interval inputs: &ecm_intervalInput;
	%put class (non-interval) inputs: &ecm_classInput;
	%put BY vars plain: &ecm_byvars;
	%put BY vars comma-separated, quoted list: &ecm_byvars_csqlist;
	%put time id: &local_timeid;
%end;

proc tsmodel data=&dm_data
			 out=&dm_datalib.._tmp_ecm_aggcount;
	by &ecm_byvars;
	id &local_timeid interval=&ecm_user_periodOfInterest accumulate=avg setmiss=0;
	var &ecm_intervalInput;
	%if &dm_num_class_inputNoQ > 0 %then %do;
		var &ecm_classInput / accumulate=maximum;
	%end;
	var &ecm_sev_target / accumulate=n;
run;

/* Compute matched losses */
proc tsmodel data=&dm_data out=&dm_datalib.._tmp_ecm_aggsev;
	by &ecm_byvars;
	id &local_timeid interval=&ecm_user_periodOfInterest accumulate=sum setmiss=0;
	var &ecm_sev_target;
run;

proc cas;
%if "&debugThis" ne "" %then %do;
	tabledetails / name="_TMP_ECM_AGGCOUNT", level="node";
%end;
	/* Shuffle to improve count modeling performance, because
	   TSMODEL puts one BY group on one node */
	droptable / name="&ecm_countTable", quiet=True;
    table.shuffle / table={name="_TMP_ECM_AGGCOUNT"}, 
		casout={name="&ecm_countTable", promote=TRUE};
	droptable / name="_TMP_ECM_AGGCOUNT";
	
%if "&debugThis" ne "" %then %do;
	tabledetails / name="&ecm_countTable", level="node";
%end;

	altertable / name="&ecm_countTable",
		columns={{name="&ecm_sev_target",rename="&ecm_freq_target"},
				 {name="&local_timeid", drop=True}};
run;

%if "&debugThis" ne "" %then %do;
	tabledetails / name="_TMP_ECM_AGGSEV", level="node";
	droptable / name="&ecm_ByGrpInfoDS", quiet=True;
%end;
    simple.groupByInfo /
      includeDuplicates=false,
      generatedColumns={"GROUPID"},
      noVars=true,
      casOut={name="&ecm_ByGrpInfoDS"},
      table={groupBy={&ecm_byvars_csqlist}, name="_TMP_ECM_AGGSEV"};
run;

	tableInfo result=r / table="&ecm_ByGrpInfoDS";
%if "&debugThis" ne "" %then %do;
	print r;
%end;
	symputx("ecm_nByGrp", r.TableInfo[1,"Rows"], 'G');
run;

	fedsql.execdirect / query="create table _TMP_ECM_AGGSEV_ONEBYVAR {options replace=true} as
      select ta.&local_timeid, ta.&ecm_sev_target, 
             cast('Marginal'||trim(put(tb._GroupID_,12. -L)) as varchar) as Marginal
      from _TMP_ECM_AGGSEV ta, &ecm_ByGrpInfoDS tb
      where &joinCondition";
      /* cntl={nowarn=True}; nowarn=True suppresses NVARCHAR to VARCHAR conversion 
                             warning for 'Marginal' computation */
	droptable / name="_TMP_ECM_AGGSEV";
	
%if "&debugThis" ne "" %then %do;
	columnInfo result=r / table="_TMP_ECM_AGGSEV_ONEBYVAR";
	print r;
%end;
run;

	/* Transpose to get aggregated values of all groups in one row. */
	droptable / name="&ecm_matchedLossTable", quiet=True;
	transpose.transpose / table={name="_TMP_ECM_AGGSEV_ONEBYVAR", groupby="&local_timeid"},
	                      id={"Marginal"}, transpose={"&ecm_sev_target"}, 
                          casout={name="&ecm_matchedLossTable", promote=True};
	droptable / name="_TMP_ECM_AGGSEV_ONEBYVAR";
	altertable / name="&ecm_matchedLossTable", 
		columns={{name="_name_", drop=True},
				 {name="&local_timeid", drop=True}};
%if "&debugThis" ne "" %then %do;
	tabledetails / name="&ecm_matchedLossTable", level="node";
%end;

quit;

proc datasets lib=&dm_datalib;
quit;


/*** Prepare a table of project-wide, internal macro variable values ***/
proc sql noprint ;
	create table ecm_tmp_macrovars as 
		select name, value from dictionary.macros 
		where (substr(name, 1, 3) = 'ECM');
quit;

%dmcas_addDataset(&dm_projectId, work, ecm_tmp_macrovars);

data work.&ecm_ByGrpInfoDS;
	set &dm_datalib..&ecm_ByGrpInfoDS;
run;
%dmcas_addDataset(&dm_projectId, work, &ecm_ByGrpInfoDS);

%exit:
;
