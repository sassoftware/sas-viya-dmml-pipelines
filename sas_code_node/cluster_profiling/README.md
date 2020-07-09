This example is SAS code for providing some basic profiling of clusters. 

The basic cluster profiler helps you interpret clusters derived using the Clustering node. The results consist of two plots: 

1. Input Variable Distributions by Cluster. 
   - The frequency distribution for each input variable, color coded by Cluster ID. Any interval inputs are binned. You can use these plots to see and compare the distribution of each variable across the different clusters. 

2. Cluster Projection
   - A principal components projection of the input variables in two dimensions. Each observation is color coded by Cluster ID. You can use the plot to judge the degree of separation vs. overlap among the clusters. Note that the projection only considers interval input variables, so if your cluster solution involves a large proportion of class inputs, the projection may lose fidelity.

**Instructions:** In Model Studio, place a SAS Code node after a Clustering node in your pipeline, paste this code into the Training Code pane and run the node.

