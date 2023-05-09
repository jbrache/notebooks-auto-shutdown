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

# import urllib
# import google.auth.transport.requests
import functions_framework
from google.cloud import resourcemanager_v3
import os
from google.auth.transport.requests import AuthorizedSession
from google import auth
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
        print(project.project_id)
        project_ids.append(project.project_id)

    return project_ids

def stop_server(request):
    credentials, project = auth.default(scopes = ['https://www.googleapis.com/auth/cloud-platform'])
    authed_session = AuthorizedSession(credentials)

    project_ids = get_project_ids()

    return_response = {}
    for project_id in project_ids:
        # Get zone resources available to the project
        # https://cloud.google.com/ai-platform/notebooks/docs/reference/rest/v1/projects.locations/list   
        response = authed_session.get(f"https://notebooks.googleapis.com/v1/projects/{project_id}/locations")
        # print(response.json())
        locations_json = response.json()
        try:
            locations = locations_json["locations"]
        except:
            continue
        now_utc = datetime.now(timezone.utc)

        for location in locations:
            location_id = location["locationId"]
            # this example only runs instances in a region, exclude this to run for all zones
            skip = False
            for region in REGION_LIST:
                if region not in location_id:
                    skip = True
            if skip:
                continue
            print(location_id)

            # Get AI Platform notebook instances
            response = authed_session.get(f"https://notebooks.googleapis.com/v1/projects/{project_id}/locations/{location_id}/instances")
            #print(response.json())
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
                # print(instance)

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