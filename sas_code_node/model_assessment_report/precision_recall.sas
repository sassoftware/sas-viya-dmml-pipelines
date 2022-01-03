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
  ods output rocinfo=&dm_lib.._rocinfo 
run;

data &dm_lib.._rocinfo;
  set &dm_lib.._rocinfo;
  precision = tp / (tp + fp);
  recall = tp / (tp + fn);
run;

%dmcas_report(dataset=&dm_lib.._rocinfo, reporttype=SeriesPlot, X=recall, Y=precision, group = &dm_partitionvar, description=%nrbquote(Precision and Recall));
