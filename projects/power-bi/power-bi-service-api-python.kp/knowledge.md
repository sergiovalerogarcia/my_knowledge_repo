---
authors:
- sergiovalero92@gmail.com
created_at: 2020-01-07 00:00:00
tags:
- powerbi
- api
title: Power Bi Service API Python
tldr: Power Bi Service API Python.
updated_at: 2020-01-19 16:46:28.772557
---

# Power Bi Service API Python

## Publish an app

Publish an app: <https://dev.powerbi.com/apps>

allowPublicClient: 
    1. <https://portal.azure.com/>
    2. App registrations
    3. Select you app 
    4. Manifest
    5. "allowPublicClient": true

## API Documentation
<https://docs.microsoft.com/en-us/rest/api/power-bi/>

## Code


```python
import adal
import requests
from adal import AuthenticationContext
```

```python
url_base = "https://api.powerbi.com/v1.0/myorg/" 
reportId = "fill_me"
groupId = "fill_me" #workspace
targetWorkspaceId = "fill_me"
```
### Get token


```python
def authenticate_device_code():
    authority_host_uri = 'https://login.microsoftonline.com'
    tenant = 'fill_me'
    authority_uri = authority_host_uri + '/' + tenant
    resource_uri = 'https://analysis.windows.net/powerbi/api'
    client_id = 'fill_me'

    context = adal.AuthenticationContext(authority_uri, api_version=None)
    code = context.acquire_user_code(resource_uri, client_id)
    print(code['message'])
    mgmt_token = context.acquire_token_with_device_code(resource_uri, code, client_id)
    return mgmt_token
```

```python
accessToken = authenticate_device_code()['accessToken']

headers = {
    "Authorization": "Bearer " + accessToken
}

```
### Get reports


```python
response = requests.get(url_base + "reports", headers=headers
```

```python
url = url_base + "groups/" + groupId + "/reports/" + reportId
response = requests.delete(url, headers=headers)
```

```python
url = url_base + "groups/" + groupId + "/reports/" + reportId + "/Clone"
data={
    'name': 'task',
    'targetWorkspaceId': targetWorkspaceId
}
response = requests.post(url, headers=headers, data=data)

```

```python
url = url_base + "groups/" + groupId + "/reports/" + reportId + "/Clone"
data={
    'name': 'task',
    'targetWorkspaceId': targetWorkspaceId
}
# response = requests.post(url, headers=headers, data=data)
# print (response)

```

```python
url = url_base + "groups/" + groupId + "/reports/" + reportId + "/Export"

response = requests.get(url, headers=headers)
print (response)

with open('fill_me.pbix', 'wb') as file:
    file.write(response.content)

```