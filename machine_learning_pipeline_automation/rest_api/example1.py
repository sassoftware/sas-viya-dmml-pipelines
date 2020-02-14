# Invoke Machine Learning Pipeline Automation (MLPA) using the REST API
import requests json, uuid, time
 
# -------------------------------------------------------------------
# Set up parameters, data set name, target name, and CAS library name
# -------------------------------------------------------------------
urlPrefix   = 'http://hostname.sas.com'
authUser    = 'userid'
authPw      = 'password'
datasetName = 'uci_default_credit_card'
target      = 'default_payment_next_month'
publicUri   = '/dataTables/dataSources/cas~fs~cas-shared-default~fs~Public/tables/'
 
# Append uuid to make projectName unique
projectName = datasetName + "-" + str(uuid.uuid4())
 
 
# -----------------------------------------------
# Function definitions
# -----------------------------------------------
def executeRestCall(urlPrefix, method, uri, requestBody, headers, fullResponse=False):
  response = requests.request(method, urlPrefix + uri, json=requestBody, headers=headers)
  response_txt = response.text
 
  if response.status_code >= 400:
    print("Error in executeRestCall with status_code: " + str(response.status_code))
    print(response_txt)
 
  if fullResponse:
    return response, json.loads(response_txt)
  else:
    return json.loads(response_txt)
 
def executeRestCallWithPayload(urlPrefix, method, uri, payload, headers):
  response = requests.request(method, urlPrefix + uri, data=payload, headers=headers)
  response_txt = response.text
 
  if response.status_code >= 400:
    print("Error in executeRestCallWithPayload with status_code: " + str(response.status_code))
    print(response_txt)
 
  return json.loads(response_txt)
 
def getOauthToken(urlPrefix, authCred):
  tokenUri = "/SASLogon/oauth/token"
  payload = "grant_type=" + authCred
  headers = {
    'accept': "application/json",
    'content-type': "application/x-www-form-urlencoded",
    'authorization': "Basic c2FzLmVjOg=="
  }
 
  token = executeRestCallWithPayload(urlPrefix, "POST", tokenUri, payload, headers)
  return "Bearer " + token["access_token"]
 
 
# -----------------------------------------------
# Get authentication token
# -----------------------------------------------
authCred = 'password&username=' + authUser + '&password=' + authPw
oauthToken = getOauthToken(urlPrefix, authCred)
 
 
# -----------------------------------------------
# REST request for creating MLPA project
# -----------------------------------------------
tokenUri = "/mlPipelineAutomation/projects"
headers = {
  'Authorization': oauthToken,
  'Accept': "application/vnd.sas.analytics.ml.pipeline.automation.project+json",
  'Content-Type': "application/json"
}
payload = {
  'dataTableUri': publicUri + datasetName,
  'type': 'predictive',
  'name': projectName,
  'description': 'Project generated for test',
  'settings': {
    'autoRun': True,
    'modelingMode': 'Standard',
    'maxModelingTime': 30
  },
  'analyticsProjectAttributes': {
    'targetVariable': target
  }
}
payload_data = json.dumps(payload, indent=4)
 
 
# Create new MLPA project and run pipeline
mlpaProject = executeRestCallWithPayload(urlPrefix, "POST", tokenUri, payload_data, headers)
 
# Print settings and attributes of new MLPA project being created
for key, val in mlpaProject['settings'].items():
  print(key + '=' + str(val))
for key, val in mlpaProject['analyticsProjectAttributes'].items():
  print(key + '=' + str(val))
 
 
# -----------------------------------------------------------
# Poll every 5 seconds until MLPA project state is completed
# -----------------------------------------------------------
projectStateLink = list(filter(lambda x: x["rel"] == "state", mlpaProject["links"]))[0]
headers = {
  'Authorization': oauthToken,
  'Accept': projectStateLink["type"]
}
 
attempts = 0
maxAttempts = 60*60/5
while True:
  attempts = attempts + 1
  projectState = requests.request(projectStateLink["method"], urlPrefix + projectStateLink["uri"], headers=headers).text
  print("Polling project state: Attempt " + str(attempts) + ", state is " + projectState)
 
  if projectState == "completed" or projectState == "failed" or attempts > maxAttempts:
    break;
 
  time.sleep(5)
 
print("Final MLPA project state is " + projectState + ', polled for approx ' + str(attempts*5/60) + ' minutes')
 
 
# -----------------------------------------------
# Get the champion model
# -----------------------------------------------
tokenUri = "/mlPipelineAutomation/projects/" + mlpaProject["id"] + "/championModel"
headers = {
  'authorization': oauthToken,
  'Content-type': "application/vnd.sas.analytics.ml.pipeline.automation.project.champion.model+json"
}
champModel = executeRestCall(urlPrefix, 'GET', tokenUri, [], headers)
 
