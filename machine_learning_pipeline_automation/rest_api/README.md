## Summary

The Machine Learning Pipeline Automation REST API is a set of endpoints that enable you to control more parameters than those available through the Model Studio user interface. They allow you to embed this capability into your custom applications and drive it with a few clicks.

### example1.py
An end-to-end example in Python to automatically generate pipelines using the REST API. In the example code, modify the setup parameters urlPrefix (host name of the microservice), authUser (user ID), authPw (password), datasetName (name of the input data loaded in CAS), target (target variable in data), and publicUri (URI of CAS library name where data reside) in the beginning section. 

Data: [UCI Machine Learning Repository, Default of credit card clients](https://archive.ics.uci.edu/ml/datasets/default+of+credit+card+clients#) 

The example code performs the following steps:
1.  Creates a Model Studio project for automated pipeline.

2.  Polls every 5 seconds to wait until the project state goes to completion. The project state starts in pending state and transitions to waiting, ready, modeling, constructingPipeline, runningPipeline, and finally to completed state.

3.  Retrieves and prints the champion model information.

4.  Publishes the champion model to SAS Micro Analytic Service destination.

5.  Scores new data.

6.  Retrains project (when new training data become available).

Before you execute the example, the input data set should be loaded into the corresponding CAS library that is specified in the publicUri parameter, and the location of analytic store model files needs to be configured for the SAS Micro Analytic Service destination as described in the documentation for [SAS Viya Administration: Models](https://go.documentation.sas.com/?docsetId=calmodels&docsetTarget=n10916nn7yro46n119nev9sb912c.htm&docsetVersion=3.5&locale=en).

Refer to the [SAS developer site](https://developer.sas.com/apis/rest/MachineLearningPipeline) for more information about the REST APIs. 
