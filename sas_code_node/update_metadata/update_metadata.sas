/* Metachange to set input variable (var1) role to Rejected. 
   Valid values for role are Rejected, Input.
 */
%dmcas_metaChange(NAME=var1, ROLE=REJECTED);


/* Metachange to set input variable (var2) role to Input and level to Nominal.
   Valid values for level are Binary, Interval, Nominal.
 */
%dmcas_metaChange(NAME=var2, ROLE=INPUT, LEVEL=NOMINAL);


/* Metachange to update role of multiple input variables (var1, var2, var3) to Rejected. */
filename delta "&dm_file_deltacode";
data _null_;
  file delta;
  put "if NAME='var1' or NAME='var2' or NAME='var3' then do; ROLE='REJECTED'; end;"
run;
filename delta;


/* Metachange to update role and level of multiple input variables (var1, var2, var3) */
filename delta "&dm_file_deltacode";
data _null_;
  file delta;
  put "if NAME='var1' or NAME='var2' or NAME='var3' then do; ROLE='INPUT'; LEVEL='NOMINAL'; end;"
run;
filename delta;
