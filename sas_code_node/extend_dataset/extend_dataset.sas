
/* Training Code */
/* Let the output data contain the doubled data from the input data set */
/* ```dm_data``` in terms of rows. */

/* training code */
data &dm_output_data;
    set &dm_data &dm_data;
run;
%dmcas_register(dataset=&DM_OUTPUT_DATA, type=cas);



/* Scoring Code */
/* Nothing else is required */