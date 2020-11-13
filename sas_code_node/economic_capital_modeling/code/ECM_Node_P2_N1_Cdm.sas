/*** Read user simulation settings ***/
data _null_;
    set work.nodes(where=(component="sascode" and order=1));
    call symput("simSettingsNodeGuid", guid);
    stop;
run;
%put settings node guid = &simSettingsNodeGuid;

%dmcas_fetchDataset(&simSettingsNodeGuid, &dm_nodedir, ecm_user_sim_settings);

/* proc print data=&dm_lib..ecm_user_sim_settings; run; */

data _null_;
    set &dm_lib..ecm_user_sim_settings;
    call symput(trim(name), value);
run;

/*** Read project-wide macros created by the modeling pipeline (P1) ***/
%dmcas_fetchDataset(&dm_projectId, &dm_nodedir, ecm_tmp_macrovars);
/* proc print data=&dm_lib..ecm_tmp_macrovars; run; */
data _null_;
    set &dm_lib..ecm_tmp_macrovars;
    call symput(trim(name), trim(value));
run;

/*** Get the previously loaded scenario table ***/
libname temp cas caslib="&ecm_user_scenarioCASLIB";
data &dm_datalib..ecm_cdmscenario;
    set temp.&ecm_user_scenarioTable;
run;

/* NOTE: if the data set is saved with dmcas_addDataset, the name of
   the data set is case-sensitive, not all-lower-case like the data set
   that is saved with dmcas_register */
%let byinfods = &ecm_ByGrpInfoDS;
%put by info ds = &byinfods;
%dmcas_fetchDataset(&dm_projectId, &dm_nodedir, &byinfods);
/* proc print data=&dm_lib..&byinfods; run; */

%dmcas_fetchDataSet(&dm_projectId, &dm_nodedir, ecm_prepsevguid);
data _null_;
    set &dm_lib..ecm_prepsevguid(where=(component="sascode" and order=4));
    call symput("bestsevNodeGuid", guid);
run;
%put best sev guid = &bestsevNodeGuid;

%dmcas_fetchDataset(&bestsevNodeGuid, &dm_nodedir, ecm_bestsev);
proc print data=&dm_lib..ecm_bestsev;
run;

%dmcas_fetchDataSet(&dm_projectId, &dm_nodedir, ecm_prepcntguid);
data _null_;
    set &dm_lib..ecm_prepcntguid(where=(component="sascode" and order=4));
    call symput("bestcntNodeGuid", guid);
run;
%put best cnt guid = &bestcntNodeGuid;

%dmcas_fetchDataset(&bestcntNodeGuid, &dm_nodedir, ecm_bestcnt);
proc print data=&dm_lib..ecm_bestcnt;
run;

/* calculate ecm_cdmNPerturb such that 
  (&ecm_cdmNPerturb + 1) ** &ecm_nByGrp >= &ecm_user_nTotalLossSamples */
%global ecm_cdmNPerturb;
%if &ecm_user_nTotalLossSamples > 0 %then %do;
    %let ecm_cdmNPerturb = %sysfunc(log(&ecm_user_nTotalLossSamples));
    %let ecm_cdmNPerturb = %sysevalf(&ecm_cdmNPerturb/&ecm_nByGrp);
    %let ecm_cdmNPerturb = %sysfunc(ceil(%sysfunc(exp(&ecm_cdmNPerturb))));
    %let ecm_cdmNPerturb = %eval(&ecm_cdmNPerturb - 1);
    %put &ecm_cdmNPerturb;
%end;
%else %do;
    %let ecm_cdmNPerturb = 0;
%end;
%put nperturb per marginal = &ecm_cdmNPerturb;

%let dsid=%sysfunc(open(&dm_lib..&byinfods, i));
%do iby=1 %to &ecm_nbyvars;
    %let bvar=%scan(&ecm_byvars, &iby, " ");
    %let vnum=%sysfunc(varnum(&dsid, &bvar));
    %if (%sysfunc(vartype(&dsid, &vnum))=N) %then
        %let type = N;
    %else
        %let type = C;
    %put by var = &bvar, type = &type;
    %let bvar&iby = &bvar;
    %let btyp&iby = &type;
%end;
%let rc=%sysfunc(close(&dsid));

%do igrp=1 %to &ecm_nByGrp;
    /* form a where condition for the BY group */
    data _null_;
        set &dm_lib..&byinfods(where=(_groupid_=&igrp));
        length cond $512;
        cond = "";
        %do iby=1 %to &ecm_nbyvars;
            %let bvar = &&bvar&iby;
            %let btyp = &&btyp&iby;
            %put &bvar &btyp;
            %if &iby > 1 %then %do;
                cond=cat(trim(cond)," and");
            %end;
            %if (&btyp = C) %then %do;
                cond=cat(trim(cond)," &bvar = '",trim(&bvar),"'");
            %end;
            %else %do;
                cond=cat(trim(cond)," &bvar = ",trim(left(put(&bvar,BEST12.))));
            %end;
        %end;
        call symput("wherecond", trim(left(cond)));
    run;
    %put group &igrp, where condition=|&wherecond|;

    data _null_;
        set &dm_lib..ecm_bestsev(where=(&wherecond));
        call symput("best_sev_dist", best_sev_model);
    run;
    %put best sev dist = &best_sev_dist;

    data _null_;
        set &dm_lib..ecm_bestcnt(where=(&wherecond));
        call symput("best_cnt_store", best_store);
    run;
    %put best cnt store = &best_cnt_store;

    proc cas;
        droptable / name="ecm_margsample&igrp", quiet=True;
    quit;

    *** Simulate CDM for commercial banking LoB ***;
    *** NOTE: A separate CDM needs to be simulated for each business line, because
    the best count model is different for each business line and it is stored
    in a different count item store;
    title "Estimate CDM for &wherecond";
    proc ccdm data=&dm_datalib..ecm_cdmscenario(where=(&wherecond))
              countstore=&dm_datalib..&best_cnt_store severitystore=&dm_datalib..ecm_sevStore
              seed=&ecm_user_cdmSeed nreplicates=&ecm_user_cdmNRep 
              %if &ecm_cdmNPerturb > 0 %then %do;
                  nperturb=&ecm_cdmNPerturb
              %end;
              print=all;
       by &ecm_byvars;
       severitymodel &best_sev_dist;
       output out=&dm_datalib..ecm_margsample&igrp(promote=yes) samplevar=Marginal&igrp
              %if &ecm_cdmNPerturb > 0 %then %do;
                  / perturbOut
              %end;
              ;
       outsum out=&dm_datalib..ecm_margsumm mean std skew kurt median qrange 
              pctlpts=1, 5, 10, 20, 75, 90, 97.5, 99.5;
    run;

    proc print data=&dm_datalib..ecm_margsumm;
    run;

%end;

data &dm_lib..ecm_cdm_macrovars;
    length name varchar(32) value varchar(*);
    name = "ecm_cdmNPerturb";
    value = "&ecm_cdmNPerturb";
    output;
    name = "ecm_user_nTotalLossSamples";
    value = "&ecm_user_nTotalLossSamples";
    output;
run;

%dmcas_register(dataset=&dm_lib..ecm_cdm_macrovars);

%exit:
;
