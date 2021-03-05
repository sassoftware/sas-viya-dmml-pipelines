## Register A Model With Python Score Code

This example shows how to register a model that has Python score code within the Open Source Code node. The pipeline has the form Data >> Open Source Code >> Model Comparison where the score code includes only Python code.

**This functionality is available from Viya 4 2020.1.3 release.**

Data: [HMEQ data](https://github.com/sassoftware/sas-viya-dmml-pipelines/tree/master/data/hmeq.csv)

Data Description: The data contains observations for 5,960 mortgage applicants. The variable BAD indicates whether the customer has paid on the loan (0) or has defaulted on it (1).


### Prerequisites to run the example
1. Apply [sas-open-source-config](https://go.documentation.sas.com/?cdcId=vdmmlcdc&cdcVersion=v_002&docsetId=vdmmlref&docsetTarget=n0uzvzre3sg7a5n1c30ipu1s039w.htm&locale=en) overlay (this example only needs Python part of the overlay)

2. Apply [sas-microanalytic-score astores](https://go.documentation.sas.com/?docsetId=masag&docsetTarget=n0er040gsczf7bn1mndiw7znffad.htm&docsetVersion=v_002&locale=en) overlay


### Steps to run this example
1. Download hmeq.csv file from link above.

2. Log into SAS Visual Data Mining & Machine Learning, choose "Build Models" (Model Studio) and create a new project; select the above CSV file as data source with default options.

3. Under Data tab, select BAD as target variable.

4. Under Pipelines tab, create a simple pipeline with nodes: **Data >> Open Source Code >> Model Comparison** (you need to move the Open Source Code node to Supervised Learning lane).

5. Select Open Source Code node and click Open Code Editor button from properties. Copy code from hmeq_train.py into the **Training Code** pane and hmeq_score.py into the **Scoring Code** pane of the editor. Click Save and close the editor.

6. Run the pipeline and right-click and select Results to view output

7. Under Pipeline Comparison tab, select the model from above pipeline and click the three vertical dots at top right corner to select **Register models**. This registers the model in SAS Model Manager from where it can be deployed to various publishing destinations.
