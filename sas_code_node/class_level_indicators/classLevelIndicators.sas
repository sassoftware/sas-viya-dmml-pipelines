/*----------------------------------------------------------------------------------------
 * Copyright (c) 2018 by SAS Institute Inc., Cary, NC USA 27513
 * NAME:         classLevelIndicators.sas
 * SUPPORT:      https://support.sas.com/techsup/contact/
 * PRODUCT:      DMCAS
 * PURPOSE:      Creates the scorecode and delta code which generate the class level indicators
 *               (value of 0 or 1) from all the identified class variables.
 *----------------------------------------------------------------------------------------*/

/*****************************************************************************************************************
**Summary**
This macro generates the class level indicators (values of 0 or 1) for all class variables identified in metadata.
Scorecode is generated which creates the class level indicators, with the scorecode file (scorecode.sas) being written to the
path referenced by the macro variable &dm_file_scorecode.  The dummy variable names are derived as
<ClassVariableName>_<ClassLevel>.  If a derived dummy variable name is greater than the Maximum name length
(default of 32), the class level part of the dummy name is trimmed down to bring the dummy name to LE the maximum.
If a class variable name itself is at the maximum, the last characters of the variable name are replaced with
ascending numeric digits to derive the dummy names.  Any duplicates in resulting dummy names are resolved by using
the generic name _CLASSLEVn (_CLASSLEV1, _CLASSLEV2, etc.) for the duplicates.  Any dummy name conflicts with other
variables in the source data are resolved also by using _CLASSLEVn.  By default, the class level indicators are created as numeric
INTERVAL variables, and all source data is used to extract the cardinality (as opposed to using only the training data).
The delta code file (deltacode.sas) is written to the &dm_file_deltacode path.


**Macro Parameters**
&p_dummyvarrole - The role of the generated class level indicators.  Possible values are INTERVAL or BINARY.  If INTERVAL,
        the class level indicators are populated with numeric values 0 or 1.  If BINARY, they are populated with character values
        '0' or '1'.  Defaults to INTERVAL if blank.
&p_trainonly - Identifies whether all data is used for determining the Class variable levels, or just the Training data.
        Possible values are YES or NO.  If YES, Training data is used to deterimine the Class variable levels
        in the data.  If NO, all data is used.  Defaults to NO if blank.
&p_scorecode - Required value of 1.
&p_maxnamelen - The maximum variable name length for the generated class level indicators.  If blank, uses &dm_maxNameLen
        if exists, otherwise uses 32.  The maximum supported value is 32.
&p_vdmmlflag - Required value of 1.
*****************************************************************************************************************/

%Macro dmcas_classlevs(p_dummyvarrole=, p_trainonly=, p_scorecode=1, p_maxnamelen=, p_vdmmlflag=1) /minoperator;
%let syscc=0;
%let l_numclass=0;   /*Number of Class Variables*/
%local cl_data cl_meta cl_maxclasslevs cl_outtable cl_scorecodefile cl_lib cl_maxnamelen cl_dummyvarrole cl_trainonly cl_train_clause;

%let p_vdmmlflag=1;

/*Derive &l_dummyvarrole:  Dummy variable role.  If parameter &p_vdmmlflag=1, use &p_dummyvarrole.
  If not, use &cl_dummyvarrole.  If blank, set to INTERVAL.*/
%local l_dummyvarrole;
%If (%superq(p_vdmmlflag) ne 1) %then %let l_dummyvarrole=%upcase(&cl_dummyvarrole.);  /*Set to &cl_dummyvarrole if blank.*/
%Else %let l_dummyvarrole=%upcase(&p_dummyvarrole.);
%If %superq(l_dummyvarrole)= %then %let l_dummyvarrole=INTERVAL;
%If not(%superq(l_dummyvarrole) in (BINARY INTERVAL)) %then %let l_dummyvarrole=INTERVAL;

/*Validate &p_scorecode.*/
/*If p_scorecode=0, generate the scorecode in a temp path and do not generate the Delta code.*/
%If %superq(p_scorecode)= %then %let p_scorecode=1;
%If not(%superq(p_scorecode) in (0 1)) %then %let p_scorecode=1;

/*Derive &l_maxnamelen:  Maximum variable name length.  If parameter &p_vdmmlflag=1, use &p_maxnamelen.
  If not, use &cl_maxnamelen.  If blank, use &dm_maxNameLen if it exists.  If not, set to 32.
  &dm_maxNameLen should be initialized in Model Studio - Data Mining.*/
