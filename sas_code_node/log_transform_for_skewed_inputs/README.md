This example SAS code shows how you can modify the column metadata using the delta code file to set the transformation method for a subset of inputs. 

In this example, interval inputs that have a skewness greater than 3 have their Transform method set to "Log". When a Transformations node is used after the SAS Code node that runs this code, only those inputs are transformed.

**Instructions:** In Model Studio, add a SAS Code node to your pipeline, then open it and paste this code into the Training Code pane, then save and close the node. Add a Transformations node after the SAS Code node, and run the pipeline from that to have the skewed inputs log-transformed.
