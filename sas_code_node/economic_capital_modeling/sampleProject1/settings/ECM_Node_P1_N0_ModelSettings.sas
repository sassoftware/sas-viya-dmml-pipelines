/* User Configures the Following Settings for Various Stages */

/****************** BEGIN USER SETTINGS ******************/

/*-----------------------------------------------------*
 For DATA Preparation 
 *-----------------------------------------------------*/
%let ecm_user_periodOfInterest  = dtweek;

/*-----------------------------------------------------*
 For Severity Modeling 
 *-----------------------------------------------------*/
%let ecm_user_sevdists          = gamma logn weibull;
%let ecm_user_sevDistSlctCrit   = aicc;
%let ecm_user_sevEffects        = corpKRI1 corpKRI2 cbKRI2 rbKRI1 rbKRI3 corpKRI1*rbKRI3;
%let ecm_user_sevSlctMethod     = ;
%let ecm_user_sevEffectSlctCrit = sbc;

/*-----------------------------------------------------*
 For Count Modeling
 *-----------------------------------------------------*/
%let ecm_user_cntDists          = poisson negbin(p=2);
%let ecm_user_cntDistSlctCrit   = AIC;
%let ecm_user_cntEffects        = corpKRI1 corpKRI2 cbKRI1 cbKRI2 cbKRI3 cbKRI2*cbKRI3 rbKRI1 rbKRI2;
%let ecm_user_cntSlctMethod     = ;
%let ecm_user_cntSlctCrit       = sbc;

/*-----------------------------------------------------*
 For Copula Modeling
 *-----------------------------------------------------*/
%let ecm_user_copModels         = t gumbel clayton;
%let ecm_user_copModelSlctCrit  = AIC;

/* You can override the following two settings later in 'Simulate Copula' node. */
%let ecm_user_nCopObs           = 5000000; 
%let ecm_user_copSeed           = 123; 

/****************** END USER SETTINGS ******************/


/*-----------------------------------------------------*
 DO NOT EDIT THIS CODE BELOW THIS LINE UNLESS YOU KNOW WHAT YOU ARE DOING.
 Save User Settings in a Project-level Data Set.
 *-----------------------------------------------------*/
proc sql noprint ;
    create table &dm_lib..ecm_user_settings as 
        select name, value from dictionary.macros 
        where (substr(name, 1, 8) = 'ECM_USER');
quit;

proc print;run;

%dmcas_register(dataset=&dm_lib..ecm_user_settings);

%exit:
;
