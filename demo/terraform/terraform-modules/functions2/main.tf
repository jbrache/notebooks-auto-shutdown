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
variable "function_storage_bucket" {}

variable "cf_identity_email" {
  description = "Service account name of the Cloud Function."
  type        = string
  default     = "cf-auto-shutdown-sa"
}

variable "cf_auto_shutdown_name" {
  description = "Name of the Cloud Function."
  type        = string
  default     = "cf-nb-auto-shutdown"
}

variable "region" {
  description = "Region of function. If it is not provided, the provider region is used."
  type        = string
  default     = "us-central1"
}

### Cloud Functions GCS Objects
data "archive_file" "cf_create_shutdown_module_zip" {
  output_path = "${path.root}/function/notebooks_auto_shutdown.zip"
  type        = "zip"
  source_dir  = "${path.root}/function/notebooks_auto_shutdown"
}

resource "google_storage_bucket_object" "cf_create_shutdown_module_zip" {
  bucket       = var.function_storage_bucket
  name         = "notebooks_auto_shutdown.zip"
  content_type = "application/zip"
  source       = data.archive_file.cf_create_shutdown_module_zip.output_path
}

resource "google_cloudfunctions2_function" "shutdown_function" {
  project     = var.project_id
  name        = var.cf_auto_shutdown_name
  location    = var.region
  description = "Cloud Function to shutdown Vertex AI user-managed notebook instances."

  build_config {
    runtime = "python311"
    entry_point = "stop_server"  # Set the entry point 
    environment_variables = {
        BUILD_CONFIG_TEST = "build_test"
    }
    source {
      storage_source {
        bucket = var.function_storage_bucket
        object = google_storage_bucket_object.cf_create_shutdown_module_zip.name
      }
    }
  }

  service_config {
    max_instance_count  = 10
    min_instance_count = 0
    available_memory    = "512M"
    timeout_seconds     = 60
    max_instance_request_concurrency = 10
    available_cpu = "1"
    environment_variables = {
        SERVICE_CONFIG_TEST = "config_test"
    }
    # ingress_settings = "ALLOW_INTERNAL_ONLY"
    ingress_settings = "ALLOW_ALL"
    all_traffic_on_latest_revision = true
    service_account_email = var.cf_identity_email
  }
}
