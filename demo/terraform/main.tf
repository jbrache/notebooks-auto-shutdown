# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ==============================================================================

variable "cf_identity_id" {
  description = "Service account name of the Cloud Function used to shutdown resources."
  type        = string
  default     = "cf-auto-shutdown-sa"
}

variable "scheduler_identity_id" {
  description = "Service account name used by Cloud Scheduler to invoke the Cloud Function."
  type        = string
  default     = "scheduler-sa"
}

# Create a random string for the project/bucket suffix
# Apply suffix to bucket so the name is unique
resource "random_string" "project_random" {
  length  = 10
  upper   = false
  lower   = true
  numeric  = true
  special = false
}

resource "random_id" "server" {
  byte_length = 4
}

####################################################################################
# Local Variables used inside the module, 
####################################################################################
locals {
  # Use the GCP user or the service account running this in a DevOps process
  # local_impersonation_account = var.deployment_service_account_name == "" ? "user:${var.gcp_account_name}" : "${var.deployment_service_account_name}"
  local_impersonation_account = var.deployment_service_account_name == "" ? "user:${var.gcp_account_name}" : "serviceAccount:${var.deployment_service_account_name}"

  cf_uri = module.cloudfunctions2.shutdown_https_trigger_url

  project_id = var.project_id
  project_number = var.project_number
  region = var.region == "" ? "us-central1" : var.region

  cf_sa_project_roles = [
    "roles/cloudbuild.serviceAgent",
    "roles/cloudfunctions.serviceAgent",
    "roles/pubsub.serviceAgent",
    "roles/run.serviceAgent",
    "roles/containerregistry.ServiceAgent"
  ]

  cf_sa_organization_roles = [
    "roles/resourcemanager.organizationViewer",
    "roles/notebooks.serviceAgent"
  ]
  
  scheduler_sa_project_roles = [
    "roles/run.invoker"
  ]
  
  # These roles are not used, however if deploying via a service account impersonation
  # these are the roles that would be utilized
  deployment_sa_project_roles = [
    "roles/resourcemanager.projectIamAdmin",
    "roles/iam.serviceAccountAdmin",
    "roles/cloudfunctions.admin",
    "roles/storage.admin",
    "roles/serviceusage.serviceUsageAdmin"
  ]
  
  project_apis = [
    "cloudscheduler.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudfunctions.googleapis.com",
    "run.googleapis.com",
    "pubsub.googleapis.com",
    "storage-component.googleapis.com",
    "storage.googleapis.com"
  ]

  service_config = {
    disable_on_destroy         = true
    disable_dependent_services = true
  }
}

module "org_policy" {
  source                = "./terraform-modules/org-policies"
  project_id            = var.project_id
}

module "service_account" {
  source                = "./terraform-modules/service-account"
  project_id            = var.project_id
  cf_identity_id        = var.cf_identity_id
  scheduler_identity_id = var.scheduler_identity_id
  
  depends_on = [
    module.org_policy
  ]
}

module "project_services" {
  source                 = "./terraform-modules/apis"
  project_id             = var.project_id
  project_apis           = local.project_apis
  service_config         = local.service_config

  depends_on = [
    module.org_policy
  ]
}

# Buckets to store cloud functions and agent archive
# Apply suffix to bucket so the name is unique
module "gcs" {
  source                 = "./terraform-modules/gcs"
  project_id             = var.project_id
  bucket_suffix          = random_string.project_random.result  

  depends_on = [
    module.project_services
  ]
}

# Cloud Function to shut down Vertex AI user-managed notebooks across an organization
module "cloudfunctions2" {
  source                   = "./terraform-modules/functions2"
  project_id               = var.project_id
  cf_auto_shutdown_name    = "cf-nb-auto-shutdown"
  cf_identity_email        = module.service_account.function_identity_email
  region                   = local.region

  function_storage_bucket  = module.gcs.function_storage_name

  depends_on = [
    module.project_services,
    module.service_account,
    module.gcs
  ]
}

# Scheduler to trigger the Cloud Function above at a 5 minute interval
module "scheduler" {
  source                   = "./terraform-modules/scheduler"
  project_id               = var.project_id
  cf_uri                   = module.cloudfunctions2.shutdown_https_trigger_url
  scheduler_name           = "notebooks-auto-shutdown"
  scheduler_identity_email = module.service_account.scheduler_identity_email
  region                   = local.region

  depends_on = [
    module.project_services,
    module.service_account,
    module.gcs,
    module.cloudfunctions2
  ]
}

data "google_project" "project" {
  project_id = var.project_id
  depends_on = [
    module.project_services
  ]
}
