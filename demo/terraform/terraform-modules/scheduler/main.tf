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

variable "project_id" {}

variable "scheduler_identity_email" {
  description = "Service account name used by Cloud Scheduler to invoke the Cloud Function."
  type        = string
  default     = "scheduler-sa"
}

variable "cf_uri" {
  description = "URI of the Cloud Function which shutsdown Vertex AI user-managed notebooks."
  type        = string
}

variable "scheduler_name" {
  description = "Name of the Cloud Scheduler."
  type        = string
  default     = "notebooks-auto-shutdown"
}

variable "region" {
  description = "Region of Cloud Scheduler. If it is not provided, the provider region is used."
  type        = string
  default     = "us-central1"
}

resource "google_cloud_scheduler_job" "job" {
  project          = var.project_id
  name             = var.scheduler_name
  region           = var.region
  description      = "Cloud Scheduler to shutdown Vertex AI user-managed notebooks"
  schedule         = "*/5 * * * *"
  time_zone        = "America/New_York"
  attempt_deadline = "320s"

  retry_config {
    retry_count = 3
  }

  http_target {
    http_method = "POST"
    uri         = var.cf_uri
    body        = base64encode("{\"foo\":\"bar\"}")

    oidc_token {
      service_account_email = var.scheduler_identity_email
    }
  }
}