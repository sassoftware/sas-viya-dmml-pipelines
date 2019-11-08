import numpy as np
print('Input column names:')
print(dm_inputdf.columns)

# Log transform IMP_DEBTINC variable
dm_scoreddf = dm_inputdf
dm_scoreddf['LOG_IMP_DEBTINC'] = np.log(dm_inputdf['IMP_DEBTINC'])
dm_scoreddf.drop('IMP_DEBTINC', axis=1, inplace=True)

print('Output column names:')
print(dm_scoreddf.columns)