%local l_maxnamelen;
%If (%superq(p_vdmmlflag)=1) %then %let l_maxnamelen=&p_maxnamelen.;
%Else %let l_maxnamelen=&cl_maxnamelen.;
%If (%superq(l_maxnamelen)=%str() and %symexist(dm_maxNameLen)) %then %let l_maxnamelen=&dm_maxNameLen.;
%Else %if %superq(l_maxnamelen)= %then %let l_maxnamelen=32;

/*Derive &l_maxclasslevs.*/
%local l_maxclasslevs;
%If %superq(cl_maxclasslevs)=%str() %then %let l_maxclasslevs=20;
%Else %let l_maxclasslevs=&cl_maxclasslevs.;

/*Derive &l_data and &l_caslibref:  Use &cl_data if &p_vdmmlflag ne 1.  Otherwise, use &dm_data
  and &dm_casiocalib if they exist.*/
%local l_data l_caslibref;
%If (%superq(p_vdmmlflag) ne 1) %then %do;
 %let l_data=&cl_data.;
 %let l_caslibref=%scan(%superq(cl_data),1,.);
%End;
%If %superq(l_data)= %then %do;
 %if %symexist(dm_data) %then %let l_data=&dm_data.;
 %if %symexist(dm_casiocalib) %then %let l_caslibref=&dm_casiocalib.;
%End;

/*Derive &l_meta:  Use &cl_meta if &p_vdmmlflag ne 1.  Otherwise, use &dm_metadata if it exists.*/
%local l_meta;
%If (%superq(p_vdmmlflag) ne 1) %then %let l_meta=&cl_meta.;
%If (%superq(l_meta)=%str() and %symexist(dm_metadata)) %then %let l_meta=&dm_metadata.;

/*Derive &l_lib:  Use &cl_lib if &p_vdmmlflag ne 1.  Otherwise, use &dm_lib if it exists.  If not, use WORK.*/
%local l_lib;
%If (%superq(p_vdmmlflag) ne 1) %then %let l_lib=&cl_lib.;
%If (%superq(l_lib)=%str() and %symexist(dm_lib)) %then %let l_lib=&dm_lib.;    /*Set to &dm_lib if &cl_lib is blank.*/
%Else %if %superq(l_lib)= %then %let l_lib=work;     /*Set to WORK otherwise.*/

/*Derive &l_scorecodefile:  Use &cl_scorecodefile if &p_vdmmlflag ne 1.  Otherwise, use &dm_file_scorecode if it exists.
  If not, use the WORK path.*/
%local l_scorecodefile;
%If (%superq(p_vdmmlflag) ne 1) %then %let l_scorecodefile=&cl_scorecodefile.;
%If (%superq(l_scorecodefile)=%str() and %symexist(dm_file_scorecode)) %then %let l_scorecodefile=&dm_file_scorecode.;    /*Set to &dm_file_scorecode if &cl_scorecodefile is blank.*/
%If %superq(l_scorecodefile)= %then %let l_scorecodefile=%sysfunc(pathname(WORK,L))/scorecode.sas;

/*Derive &l_deltacodefile:  Use &dm_file_deltacode if it exists.  If not, use the WORK path.*/
%local l_deltacodefile;
%If %symexist(dm_file_deltacode) %then %let l_deltacodefile=&dm_file_deltacode.;    /*Set to &dm_file_deltacode if it exists.*/
%If %superq(l_deltacodefile)= %then %let l_deltacodefile=%sysfunc(pathname(WORK,L))/deltacode.sas;

/*Write Class Vars to Macro Variables &varclass1, &varclass2, etc.  Exclude Unary variables.*/
%If %superq(l_meta) ne %then %do;   /*Execute this if variable metadata has not been provided, where p_vdmmlflag ne 1.*/
Data &l_lib..classvars;
 Set &l_meta. end=last;
 Where upcase(role)='INPUT';
/*Process Class Variables.*/
 If upcase(level) ne "INTERVAL" and upcase(level) ne "UNARY" then do;
  classn+1;
  Call symputx('varclass'||strip(put(classn,10.)),"'"||tranwrd(ktrim(name),"'","''")||"'n",'G');
  Output &l_lib..classvars;
  Call symputx('l_numclass',classn,'F');
 End;
Run;
%If not(&syscc. in (0 4)) %then %goto exit;

