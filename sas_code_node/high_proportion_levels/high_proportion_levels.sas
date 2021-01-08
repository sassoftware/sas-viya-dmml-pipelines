/* SAS code */
/*-----------------------------------------------------------
* Project: 		VDMML code nodes
* Author: 		SAS CZE,Jaroslav.Pulpan@sas.com
* Module name:	high_proportion_levels
* Purpose:		find values with high/low proportion 
*				to be used for setting rejected variables or collapsing rare levels
* Major changes: 
*	2020-11-16 - inital coding for Assisto
*-----------------------------------------------------------*/
%macro high_proportion_levels(
	inds=				/*	input dataset, should be in CAS library, default =&DM_DATA*/
	,varlist=			/*list of variables to be scanned*/
						/*	default= %dm_interval_input %dm_binary_input %dm_nominal_input %dm_ordinal_input*/
	,missing=1			/*	include missing values to analysis of proportions*/
	,sample_proportion=0.1			/*	if not empty INDS will be sampled before analyzing proportion */
	,pct_treshold_high_proportion=4	/*proportion [%] of variable values/(class levels) to be selected as high proportion one */
	,pct_treshold_rare_proportion=		/*proportion [%] of variable values/(class levels) to be selected as rare values */
	,caslib=casuser					/*	CASLIB to be used for intermediate tables/results*/
	,verbose =1						/*	print identified high proportion levels*/
	,prefix_hp_global_mvars=__hp_	/*	prefix of returned global macrovars with list of identified leveles*/
						/*	if not empty generates macrovars with names like __hp_ORIGINAL_VAR*/
	,prefix_rare_global_mvars=__rare_	/*	prefix of returned global macrovars with list of identified leveles*/
						/*	if not empty generates macrovars with names like __rare_ORIGINAL_VAR*/
	,separator_returned_lists=|			/*	separator for values in returned macrovars*/
	,list_of_hp_vars=high_proportion_vars		/*	name of global macrovar with list of macrovars having identified hp levels*/
	,list_of_rare_vars=rare_proportion_vars	/*	name of global macrovar with list of macrovars having identified hp levels*/
	,score_high_proportion=1		/*	flag requesting score code generation that will pass all non high frequency levels to rare group*/
	,rare_group_str=_rare_			/*	label for rare group of character variables*/
	,rare_group_num=99999999		/*	label for rare group of numeric variables*/
)/  des='find values with high/low proportion ';

%local sample_ds i var mvar ret_list;

%if %length(&inds) eq 0 %then %do;
	%let inds=&dm_datalib..&dm_memname;
	%put &inds;
%end;
%if %length(&varlist) eq 0 %then %do;
	%dmcas_varmacro(name=dm_binary_inputNoQ, metadata=&dm_metadata, key=NAME
					, where=(ROLE='INPUT' and LEVEL = 'BINARY'), nummacro=dm_num_binary_inputNoQ, quote=N, comma=N); 	  
	%dmcas_varmacro(name=dm_ordinal_inputNoQ, metadata=&dm_metadata, key=NAME
					, where=(ROLE='INPUT' and LEVEL = 'ORDINAL'), nummacro=dm_num_ordinal_inputNoQ, quote=N, comma=N); 	  
	%dmcas_varmacro(name=dm_nominal_inputNoQ, metadata=&dm_metadata, key=NAME
					, where=(ROLE='INPUT' and LEVEL = 'NOMINAL'), nummacro=dm_num_nominal_inputNoQ, quote=N, comma=N); 	  
	%let varlist=%DM_BINARY_INPUTNoQ %DM_NOMINAL_INPUTNoQ %DM_ORDINAL_INPUTNoQ;
	%put &varlist;
%end;


%if %length(&sample_proportion) ne 0 %then %do;
	%let sample_ds=&dm_datalib..__sample;
	proc PARTITION data=&inds samppct=10 ;
	 output out=&sample_ds ;
	run;
%end;
%else %do;
	%let sample_ds=&inds;
%end;

/*
*naive run with sample dataset;
ods html close;
ods output clear;
ods output    NLevels= casuser.NLevels_sample;
	proc freqtab data=&sample_ds NLevels missing ;
	tables &varlist;
	run;
ods html;
*/

/*generate list of levels table usin CAS procedure FREQTAB*/
proc freqtab 
	data=&sample_ds 
	noprint 
	%if &missing eq 1 %then %do;
		missing
	%end;
;
%do i=1 %to %sysfunc(countw(&varlist));
	%let var=%scan(&varlist,&i);
	tables &var 		/out=&caslib..&var nocum;
%end;
run;


