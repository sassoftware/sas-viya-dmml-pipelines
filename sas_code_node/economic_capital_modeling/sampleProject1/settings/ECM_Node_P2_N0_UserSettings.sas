/* User Configures the following Settings for Simulation Stages */

/*-----------------------------------------------------*
 For CDM Modeling
 *-----------------------------------------------------*/
%let ecm_user_scenarioCASLIB    = Public;
%let ecm_user_scenarioTable     = opriskscenario1;
%let ecm_user_cdmNRep           = 10000;
%let ecm_user_nTotalLossSamples = 10;
%let ecm_user_cdmSeed           = 345;

/*-----------------------------------------------------*
 For ECM Modeling
 *-----------------------------------------------------*/
%let ecm_user_varLevels         = 50, 90, 95, 97.5, 99, 99.5;
%let ecm_user_tvarLevels        = 90, 95, 97.5, 99, 99.5;
%let ecm_user_edfAccuracy       = 5.0e-3;

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