%If (&l_numclass.=0) %then %do;
 %If (%superq(p_vdmmlflag)=1) %then %dmcas_msg(warning,dm_vclus_noclassvars);
 %Else %put WARNING: Class variables do not exist in the data.  Class level indicators will not be created.;
 %If &syscc.=0 %then %let syscc=4;
 %goto exit;
%End;
%End;   /*%superq(l_meta) ne */
 
/*Derive &l_trainonly:  Use &cl_trainonly if &p_vdmmlflag ne 1.  Otherwise use &p_trainonly.*/
%local l_trainonly;
%If (%superq(p_vdmmlflag) ne 1) %then %let p_trainonly=&cl_trainonly.;
%If %superq(p_trainonly)= %then %let p_trainonly=NO;                    /*Set to NO if blank.*/
%If %qupcase(&p_trainonly.) in (YES Y YE) %then %let l_trainonly=1;
%Else %let l_trainonly=0;

/*Derive &l_train_clause:  Use &cl_train_clause if &p_vdmmlflag ne 1.  Otherwise, use &dm_partitionTrainWhereClauseNLit if it exists.*/
%local l_train_clause;
%If (%superq(p_vdmmlflag) ne 1) %then %let l_train_clause=&cl_train_clause.;
%If (%superq(l_train_clause)=%str() and %symexist(dm_partitionTrainWhereClauseNLit)) %then %let l_train_clause=&dm_partitionTrainWhereClauseNLit.;    /*Set to &dm_partitionTrainWhereClauseNLit if &cl_train_clause is blank.*/

/*Generate the Partition Where Clause if there is a Train clause and &l_trainonly=1.  Only Training data is used.*/
%local l_partwhere;
%If (%superq(l_train_clause) ne %str() and &l_trainonly.) %then %let l_partwhere=Where &l_train_clause.%str(;);

%If (&l_numclass.>0) %then %do;  /*Variable metadata has been provided.*/
/*Run Proc Cardinality to extract the Class Variable levels.*/
%If (%superq(p_vdmmlflag)=1) %then %dmcas_debug(Begin Cardinality: Extract Class Levels);
Proc cardinality data=&l_data. maxlevels=254 outdetails=&l_caslibref..card_d outcard=&l_caslibref..card;
 &l_partwhere.           /*Where Clause for the Training Partition data*/
 Vars %local y; %Do y=1 %to &l_numclass.; &&varclass&y. %End;;
Run;
%If (%superq(p_vdmmlflag)=1) %then %dmcas_debug(End Cardinality: Extract Class Levels);
%If not(&syscc. in (0 4)) %then %goto exit;
%End;   /*(&l_numclass.>0)*/
/*Run Cardinality using the max levels supplied by the user.*/
%Else %do;    /*Variable metadata has not been provided.*/
 Proc cardinality data=&l_data. maxlevels=&l_maxclasslevs. outdetails=&l_caslibref..card_d outcard=&l_caslibref..card;
  &l_partwhere.           /*Where Clause for the Training Partition data*/
 Run;
%End;

/*Extract variable lengths of the Cardinality Details dataset.*/
Proc contents data=&l_caslibref..card_d noprint out=&l_lib..carddcols (keep=name length);
Run;

/*Run Proc Contents on the source data to get the format information.*/
Proc contents data=&l_data. noprint out=&l_lib..varmeta;
Run;

Data &l_lib..card;
 Set &l_caslibref..card;
Run;

/*Bring in the format information to cardinality.*/
/*Exclude Unary variables.*/
/*Extract variables where _rlevel_='CLASS' if variable metadata has not been provided.*/
Proc sql;
 Create table &l_lib..card1 as
 Select a.*, b.format as FMTNAME label='FMTNAME', b.formatl, b.formatd, b.length, b.label
 From &l_lib..card a, &l_lib..varmeta b
 Where a._varname_=b.name and a._cardinality_>1
%If (&l_numclass.=0) %then
  %str(and) a._rlevel_='CLASS';;
Quit;
%If not(&syscc. in (0 4)) %then %goto exit;

/*Exit if there are no class variables.*/
%If (&sqlobs.=0) %then %do;
 %If (%superq(p_vdmmlflag)=1) %then %dmcas_msg(warning,dm_vclus_noclassvars);
 %Else %put WARNING: Class variables do not exist in the data.  Class level indicators will not be created.;
 %If &syscc.=0 %then %let syscc=4;
 %goto exit;
%End;

