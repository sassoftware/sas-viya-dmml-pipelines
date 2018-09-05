/*-------------------------------------------------------------------------*/
/* Copyright (c) 2017 by SAS Institute Inc., Cary, NC USA 27513            */
/* NAME:       Basic profiler (test code)                                  */
/* SUPPORT:    Ray Wright (ray.wright@sas.com)                             */
/* Created:    6/1/2017                                                    */
/* TYPE:       Portable                                                    */
/* PURPOSE:    profile clusters                                            */
/* Changes:                                                                */
/*-------------------------------------------------------------------------*/


%macro dmcas_basicProfile();




        /*get unquoted variable lists for CAS action call.*/
        
	%dmcas_varmacro(name=dm_interval_inputNoQ, metadata=&dm_metadata, key=NAME, where=(ROLE='INPUT' and LEVEL = 'INTERVAL'), nummacro=dm_num_interval_inputNoQ, quote=N, comma=N); 	   
	%dmcas_varmacro(name=dm_class_inputNoQ, metadata=&dm_metadata, key=NAME, where=(ROLE='INPUT' and LEVEL NE 'INTERVAL'), nummacro=dm_num_class_inputNoQ, quote=N, comma=N); 	  
	%dmcas_varmacro(name=dm_segmentNoQ, metadata=&dm_metadata, key=NAME,  where=(ROLE='SEGMENT'), quote=N, comma=N);
	

	%put dm_segNoQ =  %dm_segmentNoQ; 
	
	*use first segment var; 
	%let segVar = %scan(%dm_segmentNoQ,1); 
	
	
	data _null_;
		set &dm_metadata (where=(NAME = strip("&segVar.") ));
		call symput ('segVarType',strip(Type));
		call symput ('segVarFormat',strip(Format));
	run; 
		

	%put segment var type: &segVarType.; 
	%put segment var format: &segVarFormat.;
	
	

	/*find number of segments and size of largest segment*/
	proc cardinality data=&dm_data.
	    outdetails=&dm_casiocalib..details
	    /*outcard=&dm_casiocalib..card*/;
	    var &segVar.; 	    
	    %if &dm_freq. NE %str() %then
                  freq &dm_freq;
                ;
            performance details; 
	run;

	
	data clusterStats;
		set &dm_casiocalib..details  end = eof;
		if  eof then call symput  ('nClusters',strip(_n_));
	run; 

	proc sort data = clusterStats; by  _FREQ_; 

	data _null_;
		set clusterStats end = eof; 
		if eof then call symput('maxClusterN',_FREQ_);
	run; 


%put number of clusters: &nClusters.;
%put max cluster size: &maxClusterN.;

	

	/*bin interval inputs */

	proc binning
	    method=bucket  
	    binmapping = right
	    data = &dm_data.
	    numbin=8;
	    input %dm_interval_inputNoQ; 
	    output out=&dm_casiocalib..binnedInData copyvars=(%dm_class_inputNoQ &segVar.);
	    ods output binDetails = bins (where=(binID GT 0));
	run; 


	proc contents data = &dm_casiocalib..binnedInData;
		ods output Variables = BinVars ( where = (substr(Variable,1,4) = "BIN_"));
	run;


	data _null_;
		set BinVars end = eof;
		call symput('binOutVar'!!strip(put(_n_,3.0)),strip(Variable));
		if eof then call symput('nBinOutVars',strip(put(_n_,3.0)));
	run; 

	/*handle bins for missing values*/  
	data &dm_casiocalib..binnedInData /* binnedData */;
		set &dm_casiocalib..binnedInData;
		if not(missing(&segvar.));
		array binVars (&dm_num_interval_inputNoQ)
			%do  i = 1 %to &dm_num_interval_inputNoQ;
				&&binOutVar&i.
			%end; 	
		; 
		do i = 1 to dim(binVars);
			if binvars[i] = 0 then binvars[i] = .;
		end; 

		drop i; 
	run;         		


        /*get unquoted list of class and binned interval inputs */    		

	proc contents data = &dm_casiocalib..binnedInData ;
		ods output Variables=Variables;
	run;           		

	data inputs (keep = variable level role);
		set variables;
		LEVEL = "NOMINAL";
		ROLE="INPUT";
		if variable ne strip("&segVar.");
	run; 

	%dmcas_varmacro(name=dm_class_binned, metadata=inputs, key=VARIABLE, nummacro=dm_num_class_binned, quote=N, comma=N);
	%put class inputs with binned interval: %dm_class_Binned; 	     



	/*build crosstabulations (creates one CAS table for each pair of target and input) */

	Proc cas;

		%do i = 1 %to &dm_num_class_binned.;

		  %let currInput = %sysfunc(scan(%dm_class_binned,&i.));

		  Action simple.crossTab result=xTabs&i. /
		   table={name="binnedInData"}
		   row="&currInput."
		   col="&segVar."  
		   includeMissing=TRUE  
		   fullTable=TRUE
		   ;

		%end; 

	run;



