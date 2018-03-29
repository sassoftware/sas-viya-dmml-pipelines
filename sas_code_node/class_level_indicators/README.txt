This example SAS code generates the class level indicators (also known as dummy variables) with values of 0 or 1 for all class inputs identified in metadata.  Score code is generated which creates the class level indicators.

The class level indicator variable names are derived as <ClassVariableName>_<ClassLevel>.  If the length of a derived name is greater 
than the Maximum name length (default of 32), the class level part of the name is trimmed down to bring the name to LE the maximum.  If a class variable name itself is at the maximum, the last characters of the variable name are
replaced with ascending numeric digits to derive the variable names.  Any duplicates in resulting names are resolved by
using the generic name _CLASSLEVn (_CLASSLEV1, _CLASSLEV2, etc.) for the duplicates.  Any name conflicts with other
variables in the source data are resolved also by using _CLASSLEVn.

See the comments at the top of the SAS code for macro variables you can change as desired.  

Instructions: In Model Studio, add a Code node to your pipeline, then open it and paste this code into the code editor, then save and close the node.  Nodes added to this Code node will use the class level indicators as interval inputs (by default) in place of the original class inputs.
