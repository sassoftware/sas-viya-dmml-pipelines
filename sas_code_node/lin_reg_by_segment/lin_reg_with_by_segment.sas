/*-----------------------------------------------------------
* Project: 		VDMML
* Author: 		SAS CZE,Jaroslav.Pulpan@sas.com
* Module name:	lin_reg_with_by_segment
* Purpose:		SAS Code node for SAS Model Studio v3.5 project 
*				that runs PROC REGSELECT with BY statement 
*				set to project variable having role SEGMENT
*
* Major changes: 
*	2020-11-10 - initial coding for Assisto
*-----------------------------------------------------------*/

/* ---------------------start of score code ----------------------------- */
/*Add following code (uncomented) to score window of the SAS Code node) */
/*%include "&score_file";*/
/* ---------------------end of score code ----------------------------- */


/* ---------------------start of Train code ----------------------------- */
/*optionally print SAS Model Studio all variables*/
/*proc print data=&dm_projectmetadata;*/
/*run;*/

/* search for target */
%dmcas_varmacro(name=target_var_macro, metadata=&dm_metadata, key=NAME,  where=(ROLE='TARGET'), quote=N, comma=N); 
/* select first target */
%let target_var = %scan(%target_var_macro,1);  

/* define segment */
%dmcas_varmacro(name=segment_var_macro, metadata=&dm_metadata, key=NAME,  where=(ROLE='SEGMENT'), quote=N, comma=N); 
/* select first target */
%let segment_var = %scan(%segment_var_macro,1);  

/* score code location */
%let score_file=&dm_nodedir&dm_dsep.LR_BY_SCORE_&dm_nodeid..sas;
%put score_file:&score_file;

/* ---------------------LR with BY segment_var ----------------------------- */
%let class_vars=%dm_binary_input %dm_nominal_input %dm_ordinal_input;
%let model_vars=%dm_interval_input &class_vars;

%put ==============================;
%put Variables to be used for LR:;
%put ==============================;
%put target_var:&target_var;
%put class_vars:&class_vars;
%put dm_interval_input:%dm_interval_input;
%put segment_var:&segment_var;
%put ==============================;


proc regselect data=&dm_data;
	%if %length(&dm_partition_valid_val) ne 0 %then %do;
		/* 	if validation partition exists do selection validation by validate partition */
    	partition roleVar=&dm_partitionvar
    		(
    			train="&dm_partition_train_val"
	    		validate="&dm_partition_valid_val" 
	    		%if %length(&dm_partition_test_val) ne 0 %then %do;
	    			test="&dm_partition_test_val"
	    		%end;
    		);
    %end;
    class &class_vars;
    model &target_var =  &model_vars/stb;
    selection method = stepwise(select=sl sle=0.1 sls=0.15 
    							%if %length(&dm_partition_valid_val) ne 0 %then %do;
    								choose=validate
    							%end;
    							)
			/*                        hierarchy=single  */
			/*                        details=steps  */
                       plots(startstep=5)=all;
    by &segment_var;
    code  file="&score_file";
 run;
/* ---------------------end of train code ----------------------------- */
 
/* ---------------------start of score code ----------------------------- */
/*Add following code (uncomented) to score window of the SAS Code node) */
/*%include "&score_file";*/
/* ---------------------end of score code ----------------------------- */
 
 
