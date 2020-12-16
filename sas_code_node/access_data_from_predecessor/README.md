This example SAS code shows how you can access data from a predecessor node in a SAS Code node.

list_data_from_predecessor.sas has code to list the data sets that were registered by the previous node if you don't know the name of the data set you want to access.

use_data_from_predecessor.sas shows how to access a data sets that was registered by the previous node when you already know its name.

Instructions: In Model Studio, add a SAS Code node to your pipeline as a child node to the node whose registered data you want to access, then open it and paste either code file into the Training Code pane, make any modifications needed, then save and close the node.
