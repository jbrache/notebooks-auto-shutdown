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

terraform {
  required_version = ">= 0.13"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.48.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "4.48.0"
    }
  }
}

####################################################################################
# Variables
####################################################################################
variable "project_id" {
 description = "project id in which demo deploy"
}

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

####################################################################################
# Resources
####################################################################################
resource "google_service_account" "function_identity" {
  project     = var.project_id
  account_id  = var.cf_identity_id
  description = "Service Account attached to the Cloud Function to shutdown resources."
}

resource "google_service_account" "scheduler_identity" {
  project     = var.project_id
  account_id  = var.scheduler_identity_id
  description = "Service Account attached to the Cloud Scheduler to invoke the Cloud Function."
}

####################################################################################
# Outputs
####################################################################################
output "function_identity_email" {
  value = google_service_account.function_identity.email
}

output "scheduler_identity_email" {
  value = google_service_account.scheduler_identity.email
}