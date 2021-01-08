/*-----------------------------------------------------------
* Project: 		VDMML games
* Author: 		SAS CZE,Jaroslav.Pulpan@sas.com
* Module name:	bin_model_plot_assessments
* Purpose:		plot/print assesment of several models/roles of binary target
*
* TBA:
* 	-best/random model see https://support.sas.com/kb/41/683.html
*	-other zoo of tresholds/grapgs see 
*		https://towardsdatascience.com/the-ultimate-guide-to-binary-classification-metrics-c25c3627dd0a#42a0
*	-target info from VDMML dm_target dataset
*	-optional group/by of model_id role_id
* Major changes: 
*	2020-11-19 - updated from KS charts macro for CAS VDMML procs
*	2021-01-05 - added more graph types
*-----------------------------------------------------------*/
%macro bin_model_plot_assessments(
/*binary target */
	target_var=BAD				/*name of the binary target*/
	,event_val=1				/*event value of TARGET */
	,nonevent_val=0				/*non event value of TARGET */
/*scored data inputs */
	,inds_list=					/*list of dataset with scored model*/
	,inds_label_list=			/*list of labels to be used for plots/fits stats*/
/*variables in inputs */
	,p_event_var=p_bad1			/*variable with predicted probablity of event */
	,p_nonevent_var=p_bad0		/*variable with predicted probablity of nonevent */
	,partition_var=_partind_	/*name of the variable with partiton identification*/
	,partition_values_list=1|0	/*values of partition_var*/
	,partition_values_label_list=|train|validate|
/*variables to be added to graph dataset*/
	,model_id_var=Model
		/*	name of the variable with model identification (generated from INDS_LABEL_LIST)*/
	,Role_id_var=Role
		/*	name of the variable with role identification (generated from partition_values_label_list)*/
	,model_role_id_var=Model_Role
		/*	name of the variable combination fo mode ID and role ID */
	/*	labels for partitions values PARTITION_VALUES_LIST*/
	,NBINS=50 
	/*specifies the number of bins to be used in the lift calculation, where integer must be an integer greater than or equal to 2*/
	,NCUTS=100
		/*specifies the number of cuts to be used in the ROC calculation, NCUTS=10 generates 10 intervals*/
	,graphs_by_var=Role
/*			plot separate graphs by values of GRAPHS_BY_VAR , if empty all lines are on one graph*/
/*			(use name from ROLE_ID_VAR or name from MODEL_ID_VAR or name from MODEL_ROLE_ID_VAR)*/
	,graphs_group_var=model
		/*	plot separate line on for each values GRAPHS_GROUP_VAR, , if empty all lines are on separated graphs*/
		/*	(use name from ROLE_ID_VAR or name from MODEL_ID_VAR or name from MODEL_ROLE_ID_VAR)*/
)/  des='plot/print assesment of several models/roles of binary target';

%local i inds n_inds;
%let n_inds=%sysfunc(countw(&inds_list,%str( )));

%put &n_inds;
%do i=1 %to &n_inds;
	%let inds=%scan(&inds_list,&i,%str(% ));
	%put &inds;
	/*-------------------------------------------*/
	/*	process all input ds by assess procedure */
	/*-------------------------------------------*/
	ods select none;
	proc assess data=&inds
		NBINS=&nbins 
		NCUTS=&ncuts
	;
		 input &p_event_var  ;
		 target &target_var/  level=nominal event="&event_val";
		 fitstat pvar=&p_nonevent_var / pevent="&nonevent_val";
		 by &partition_var;

		 ods output
			 fitstat=_fitstat_&i
			  rocinfo=_rocinfo_&i
			 liftinfo=_liftinfo_&i
	;
	run;
	ods select all;
%end;


%macro set_model_id_in_ds_list(
/*---------------------------------------------------------------*/
/*combine all assesment data + add model_ID role_ID model_rols_id */
/*---------------------------------------------------------------*/
	ds_prefix
);
%local i ;

