import pickle
import pandas as pd

with open(settings.pickle_path + dm_pklname, 'rb') as f:
    intv_imputer = pickle.load(f)
    class_imputer = pickle.load(f)
    
def score_method(CLAGE, CLNO, DEBTINC, LOAN, MORTDUE, VALUE, YOJ, DELINQ, DEROG, JOB, NINQ, REASON):
    "Output: IMP_CLAGE, IMP_CLNO, IMP_DEBTINC, IMP_LOAN, IMP_MORTDUE, IMP_VALUE, IMP_YOJ, IMP_DELINQ, IMP_DEROG, IMP_JOB, IMP_NINQ, IMP_REASON"

    record = pd.DataFrame([[CLAGE, CLNO, DEBTINC, LOAN, MORTDUE, VALUE, YOJ, DELINQ, DEROG, JOB, NINQ, REASON]],\
             columns=dm_interval_input+dm_class_input)

    rec_intv = record[dm_interval_input]
    rec_intv_imp = intv_imputer.transform(rec_intv)
    
    rec_class = record[dm_class_input]
    rec_class_imp = class_imputer.transform(rec_class)
    
    return float(rec_intv_imp[0][0]), float(rec_intv_imp[0][1]), float(rec_intv_imp[0][2]), float(rec_intv_imp[0][3]),\
           float(rec_intv_imp[0][4]), float(rec_intv_imp[0][5]), float(rec_intv_imp[0][6]),\
           rec_class_imp[0][0], rec_class_imp[0][1], rec_class_imp[0][2], rec_class_imp[0][3], rec_class_imp[0][4]
