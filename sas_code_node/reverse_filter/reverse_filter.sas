
/* You can change the value of this macro variable to whatever name you want to use for your reverse filter */
%let newfilter = _KeepAnomalies;

filename sc "&dm_file_scorecode";

/* Write out score code to create a variable with the filter reversed so only outliers are included when training */
data _null_;
  file sc;
  put "length &newfilter 8;";
  put "&newfilter = 0 - _SVDDSCORE_;";
run;

/* Change the metadata for the _svddscore_ and the new, reverse filter variable */
%dmcas_metaChange(NAME=_svddscore_, ROLE=REJECTED, LEVEL=INTERVAL);
%dmcas_metaChange(NAME=&newfilter, ROLE=FILTER, LEVEL=INTERVAL);
