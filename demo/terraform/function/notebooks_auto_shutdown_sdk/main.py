# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os
import functions_framework
from google import auth
from google.auth.transport.requests import AuthorizedSession
from google.cloud import resourcemanager_v3
from google.cloud import notebooks_v1
# from google.cloud.location import locations_pb2
from datetime import datetime,timezone
from dateutil.parser import isoparse

PROJECT_ID = os.environ.get("PROJECT_ID", "the-foo-bar") # Update placeholder value when this environment variable is not set. 'Specified environment variable is not set.'
SHUTDOWN_SECONDS_METADATA_KEY = os.environ.get("SHUTDOWN_SECONDS_METADATA_KEY", "auto-shutdown-seconds") # Look for this key in notebooks metadata value, defaults to "auto-shutdown-seconds"
REGION_LIST = ["us-central1"] # will only stop instances in this list of regions

# https://cloud.google.com/python/docs/reference/cloudresourcemanager/latest/google.cloud.resourcemanager_v3.services.projects.ProjectsClient#google_cloud_resourcemanager_v3_services_projects_ProjectsClient_search_projects
def get_project_ids():
    client = resourcemanager_v3.ProjectsClient()

    # Construct the request argument
    request = resourcemanager_v3.SearchProjectsRequest(
        query="state:ACTIVE",
    )
    projects = client.search_projects(request=request)
        
    # Iterate
    project_ids = []
    for project in projects:
        project_ids.append(project.project_id)
    return project_ids

# Gets supported locations for the notebooks service given a Project ID
def get_location_ids(project_id):
    credentials, project = auth.default(scopes = ['https://www.googleapis.com/auth/cloud-platform'])
    authed_session = AuthorizedSession(credentials)

    # Get zone resources available to the project
    # https://cloud.google.com/ai-platform/notebooks/docs/reference/rest/v1/projects.locations/list   
    response = authed_session.get(f"https://notebooks.googleapis.com/v1/projects/{project_id}/locations")

    locations_json = response.json()
    location_ids = []
    try:
        locations = locations_json["locations"]
        for location in locations:
            location_ids.append(location["locationId"])
    except:
        location_ids = []
    return location_ids

# List instances for a Project ID and Location ID
# https://github.com/googleapis/python-notebooks/blob/main/samples/generated_samples/notebooks_v1_generated_notebook_service_list_instances_sync.py
# https://cloud.google.com/vertex-ai/docs/workbench/reference/rest/v1/projects.locations.instances/list
def list_instances(project_id, location):
    client = notebooks_v1.NotebookServiceClient()

    # Initialize request argument(s)
    request = notebooks_v1.ListInstancesRequest(
        parent=f"projects/{project_id}/locations/{location}",
    )

    page_result = client.list_instances(request=request)
    return list(page_result)

# Stops a Notebooks instance given a fully qualified name
# https://github.com/googleapis/python-notebooks/blob/main/samples/generated_samples/notebooks_v1_generated_notebook_service_stop_instance_sync.py
# https://cloud.google.com/vertex-ai/docs/workbench/reference/rest/v1/projects.locations.instances/stop
def stop_instance(instance_name):
    client = notebooks_v1.NotebookServiceClient()

    # Initialize request argument(s)
    request = notebooks_v1.StopInstanceRequest(
        name=instance_name,
    )

    # Make the request
    operation = client.stop_instance(request=request)
    print("Waiting for stop operation to complete...")
    response = operation.result()
    return response

