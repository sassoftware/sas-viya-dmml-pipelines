## Summary

The **open_source_code_node** folder contains example pipelines and materials for using Model Studio's Open Source Code node that is first shipped as part of SAS Visual Data Mining and Machine Learning (VDMML) 8.3 release.

In Model Studio, the Open Source Code node is a Miscellaneous node that can run Python or R code. This node can subsequently be moved to the Supervised Learning group if a Python or R model needs to be assessed and compared with other models using the Model Comparison node. For convenience, a [list of variables](https://go.documentation.sas.com/?cdcId=vdmmlcdc&cdcVersion=8.3&docsetId=vdmmlref&docsetTarget=p0doq3u7i2yghzn1azsbn1eu9zmf.htm&locale=en) are made available to the user in the Open Source Code node editor.

Starting with the 2021.1.1 release of SAS Viya 4, the capability to productionalize these pipelines was incrementally added and full support to register them to SAS Model Manager is available from 2021.1.4 release. Note that this applies to the Python language and not R. Refer to the [blog post](https://blogs.sas.com/content/subconsciousmusings/2021/08/25/machine-learning-pipeline-using-sas-and-python/) and examples in register_pyonly_model, register_py_model, and register_py_preprocess folders for more details.

### Additional resources
- [Executing Open Source Code in SAS Visual Data Mining & Machine Learning Pipelines (video)](https://youtu.be/VSryf7qJi1g)
- [SAS Visual Data Mining and Machine Learning 8.5 User's Guide Reference Help: Open Source Code node](https://go.documentation.sas.com/?cdcId=vdmmlcdc&cdcVersion=8.5&docsetId=vdmmlref&docsetTarget=n0gn2o41lgv4exn17lngd558jcso.htm&locale=en)