print('Champion model is ' + champModel['championModelName'])
for itm in champModel['items']:
  if itm['name'] == 'projectSummary':
    print('***************************************')
    print('*** Champion model project summary: ***')
    print('***************************************')
    print(itm['data'][0]['dataMap']['contents'])
  elif itm['name'] == 'dmcas_relativeimportance':
    print('********************************')
    print('***' + itm['description'] + ': ***')
    print('********************************')
    for itm2 in itm['data']:
      print(itm2['dataMap'])
  elif itm['name'] == 'dmcas_lift':
    print('***********************')
    print('***' + itm['description'] + ': ***')
    print('***********************')
    for itm2 in itm['data']:
      print(itm2['dataMap'])
 
 
# ----------------------------------------------------
# Publish champion model to MAS (maslocal destination)
# ----------------------------------------------------
publishChampModelLink = list(filter(lambda x: x["rel"] == 'publishChampionModel', champModel["links"]))[0]
headers = {
  'authorization': oauthToken
}
 
publishChampModelResponse = requests.request(
  publishChampModelLink["method"],
  urlPrefix + publishChampModelLink["uri"].replace('{destinationName}', 'maslocal'),
  json=[],
  headers=headers)
 
if publishChampModelResponse.status_code == 200:
  print("Publishing champion model to MAS (maslocal destination) successful")
else:
  print("Error in publish champion model call, status_code: " + str(publishChampModelResponse.status_code))
  print(publishChampModelResponse.text)
 
 
# -----------------------------------------------
# Score data
# -----------------------------------------------
scoreDatalLink = list(filter(lambda x: x["rel"] == 'scoreData', champModel["links"]))[0]
headers = {
  'authorization': oauthToken,
  'Content-type': scoreDatalLink["type"] + "+json"
}
scoreRow = {
  "scoreType": "Individual",
  "destinationName" : "maslocal",
  "inputs": [
    {"name": "ID", "value": 50000},
    {"name": "LIMIT_BAL", "value": 80000},
    {"name": "AGE", "value": 38},
    {"name": "PAY_0", "value": -1},
    {"name": "PAY_2", "value": -1},
    {"name": "PAY_3", "value": 0},
    {"name": "PAY_4", "value": 0},
    {"name": "PAY_5", "value": -1},
    {"name": "PAY_6", "value": 0},
    {"name": "BILL_AMT1", "value": 2100},
    {"name": "BILL_AMT2", "value": 3000},
    {"name": "BILL_AMT3", "value": 3277},
    {"name": "BILL_AMT4", "value": 3100},
    {"name": "BILL_AMT5", "value": 1150},
    {"name": "BILL_AMT6", "value": 1000},
    {"name": "PAY_AMT1", "value": 1000},
    {"name": "PAY_AMT2", "value": 1000},
    {"name": "PAY_AMT3", "value": 1500},
    {"name": "PAY_AMT4", "value": 2000},
    {"name": "PAY_AMT5", "value": 1000},
    {"name": "PAY_AMT6", "value": 800},
    {"name": "sex", "value": "Female"},
    {"name": "education", "value": "GraduateSchool"},
    {"name": "marriage", "value": "Single"}
  ]
}
 
scoredData = executeRestCall(
        urlPrefix,
        scoreDatalLink["method"],
        scoreDatalLink["uri"],
        scoreRow,
        headers)
 
print('***************************************')
print("*** Score data, Execution state: " + scoredData["executionState"])
print('***************************************')
print("*** Score data, Output: ")
print('***************************************')
for itm in scoredData["outputs"]:
  if "value" in itm:
    print(itm["name"] + ": " + str(itm["value"]))
 
 
# -----------------------------------------------
# Retrain project
# -----------------------------------------------
# Get latest project information
mlpaProjectSelfLink = list(filter(lambda x: x["rel"] == 'self', mlpaProject["links"]))[0]
headers = {
  'authorization': oauthToken,
  'Content-type': mlpaProjectSelfLink["type"] + "+json"
}
mlpaProjectSelfResp, mlpaProjectSelf = executeRestCall(
                      urlPrefix,
                      mlpaProjectSelfLink["method"],
                      mlpaProjectSelfLink["uri"],
                      [],
                      headers,
                      fullResponse=True)
 
# Retrain
retrainProjectLink = list(filter(lambda x: x["rel"] == 'retrainProjectReplacePipelines', mlpaProjectSelf["links"]))[0]
headers = {
  'authorization': oauthToken,
  'If-Match': mlpaProjectSelfResp.headers['ETag'],
  'Content-type': retrainProjectLink["type"] + "+json"
}
mlpaProjectSelf['analyticsProjectAttributes']['classSelectionStatistic'] = 'mce'
retrainProject = executeRestCall(urlPrefix, retrainProjectLink["method"], retrainProjectLink["uri"], mlpaProjectSelf, headers)

