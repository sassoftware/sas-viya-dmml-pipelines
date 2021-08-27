## Summary

The **open_source_code_node** folder contains example pipelines and materials for using Model Studio's Open Source Code node that is first shipped as part of SAS Visual Data Mining and Machine Learning (VDMML) 8.3 release.

In Model Studio, the Open Source Code node is a Miscellaneous node that can run Python or R code. This node can subsequently be moved to the Supervised Learning group if a Python or R model needs to be assessed and compared with other models using the Model Comparison node. For convenience, a [list of variables](https://go.documentation.sas.com/?cdcId=vdmmlcdc&cdcVersion=8.3&docsetId=vdmmlref&docsetTarget=p0doq3u7i2yghzn1azsbn1eu9zmf.htm&locale=en) are made available to the user in the Open Source Code node editor.

### Pipelines with Python score code
Starting with the 2021.1.1 release of SAS Viya 4, the capability to productionalize the pipelines was incrementally added and full support to register them to [SAS Model Manager](https://support.sas.com/en/software/model-manager-support.html) is available from 2021.1.4 release. Note that this registration capability applies to the Python language and not R. Refer to the [blog post](https://blogs.sas.com/content/subconsciousmusings/2021/08/25/machine-learning-pipeline-using-sas-and-python/) and examples in register_pyonly_model, register_py_model, and register_py_preprocess folders for more details.

#### Things to remember when creating pipelines with Python score code
- If there are any nodes after the Open Source Code node, remember to select the “Use output data in child node” property. This makes the output data created in the training code (dm_scoreddf) available to the next node in the pipeline.
- When saving to a Python pickle file in the Training code pane or reading it from the Scoring code pane, use the pre-defined handles. The variable handle in Training code pane is dm_pklpath and that in Scoring code pane is dm_pklname. This enables Model Studio to save the pickle file to a known location and eventually move it to SAS Model Manager during registration.
- Score code written in Scoring code pane should adhere to a pre-defined format for consumption by SAS Model Manager (see Rules when writing score code section below).
- Score code provided in the Scoring code pane is not validated by Model Studio so make sure it is valid. You can use the Training code pane to run a quick test if necessary.

#### Rules when writing Python score code
When registering pipelines to SAS Model Manager, you will need to provide score code (as a Python function) in addition to train code. The score function should be of the form:
```python
def score_record(var_1, var_2, var_3, var_4):
    "Output: outvar_1, outvar_2"
    <code line 1>
    <code line 2 and so on>
    return out_1, out_2
```
The first line of the score function should contain the "Output: outvar_1, outvar_2" string listing the return variables names in the order they will be returned when the function is called.

If a pickle file is saved in dm_pklpath in the Training code pane of the code editor, it can be accessed in the Scoring code pane with the following Python code:
```python
open(settings.pickle_path + dm_pklname)
```
Samples of the score code are available in hmeq_score.py file in register_pyonly_model, register_py_model/example1, and register_py_preprocess/example1 folders


### Additional resources
- [Executing Open Source Code in SAS Visual Data Mining & Machine Learning Pipelines (video)](https://youtu.be/VSryf7qJi1g)
- [SAS Visual Data Mining and Machine Learning 8.5 User's Guide Reference Help: Open Source Code node](https://go.documentation.sas.com/?cdcId=vdmmlcdc&cdcVersion=8.5&docsetId=vdmmlref&docsetTarget=n0gn2o41lgv4exn17lngd558jcso.htm&locale=en)
