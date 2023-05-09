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

variable "project_id" {
  type        = string
  description = "project id required"
}
variable "project_name" {
  type        = string
  description = "project name in which demo deploy"
  default     = ""
}
variable "project_number" {
  type        = string
  description = "project number in which demo deploy"
  default     = ""
}
variable "gcp_account_name" {
  type        = string
  description = "user performing the demo"
  default     = ""
}
variable "deployment_service_account_name" {
  type        = string
  description = "Cloudbuild_Service_account having permission to deploy terraform resources"
  default     = ""
}
variable "org_id" {
  type        = string
  description = "Organization ID in which project created"
  default     = ""
}
variable "data_location" {
  type        = string
  description = "Location of source data file in central bucket"
  default     = ""
}
variable "secret_stored_project" {
  type        = string
  description = "Project where secret is accessing from"
  default     = ""
}

#############################################################
#Variables related to modules
#############################################################

###############################################################################################################################################
#Local declaration block is for the user to declare those variables here which is being used in .tf files in repetitive manner OR get the exact #definition from terraform document
###############################################################################################################################################
locals {
  # The project is the provided name OR the name with a random suffix
  local_project_id = var.project_number == "" ? "${var.project_id}-${random_string.project_random.result}" : var.project_id
  # Apply suffix to bucket so the name is unique
  local_storage_bucket = "${var.project_id}-${random_string.project_random.result}"
  # Use the GCP user or the service account running this in a DevOps process
  # local_impersonation_account = var.deployment_service_account_name == "" ? "user:${var.gcp_account_name}" : "serviceAccount:${var.deployment_service_account_name}"

}

############################################################################
#Variables which are required for running modules
############################################################################

#GCP Region to Deploy
variable "region" {
  type        = string
  description = "The GCP region to deploy"
  default     = "us-central1"
}

#Zone in the region
variable "zone" {
  type        = string
  description = "The GCP zone in the region. Must be in the region."
  default     = ""
}

#Default value of the spanner
variable "spanner_config" {
  type        = string
  description = "This should be a spanner config in the region.  See: https://cloud.google.com/spanner/docs/instance-configurations#available-configurations-multi-region"
  default     = ""
}

#Variable for BiqQuery
variable "bigquery_region" {
  type        = string
  description = "The GCP region to deploy BigQuery.  This should either match the region or be 'us' or 'eu'.  This also affects the GCS bucket and Data Catalog."
  default = "US"  
}

variable "omni_dataset" {
  type        = string
  description = "The full path project_id.dataset_id to the OMNI data."
  default     = "Keep you dataset name.table name"
}