Data &l_lib..card_d1;
 Set &l_caslibref..card_d;
Run;

/*Derive the format to be applied to the Class variables.  Use _fmtwidth_ from Cardinality for the format length.
  The format length from Cardinality is used because this may be different from the length extracted from Proc Contents.*/
%local l_highcardnum;
%let l_highcardnum=0;
Data &l_lib..card2;
 Set &l_lib..card1;
 length FORMAT $40;
 If FMTNAME ne '' then do;
  If FMTNAME='$' then format='';
  Else if _type_='N' and fmtname ne 'BEST' and formatd>0 then format=strip(fmtname)||strip(put(_fmtwidth_,10.))||'.'||strip(put(formatd,10.));
  Else format=strip(fmtname)||strip(put(_fmtwidth_,10.))||'.';    /*Add _fmtwidth_ to the format.*/
 End;
 Else if formatd>0 and _type_='N' then format='F'||strip(put(_fmtwidth_,10.))||'.'||strip(put(formatd,10.));
 Else if _type_='N' then format='BEST'||strip(put(_fmtwidth_,10.))||'.';   /*Use BEST as the format for numerics that don't have a format.*/
/*Add check for variables with more than 254 levels.*/
 If _more_='Y' then do;
  gt254+1;
  Call symput('highcardnl'||strip(put(gt254,10.)),"'"||tranwrd(ktrim(_varname_),"'","''")||"'n");  /*n-literal*/
  Call symput('highcard'||strip(put(gt254,10.)),"'"||tranwrd(ktrim(_varname_),"'","''")||"'");    /*Name in single quotes*/
  Call symputx('hctype'||strip(put(gt254,10.)),_type_,'L');    /*Variable _type_ (N or C)*/
  Call symputx('l_highcardnum',gt254,'F');            /*Number of variables greater than 254 cardinality.*/
 End;
Run;

/*If there are variables greater than 254 cardinality, extract all levels with Proc Freqtab, and replace the values
  in CARD_D1.*/
%If (&l_highcardnum.>0 and &l_numclass.>0) %then %do;
 Proc freqtab data=&l_data. order=FORMATTED noprint;
  &l_partwhere.           /*Where Clause for the Training Partition data*/
 %Do x=1 %to &l_highcardnum.; 
  tables &&highcardnl&x. /out=&l_lib..hctable&x.;
 %End;
 Run;

/*Delete the high-cardinality entries from CARD_D1.*/
 Proc sql;
 %Do x=1 %to &l_highcardnum.;
  Delete from &l_lib..card_d1
  Where _varname_=&&highcard&x.;
 %End;
 Quit;

/*Add-in the freqtab entries.*/
 Data &l_lib..card_d1;
  Set &l_lib..card_d1 (in=a) %do x=1 %to &l_highcardnum.; &l_lib..hctable&x. %end;;
  If not(a) then do;
 %local el;
 %Do x=1 %to &l_highcardnum.;
  %If (&x.>1) %then %let el=%str(else);
   &el. If not(missing(&&highcardnl&x.)) then do;
    _varname_=&&highcard&x.;
  %If %superq(hctype&x.)=N %then
    _rawnum_=&&highcardnl&x.;
  %Else
    _rawchar_=&&highcardnl&x.;;
   End;
 %End;
   _freq_=count;
   freqpercent=percent;
  End;
 Run;
%End;      /*&l_highcardnum.>0 and &l_numclass.>0*/

 %local len len2;
 %let len=1000;
 %let len2=1000;
/*Extract the length of the _CFMT_ column, add 100, and write to &len.  Add 300 and write to &len2.*/
 Proc sql noprint;
  Select (length+100) as newlength format=10., (length+300) as newlength2 format=10.
  Into :len TRIMMED, :len2 TRIMMED
  From &l_lib..carddcols
  Where upcase(name)='_CFMT_';
 Quit;

/*Bring in the FORMAT, _TYPE_, LENGTH, LABEL, and _ORDER_ to Cardinality details.*/
 Proc sql;
  Create table &l_lib..card_d as
  Select a.*, c.length, c.label, c.fmtname, c.format, c._order_, c._cardinality_, c._type_
  From &l_lib..card_d1 a, &l_lib..card2 c
  Where a._varname_=c._varname_;
 Quit;
 %If not(&syscc. in (0 4)) %then %goto exit;

