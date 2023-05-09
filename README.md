# Notebooks Auto Shutdown

This template demonstrates how to shutdown a Vertex AI [user-managed notebook](https://cloud.google.com/vertex-ai/docs/workbench/user-managed/introduction) (UmN) after a specified number of seconds. This is also extended to be able to operate at the organization level, scanning for all projects, inspecting notebook metadata values to make a decision on whether to shutdown a notebook instance. For examples, you can setup your notebooks to shutdown after 8 hours from starting up.

**Important:** By default, the Cloud Function inspects a specific UmN metadata value for the timer threshold:
* `auto-shutdown-seconds`

Where the value for `auto-shutdown-seconds` is the number of seconds since the instance has been Active, i.e. 28800 seconds / 8 Hours. You will need to set this key/value on user-managed notebooks for the Cloud Function to shutdown instances.

## GCP Products/Services
Use Terraform in Google Cloud to provision these resources

* Cloud Functions (2nd gen) for scanning notebooks, shutting them down across an Organization
* Cloud Scheduler
* Buckets storing the Cloud Function artifacts

## Prerequisites
* [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/gcp-get-started) version 1.0 or higher.
* [gcloud](https://cloud.google.com/sdk/docs/install) SDK version 360.0.0 or higher.

Create a GCP project to host your Notebooks Auto Shutdown Project
* `gcloud projects create <project-id>`

## IAM Permissions Prerequisites
When deploying in an existing project (By a user or service account), ensure that the identity executing this module has the following IAM permissions on the project:

- `roles/owner`

NOTE: Deployment via service account impersonation is not in scope of this demo.

### Organization IAM Permissions Prerequisites
The existing project is required to be run as part of a Google Organization in Google Cloud. Be sure that the Google Cloud user or service account executing this module has the following roles:

- At the Organization level: `roles/orgpolicy.policyAdmin`

## Installation in an existing project

```shell
export GCP_PROJECT_ID="REPLACE_ME"
export GCP_ORG_ID="REPLACE_ME"

git clone https://github.com/jbrache/notebooks-auto-shutdown.git

# Step down in the directory that contains the Terraform code
cd notebooks-auto-shutdown/demo/terraform

# Configure your CLI to point to the GCP project you want to deploy into
gcloud config set project ${GCP_PROJECT_ID}

# Initialise the Terraform codebase
terraform init -upgrade -reconfigure

# Inspect the Terraform plan
terraform plan -var project_id=${GCP_PROJECT_ID} -var org_id=${GCP_ORG_ID}

# Create the necessary resources
terraform apply -auto-approve -var project_id=${GCP_PROJECT_ID} -var org_id=${GCP_ORG_ID}
```

## Disclaimer

This project is not an official Google project. It is not supported by Google and Google specifically disclaims all warranties as to its quality, merchantability, or fitness for a particular purpose.

---

Copyright 2023 Google LLC.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at: http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
