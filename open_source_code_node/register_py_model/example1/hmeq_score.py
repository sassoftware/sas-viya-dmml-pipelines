import pickle
import numpy as np
import pandas as pd

with open(settings.pickle_path + dm_pklname, 'rb') as f:
    ohe = pickle.load(f)
    model = pickle.load(f)

def score_method(IMP_DELINQ, IMP_DEROG, IMP_JOB, IMP_NINQ, IMP_REASON, IMP_CLAGE, IMP_CLNO, IMP_DEBTINC, IMP_MORTDUE, IMP_VALUE, IMP_YOJ, LOAN):
    "Output: P_BAD0, P_BAD1, I_BAD"

    record = pd.DataFrame([[IMP_DELINQ, IMP_DEROG, IMP_JOB, IMP_NINQ, IMP_REASON, IMP_CLAGE, IMP_CLNO, IMP_DEBTINC, IMP_MORTDUE, IMP_VALUE, IMP_YOJ, LOAN]],\
             columns=dm_class_input + dm_interval_input)

    rec_intv = record[dm_interval_input]

    rec_class = record[dm_class_input].applymap(str)
    rec_class_ohe = ohe.transform(rec_class).toarray()

    rec = np.concatenate((rec_intv, rec_class_ohe), axis=1)
    rec_pred_prob = model.predict_proba(rec)
    rec_pred = model.predict(rec)

    return float(rec_pred_prob[0][0]), float(rec_pred_prob[0][1]), float(rec_pred[0])
