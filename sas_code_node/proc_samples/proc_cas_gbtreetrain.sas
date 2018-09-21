/* Run Gradient Boosting using gbtreetrain action; target is categorical */

/* The dmcas_varmacro macro creates a macro (name=) that has comma separated quoted variables and a
   macro variable (nummacro=) that has the count of those variables */
/* For example, below statement creates dm_interval_inputq macro that has comma separated quoted interval variables (e.g., "var1", "var2", "var3") and
   dm_num_interval_inputq that has their count (e.g., 3)  */
%dmcas_varmacro(name=dm_interval_inputq, metadata=&dm_metadata, where=%nrbquote(ROLE='INPUT' and LEVEL in('INTERVAL')), 
                key=NAME, nummacro=dm_num_interval_inputq, quote=Y, comma=Y);
%dmcas_varmacro(name=dm_class_inputq, metadata=&dm_metadata, where=%nrbquote(ROLE='INPUT' and LEVEL in('BINARY', 'NOMINAL')), 
                key=NAME, nummacro=dm_num_class_inputq, quote=Y, comma=Y);
%dmcas_varmacro(name=dm_targetq, metadata=&dm_metadata, where=%nrbquote(ROLE='TARGET'), 
                key=NAME, nummacro=dm_num_targetq, quote=Y, comma=Y);

proc cas;
  decisiontree.gbtreetrain result=rslt /
    table     ={name="&dm_memname.", where="&dm_partitionvar=&dm_partition_train_val", &dm_data_caslib}
    inputs    ={%dm_interval_inputq, %dm_class_inputq}
    nominals  ={%dm_class_inputq, %dm_targetq} /* target is categorical */
    target    =%dm_targetq
    varimp    =true
    savestate ={name="&dm_rstoreTable.", replace=true, &dm_data_caslib}
  ;
run;
/* Print results from gbtreetrain to ODS Output window */
print rslt;
run;
/* Save result tables for adding to reports below */
saveresult rslt["ModelInfo"] replace dataset=&dm_lib..ModelInfo;
saveresult rslt["DTreeVarImpInfo"] replace dataset=&dm_lib..VarImp;
run;
quit;

/* Add reports to node results */
%dmcas_report(dataset=ModelInfo, reportType=Table, description=%nrbquote(Model Information));
%dmcas_report(dataset=VarImp, reportType=Table, description=%nrbquote(Variable Importance));
