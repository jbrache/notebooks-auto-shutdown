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

# NOTE: google_org_policy_policy does not work with automated bulids, you have to use google_project_organization_policy
# ####################################################################################
# # Organizational Policies 
# ####################################################################################
# # This list constraint defines the allowed ingress settings for deployment of a Cloud Function. When this constraint is enforced, functions will be required to have ingress settings that match one of the allowed values.
# resource "google_org_policy_policy" "allowedIngressSettings" {
#   name     = "projects/${var.project_id}/policies/cloudfunctions.allowedIngressSettings"
#   parent   = "projects/${var.project_id}"
#   spec {
#     rules {
#       allow_all = "TRUE"
#     }
#   }
# }

# ##################################################################################
# # THESE BELOW ARE OPTIONAL
# ##################################################################################
# # Domain restricted sharing, will need to be modified only if using Dialogflow CX Integrations like Twilio, Audiocodes, etc. 
# # Domain restricted sharing
# # By default, all user identities are allowed to be added to IAM policies.
# # If this constraint is active, only principals that belong to the allowed customer IDs can be added to IAM policies.
# resource "google_org_policy_policy" "allowedPolicyMemberDomains" {
#   name     = "projects/${var.project_id}/policies/iam.allowedPolicyMemberDomains"
#   parent   = "projects/${var.project_id}"
#   spec {
#     rules {
#       allow_all = "TRUE"
#     }
#   }
# }

# #All new Compute Engine VM instances use Shielded disk images with Secure Boot, vTPM, and Integrity Monitoring options enabled when it is true. 
# resource "google_org_policy_policy" "org_policy_require_shielded_vm" {
#   name     = "projects/${var.project_id}/policies/compute.requireShieldedVm"
#   parent   = "projects/${var.project_id}"
#   spec {
#     rules {
#       enforce = "FALSE"
#     }
#   }
# }

# # This constraint defines the set of projects that can be used for image storage and disk instantiation for Compute Engine.
# #By default, instances can be created from images in any project that shares images publicly or explicitly with the user.
# resource "google_org_policy_policy" "trustedImageprojects" {
#   name     = "projects/${var.project_id}/policies/compute.trustedImageProjects"
#   parent   = "projects/${var.project_id}"
#   spec {
#     rules {
#       allow_all = "TRUE"
#     }
#   }
# }

# ####################################################################################
# # Time Delay for Org Policies
# ####################################################################################
# # https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep
# # The org policies take some time to proprogate.  
# # If you do not wait the below resource will fail.
# resource "time_sleep" "time_sleep_org_policies" {
#   create_duration = "30s"
#   depends_on = [
#     google_org_policy_policy.allowedIngressSettings,
#     google_org_policy_policy.allowedPolicyMemberDomains,
#     google_org_policy_policy.org_policy_require_shielded_vm,
#     google_org_policy_policy.trustedImageprojects
#   ]
# }