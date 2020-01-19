---
authors:
- sergiovalero92@gmail.com
created_at: 2020-01-07 00:00:00
tags:
- powerbi
- api
title: Power Bi Server API Python
tldr: Power Bi Server API Python.
updated_at: 2020-01-19 16:44:35.582853
---

## Power Bi Server API Python

This script update the policies of a specific folder using a user_list_to_append and all her reports roles based on a roleName.

Notes: 
- There is a swagger(<https://app.swaggerhub.com/apis/microsoft-rs/PBIRS/2.0>)
- Tou will need to install requests_ntlm:
    - pip3 install requests_ntlm
- At the end of the file there are payloads examples


```python
import requests
import json
import re

from requests_ntlm import HttpNtlmAuth
```

```python
url='http://fill_me'
domain ='domain\\'
auth=HttpNtlmAuth(domain + 'user', 'pass')
headersGet = {'accept': 'application/json'}
headersPut = {'accept': 'application/json', 'content-type': 'application/json'}

foder_path = '/fill me'

user_list_to_append = [
  { 'name' : 'user1', 'role': 'Content Manager'},
  { 'name' : 'user2', 'role': 'Content Manager'}
]

roleName = 'Role Filter'
```
## Functions


```python
def get_folder_id(folder_path):
  response = requests.get(
    url + '/Folders', 
    auth=auth, 
    headers=headersGet
  )
  folders = json.loads(response.text)
  for folder in folders["value"]:
    if folder['Path'] == folder_path:
      return folder['Id']

def get_folder_policies(folder_id):
  response = requests.get(
    url + '/Folders('+folder_id+')/Policies', 
    auth=auth, 
    headers=headersGet
  )
  policies = json.loads(response.text)
  return policies['Policies']

def create_policie(usr_name, role):
  group_user_name = domain+usr_name
  if role == "Content Manager":
    return {
            "GroupUserName":group_user_name,"Roles":[
              {
                "Name":"Content Manager","Description":"May manage content in the Report Server.  This includes folders, reports and resources."
              }
            ]
          }
  elif role == "Browser":
    return {
            "GroupUserName":group_user_name,"Roles":[
              {
                "Name":"Browser","Description":"May view folders, reports and subscribe to reports."
              }
            ]
          }

def is_the_policie_duplicate(name, groupUserName):
  return domain+name == groupUserName

def append_policies_and_remove_duplicates(policies, user_list_to_append):
  for user in user_list_to_append:
    policies["Policies"][:] = [policie
      for policie in policies["Policies"] if not is_the_policie_duplicate(user['name'], policie["GroupUserName"])]
    policies["Policies"].append(create_policie(user['name'],user['role']))
  return (policies)

def put_policies(folder_id, payload_put_policies):
  return requests.put(
    url + '/Folders('+folder_id+')/Policies', 
    auth=auth, 
    headers=headersPut, 
    data=json.dumps(payload_put_policies)
  )

def is_in_folder(parentFolderId, folder_id):
  return parentFolderId == folder_id


def get_reports_ids(folder_id):
  response = requests.get(
    url + '/PowerBIReports', 
    auth=auth, 
    headers=headersGet
  )
  reports = json.loads(response.text)['value']

  reports[:] = [report
      for report in reports if is_in_folder(report['ParentFolderId'], folder_id) ]

  reports_ids = []

  for report in reports:
    reports_ids.append(report['Id'])

  return reports_ids

def can_find_role_name(modelRoleName, roleName):
  return modelRoleName == roleName

def get_role_id_by_role_name(report_id, roleName):
  response = requests.get(
    url + '/PowerBIReports('+report_id+')/DataModelRoles', 
    auth=auth, 
    headers=headersGet
  )
  roles = json.loads(response.text)['value']
  
  roles [:] = [role_id
      for role_id in roles if can_find_role_name(role_id['ModelRoleName'], roleName) ]

  roles_ids = []

  for role in roles:
    roles_ids.append(role['ModelRoleId'])

  return roles_ids

def get_roles(report_id):
  response = requests.get(
    url + '/PowerBIReports('+report_id+')/DataModelRoleAssignments', 
    auth=auth, 
    headers=headersGet
  )
  return json.loads(response.text)['value'] 
  
def create_role(usr_name, roles_id):
  group_user_name = domain + usr_name
  return {
    "GroupUserName": group_user_name,
    "DataModelRoles": roles_id
  }

def not_exist_the_role_in_users (users, groupUserName):
  for user in users:
    if domain + user['name'] == groupUserName:
      return False
  return True

def not_exist_the_user_in_roles (roles, name):
  for role in roles:
    if role['GroupUserName'] == domain + name:
      return False
  return True

def exist_the_role_in_users (users, groupUserName):
  for user in users:
    if domain + user['name'] == groupUserName:
      return True
  return False

def add_reports_id_to_roles (role, roles_id):
  roles_to_replace = list( dict.fromkeys(roles_id + role['DataModelRoles']))
  return {
    "GroupUserName": role['GroupUserName'],
    "DataModelRoles": roles_to_replace
  }

def append_roles_and_remove_duplicates(roles, roles_id, users):
  if len(roles_id) > 0:
    roles_to_return = []
    for user in users:
      if not_exist_the_user_in_roles(roles, user['name']):
        roles_to_return.append(create_role(user['name'],roles_id))
    
    for role in roles:
      if not_exist_the_role_in_users(users, role['GroupUserName']):
        roles_to_return.append(role)

    for role in roles:
      if exist_the_role_in_users(users, role['GroupUserName']):
        roles_to_return.append(add_reports_id_to_roles(role, roles_id))

    return roles_to_return
  else:
    return []


def put_roles(report_id, payload_put_roles):
  return requests.put(
    url + '/PowerBIReports('+report_id+')/DataModelRoleAssignments', 
    auth=auth, 
    headers=headersPut, 
    data=json.dumps(payload_put_roles)
  )

def get_folder_policies_users(folder_id):
  policies = get_folder_policies(folder_id)
  users = []
  for policie in policies:
    name = re.sub(domain+'\\', '', policie['GroupUserName'])
    users.append({'name': name})
  return users

```
## The mambo start here.

### Get folder id using foder_path variable defined above


```python
folder_id = get_folder_id(foder_path) 
folder_id
```

```python
# Payloads for policies
policies = {
    "Policies": get_folder_policies(folder_id)
  } 
```
### Update payloads from policies based on then variable user_list_to_append defined above


```python
put_policies(folder_id, append_policies_and_remove_duplicates(policies, user_list_to_append))
```
### For all reports inside the foder_path update roles using roleName.


```python
for report_id in get_reports_ids(folder_id):
  roles_to_put = append_roles_and_remove_duplicates(
      get_roles(report_id), 
      get_role_id_by_role_name(report_id, roleName), 
      get_folder_policies_users(folder_id)
    ) 
  if len(roles_to_put) > 0: 
    put_roles(report_id, roles_to_put)
```
## Appendix


```python
# Payloads for puts. Note: Is diferent from the swagger (https://app.swaggerhub.com/apis/microsoft-rs/PBIRS/2.0#)
payload_add_policies = {
    "Policies": [
        {
          "GroupUserName":"domain\\user","Roles":[
            {
              "Name":"Content Manager","Description":"May manage content in the Report Server.  This includes folders, reports and resources."
            }
          ]
        },
        {
          "GroupUserName":"domain\\user","Roles":[
            {
              "Name":"Content Manager","Description":"May manage content in the Report Server.  This includes folders, reports and resources."
            }
          ]
        }
    ]
  }

payload_put_roles = [
  {
    "GroupUserName": "domain\\user",
    "DataModelRoles": [
      "9a8716af-bfd3-45ae-ab7e-65cc550e9599"
    ]
  }
]
```