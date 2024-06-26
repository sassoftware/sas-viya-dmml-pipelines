import numpy as np
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import OneHotEncoder
from sklearn import ensemble
import pickle

# Enable compact pritning of numpy arrays
np.set_printoptions(suppress=True, precision=2)

#----------
# Prepare data for training
#----------
# Get interval inputs
trainX_intv = dm_traindf[dm_interval_input]
# Get class inputs, convert data to str (missing becomes nan str)
trainX_class = dm_traindf[dm_class_input].applymap(str)

# Impute interval missing values to median
intv_imputer = SimpleImputer(strategy='median')
intv_imputer = intv_imputer.fit(trainX_intv)
trainX_intv_imp = intv_imputer.transform(trainX_intv)

# One-hot encode class inputs, unknown levels are set to all 0s
class_ohe = OneHotEncoder(handle_unknown="ignore")
class_ohe = class_ohe.fit(trainX_class)
trainX_class_ohe = class_ohe.transform(trainX_class).toarray()

# Concatenate interval and class input arrays
trainX = np.concatenate((trainX_intv_imp, trainX_class_ohe), axis=1)
trainy = dm_traindf[dm_dec_target]
#print(trainX)
#print(trainy)

#----------
# Train a model
#----------
# Fit Random Forest model w/ training data
params = {'n_estimators': 100, 'max_depth': 20, 'min_samples_leaf': 5}
dm_model = ensemble.RandomForestClassifier(**params)
dm_model.fit(trainX, trainy)
#print(dm_model)

#----------
# Create dm_scoreddf
#----------
fullX_intv = dm_inputdf[dm_interval_input]
fullX_intv_imp = intv_imputer.transform(fullX_intv)

fullX_class = dm_inputdf[dm_class_input].applymap(str)
fullX_class_ohe = class_ohe.transform(fullX_class).toarray()

fullX = np.concatenate((fullX_intv_imp, fullX_class_ohe), axis=1)

# Score full data: posterior probabilities
dm_scoreddf_prob = pd.DataFrame(dm_model.predict_proba(fullX), columns=dm_predictionvar)

# Score full data: class prediction
dm_scoreddf_class = pd.DataFrame(dm_model.predict(fullX), columns=[dm_classtarget_intovar])

# Column merge posterior probabilities and class prediction
dm_scoreddf = pd.concat([dm_scoreddf_prob, dm_scoreddf_class], axis=1)
print('***** 5 rows from dm_scoreddf *****')
print(dm_scoreddf.head(5))
print(dm_input)
print(', '.join(dm_input))

#----------
# Results
#----------
# Save VariableImportance to CSV
# Use try-except to support deprecated method in scikit-learn version >1.2
try:
    full_input_vars = dm_interval_input + list(class_ohe.get_feature_names())
except AttributeError:
    full_input_vars = dm_interval_input + list(class_ohe.get_feature_names_out())
varimp = pd.DataFrame(list(zip(full_input_vars, dm_model.feature_importances_)), columns=['Variable Name', 'Importance'])
varimp.to_csv(dm_nodedir + '/rpt_var_imp.csv', index=False)

#----------
# Build composite pickle file
#----------
with open(dm_pklpath, 'wb') as f:
    pickle.dump(intv_imputer, f)
    pickle.dump(class_ohe, f)
    pickle.dump(dm_model, f)