data _all&ds_prefix;
  	set 
		%do i= 1 %to &n_inds;
			&ds_prefix.&i (in=in&i)
		%end;
	;
	by  &partition_var;  
	/*	add model ID*/
	length &model_id_var $64;
	%do i= 1 %to  &n_inds;
		if in&i then &model_id_var="%scan(&inds_label_list,&i,|)";
	%end;

	length &model_id_var $ 64;
	/*	convert partition id to role name*/
	%do i= 1 %to %sysfunc(countw(&partition_values_list,|));
		if &partition_var eq %scan(&partition_values_list,&i,|) then &role_id_var="%scan(&partition_values_label_list,&i,|)";
	%end;

	length &model_role_id_var $64;
	&model_role_id_var=strip(&model_id_var) ||'('||strip(&role_id_var)||')';
%mend set_model_id_in_ds_list;

%macro group_by_graph();
		%if %length(&graphs_by_var) eq 0 %then %do;
			group=&model_role_id_var 
		%end;
		%else %if %length(&graphs_group_var) ne 0 %then %do;
			group=&graphs_group_var 
		%end;
	;

	%if %length(&graphs_group_var) eq 0 %then %do;
		by &model_role_id_var notsorted;
	%end;
		%else %if %length(&graphs_by_var) ne 0 %then %do;
		by &graphs_by_var notsorted;
	%end;
%mend group_by_graph;

/*=================*/
/*FITSTAT*/
/*=================*/
%set_model_id_in_ds_list(_fitstat_);
title "Fit statistics by model and role ";
proc print 
	data=_all_fitstat_ (drop =&partition_var &model_role_id_var)
	label ;
	id &model_id_var &role_id_var;
run;

/*=================*/
/*LIFTINFO*/
/*=================*/
%set_model_id_in_ds_list(_liftinfo_);

proc sort data=_all_liftinfo_;
	%if %length(&graphs_by_var) eq 0 %then %do;
		by &model_role_id_var;
	%end;
	%else %do;
		by &graphs_by_var;
	%end;
run;

/* Draw lift charts */   
proc sgplot data=_all_liftinfo_; 
	title "Lift Chart (using validation data)";
	yaxis label=' ' grid;
	series x=depth y=lift / 
		markers markerattrs=(symbol=circlefilled)
	%group_by_graph();
run;


/*=================*/
/*ROCINFO*/
/*=================*/
%set_model_id_in_ds_list(_rocinfo_);
/* Print AUC (Area Under the ROC Curve) */

title "AUC (using validation data) ";
proc sql;
	select distinct 
		&model_id_var
		, &role_id_var
		,c 
	from 
		_all_rocinfo_ 
	order by 
		&role_id_var
		,c desc;
quit;

proc sort data=_all_rocinfo_;
	%if %length(&graphs_by_var) eq 0 %then %do;
		by &model_role_id_var;
	%end;
	%else %do;
		by &graphs_by_var;
	%end;
run;

/* Draw ROC charts */ 
proc sgplot data=_all_rocinfo_ aspect=1;
  title "ROC Curve (using validation data) ";
  xaxis values=(0 to 1 by 0.25) grid offsetmin=.05 offsetmax=.05; 
  yaxis values=(0 to 1 by 0.25) grid offsetmin=.05 offsetmax=.05;
  lineparm x=0 y=0 slope=1 / transparency=.7;
  series x=fpr y=sensitivity / 		
	%group_by_graph();
run;


/* Plot specific rates <-- HTML output */
proc sgplot data=_all_rocinfo_; 
  title "Sensitivity";
	series x=cutoff y=Sensitivity/ 
	%group_by_graph();
run;

proc sgplot data=_all_rocinfo_; 
  title "Specificity";
  series x=cutoff y=Specificity/ 
	%group_by_graph();
run;

proc sgplot data=_all_rocinfo_; 
  title "False Positive rate ";
  series x=cutoff y=FPR/ 
	%group_by_graph();
run;

