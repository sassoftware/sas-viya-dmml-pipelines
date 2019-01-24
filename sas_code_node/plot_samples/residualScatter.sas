/* SAS code */

data &dm_lib..samp;
      set &dm_data(obs=200);
      Residual = Target - P_Target; /* substitute "Target" with the name of your target variable */
run;

%dmcas_report(dataset=samp, reportType=ScatterPlot, x=P_Target, y=Residual, description=%nrbquote(Scatter Plot), yref=0);
