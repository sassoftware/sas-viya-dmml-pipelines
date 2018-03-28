
proc cardinality data=&dm_data outcard=&dm_datalib..outcard;
	var %dm_interval_input;
run;

filename deltac "&dm_file_deltacode";

data skewed;
	file deltac;
	set &dm_datalib..outcard end=eof;

	length codeline $ 500;
	if _skewness_ > 3 then do;
		codeline = "if upcase(NAME) = '"!!upcase(tranwrd(ktrim(_VARNAME_), "'", "''"))!!"' then do;";
		put codeline;

		codeline = "TRANSFORM    = 'LOG';";
		put +3 codeline;
		put 'end;';
		output;
	end;
run;

filename deltac;

title 'Variables to Log-transform';
proc print data=skewed label;
	var _varname_ _skewness_;
run;

title;

