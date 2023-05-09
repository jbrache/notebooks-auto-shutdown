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
variable "project_id" {}
variable "bucket_suffix" {}

variable "bucket_function_deployments_location" {
  description = "Location where the bucket stores it archives for deploying Cloud Functions."
  type        = string
  default     = "US"
}

variable "bucket_function_deployments_versioning" {
  description = "Whether or not to enable versioning on the bucket that contains the Cloud Function archives."
  type        = bool
  default     = true
}

locals {
  # Apply suffix to bucket so the name is unique
  fn_storage_bucket = "${var.project_id}-${var.bucket_suffix}-fn-deployments"
  bucket_function_deployments_location = var.bucket_function_deployments_location
  bucket_function_deployments_versioning = var.bucket_function_deployments_versioning
}

# Storage bucket for function archives (.zip), so they can be deployed.
resource "google_storage_bucket" "function_archive_storage" {
  project                     = var.project_id
  location                    = local.bucket_function_deployments_location
  name                        = local.fn_storage_bucket
  force_destroy               = true
  uniform_bucket_level_access = true

  versioning {
    enabled = local.bucket_function_deployments_versioning
  }
}
