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
variable "project_apis" {}
variable "service_config" {}

locals {
    project_apis = var.project_apis
    service_config = var.service_config    
}

resource "google_project_service" "project_services" {
  for_each                   = toset(local.project_apis)
  project                    = var.project_id
  service                    = each.value
  disable_on_destroy         = local.service_config.disable_on_destroy
  disable_dependent_services = local.service_config.disable_dependent_services
}

resource "time_sleep" "wait_project_services" {
  depends_on = [
    google_project_service.project_services,
  ]
  create_duration = "180s"
}