/*Concatenate the variable name and its formatted level values.  Write to VARLEVTEMP.*/
 Data &l_lib..card_dlev;
  Set &l_lib..card_d;
  Length VARLEVTEMP VARLEVTEMPG $&len2.;
  CFMT=_cfmt_;
  If _order_ ne 'ASCFMT' or _cfmt_='' then do;
   If _type_='C' then do;   /*Character values*/
    If format ne '' then do;
     varlevtemp=ktrim(_varname_)||'_'||kstrip(putc(_rawchar_,format));
     varlevtempg=ktrim(_varname_)||' '||kstrip(putc(_rawchar_,format));
     cfmt=putc(_rawchar_,format);
    End;
    Else do;
     varlevtemp=ktrim(_varname_)||'_'||kstrip(_rawchar_);
     varlevtempg=ktrim(_varname_)||' '||kstrip(_rawchar_);
     cfmt=_rawchar_;
    End;
   End;
   Else do;       /*Numeric values*/
    If format ne '' then do;
     varlevtemp=ktrim(_varname_)||'_'||kstrip(putn(_rawnum_,format));
     varlevtempg=ktrim(_varname_)||' '||kstrip(putn(_rawnum_,format));
     cfmt=putn(_rawnum_,format);
    End;
    Else do;
     varlevtemp=ktrim(_varname_)||'_'||strip(put(_rawnum_,best12.));
     varlevtempg=ktrim(_varname_)||' '||strip(put(_rawnum_,best12.));
     cfmt=put(_rawnum_,best12.);
    End;
   End;
  End;
  Else do;
   varlevtemp=ktrim(_varname_)||'_'||kstrip(_cfmt_);
   varlevtempg=ktrim(_varname_)||' '||kstrip(_cfmt_);
  End;
 Run;

 /*Remove any duplicate VARLEVTEMP values.  Duplicate values could be possible after stripping leading
   blanks from the level values.*/
 Proc sort data=&l_lib..card_dlev out=&l_lib..card_dlev2 nodupkey;
  By _varname_ varlevtemp;
 Run;

 /*Derive VARLEV from VARLEVTEMP:  Trim down to the max variable length if necessary.*/
 %local varlev;
 Data &l_lib..card_dlev3;
  Set &l_lib..card_dlev2;
  Length FMTVAL FMTVALRPT LBLPART $&len. VARLABEL LABELRPT $1000 VARLEV VARLEVUP $500;
  Drop len klen klensub;
/*Where the length of _varname_ is LT the Max name length minus one, concatenate _cfmt_ to _varname_.*/
  If length(_varname_) lt %eval(&l_maxnamelen.-1) then do;
   call symput('varlev',ktrim(varlevtemp));
   lblpart=kstrip(cfmt);
  End;
  Else do;  /*If the length of _varname_ is the max name length or one less, use just the _varname_.*/
   call symput('varlev',ktrim(_varname_));
  End;
  len=length(symget('varlev'));
  klen=klength(symget('varlev'));
/*Repeatedly trim the varlev values (concatenated _varname_ and _cfmt_ values) that are GT the max name length
  until the max name length is achieved.*/
  Do while(len>&l_maxnamelen. and klen>1);
   klensub=klen-1;
   Call symput('varlev',ksubstr(symget('varlev'),1,klensub));  /*Use ksubstr to prevent invalid truncation of multi-byte national characters.*/
   len=length(symget('varlev'));
   klen=klength(symget('varlev'));
  End;
  VARLEV=symget('varlev');
  VARLEVUP=upcase(varlev);
  FMTVAL=kstrip(tranwrd(cfmt,"'","''"));
  LABELNEW=label;
  If label='' then labelnew=_varname_;  /*Use the Variable name for the label if LABEL is blank.*/
  VARLABEL=tranwrd(kstrip(labelnew),"'","''")||'='||kstrip(tranwrd(cfmt,"'","''"));
  LABELRPT=kstrip(labelnew)||'='||kstrip(cfmt);
  FMTVALRPT=kstrip(cfmt);
 Run;

 Proc sort data=&l_lib..card_dlev3;
  By _varname_ varlevup cfmt;
 Run;

 Proc sql;
  Drop table &l_caslibref..card_d, &l_caslibref..card;
 Quit;

