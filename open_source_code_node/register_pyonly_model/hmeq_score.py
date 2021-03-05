import pickle
import numpy as np
import pandas as pd

# Load pickle file objects
with open(settings.pickle_path + dm_pklname, 'rb') as f:
    imputer = pickle.load(f)
    ohe = pickle.load(f)
    model = pickle.load(f)

def score_method(DELINQ, DEROG, JOB, NINQ, REASON, CLAGE, CLNO, DEBTINC, LOAN, MORTDUE, VALUE, YOJ):
    "Output: P_BAD0, P_BAD1, I_BAD"

    # Create single row dataframe
    record = pd.DataFrame([[DELINQ, DEROG, JOB, NINQ, REASON, CLAGE, CLNO, DEBTINC, LOAN, MORTDUE, VALUE, YOJ]],\
             columns=['DELINQ', 'DEROG', 'JOB', 'NINQ', 'REASON', 'CLAGE', 'CLNO', 'DEBTINC', 'LOAN', 'MORTDUE', 'VALUE', 'YOJ'])

    dm_class_input = ["DELINQ", "DEROG", "JOB", "NINQ", "REASON"]
    dm_interval_input = ["CLAGE", "CLNO", "DEBTINC", "LOAN", "MORTDUE", "VALUE", "YOJ"]

    # Impute interval missing values to median if needed
    rec_intv = record[dm_interval_input]
    rec_intv_imp = imputer.transform(rec_intv)

    # One-hot encode class inputs, unknown levels are set to all 0s
    rec_class = record[dm_class_input].applymap(str)
    rec_class_ohe = ohe.transform(rec_class).toarray()

    # Score data passed to this method
    rec = np.concatenate((rec_intv_imp, rec_class_ohe), axis=1)
    rec_pred_prob = model.predict_proba(rec)
    rec_pred = model.predict(rec)

    return float(rec_pred_prob[0][0]), float(rec_pred_prob[0][1]), float(rec_pred[0])