/*-----------------------------------------------------------
* Project: 		VDMML games
* Author: 		SAS CZE,Jaroslav.Pulpan@sas.com
* Module name:	plot_pdf_interval_var
* Purpose:		plot histograms like step graphs based on percentiles and PDF
*
* Major changes: 
*	2020-11-19	percentile calculation converted to CAS percentile action
*-----------------------------------------------------------*/
%macro plot_pdf_interval_var(
	cas_sess=				/* 	name of the cas session  (empty for run in Model Studio)*/
	,incaslib=				/*	name of CAS library with input data (empty for run in Model Studio)*/
	,inds=					/*	name of input dataset in incaslib (empty for run in Model Studio)*/
	,interval_var_list=		/*	list of interval variables to be analyzed (for run in Model Studio: if empty it will be set to Interval vars from train dataset )*/
	,by_var=				/*	plot pdf by by_var (if empty it will be set to TARGET for run in Model Studio) */
	,nbins=100				/*	number of bins in histogram 100=>percentiles*/
	,pct_low=0				/*	lower band of percentiles in % for outliners ,these will not be plotted but only printed */
	,pct_high=100			/*	upper band of percentiles in % for outliners ,these will not be plotted but only printed */
	,nobyplots=0			/*	flag indicator that request separate plots by VAR*/
)/  des='plot histograms like step graphs based on percentiles and PDF';


/*optionally print SAS Model Studio all variables*/
/* proc print data=&dm_projectmetadata; */
/* run; */

/*set defaults from vdmml macros*/

%if %length(&cas_sess) eq 0 %then %do;
	%let cas_sess=&dm_cassessref;
	%put cas_sess:&cas_sess;
%end;

%if %length(&incaslib) eq 0 %then %do;
	%let incaslib=&dm_ds_caslib;
	%put incaslib:&incaslib;
%end;

%if %length(&inds) eq 0 %then %do;
	%let inds=&dm_memname;
	%put inds:&inds;
%end;

/* search for the first target */
%if %length(&by_var) eq 0 %then %do;
	%dmcas_varmacro(name=target_var_macro, metadata=&dm_metadata, key=NAME,  where=(ROLE='TARGET'), quote=N, comma=N); 
	%let by_var = %scan(%target_var_macro,1);   
	%put by_var:&by_var; 
%end;

%if %length(&interval_var_list) eq 0 %then %do;
	%dmcas_varmacro(name=interval_var_macro, metadata=&dm_metadata, key=NAME,  
					where=%nrbquote(ROLE='INPUT' and LEVEL in('INTERVAL')), 
					quote=N, comma=N); 
	%let interval_var_list=%interval_var_macro; 
	%put interval_var_list:&interval_var_list; 
%end;


%local i var;

