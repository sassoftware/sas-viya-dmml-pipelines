library(rpart)
library(rpart.plot)
library(ggplot2)

# Build decision tree model
dm_model <- rpart(dm_model_formula, data=dm_traindf)

# Save decision tree visual to file using rpart.plot
png("rpt_tree_classification.png")
prp(dm_model)

# Save scatter plot visual to file using ggplot2
png("rpt_ggscatter.png")
ggplot(data=dm_inputdf, aes(x=Horsepower, y=MSRP)) + 
  geom_point(size=2, aes(color=DriveTrain)) + 
  ggtitle("Data exploration(scatter plot) using CARS data")

# Save density plot visual to file using ggplot2
png("rpt_ggdensity.png")
ggplot(data=dm_inputdf, aes(x=as.numeric(MSRP))) + 
  geom_density(size=2, aes(color=DriveTrain)) + 
  ggtitle("Data exploration(density plot) using CARS data")

# Save heatmap visual to file using ggplot2
png("rpt_ggheatmap.png")
ggplot(data=dm_inputdf, aes(y=MSRP, x=factor(Cylinders))) + 
  geom_bin2d() + 
  ggtitle("Data exploration(heatmap) using CARS data")

dev.off()