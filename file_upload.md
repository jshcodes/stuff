# Authentication

## Service Class
### Credential authentication
```python
from falconpy import sample_uploads as FalconUploads

falcon = FalconUploads.Sample_Uploads(creds={
        "client_id": falcon_client_id,
        "client_secret": falcon_client_secret
    }
)
```
### Object authentication
```python
from falconpy import oauth2 as FalconAuth
from falconpy import sample_uploads as FalconUploads

auth = FalconAuth.OAuth2({
        "client_id": falcon_client_id,
        "client_secret": falcon_client_secret
    }
)

falcon = FalconUploads.Sample_Uploads(auth_object=auth)
```
### Legacy authentication
```python
from falconpy import sample_uploads as FalconUploads

auth = FalconAuth.OAuth2({
        "client_id": falcon_client_id,
        "client_secret": falcon_client_secret
    }
)
try:
    token = auth.token()['body']['access_token']
except Exception:
    token = False
    
if token:
    falcon = FalconUploads.Sample_Uploads(access_token=token)
```
## Uber Class
```python
from falconpy import api_complete as FalconSDK

falcon = FalconSDK.APIHarness(creds={
        "client_id": falcon_client_id,
        "client_secret": falcon_client_secret
    }
)
```

# Interacting with the API

## Service Class
```python
FILENAME = "testfile.jpg"
PAYLOAD = open(FILENAME, 'rb').read()
response = falcon.UploadSampleV3(file_name="newfile.jpg", file_data=PAYLOAD)
sha = response["body"]["resources"][0]["sha256"]
response = falcon.GetSampleV3(ids=sha)
open('serviceclass.jpg', 'wb').write(response)
response = falcon.DeleteSampleV3(ids=sha)
print(json.dumps(response, indent=4))
```
## Uber Class
```python
FILENAME = "testfile.jpg"
PAYLOAD = open(FILENAME, 'rb').read()
response = falcon.command('UploadSampleV3', 
                          file_name="newfile.jpg",
                          data=PAYLOAD,
                          content_type="application/octet-stream"
                          )
sha = response["body"]["resources"][0]["sha256"]
response = falcon.command("GetSampleV3", ids=sha)
open('uberclass.jpg', 'wb').write(response)
response = falcon.command("DeleteSampleV3", ids=sha)
print(json.dumps(response, indent=4))
```