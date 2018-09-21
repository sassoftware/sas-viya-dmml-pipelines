/* Run Gradient Boosting using gradboost procedure */

proc gradboost data=&dm_data
  numBin=20 maxdepth=6 maxbranch=2 minleafsize=5 minuseinsearch=1 
  ntrees=100 learningrate=0.1 samplingrate=0.6 lasso=0 ridge=0 seed=1234;
  
  %if &dm_num_interval_input %then %do;
    input %dm_interval_input / level=interval;
  %end;

  %if &dm_num_class_input %then %do;
    input %dm_class_input/ level=nominal;
  %end;

  %if "&dm_dec_level" = "INTERVAL" %then %do;
    target %dm_dec_target / level=interval ;
  %end;
  %else %do;
    target %dm_dec_target / level=nominal;
  %end;

  &dm_partition_statement;
  ods output
    VariableImportance = &dm_lib..VarImp
    Fitstatistics      = &dm_data_outfit
  ;
  savestate rstore=&dm_data_rstore;
run;

/* Add reports to node results */
%dmcas_report(dataset=VarImp, reportType=Table, description=%nrbquote(Variable Importance));
%dmcas_report(dataset=VarImp, reportType=BarChart, category=Variable, response=RelativeImportance, 
              description=%nrbquote(Relative Importance Plot));