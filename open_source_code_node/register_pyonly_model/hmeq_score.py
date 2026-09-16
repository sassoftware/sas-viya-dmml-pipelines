import pickle
import numpy as np
import pandas as pd

# Load pickle file objects
with open(settings.pickle_path + dm_pklname, 'rb') as f:
    imputer, ohe, model = pd.read_pickle(f)


def score_method(DELINQ, DEROG, JOB, NINQ, REASON, CLAGE, CLNO, DEBTINC, LOAN, MORTDUE, VALUE, YOJ):
    "Output: P_BAD0, P_BAD1, I_BAD"

    # If/Else block to differentiate between single and batch data
    if not isinstance(JOB, pd.Series):
        index = [0]
    else:
        index = None

    threshold =.5

    input_array = pd.DataFrame(
        {
            "JOB": JOB,
            "REASON": REASON,
            "CLAGE": CLAGE,
            "CLNO": CLNO,
            "DEBTINC": DEBTINC,
            "DELINQ": DELINQ,
            "DEROG": DEROG,
            "NINQ": NINQ,
            "YOJ": YOJ, 
            "LOAN": LOAN, 
            "MORTDUE": MORTDUE, 
            "VALUE": VALUE
        },
        index=index
    )
    
    dm_class_input = ["DELINQ", "DEROG", "JOB", "NINQ", "REASON"]
    dm_interval_input = ["CLAGE", "CLNO", "DEBTINC", "LOAN", "MORTDUE", "VALUE", "YOJ"]

    # Impute interval missing values to median if needed
    rec_intv = input_array[dm_interval_input]
    rec_intv_imp = imputer.transform(rec_intv)

    # One-hot encode class inputs, unknown levels are set to all 0s
    rec_class = input_array[dm_class_input].map(str)
    rec_class_ohe =  ohe.transform(rec_class).toarray()

    # Score data passed to this method
    full =np.concatenate([rec_intv_imp,rec_class_ohe], axis=1)
    prediction = pd.DataFrame(model.predict_proba(full))

    if isinstance(prediction, np.ndarray):
        prediction = prediction.tolist()

    if input_array.shape[0] == 1:
        if prediction[0][1] > threshold:
            I_BAD = "1"
        else:
            I_BAD = "0"
        return I_BAD, prediction[0][1]
    else:
        df = pd.DataFrame(prediction)
        proba = df[1]
        classifications = np.where(df[1] > threshold, "1", "0")
        return pd.DataFrame(
            {"I_BAD": classifications, "P_BAD1": proba, "P_BAD0": 1-proba}
        )
