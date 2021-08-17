from sklearn.impute import SimpleImputer
import numpy as np
import pickle

#----------
# Prepare data for training
#----------
# Impute interval missing values to median
intv_imputer = SimpleImputer(strategy='median')
intv_imputer = intv_imputer.fit(dm_traindf[dm_interval_input])
fullX_intv_imp = intv_imputer.transform(dm_inputdf[dm_interval_input])

# Impute class missing values to most_frequent
class_imputer = SimpleImputer(strategy='most_frequent')
class_imputer = class_imputer.fit(dm_traindf[dm_class_input])
fullX_class_imp = class_imputer.transform(dm_inputdf[dm_class_input])

# Concatenate interval and class input arrays
dm_scored_data = np.concatenate((fullX_intv_imp, fullX_class_imp), axis=1)
# Index columns include target, partition and key - they should be included in dm_scoreddf
dm_idx_cols = [dm_dec_target, dm_partitionvar, dm_key]
dm_idx_data = dm_inputdf[dm_idx_cols]
dm_scored = np.concatenate((dm_idx_data, dm_scored_data), axis=1)

dm_intv_imp_cols = ['IMP_' + s for s in dm_interval_input]
dm_class_imp_cols = ['IMP_' + s for s in dm_class_input]
dm_scoreddf = pd.DataFrame(dm_scored, columns=dm_idx_cols + dm_intv_imp_cols + dm_class_imp_cols)
print(dm_scoreddf.columns)
print(dm_scoreddf.shape)
print(dm_scoreddf.head(5).to_string(index=False))

#----------
# Build composite pickle file
#----------
with open(dm_pklpath, 'wb') as f:
    pickle.dump(intv_imputer, f)
    pickle.dump(class_imputer, f)