/*	High frequency  levels*/
%if %length(&pct_treshold_high_proportion) ne 0 %then %do;
	%global &list_of_hp_vars;
	%let &list_of_hp_vars=;
	%do i=1 %to %sysfunc(countw(&varlist));
		%let var=%scan(&varlist,&i);
		proc sql noprint;
			select 
				&var 
					into :ret_list separated by "&separator_returned_lists"
			from
				&caslib..&var
			where 
				percent ge &pct_treshold_high_proportion
		;
		quit;
		%if &sqlobs ne 0 %then %do;
			/*	define global macrovar to be returned */
			%let  mvar=&prefix_hp_global_mvars.&var ;
			%global &mvar;
			%let &mvar=&ret_list;
			%put global mvar set &mvar:&&&mvar ;
			%let &list_of_hp_vars=&&&list_of_hp_vars &var;

			%if &verbose eq 1 %then %do;
				title "high frequency levels for variable &VAR";
				title2 "pct_treshold_high_proportion: &PCT_TRESHOLD_HIGH_PROPORTION";
				proc print data=&caslib..&var ;
				where percent ge &pct_treshold_high_proportion;
				run;
			%end;
		%end;
	%end;
	%put Lists of vars with high frequency levels set to macrovar &list_of_hp_vars:&&&list_of_hp_vars;
%end;

/*	rare levels*/
%if %length(&pct_treshold_rare_proportion) ne 0 %then %do;
	%global &list_of_rare_vars;
	%let &list_of_rare_vars=;
	%do i=1 %to %sysfunc(countw(&varlist));
		%let var=%scan(&varlist,&i);
		proc sql noprint;
			select 
				&var 
					into :ret_list separated by "&separator_returned_lists"
			from
				&caslib..&var
			where 
				percent le &pct_treshold_rare_proportion;
		;
		quit;
		%if &sqlobs ne 0 %then %do;
			/*class levels) selected as rare values */
			%let  mvar=&prefix_rare_global_mvars.&var ;
			%global &mvar;
			%let &mvar=&ret_list;
			%put global mvar set &mvar:&&&mvar ;
			%let &list_of_rare_vars=&&&list_of_rare_vars &var;

			%if &verbose eq 1 %then %do;
				title "rare levels for variable &VAR";
				title2 "pct_treshold_rare_proportion: &PCT_TRESHOLD_RARE_PROPORTION";
				proc print data=&caslib..&var ;
				where percent le &pct_treshold_rare_proportion;
				run;
			%end;
		%end;
	%end;
	%put Lists of vars with rare levels set to macrovar &list_of_rare_vars:&&&list_of_rare_vars;
%end;


%if &score_high_proportion ne 0 %then %do;
	/*	score code generation that will pass all non high frequency levels to rare group*/

	/*	find out numerical variables*/
	proc sql;
		select 
			name into :num_vars separated by "|"
		from 
			&dm_projectmetadata
		where type="N"
	;
	quit;

	/* score code location */
	%global score_file;
	%let score_file=&dm_dsep.home&dm_dsep.&SYSUSERID.&dm_dsep.high_proportion_levels.sas;
/* 	%let score_file=/home/sasdemo/high_proportion_levels_score.sas;	 */
	%put score_file:&score_file;

	/*generate score code*/
	data _null_;
	file "&score_file";
		%local level i ii;
		%do i=1 %to %sysfunc(countw(&&&list_of_hp_vars));
		%let var=%scan(&&&list_of_hp_vars,&i);
			put "select (&var);";
				%let mvar=&prefix_hp_global_mvars.&var;
				%do ii=1 %to %sysfunc(countw(&&&mvar,|));
					%let level=%scan(&&&mvar,&ii,|);
					/*find out type of variable*/
					%if %sysfunc(findw(&num_vars,&var,|)) eq 0 %then %do;
						/*char var*/
				   		put "when ('&level')   &var=&var;";
					%end;
					%else %do;
				   		put "when (&level)   &var=&var;";
					%end;
				%end;
				/*find out type of variable*/
				%if %sysfunc(findw(&num_vars,&var,|)) eq 0 %then %do;
						/*char var*/
						put "otherwise	&var='&rare_group_str';";
				%end;
				%else %do;
						put "otherwise   &var=&rare_group_num;";
				%end;
			put "end;";
		%end;
	run;
%end;

%if &verbose eq 1 %then %do;
	/* show generated score code */
	data _null_;
		infile "&score_file";
		input;
		put _infile_;
	run;
%end;

%mend high_proportion_levels;

%macro t_high_proportion_levels();
/*test outside VDMML*/
options mprint mlogic nosymbolgen;
options nomprint nomlogic nosymbolgen nonotes;