/*weird bug: col1 is not properly labeled for character segment var.
other cols look fine. this messes up chart 
label is like 'abulation of BIN_CLAGE by JOB for BINNEDINDATA.' */

		%do i = 1 %to &dm_num_class_binned.;
		  saveresult xTabs&i. replace dataset=crosstabs&i.; 		                                                     
		%end;                                               

	  run;

	quit; 


	/*assemble the individual crosstabulations */
	data crosstabs; 
	    length variable $ 256; 
		length value $ 256;
		set 
			%do i = 1 %to &dm_num_class_binned.;
			    %let currInput = %sysfunc(scan(%dm_class_binned,&i.));
				crosstabs&i. (rename=(&currInput.=value) in=in&i.)
		    %end; 
	        ;

			%do i = 1 %to &dm_num_class_binned.;
			    %let currInput = %sysfunc(scan(%dm_class_binned,&i.));
				if in&i. then variable = "&currInput.";
			%end; 

	    value = strip(value); 
	    
	    label variable = 'Variable';
	    label value = 'Value'; 
	run; 



	data crosstabs;  
		retain variable value &segVar.;
		set 
			%do i = 1 %to &nClusters.;
			    %let currInput = %sysfunc(scan(%dm_class_binned,&i.));
			    crosstabs (in=in&i.) 
			%end; 
	      ; 

		%do i = 1 %to &nClusters.;
				if in&i. then 
					do;
						count = col&i.;
						
						%if &segVarType. = N and &segVarFormat. EQ %str() %then
							%do; 
							        &segVar.= input(vlabel(col&i.),8.);  
							%end;
						%else 
						        %do;
								&segVar. = vlabel(col&i.);
						        %end;
												 	
					end; 
			%end; 


                label &segVar. = "Segment";

		keep variable value count &segVar.; 
	run; 




	/* get totals for percent computation*/

	data &dm_casiocalib..crosstabs;
		set crosstabs; 
	run; 
 
	proc mdsummary table=&dm_casiocalib..crosstabs;
		groupby variable &segVar.; 
		var count; 
		output out=&dm_casiocalib..totals ;
	run;

	data totals (rename=(_sum_ = total)); 
		set &dm_casiocalib..totals;
		keep variable &segVar. _sum_;
	run; 

	proc sort data = totals ;
		by variable &segVar.; 
	run; 


	proc sort data = crosstabs;
		by variable &segVar.; 
	run; 


        /*compute percents */
	data crosstabs; 
		merge crosstabs totals;
		by variable &segVar.;

		freqPercent = count / total; 
	run; 


	proc sort data = crosstabs;
		by variable &segVar.; 
	run; 


	*create reports ;

	data &dm_lib..crosstabs;
		set crosstabs;
	run; 


	%dmcas_report(dataset=crosstabs, 
	              reportType=BarChart, 
	              byVar=Variable, 
	              category=value, 
	              response=freqPercent, 
	              group=&segVar., 
	              description=Variable Distributions by Segment);



	/*project clusters in 2D */

	%if &dm_num_interval_input. GE 2 %then /*projection is based on interval inputs only*/
		%do; 
	
			*find number obs in dataset for stratified sampling;
			%let dsid = %sysfunc(open(&dm_data.));
			%let nobs =%sysfunc(attrn(&dsid,nobs));
			%let rc = %sysfunc(close(&dsid));

			%put number of observations: &nObs.; 


			proc pca data=&dm_Data. n=2;
			    var %dm_interval_inputNoQ; 	/*need to incorporporate categorical inputs*/
			    %if &dm_freq ne %then %do;
				weight &dm_freq;
			    %end;

			    output out=&dm_casiocalib..outPC  score=prin copyvars=(&segVar.);
			    ods exclude corr cov eigenvalues eigenvectors;
			run; 


		       /*stratified sample within each cluster */
		       /*change this to calculate percentage not to exceed  N obs for largest cluster*/
		       /*this is not ideal because same percentage used for each cluster as it could choose few very samples for small clusters */

			*sample based on maxObs for largestcluster; 
			%let maxObs = 250; 
			%let sampPct = %sysevalf((&maxObs. / &maxClusterN.) * 100);

			%put sample percent: &sampPct; 


			%if %sysevalf(&sampPct. LT 100) %then 
				%do;
					 proc partition data=&dm_casiocalib..outPC sampPct = &sampPct.  seed = 12345;
					      by &segVar.;
					      output out=&dm_casiocalib..outPCSample copyvars=(&segVar. prin:);
					 run;
				%end; 


			/*projection plot */

			data &dm_lib..proj ;
				set 
				     %if %sysevalf(&sampPct LT 100) %then &dm_casiocalib..outPCSample;
					%else &dm_casiocalib..outPC;
				;
			run; 


			%dmcas_report(dataset=proj, 
				      reportType=Scatterplot, 
				      x=prin1, 
				      y=prin2, 
				      group=&segVar., 
				      description=%nrbquote(Cluster Projection));


		%end; 

	
%mend dmcas_basicProfile;


%dmcas_basicProfile; 