proc sgplot data=_all_rocinfo_; 
  title "Accuracy";
  series x=cutoff y=Acc/ 
	%group_by_graph();
run;


%mend bin_model_plot_assessments;

%macro t_bin_model_plot_assessments();
	%if %symexist(global_skip_test) eq 0 %then
		%return;
	%put ********************************************************;
	%put * loading test code: &SYSMACRONAME;
	%put ********************************************************;

	%if &global_skip_test eq 1 %then
		%return;


options mprint mlogic nosymbolgen;
/*options nomprint nomlogic nosymbolgen;*/

%global global_skip_test;
%let global_skip_test=0;
libname hashsas "c:\ajps\_sas-courses\hashsas\data\";
%let ds=hashsas.accepts;

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
cas;
caslib _all_ assign;
data casuser.accepts0;
set hashsas.accepts;
run;

proc partition data=casuser.accepts0 partition samppct=70 seed=12345;
/* by b_tgt;*/
 output out=casuser.accepts copyvars=(_ALL_);
run;

proc freq;
table _partind_;
run;

/*develop models*/
proc treesplit data=casuser.accepts     outmodel=casuser.tree_model;;
 input bureau_score loan_amt / level=interval;
/* input &class_inputs. loan_amt / level=nominal;*/
 target bad/ level=nominal;
 partition rolevar=_partind_(train='1' validate='0');
 grow entropy;
 prune c45;
/* code file="c:/temp/treeselect_score_bin.sas";*/
run;
proc gradboost data=casuser.accepts ntrees=10 intervalbins=20 maxdepth=5 
               outmodel=casuser.gb_model;
  input bureau_score loan_amt  rev_util / level = interval;
/*  input &class_inputs. / level = nominal;*/
  target bad / level=nominal;
  partition rolevar=_partind_(train='1' validate='0');
run;

/*score models*/
proc treesplit data=casuser.accepts inmodel=casuser.tree_model;
  output out=casuser.tree_scored copyvars=(_ALL_);
run; 

proc gradboost  data=casuser.accepts inmodel=casuser.gb_model;
  output out=casuser.gb_scored copyvars=(_ALL_);
run; 

%bin_model_plot_assessments(
/*binary target */
	target_var=BAD				/*name of the binary target*/
	,event_val=1				/*event value of TARGET */
	,nonevent_val=0				/*non event value of TARGET */
/*scored data inputs */
	,inds_list=	casuser.gb_scored casuser.tree_scored
		/*list of dataset with scored model*/
	,inds_label_list=|Gradient Boosting|Decision Tree (C45/Entropy)|
				/*list of labels to be used for plots/fits stats*/
/*variables in inputs */
	,p_event_var=p_bad1			/*variable with predicted probablity of event */
	,p_nonevent_var=p_bad0		/*variable with predicted probablity of nonevent */
	,partition_var=_partind_	/*name of the variable with partiton identification*/
	,partition_values_list=1|0	/*values of partition_var*/
	,partition_values_label_list=|train|validate|
	/*	labels for partitions values PARTITION_VALUES_LIST*/
	,model_id_var=Model_name
		/*	name of the variable with model identification (generated from INDS_LABEL_LIST)*/
	,Role_id_var=Role_name
		/*	name of the variable with role identification (generated from partition_values_label_list)*/
	,model_role_id_var=Model_Role_cross
	,graphs_by_var=
	/*Role_name*/
/*			plot separate graphs by values of GRAPHS_BY_VAR , if empty all lines are on one graph*/
/*			(use name from ROLE_ID_VAR or name from MODEL_ID_VAR or name from MODEL_ROLE_ID_VAR)*/
	,graphs_group_var=Model_name
		/*	plot separate line on for each values GRAPHS_GROUP_VAR, , if empty all lines are on separated graphs*/
		/*	(use name from ROLE_ID_VAR or name from MODEL_ID_VAR or name from MODEL_ROLE_ID_VAR)*/
);


%mend t_bin_model_plot_assessments;

%t_bin_model_plot_assessments();