libname hashsas "c:\ajps\_sas-courses\hashsas\data\";
%let ds=hashsas.accepts;
cas;
caslib _all_ assign;
data casuser.accepts;
set hashsas.accepts;
run;
%let ds=casuser.accepts;
/*"Column Name", "Type", "Length", "Format", "Informat", "Label", "Transcode",*/
/*"bankruptcy", "Number", "8", "", "", "", "No",*/
/*"bad", "Number", "8", "", "", "", "No",*/
/*"app_id", "Number", "8", "", "", "", "No",*/
/*"tot_derog", "Number", "8", "", "", "", "No",*/
/*"tot_tr", "Number", "8", "", "", "", "No",*/
/*"age_oldest_tr", "Number", "8", "", "", "", "No",*/
/*"tot_open_tr", "Number", "8", "", "", "", "No",*/
/*"tot_rev_tr", "Number", "8", "", "", "", "No",*/
/*"tot_rev_debt", "Number", "8", "", "", "", "No",*/
/*"tot_rev_line", "Number", "8", "", "", "", "No",*/
/*"rev_util", "Number", "8", "", "", "", "No",*/
/*"bureau_score", "Number", "8", "", "", "", "No",*/
/*"purch_price", "Number", "8", "", "", "", "No",*/
/*"msrp", "Number", "8", "", "", "", "No",*/
/*"down_pyt", "Number", "8", "", "", "", "No",*/
/*"purpose", "Text", "5", "", "", "", "Yes",*/
/*"loan_term", "Number", "8", "", "", "", "No",*/
/*"loan_amt", "Number", "8", "", "", "", "No",*/
/*"ltv", "Number", "8", "", "", "", "No",*/
/*"tot_income", "Number", "8", "", "", "", "No",*/
/*"used_ind", "Number", "8", "", "", "", "No",*/
/*"weight", "Number", "8", "", "", "", "No",*/

/*ods trace on;*/
ods trace off;
%high_proportion_levels(
	inds=&ds				/*	input dataset, default =&DM_DATA*/
	,varlist=	app_id	purch_price 	loan_term bankruptcy age_oldest_tr /*list of variables to be scanned*/
						/*	default= %dm_interval_input %dm_binary_input %dm_nominal_input %dm_ordinal_input*/
	,sample_proportion=0.01		/*	if not empty INDS will be sampled before analyzing proportion, skippped whe */
	,pct_treshold_high_proportion=2	/*proportion  of variable values/(class levels) to be selected as high proportion one */
	,verbose =1						/*	print identified high proportion levels*/
);

%mend t_high_proportion_levels;

/*

%t_high_proportion_levels();

*/

options mprint mlogic nosymbolgen;
options nomprint nomlogic nosymbolgen nonotes;
%high_proportion_levels(
	inds=				/*	input dataset, should be in CAS library, default =&DM_DATA*/
	,varlist=			/*list of variables to be scanned*/
						/*	default= %dm_interval_input %dm_binary_input %dm_nominal_input %dm_ordinal_input*/
	,missing=1			/*	include missing values to analysis of proportions*/
	,sample_proportion=		/*	if not empty INDS will be sampled before analyzing proportion */
	,pct_treshold_high_proportion=4	/*proportion [%] of variable values/(class levels) to be selected as high proportion one */
	,pct_treshold_rare_proportion=2		/*proportion [%] of variable values/(class levels) to be selected as rare values */
	,caslib=casuser					/*	CASLIB to be used for intermediate tables/results*/
	,verbose =1						/*	print identified high proportion levels*/
	,prefix_hp_global_mvars=__hp_	/*	prefix of returned global macrovars with list of identified leveles*/
						/*	if not empty generates macrovars with names like __hp_ORIGINAL_VAR*/
	,prefix_rare_global_mvars=__rare_	/*	prefix of returned global macrovars with list of identified leveles*/
						/*	if not empty generates macrovars with names like __rare_ORIGINAL_VAR*/
	,separator_returned_lists=|			/*	separator for values in returned macrovars*/
	,list_of_hp_vars=high_proportion_vars		/*	name of global macrovar with list of macrovars having identified hp levels*/
	,list_of_rare_vars=rare_proportion_vars	/*	name of global macrovar with list of macrovars having identified hp levels*/
	,score_high_proportion=1		/*	flag requesting score code generation that will pass all non high frequency levels to rare group*/
	,rare_group_str=_rare_			/*	label for rare group of character variables*/
	,rare_group_num=99999999		/*	label for rare group of numeric variables*/
);


/* ---------------------end of train code ----------------------------- */
 
/* ---------------------start of score code ----------------------------- */
/*Add following code (uncommented) to score window of the SAS Code node) */
/* %include "/home/&SYSUSERID./high_proportion_levels.sas"; */
/* ---------------------end of score code ----------------------------- */
 