/*If any duplicate VARLEV values are generated from above, change those VARLEV values so as to eliminate the duplicates.
  To do this, for the duplicates, instead of concatenating _varname_ directly to the _cfmt_ part, concatenate a sequence number 
  to the end of the _varname_ before adding the _cfmt_ value.*/
 Data &l_lib..card_d2;
  Set &l_lib..card_dlev3 (rename=(varlevup=varlev2));
  By _varname_ varlev2;
  Retain num 0;
  Drop varlev2 num klen klensub digit len;
  VARLEVUP=VARLEV2;
  If first._varname_ then num=0;
  If (not(first.varlev2) or not(last.varlev2)) then do;  /*Accomplish de-duplication for any duplicates.*/
   If length(_varname_) lt %eval(&l_maxnamelen.-1) then do;  /*Length of _varname_ LT the max name length.*/
    If not(first.varlev2) then do;
     num+1;
/*Concatenate _varname_, the sequence number, and the _cfmt_ value.*/
     call symput('varlev',ktrim(_varname_)||strip(put(num,10.))||'_'||ktrim(lblpart));
     len=length(symget('varlev'));
     klen=klength(symget('varlev'));
/*Repeatedly trim the varlev value that is GT the max name length until the max name length is achieved.*/
     Do while(len>&l_maxnamelen. and klen>1);
      klensub=klen-1;
      Call symput('varlev',ksubstr(symget('varlev'),1,klensub));  /*Use ksubstr to prevent invalid truncation of multi-byte national characters.*/
      len=length(symget('varlev'));
      klen=klength(symget('varlev'));
     End;
     VARLEV=symget('varlev');
     VARLEVUP=upcase(varlev);
    End;
   End;
   Else do;   /*Length of _varname_ at or one less than the max name length.*/
    num+1;
    call symput('varlev',ktrim(_varname_)||strip(put(num,10.)));   /*Concatenate the sequence number to the _varname_ value.*/
    klen=klength(_varname_);
    digit=1;
    len=length(symget('varlev'));   
/*Trim if necessary to bring to the maximum name length.*/
    Do while(len>&l_maxnamelen. and klen>digit);
     klensub=klen-digit;
     call symput('varlev',ksubstr(_varname_,1,klensub)||strip(put(num,10.)));
     len=length(symget('varlev'));
     digit=digit+1;
    End;
    VARLEV=symget('varlev');
    VARLEVUP=upcase(varlev);
   End;
  End;
 Run;

 Proc sort data=&l_lib..card_d2;
  By varlevup;
 Run;

 %local dummylast;
 %let dummylast=0;
/*Rename varlev so as to eliminate any duplicates generated in the Data Steps above.*/
/*Substitute a generic variable name (_CLASSLEVn) for these duplicates.*/
 Data &l_lib..card_d3;
  Set &l_lib..card_d2 end=last;
  By varlevup;
  Retain vardup 0;
  Drop vardup;
  If not(first.varlevup) then do;
   vardup+1;
   varlev='_CLASSLEV'||strip(put(vardup,10.));
/*If the variable has a label, add _varname_ to VARLABEL since VARLEV no longer includes the original variable name (_varname_).*/
   If labelnew ne _varname_ then do;
    Call symput('varlabel',ktrim(varlabel));
    VARLABEL=tranwrd(ktrim(_varname_),"'","''")||': '||symget('varlabel');
    Call symput('labelrpt',ktrim(labelrpt));
    LABELRPT=ktrim(_varname_)||': '||symget('labelrpt');
   End;
  End;
  If last then call symputx('dummylast',vardup,'F');
 Run;

/*Check for any duplicates that may have been created with non-class variable inputs or other variables.*/
 Proc sql noprint;
  Select "'"||ktrim(tranwrd(a.varlev,"'","''"))||"'"
  Into :vardup1 -
  From &l_lib..card_d3 a, &l_lib..varmeta b
  Where upcase(a.varlev)=upcase(b.name);
 Quit;

 %let l_obs=&sqlobs.;

/*Rename any Varlev values that conflict with these variables.*/
/*Substitute a generic variable name (_CLASSLEVn) for those varlev values that conflict.*/
/*If the variable has a label, add _varname_ to VARLABEL since VARLEV no longer includes the original variable name (_varname_).*/
%If (&l_obs.>0) %then %do;
  Data &l_lib..card_d3;
   Set &l_lib..card_d3;
 %Do x=1 %to &l_obs.;
   If varlev=&&vardup&x. then do;
    If labelnew ne _varname_ then do;
     Call symput('varlabel',ktrim(varlabel));
     VARLABEL=tranwrd(ktrim(_varname_),"'","''")||': '||symget('varlabel');
     Call symput('labelrpt',ktrim(labelrpt));
     LABELRPT=ktrim(_varname_)||': '||symget('labelrpt');
    End;
    varlev="_CLASSLEV%eval(&dummylast.+&x.)";
   End;
  %If (&x.<&l_obs.) %then else;
 %End;
  Run;