# Stop the instances using the Python Client Library
# https://cloud.google.com/python/docs/reference/notebooks/latest
def stop_server_sdk(request):
    client = notebooks_v1.NotebookServiceClient()
    project_ids = get_project_ids()
    return_response = {}

    for project_id in project_ids:
        now_utc = datetime.now(timezone.utc)
        location_ids = get_location_ids(project_id)

        for location_id in location_ids:
            # This example only runs inspects instances in a region, exclude this to run for all zones
            skip = False
            for region in REGION_LIST:
                if (region not in location_id) or (region == location_id):
                    skip = True
            if skip:
                continue

            notebook_instances = []
            try:
                notebook_instances = list_instances(project_id, location_id)
            except:
                continue
            
            for notebook_instance in notebook_instances:
                instance_name = notebook_instance.name
                metadata = notebook_instance.metadata
                print("-------", "Instance name:", instance_name, "-------")
                print(metadata)
                auto_shutdown_seconds = 0

                try:
                    auto_shutdown_seconds = int(metadata[SHUTDOWN_SECONDS_METADATA_KEY])
                    print(SHUTDOWN_SECONDS_METADATA_KEY, "metadata set to:", auto_shutdown_seconds)
                except:
                    print(SHUTDOWN_SECONDS_METADATA_KEY, "metadata not set, skip...")
                    continue
                
                if notebook_instance.state != notebook_instance.State.ACTIVE:
                    print("Instance isn't ACTIVE, skip...")
                    continue
                
                update_time = notebook_instance.update_time

                print("timeNow:", now_utc.isoformat())
                print("updatedTime:", update_time.isoformat())

                t1 = isoparse(update_time.isoformat())
                t2 = isoparse(now_utc.isoformat())
                # get difference
                delta = t2 - t1
                delta_seconds = delta.total_seconds()
                print("Difference in seconds between updatedTime and timeNow:", delta_seconds)

                if (delta_seconds >= auto_shutdown_seconds) and delta_seconds >= 0:
                    print("Stopping server...")
                    response = stop_instance(instance_name)
                    return_response[instance_name] = response
                else:
                    print("Shutdown threshold not hit, skip...")     

    return return_response

# Stop the instances using REST API Commands
# https://cloud.google.com/vertex-ai/docs/workbench/reference/rest
def stop_server_rest(request):
    credentials, project = auth.default(scopes = ['https://www.googleapis.com/auth/cloud-platform'])
    authed_session = AuthorizedSession(credentials)
    project_ids = get_project_ids()
    return_response = {}

    for project_id in project_ids:
        # Get zone resources available to the project
        # https://cloud.google.com/ai-platform/notebooks/docs/reference/rest/v1/projects.locations/list   
        response = authed_session.get(f"https://notebooks.googleapis.com/v1/projects/{project_id}/locations")
        locations_json = response.json()
        try:
            locations = locations_json["locations"]
        except:
            continue
        now_utc = datetime.now(timezone.utc)

        for location in locations:
            location_id = location["locationId"]
            # this example only inspects instances in a region, exclude this to run for all zones
            skip = False
            for region in REGION_LIST:
                if (region not in location_id) or (region == location_id):
                    skip = True
            if skip:
                continue

            # Get AI Platform notebook instances
            response = authed_session.get(f"https://notebooks.googleapis.com/v1/projects/{project_id}/locations/{location_id}/instances")
            instances_json = response.json()
            # If the response is empty, continue
            if not instances_json:
                continue
            instances = instances_json["instances"]
            
            # Documentation
            # https://cloud.google.com/ai-platform/notebooks/docs/reference/rest/v1/projects.locations.instances/stop
            for instance in instances:
                instance_name = instance["name"]
                print("-------", "Instance name:", instance_name, "-------")
                auto_shutdown_seconds = 0
                
                try:
                    auto_shutdown_seconds = int(instance["metadata"][SHUTDOWN_SECONDS_METADATA_KEY])
                    print(SHUTDOWN_SECONDS_METADATA_KEY, "metadata set to:", auto_shutdown_seconds)
                except:
                    print(SHUTDOWN_SECONDS_METADATA_KEY, "metadata not set, skip...")
                    continue
                
                if instance["state"] != "ACTIVE":
                    print("Instance isn't ACTIVE, skip...")
                    continue
                
                update_time = instance["updateTime"]
                update_time_iso = update_time.replace("Z", "+00:00")

                print("timeNow:", now_utc.isoformat())
                print("updatedTime:", update_time_iso)

                t1 = isoparse(update_time_iso)
                t2 = isoparse(now_utc.isoformat())
                # get difference
                delta = t2 - t1
                delta_seconds = delta.total_seconds()
                print("Difference in seconds between updatedTime and timeNow:", delta_seconds)

                if (delta_seconds >= auto_shutdown_seconds) and delta_seconds >= 0:
                    print("Stopping server...")
                    response = authed_session.post(f"https://notebooks.googleapis.com/v1/{instance_name}:stop")
                    print(response.json())
                    return_response[instance_name] = response.json()
                else:
                    print("Shutdown threshold not hit, skip...")                
            
    return return_response