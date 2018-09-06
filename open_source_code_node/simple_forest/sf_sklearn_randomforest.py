# Builds RandomForest model with 100 trees
# THIS EXAMPLE DOES NOT DUMMY ENCODE CATEGORICAL VARIABLES

from sklearn import ensemble

# Training data
X = dm_traindf.loc[:, dm_input]

# Labels
y = dm_traindf[dm_dec_target]

# Fit RandomForest model w/ training data
params = {'n_estimators': 100}
dm_model = ensemble.RandomForestClassifier(**params)
dm_model.fit(X, y)
print(dm_model)

# Save VariableImportance to CSV
varimp = pd.DataFrame(list(zip(X, dm_model.feature_importances_)), columns=['Variable Name', 'Importance'])
varimp.to_csv(dm_nodedir + '/rpt_var_imp.csv', index=False)

# Score full data
fullX = dm_inputdf.loc[:, dm_input]
dm_scoreddf = pd.DataFrame(dm_model.predict_proba(fullX), columns=['P_DEFAULT_NEXT_MONTH0', 'P_DEFAULT_NEXT_MONTH1'])