%End;

 Proc sort data=&l_lib..card_d3;
  By _varname_ cfmt;
 Run;
 %If not(&syscc. in (0 4)) %then %goto exit;

/*Class Variable Mapping report table*/
Proc sql;
 Create table &l_lib..classvar_mapping as
 Select _varname_ label="Variable Name",
        label label="Variable Label",
        fmtvalrpt label="Class Level",
        varlev label="Class Level Variable Name"
 From &l_lib..card_d3
 Order by _varname_, fmtvalrpt;
Quit;

 Title 'Class Variable Mapping';
 options NLDECSEPARATOR;
 Proc print data=&l_lib..classvar_mapping label;
 Run;
 options NONLDECSEPARATOR;
 Title;

/*Generate the Length statement for each dummy variable and write to Macro Variables (e.g. &varlen1_1, &varlen1_2, etc.).*/
/*Generate the Label statement for each dummy variable and write to Macro Variables (e.g. &varlbl1_1, &varlbl1_2, etc.).*/
/*Generate the zero initialization statement for each dummy variable and write to Macro Variables (e.g. &varzero1_1, &varzero1_2, etc.).*/
  Data &l_lib..card_d4 (drop=string num);
   Set &l_lib..card_d3;
   By _varname_;
   Length varany varlevany $300 string $1000;
   Retain varany '' num varnum 0;
   If first._varname_ then do;
    varnum+1;
    num=0;
    varany="'"||tranwrd(ktrim(_varname_),"'","''")||"'n";
   End;
   num+1;
   If last._varname_ then call symputx('var'||strip(put(varnum,10.)),num,'L');
   varlevany="'"||tranwrd(ktrim(varlev),"'","''")||"'n";
   If symget('l_dummyvarrole')='INTERVAL' then do;   /*Interval class level indicators*/
    Call symputx('varzero'||strip(put(varnum,10.))||'_'||strip(put(num,10.)),ktrim(varlevany)||'=0;','L');   /*Zero assignent statement*/
    Call symputx('varlen'||strip(put(varnum,10.))||'_'||strip(put(num,10.)),'Length '||ktrim(varlevany)||' 8;','L');  /*Length statement*/
   End;
   Else do;  /*Binary (character) class level indicators*/
    Call symputx('varzero'||strip(put(varnum,10.))||'_'||strip(put(num,10.)),ktrim(varlevany)||"='0';",'L');    /*Character zero assignent statement*/
    Call symputx('varlen'||strip(put(varnum,10.))||'_'||strip(put(num,10.)),'Length '||ktrim(varlevany)||' $1;','L');  /*Length statement*/
   End;
   string="Label "||ktrim(varlevany)||"='"||ktrim(varlabel)||"';";                           /*Label statement*/
   Call symputx('varlbl'||strip(put(varnum,10.))||'_'||strip(put(num,10.)),string,'L');
  Run;


/*****************************************/
/*                ScoreCode              */
/*****************************************/
/*Generate the Datastep code to create the class level indicators.  Write to the scorecode file.*/
 %If (%superq(p_vdmmlflag)=1) %then %dmcas_debug(%str(Begin: Generate scorecode));
  %If (&p_scorecode.) %then Filename class "&l_scorecodefile."%str(;);
  %Else Filename class TEMP%str(;);
  Data _null_;
   Set &l_lib..card_d4;
   By _varname_;
   Length string $1000;
   File class;
   If first._varname_ then do;
    put;
    put '/****** ' _varname_ '******/';
    num=input(symget('var'||strip(put(varnum,10.))),10.);
    Do x=1 to num;
     string=symget('varlen'||strip(put(varnum,10.))||'_'||strip(put(x,10.)));  /*Length statements*/
     put string;
     string=symget('varlbl'||strip(put(varnum,10.))||'_'||strip(put(x,10.)));  /*Label statements*/
     put string;
    End;
    put "if not(missing(" varany +(-1) ")) then do;";
    Do x=1 to num;
     string=symget('varzero'||strip(put(varnum,10.))||'_'||strip(put(x,10.)));   /*Set all class level indicators to zero.*/
     put string;
    End;
   End;
