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

libname nodelib "&dmcas_workpath.&dm_dsep.&node_guid";

/* if you know the name of the registered data set you want to retrieve, you can enter it here for xyz */
%dmcas_fetchDataset(&node_guid, &dmcas_workpath.&dm_dsep.&node_guid, xyz);

/* Use nodelib.xyz as you want, print e.g. */
proc print data=nodelib.xyz;
run;
