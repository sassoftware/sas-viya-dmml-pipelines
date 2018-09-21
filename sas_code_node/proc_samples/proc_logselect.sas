/* Run Logistic Regression using logselect procedure; target is binary */

proc logselect data=&dm_data ;
  class %dm_class_input;
  model %dm_dec_target = %dm_interval_input %dm_class_input / link=logit;
  
  &dm_partition_statement;
  selection method=backward(choose=validate);
  ods output ParameterEstimates = &dm_lib..paramEstimates;
  
  /* pcatall iprob options needed so predicted probabilities have required variable names for assessment */
  code file="&dm_file_scorecode." pcatall iprob;    
run; 

/* Add reports to node results */
%dmcas_report(dataset=paramEstimates, reportType=Table, description=%nrbquote(Parameter Estimates));
