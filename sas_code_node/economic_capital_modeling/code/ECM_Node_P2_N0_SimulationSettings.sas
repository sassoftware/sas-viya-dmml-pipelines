/* User Configures the following Settings for Simulation Stages */

/*-----------------------------------------------------*
 For CDM Modeling (See PROC CCDM documentation)
 *-----------------------------------------------------*/
%let ecm_user_scenarioCASLIB    = <caslib of the scenario CAS table>;
%let ecm_user_scenarioTable     = <name of the scenario CAS table>;
%let ecm_user_cdmNRep           = <sample size of each marginal that PROC CCDM simulates; larger the better, but can take longer time to simulate>;
%let ecm_user_nTotalLossSamples = <number of samples to produce for enterprise-wide loss, preferrably > 30>;
%let ecm_user_cdmSeed           = 345; /* seed to use for CDM simulation for reproducibility of results */

/*-----------------------------------------------------*
 For ECM Modeling (See PROC ECM documentation)
 *-----------------------------------------------------*/
%let ecm_user_varLevels         = 50, 90, 95, 97.5, 99, 99.5; /* Value-at-risk (VaR) levels; you can use these defaults or modify the list */
%let ecm_user_tvarLevels        = 90, 95, 97.5, 99, 99.5; /* Tail Value-at-risk (TVaR) levels; you can use these defaults or modify the list */
%let ecm_user_edfAccuracy       = 5.0e-3; /* EDF accuracy; you can use this default or modify the value */

/****************** END USER SETTINGS ******************/


/*-----------------------------------------------------*
 DO NOT EDIT THIS CODE BELOW THIS LINE UNLESS YOU KNOW WHAT YOU ARE DOING.
 Save User Settings in a Project-level Data Set.
 *-----------------------------------------------------*/
proc sql noprint ;
    create table &dm_lib..ecm_user_sim_settings as 
        select name, value from dictionary.macros 
        where (substr(name, 1, 8) = 'ECM_USER');
quit;

proc print;run;

%dmcas_register(dataset=&dm_lib..ecm_user_sim_settings);

%exit:
;
