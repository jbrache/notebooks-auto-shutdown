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

#############################################################################################################################################################
#ORGANIZATION POLICIES/CONSTRAINT REQUIRED FOR THE RESOURCES/PRODUCT WE ARE USING                                                                           #
#INSIDE OUR TERRAFORM SCRIPTS.                                                                                                                              #
#ALLOWS MANAGEMENT OF ORGANIZATION POLICIES FOR A GOOGLE CLOUD PROJECT                                                                                      #      
#BOOLEAN CONSTRAINT POLICY CAN BE USED TO EXPLICITLY ALLOW A PARTICULAR CONSTRAINT ON AN INDIVIDUAL PROJECT, REGARDLESS OF HIGHER LEVEL POLICIES            #
#LIST CONSTRAINT POLICY THAT CAN DEFINE SPECIFIC VALUES THAT ARE ALLOWED OR DENIED FOR THE GIVEN CONSTRAINT. IT CAN ALSO BE USED TO ALLOW OR DENY ALL VALUES#
#############################################################################################################################################################

####################################################################################
# This uses an older TF API to set Org Policies
# This is required when deploying using Click-to-Deploy since the
# cloud build account is in a different org.
#
# NOTE: google_org_policy_policy does not work with automated bulids, you have to use google_project_organization_policy
####################################################################################

####################################################################################
# Organizational Policies 
####################################################################################
# This list constraint defines the allowed ingress settings for deployment of a Cloud Function. When this constraint is enforced, functions will be required to have ingress settings that match one of the allowed values.
# resource "google_project_organization_policy" "allowedIngressSettings" {
#   project     = var.project_id
#   constraint = "cloudfunctions.allowedIngressSettings"
#   list_policy {
#     allow {
#       all = true
#     }
#   }
# }

##################################################################################
# THESE BELOW ARE OPTIONAL
##################################################################################
# Domain restricted sharing, will need to be modified only if using Dialogflow CX Integrations like Twilio, Audiocodes, etc. 
# Domain restricted sharing
# By default, all user identities are allowed to be added to IAM policies.
# If this constraint is active, only principals that belong to the allowed customer IDs can be added to IAM policies.
# resource "google_project_organization_policy" "allowedPolicyMemberDomains" {
#   project     = var.project_id
#   constraint = "iam.allowedPolicyMemberDomains"
#   list_policy {
#     allow {
#       all = true
#     }
#   }
# }

#All new Compute Engine VM instances use Shielded disk images with Secure Boot, vTPM, and Integrity Monitoring options enabled when it is true. 
# resource "google_project_organization_policy" "org_policy_require_shielded_vm" {
#   project     = var.project_id
#   constraint = "compute.requireShieldedVm"
#   boolean_policy {
#     enforced = false
#   }
# }

# This constraint defines the set of projects that can be used for image storage and disk instantiation for Compute Engine.
#By default, instances can be created from images in any project that shares images publicly or explicitly with the user.
# resource "google_project_organization_policy" "trustedImageprojects" {
#   project     = var.project_id
#   constraint = "compute.trustedImageProjects"
#   list_policy {
#     allow {
#      all = true
#      }
#  }
# }

####################################################################################
# Time Delay for Org Policies
####################################################################################
# https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep
# The org policies take some time to proprogate.  
# If you do not wait the below resource will fail.
# resource "time_sleep" "time_sleep_org_policies" {
#   create_duration = "30s"
#   depends_on = [
#     google_project_organization_policy.allowedIngressSettings,
#     google_project_organization_policy.allowedPolicyMemberDomains,
#     google_project_organization_policy.org_policy_require_shielded_vm,
#     google_project_organization_policy.trustedImageprojects
#   ]
# }
