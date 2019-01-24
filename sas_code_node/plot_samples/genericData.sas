/* SAS code */

data &dm_lib..exampData;
     a = "a";  b = 2; c=1; d=3; x=3;
     output;

     a = "b";  b = 5; c=4; d=9; x=5;
     output;

     a = "c";  b = 4; c=2; d=5;  x=10;
     output;
run;

/* Series Plot  */
%dmcas_report(dataset=exampData, reportType=SeriesPlot, x=a, y=b, description=%nrbquote(Series Plot), yref=3);

/* Bar Chart  */
%dmcas_report(dataset=exampData, reportType=BarChart, category=a, response=b,description=%nrbquote(Bar Chart));

/* Bar Chart - sorted X-axis */
%dmcas_report(dataset=exampData, reportType=BarChart, category=a, response=b, sortBy=b, description=%nrbquote(Bar Chart - Sorted));

/* Pie Chart */
%dmcas_report(dataset=exampData, reportType=PieChart, category=a, response=b, description=%nrbquote(Segment Plot));

/* Band Plot  */
%dmcas_report(dataset=exampData, reportType=BandPlot, x=x, y=b, limitLower=c, limitUpper=d, description=%nrbquote(Band Plot));
