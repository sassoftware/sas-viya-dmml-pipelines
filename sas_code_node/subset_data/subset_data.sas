
/****** Training Code ******/
/* Metadata change to set the role of filter for the specified filter variable */
/* Enter the following into the Training Code pane: */
%dmcas_metaChange(NAME=filter_flag, ROLE=FILTER, LEVEL=BINARY);



/****** Scoring Code ******/
/* Score code to subset data based on the value(s) of a variable */
/* This example subsets the data to only include obs. with JOB='Sales' or JOB='Self' */
/* Enter the following into the Scoring Code pane: */
length filter_flag 8;
if strip(JOB) in ('Sales','Self') then filter_flag = 0;
else filter_flag = 1;
