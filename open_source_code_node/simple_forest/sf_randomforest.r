# Builds Random Forest model with 100 trees

library(randomForest)

# Fit RandomForest model w/ training data
dm_model <- randomForest(dm_model_formula, ntree=100, data=dm_traindf, importance=TRUE)

# Save MSE plot to PNG
png("rpt_forestMsePlot.png")
plot(dm_model, main='randomForest MSE Plot')
dev.off()

# Save VariableImportance to CSV
write.csv(importance(dm_model), file="rpt_forestIMP.csv", row.names=TRUE)

# Score full data
dm_scoreddf <- data.frame(predict(dm_model, dm_inputdf, type="prob"))
colnames(dm_scoreddf) <- c("P_DEFAULT_NEXT_MONTH0", "P_DEFAULT_NEXT_MONTH1")
