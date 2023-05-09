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

### Cloud Functions SA IAM Organization permissions
resource "google_organization_iam_member" "binding" {
  for_each = toset(local.cf_sa_organization_roles)
  org_id   = var.org_id
  role     = each.value
  member     = "serviceAccount:${module.service_account.function_identity_email}"
  depends_on = [
    module.project_services
  ]
}

### Cloud Functions SA IAM Project permissions
resource "google_project_iam_member" "cf_create_project_permissions" {
  project    = var.project_id
  for_each   = toset(local.cf_sa_project_roles)
  role       = each.value
  member     = "serviceAccount:${module.service_account.function_identity_email}"
  depends_on = [
    module.project_services
  ]
}

### Cloud Scheduler SA IAM Project permissions
### Permissions on the service account used by the function and Eventarc trigger
resource "google_project_iam_member" "scheduler_cf_invoking" {
  project    = var.project_id
  for_each   = toset(local.scheduler_sa_project_roles)
  role       = each.value
  member     = "serviceAccount:${module.service_account.scheduler_identity_email}"
  depends_on = [
    module.project_services
  ]
}