/*Variable contains a format.*/
   If format ne '' then do;
    If symget('l_dummyvarrole')='INTERVAL' then
     string="if kleft(put("||ktrim(varany)||","||strip(format)||"))='"||ktrim(fmtval)||"' then "||ktrim(varlevany)||"=1;";
    Else
     string="if kleft(put("||ktrim(varany)||","||strip(format)||"))='"||ktrim(fmtval)||"' then "||ktrim(varlevany)||"='1';";
    put string;
   End;
/*Variable doesn't contain a format.*/
   Else do;
/*Character variables*/
    If _type_='C' then do;
     If symget('l_dummyvarrole')='INTERVAL' then
      string="if kleft("||ktrim(varany)||")='"||ktrim(fmtval)||"' then "||ktrim(varlevany)||"=1;";
     Else
      string="if kleft("||ktrim(varany)||")='"||ktrim(fmtval)||"' then "||ktrim(varlevany)||"='1';";
     put string;
    End;
/*Numeric variables*/
    Else if _type_='N' then do;
     If symget('l_dummyvarrole')='INTERVAL' then
      string="if left(put("||ktrim(varany)||",BEST12.))='"||ktrim(fmtval)||"' then "||ktrim(varlevany)||"=1;";
     Else
      string="if left(put("||ktrim(varany)||",BEST12.))='"||ktrim(fmtval)||"' then "||ktrim(varlevany)||"='1';";
     put string;
    End;
   End;
   If not(last._varname_) then put 'else';
   Else put 'end;';
  Run;
 %If (%superq(p_vdmmlflag)=1) %then %dmcas_debug(%str(End: Generate scorecode));
 %If not(&syscc. in (0 4)) %then %goto exit;

/*Generate the output CAS table containing the class level indicators if &cl_outtable is populated.*/
%If %superq(cl_outtable) ne %then %do;
 Data &l_caslibref..&cl_outtable.;
  Set &l_data.;
  %include class;
 Run;
%End;


/*****************************************/
/*          Metadata Delta Code          */
/*****************************************/
%If (&p_scorecode. and %superq(p_vdmmlflag)=1) %then %do;
%dmcas_debug(Begin: Delta Code generation)
Filename delta "&l_deltacodefile";  /*Delta Code file*/
/*Generate the Delta code to reject the original class variables.*/
/*Comment for rejection:  Replacement of class variables with class level indicators.*/
Data _null_;
 Set &l_lib..card_d3;
 By _varname_;
 Length string $500;
 File delta;
 If first._varname_ then do;
  If _n_ ne 1 then put 'else';
  string="if upcase(NAME)='"||upcase(tranwrd(ktrim(_varname_),"'","''"))||"' then do; ROLE='REJECTED'; COMMENT='report.varclus_classvar_rejected.txt'; end;";
  Put string;
 End;
Run;

/*Generate the Delta code for the new class level indicators.*/
Data &l_lib..dummy;
 Set &l_lib..card_d3;
 Length string $500 ROLE $32 LEVEL $10;
 Keep name role level labelrpt;
 NAME=varlev;
 Retain role 'INPUT' level "&l_dummyvarrole.";
 File delta MOD;
 put 'else';
 string="if upcase(NAME)='"||upcase(tranwrd(ktrim(varlev),"'","''"))||"' then do; ROLE='INPUT'; LEVEL='"||"&l_dummyvarrole."||"'; end;";
 Put string;
Run;
%dmcas_debug(End: Delta Code generation)

/*OUTMETA dataset contains the output variable metadata, which includes the class level indicators.*/
Data &l_lib..outmeta;
 Set &l_meta. (where=(role ne 'REJECTED') rename=(label=labelorig)) &l_lib..dummy;
 length LABEL $1000 REASON $100;
 Retain reason '';
 Keep name label level role reason;
 label=labelorig;
 If labelrpt ne '' then label=labelrpt;
Run;

/*Set role=REJECTED for the orginal Class variables.*/
/*Set reason=Replacement of class variables with class level indicators*/
Proc sql;
 Update &l_lib..outmeta
 Set role='REJECTED', reason=sasmsg('sashelp.dmcas','dm_vclus_classvarrej_var_100','N')
 Where name in
  (Select _varname_
   From &l_lib..card_d3);
Quit;
%End;
%exit:
%Mend;
%dmcas_classlevs(p_dummyvarrole=INTERVAL)
