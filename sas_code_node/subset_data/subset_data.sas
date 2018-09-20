/* SAS code */

filename sc "&dm_file_scorecode";

/* Write out score code to subset data based on the value(s) of a variable */
/* This example subsets the data to only include obs. with JOB='Sales' or JOB='Self' */

data _null_;
  file sc;
  put "length filter_flag 8;";
  put "if strip(JOB) in ('Sales','Self') then filter_flag = 0;";
  put "else filter_flag = 1;";
run;

/* Metadata change to set role of filter */
%dmcas_metaChange(NAME=filter_flag, ROLE=FILTER, LEVEL=BINARY);