options mprint;
ods select none;
proc cas;                                         
	session &cas_sess; 
	percentile.percentile /                          
	table={
/* 		caslib="&incaslib" */
		name="&inds",                
		vars={
			%do i=1 %to %sysfunc(countw(&interval_var_list,%str( )));
				%let var=%scan(&interval_var_list,&i,%str(% );
					%if &i ne 1 %then %do;	, %end;
						{name="&var"}
			%end;
			}
		%if %length(&by_var) ne 0 %then %do;
			,
			groupBy={
				{name="&by_var"}
		    }
		%end;
	},
	casOut={
		caslib="CASUSER",
		name="_percentiles",
		replace=TRUE
	},
	values={
	%do i=0 %to &nbins;
		%sysevalf(100/&nbins*&i)
	%end;

	}
;
run;
ods select all;

proc sort data=casuser._percentiles  out=_percentiles ;
%if %length(&by_var) ne 0 %then %do;
	by  _Column_ &by_var _Pctl_;
%end;
%else %do;
	by  _Column_ _Pctl_;
%end;
run;

data _percentiles_plot;
set _percentiles 
	%if %length(&by_var) ne 0 %then %do;
		(where =(upcase(_column_) ne %upcase("by_var")))
	%end;
;

%if %length(&by_var) ne 0 %then %do;
	by  _Column_ &by_var _Pctl_;
	if first.bad then do;
		lag_value=.;
		lag_pctl=.;
	end;
%end;
%else %do;
	by  _Column_  _Pctl_;
	if first._Column_ then do;
		lag_value=.;
		lag_pctl=.;
	end;
%end;

retain lag:;
if _value_ ne lag_value then do;
	pdf=(_Pctl_-lag_pctl)/(_value_-lag_value);
	output;
	lag_value=_value_;
	lag_pctl=_Pctl_;
end;
/*drop lag:;*/
run;

%put interval_var_list:&interval_var_list;

%do i=1 %to %sysfunc(countw(&interval_var_list,%str( )));
	%let var=%scan(&interval_var_list,&i,%str(% ));
	title "Distribution of &VAR";
	title2 "Values pct_low>&pct_low and pct_high<&pct_high selected";
	proc sgplot data=_percentiles_plot;
		where  
			_Pctl_>&pct_low and _Pctl_<&pct_high
			and upcase(_Column_)=%upcase("&var")
		;

		STEP X=lag_value Y=pdf
		%if &nobyplots ne 1  and %length(&by_var) ne 0 %then %do;
			/group=&by_var
		%end;
		;

		%if &nobyplots eq 1 and %length(&by_var) ne 0 %then %do;
			by  _Column_ &by_var ;
		%end;
		xaxis label="&var" grid;
		yaxis label="Probability density " grid;

	run;
%if not(&pct_low eq 0 and &pct_high eq 100) %then %do;
		proc print data=_percentiles_plot;
			title2 "Values pct_low<=&pct_low and pct_high>=&pct_high selected";
			where (_Pctl_ lt &pct_low or _Pctl_ gt &pct_high)
					and upcase(_Column_)=%upcase("&var");
			var _Column_ _Pctl_ _Value_  ;
			%if %length(&by_var) ne 0 %then %do;
				by  _Column_ &by_var ;
			%end;
		run;
	%end;
%end;
title;
options nomprint ;
%mend plot_pdf_interval_var;

%macro t_plot_pdf_interval_var();
/* test run outside Model Studio */

/*test data downloaded from */
/*https://support.sas.com/documentation/onlinedoc/viya/exampledatasets/hmeq.csv*/
cas;
caslib _all_ assign;

filename indata "~/hmeq.csv";
data casuser.hmeq;
infile indata dlm="," dsd firstobs=2;
input BAD LOAN MORTDUE VALUE REASON $ JOB $ YOJ DEROG DELINQ CLAGE NINQ CLNO DEBTINC;
run;


/* options mprint mlogic symbolgen; */
/* options nomprint nomlogic nosymbolgen; */

%plot_pdf_interval_var(
	cas_sess=CASAUTO		/* 	name of the cas session */
	incaslib=CASUSER		/*	name of CAS library with input*/
	,inds=hmeq					/*	name of input dataset in incaslib*/
	,interval_var_list=LOAN MORTDUE VALUE DELINQ CLAGE
/*	list of interval variables to be analyzed*/
	,by_var=bad				/*	plot pdf by by_var (typically Target)*/
	,pct_low=0				/*	lower band of percentiles in % for outliners ,these will not be plotted but only printed */
	,pct_high=98			/*	upper band of percentiles in % for outliners ,these will not be plotted but only printed */
	,nbins=20				/*	number of bins in histogram 100=>percentiles*/
	,nobyplots=0				/*	flag indicator that request separate plots by VAR*/
);

%mend t_plot_pdf_interval_var;

/*

%t_plot_pdf_interval_var();

*/

/* run inside Model Studio */
%plot_pdf_interval_var(
	interval_var_list=	
	/*	list of interval variables to be analyzed (for run in Model Studio: if empty it will be set to Interval vars from train dataset )*/
	,by_var=				/*	plot pdf by by_var (if empty it will be set to TARGET for run in Model Studio) */
	,pct_low=0				/*	lower band of percentiles in % for outliners ,these will not be plotted but only printed */
	,pct_high=98			/*	upper band of percentiles in % for outliners ,these will not be plotted but only printed */
	,nbins=20				/*	number of bins in histogram 100=>percentiles*/
	,nobyplots=0			/*	flag indicator that request separate plots by VAR*/
);
