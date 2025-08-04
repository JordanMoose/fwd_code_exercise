# Jordan Moossazadeh - Frontline Wildfire Defense Code Exercise

## Overview

This is Jordan Moossazadeh's implementation of Frontline Wildfire Defense's code exercise.
The goal of the application is to regularly provide users with up-to-date wildfire information.

## Installation

### For local development

1. Ensure `asdf` is installed on your local machine.
2. Clone this repository to your local machine.
3. Navigate to the root directory of the repository.
4. Run `asdf install` to install the required dependencies listed in the `.tool-versions` file.
- **Note**: The Docker and Docker Compose dependencies will not be installed because asdf does not have their compatible plugins. They can safely be ignored because these dependencies are only required to build and deploy the application in a production environment.
5. Run `mix deps.get` to install the required Elixir dependencies.
6. Run `mix run --no-halt` to start the application. The application will write logs to the console and each wildfire update to `wildfire_updates/wildfire_data.<timestamp>.json`. Press Ctrl+C to stop the application at any time.

### For production deployment

1. Clone this repository to your local machine.
2. Navigate to the root directory of the repository.
3. Install the Docker and Docker Compose dependencies listed in the `.tool-versions` file.
4. Run `docker compose build` to build the application's docker images.
5. Run `docker compose up` to start the application.

## Implementation

This applicaiton uses a GenServer to poll wildfire information from ESRI's provided ArcGIS API every 15 minutes.
This interval matches the ArcGIS API's update frequency.
The GenServer then broadcasts the wildfire data as a GeoJSON object with spatial reference 4326 to all subscribers of the "wildfires" topic.
