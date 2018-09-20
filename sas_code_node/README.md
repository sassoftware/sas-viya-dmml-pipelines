## Summary

The sas_code_node folder contains example pipelines and materials for using Model Studio's SAS Code node.

In Model Studio, the SAS Code node is a Miscellaneous node. This node can be moved to the Supervised Learning group if the node writes out score code is that creates the required predicted variable or posterior probabilities, and this model can then be assessed and compared with other models using the Model Comparison node. 

This folder contains examples for:
- subsetting or filtering data
- creating class level indicators (also called one-hot or dummy encoding) for class inputs
- profiling clusters or segments created in a predecessor node such as the Clustering node
- setting the transformation for skewed variables to Log in the metadata, to be used by a subsequent Transformations node
- reversing the outlier filter created by the Anomaly Detection node so that outliers are analyzed instead of excluded by modifying the score code and metadata
