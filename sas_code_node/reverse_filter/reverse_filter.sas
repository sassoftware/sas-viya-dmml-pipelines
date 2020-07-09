
/* You can change the value of this macro variable to whatever name you want to use for your reverse filter */
%let newfilter = _KeepAnomalies;

/****** Training Code ******/
/* Change the metadata for the _svddscore_ and the new, reverse filter variable */
/* Enter the following into the Training Code pane: */
%dmcas_metaChange(NAME=_svddscore_, ROLE=REJECTED, LEVEL=INTERVAL);
%dmcas_metaChange(NAME=&newfilter, ROLE=FILTER, LEVEL=INTERVAL);


/****** Scoring Code ******/
/* Score code to create a variable with the filter reversed so only outliers are included when training */
/* Enter the following into the Scoring Code pane: */
  length &newfilter 8;
  &newfilter = 0 - _SVDDSCORE_;