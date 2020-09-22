/*
%let ecm_user_copModels       = %str(t gumbel clayton);
%let ecm_user_copModelSlctCrit= AIC;
*/

/*** Read global macro variables ***/
%dmcas_fetchDataset(&dm_projectId, &dm_nodedir, ecm_tmp_macrovars);

data _null_;
	set &dm_lib..ecm_tmp_macrovars;
	call symput(trim(name), trim(value));
run;
%put number of groups = &ecm_nByGrp;

*** Fit copula models ***;
%let ecm_user_copModels=%trim(%left(&ecm_user_copModels));

%local i j;
%let i=1;
%local mod;
%do %until ("&mod" eq "");
	%let mod = %scan(&ecm_user_copModels, &i, " ");
	%if ("&mod" ne "") %then %do;
		%local modlist&i;
		%let modlist&i = &mod;
		proc cas;
			droptable / name="ecm_copStore&i", quiet=True;
		quit;
		%put Processing model &mod;
		title "Fit &mod model";
		proc ccopula data=&dm_datalib..&ecm_matchedLossTable;
			var 
			%do j=1 %to &ecm_nByGrp;
				marginal&j
			%end;
			;
			fit &mod / store=&dm_datalib..ecm_copStore&i.(promote=yes);
			ods output fitmodelsummary=&dm_lib..fitcop&i;
		run;
		%let i = %eval(&i + 1);
	%end;
%end;
%local nmod;
%let nmod=%eval(&i - 1);
%put number of copula models = &nmod;

title "Model Comparison";
data &dm_lib..fitStatsCop(keep=Copula Criterion Store);
	retain Copula;
	length Copula $16 Store $64;
	set 
	%do i=1 %to &nmod;
		&dm_lib..fitcop&i(in=in&i)
	%end;
	;
	if (property='Copula Type') then
		Copula = propertyValue;
	else if (upcase(property)=upcase("&ecm_user_copModelSlctCrit")) then do;
		Criterion = propertyValueNum;
		%do i=1 %to &nmod;
			if (in&i) then Store = "ecm_copStore&i";
		%end;
		output;
	end;
run;
proc print; run;

%dmcas_register(dataset=&dm_lib..fitStatsCop);

%exit:
;
