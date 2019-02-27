library(rpart)
library(rpart.plot)
library(ggplot2)

# Build decision tree model
dm_model <- rpart(dm_model_formula, data=dm_traindf)

# Using rpart.plot build decision tree visual and save to file
png("rpt_tree_classification.png")
prp(dm_model)

# Using ggplot2 build scatter plot visual and save to file
png("rpt_ggscatter.png")
ggplot(data=dm_inputdf, aes(x=Horsepower, y=MSRP)) + 
  geom_point(size=2, aes(color=DriveTrain)) + 
  ggtitle("Data exploration(scatter plot) using CARS data")

# Using ggplot2 build density plot visual and save to file
png("rpt_ggdensity.png")
ggplot(data=dm_inputdf, aes(x=as.numeric(MSRP))) + 
  geom_density(size=2, aes(color=DriveTrain)) + 
  ggtitle("Data exploration(density plot) using CARS data")

# Using ggplot2 build heatmap visual and save to file
png("rpt_ggheatmap.png")
ggplot(data=dm_inputdf, aes(y=MSRP, x=factor(Cylinders))) + 
  geom_bin2d() + 
  ggtitle("Data exploration(heatmap) using CARS data")

dev.off()