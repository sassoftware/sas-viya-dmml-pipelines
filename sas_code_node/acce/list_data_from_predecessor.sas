/* SAS code */

/* Retrieve the id of the predecessor node */
%let node_guid=;

data _null_;
   set &dm_predecessors end=eof;
   if eof then call symputx('node_guid', guid);
run;

/* Create a folder to put all the files registered */
data _null_;
   folder = dcreate(strip(symget('node_guid')), "&dmcas_workpath");
run;

/* Fetch all registered files under that node */
%dmcas_fetchRegistered(&node_guid, &dmcas_workpath.&dm_dsep.&node_guid);

/* Retrieve the names of all the registered data sets */
libname nodelib "&dmcas_workpath.&dm_dsep.&node_guid";
data work.reportTables;
   set nodelib.dmcas_report;
   where upcase(name) in('DATASET');
run;

proc sort data=work.reportTables NODUPKEY;
   by VALUE;
run;

/* View the registered data sets for the node */
proc print data=work.reportTables;
run;

/* Once you find the name of the data set you want to use,
you can interact with it as nodelib.xyz where xyz is the name of the data set */



