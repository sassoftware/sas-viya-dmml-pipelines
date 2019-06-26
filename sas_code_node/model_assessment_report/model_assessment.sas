caslib _all_ assign;

/*getting target info*/
 %dmcas_varmacro(name=dm_targetq, metadata=&dm_metadata, where=%nrbquote(ROLE='TARGET'),  
                 key=NAME, nummacro=dm_num_targetq, quote=N, comma=N); 

/*additional macro variables (used in proc assess)*/
%let targ = %dm_targetq;
%let target1 = P_&targ.1;
%let target0 = P_&targ.0;


data public.dataset;
  set &dm_data;
run;



proc assess data=public.dataset;
    input &target1. ;
    target &dm_dec_target. / level=nominal event='1';
    fitstat pvar= &target0. / pevent='0';
 by &dm_partitionvar;
    ods output
      fitstat=&dm_lib.._fitstat 
      rocinfo=&dm_lib.._rocinfo 
      liftinfo=&dm_lib.._liftinfo;
run;

/*separate datasets for training, validation and test datasets*/

data &dm_lib.._rocinfo0 &dm_lib.._rocinfo1 &dm_lib.._rocinfo2;
	  set &dm_lib.._rocinfo;
	  if &dm_partitionvar = 0 then output &dm_lib.._rocinfo0;
	  else if &dm_partitionvar = 1 then output &dm_lib.._rocinfo1;
	  else if &dm_partitionvar = 2 then output &dm_lib.._rocinfo2;
run;


/*plotting specific rates <-- HTML output*/

proc sgplot data=&dm_lib.._rocinfo; 
  title "Overall Rates";
by &dm_partitionvar;
  series x=cutoff y=Sensitivity;
  series x=cutoff y=Specificity;
  series x=cutoff y=FPR;
  series x=cutoff y=Acc;
run;

title '';


/*reports*/

%dmcas_report(dataset=&dm_lib.._rocinfo, reporTtype=SeriesPlot, X=cutoff, Y=Sensitivity, group = _PartInd_, description=%nrbquote(Sensitivity));
%dmcas_report(dataset=&dm_lib.._rocinfo, reporTtype=SeriesPlot, X=cutoff, Y=Specificity, group = _PartInd_, description=%nrbquote(Specificity));
%dmcas_report(dataset=&dm_lib.._rocinfo, reporTtype=SeriesPlot, X=cutoff, Y=FPR, group = _PartInd_, description=%nrbquote(False Positive Rate));
%dmcas_report(dataset=&dm_lib.._rocinfo, reporTtype=SeriesPlot, X=cutoff, Y=ACC, group = _PartInd_, description=%nrbquote(Accuracy));


%dmcas_report(dataset=&dm_lib.._fitstat, reporTtype=Table, description=%nrbquote(Model Statistics for Different Cutoffs - Population));
%dmcas_report(dataset=&dm_lib.._rocinfo, reporTtype=Table, description=%nrbquote(Statistics for Different Cutoffs - Population));
%dmcas_report(dataset=&dm_lib.._rocinfo0, reporTtype=Table, description=%nrbquote(Statistics for Different Cutoffs - Validation));
%dmcas_report(dataset=&dm_lib.._rocinfo1, reporTtype=Table, description=%nrbquote(Statistics for Different Cutoffs - Training));
%dmcas_report(dataset=&dm_lib.._rocinfo2, reporTtype=Table, description=%nrbquote(Statistics for Different Cutoffs - Test));
%dmcas_report(dataset=&dm_lib.._liftinfo, reporTtype=Table, description=%nrbquote(Lift Statistics for Different Cutoffs - Population));