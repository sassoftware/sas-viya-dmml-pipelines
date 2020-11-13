/* User Configures the Following Settings for Various Stages */

/****************** BEGIN USER SETTINGS ******************/

/*-----------------------------------------------------*
 For DATA Preparation 
 *-----------------------------------------------------*/
%let ecm_user_periodOfInterest  = <time period (frequency) of analysis, such as dtweek>;

/*-----------------------------------------------------*
 For Severity Modeling (See PROC SEVSELECT documentation)
 *-----------------------------------------------------*/
%let ecm_user_sevdists          = <space-separated list of severity distribution keywords [example: burr logn weibull]>;
%let ecm_user_sevDistSlctCrit   = <severity model selection criterion, such as aic, aicc, etc>;
%let ecm_user_sevEffects        = <space-separated list of severity regression effects (SCALEMODEL statement)>;
%let ecm_user_sevSlctMethod     = ; /* can be left blank, but you can specify a severity effect selection method here */
%let ecm_user_sevEffectSlctCrit = sbc; /* can be left at 'sbc', but you can specify a severity effect selection criterion here */

/*-----------------------------------------------------*
 For Count Modeling (See PROC CNTSELECT documentation)
 *-----------------------------------------------------*/
%let ecm_user_cntDists          = <space-separated list of count distribution models [example: poisson negbin(p=2)]>;
%let ecm_user_cntDistSlctCrit   = <count model selection criterion, such as aic, etc>;
%let ecm_user_cntEffects        = <space-separated list of count regression effects (right side of MODEL statement)>;
%let ecm_user_cntSlctMethod     = ; /* can be left blank, but you can specify a count effect selection method here */
%let ecm_user_cntSlctCrit       = sbc; /* can be left at 'sbc', but you can specify a count effect selection criterion here */

/*-----------------------------------------------------*
 For Copula Modeling (See PROC CCOPULA documentation)
 *-----------------------------------------------------*/
%let ecm_user_copModels         = <space-separated list of copula types [example: t gumbel clayton]>;
%let ecm_user_copModelSlctCrit  = <copula selection criterion, such as aic, etc>;

/* You can override the following two settings later in 'Simulate Copula' node. */
%let ecm_user_nCopObs           = <number of observations to simulate multivariate uniform sample from the best copula; larger number is better, but results in longer simulation time>;
%let ecm_user_copSeed           = 123; /* seed to use for copula simulation for reproducibility of results */

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
