/* Get predicted probability variables and levels (works for binary target only) */
data _null_;
  set &dm_lib..dmcas_targetlevel;
  where _freq_ > 0;

  if _event_flag_ = 'Y' then do;
    call symputx('predvar_evt', _predictedvar_);
    call symputx('predvar_evt_level', _cfmt_);
  end;
  else do;
    call symputx('predvar_nonevt', _predictedvar_);
    call symputx('predvar_nonevt_level', _cfmt_);
  end;
run;


/* Assess model */
proc assess data=&dm_data;
  input &predvar_evt;
  target &dm_dec_target / level=nominal event="&predvar_evt_level";
  fitstat pvar=&predvar_nonevt / pevent="&predvar_nonevt_level";
  by &dm_partitionvar;
  ods output
    fitstat=&dm_lib.._fitstat 
    rocinfo=&dm_lib.._rocinfo 
    liftinfo=&dm_lib.._liftinfo;
run;


/* Separate train, validation and test datasets */
data &dm_lib.._rocinfo0 &dm_lib.._rocinfo1 &dm_lib.._rocinfo2;
  set &dm_lib.._rocinfo;
  
  if &dm_partitionvar = 0 then output &dm_lib.._rocinfo0;
  else if &dm_partitionvar = 1 then output &dm_lib.._rocinfo1;
  else if &dm_partitionvar = 2 then output &dm_lib.._rocinfo2;
run;


/* Plot specific rates <-- HTML output */
proc sgplot data=&dm_lib.._rocinfo; 
  title "Overall Rates";
  by &dm_partitionvar;
  series x=cutoff y=Sensitivity;
  series x=cutoff y=Specificity;
  series x=cutoff y=FPR;
  series x=cutoff y=Acc;
run;
title '';


/* Reports */
%dmcas_report(dataset=&dm_lib.._rocinfo, reporTtype=SeriesPlot, X=cutoff, Y=Sensitivity, group = _PartInd_, description=%nrbquote(Sensitivity));
%dmcas_report(dataset=&dm_lib.._rocinfo, reporTtype=SeriesPlot, X=cutoff, Y=Specificity, group = _PartInd_, description=%nrbquote(Specificity));
%dmcas_report(dataset=&dm_lib.._rocinfo, reporTtype=SeriesPlot, X=cutoff, Y=FPR, group = _PartInd_, description=%nrbquote(False Positive Rate));
%dmcas_report(dataset=&dm_lib.._rocinfo, reporTtype=SeriesPlot, X=cutoff, Y=ACC, group = _PartInd_, description=%nrbquote(Accuracy));

%dmcas_report(dataset=&dm_lib.._fitstat, reporTtype=Table, description=%nrbquote(Model Statistics for Different Cutoffs - Population));
%dmcas_report(dataset=&dm_lib.._rocinfo, reporTtype=Table, description=%nrbquote(Statistics for Different Cutoffs - Population));
%dmcas_report(dataset=&dm_lib.._rocinfo0, reporTtype=Table, description=%nrbquote(Statistics for Different Cutoffs - Validation));
%dmcas_report(dataset=&dm_lib.._rocinfo1, reporTtype=Table, description=%nrbquote(Statistics for Different Cutoffs - Training));
%dmcas_report(dataset=&dm_lib.._rocinfo2, reporTtype=Table, description=%nrbquote(Statistics for Different Cutoffs - Test));
%dmcas_report(dataset=&dm_lib.._liftinfo, reporTtype=Table, description=%nrbquote(Lift Statistics for Different Cutoffs - Population));
