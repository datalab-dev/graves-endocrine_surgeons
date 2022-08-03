# Valhalla

Arthur Koehl
07/29/2022

This notes document walks through installing and using Valhalla with docker.

## What is Valhalla?

[Valhalla](https://valhalla.readthedocs.io/en/latest/) is an open source routing engine for OpenStreetMap. It is a tool that lets you retrieve route information for driving, walking, biking, or multi-modal. Valhalla runs as a an HTTP API that passes JSON back and forth. 

For this project we are using the ‘Isochrone’ and ‘Isodistance’ API provided through Valhalla. An isochrone is a line that delimits points of equal travel time from a given location, and Isodistance delimits equal travel distance. 

## Valhalla installation with Docker

To make our lives easier, we will be setting up Valhalla and the necessary data files with Docker. Valhalla maintains docker images and documentation for using the images at [this GitHub repository](https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=&cad=rja&uact=8&ved=2ahUKEwjy4ufn44X5AhXrK0QIHd2wBxEQFnoECAwQAQ&url=https%3A%2F%2Fgithub.com%2Fgis-ops%2Fdocker-valhalla&usg=AOvVaw2IalS_zmyHydKq8faspgra).  

Running Valhalla through docker provides a variety of benefits including:

- same installation workflow for all operating systems
- supported by the Valhalla team
- don’t need to get into the weeds of building the software on your own
- ability to swap data and other configuration options for Valhalla easily
- easy ability to manage the networking interface to the software (which port it runs on)
- easy ability to monitor the status of the software through Docker’s logging and status commands

[This older guide](https://gis-ops.com/valhalla-how-to-run-with-docker-on-ubuntu/), using Docker compose to handle building the appropriate tiles and other data for Valhalla worked for Michele. I had difficulty following it on CentOS 7. So these notes walk through installing Valhalla with Docker using the newest instructions from the repository linked above and not that guide. 

1. install Docker on your system. 
2. make a directory where you will eventually store OpenStreetMap data files and Valhalla will put its configuration files and other derived data it uses:
    
    `mkdir /data/custom_data`
    
    <aside>
    💡 Chose a location that is accessible to multiple users if you expect multiple users may want to modify the data used by Valhalla. Also, during the build process for a large area, Valhalla will use a ton of space. For building its data for the US, Valhalla created over 80GB of files, eventually, when its finished building, the total file size is 15GB.
    
    </aside>
    
3. Create a file called `valhalla.env` with the following lines:
    
    ```bash
    use_titles_ignore_pbf=False
    force_rebuild=True
    ```
    
    Notice that the environment variable name is lowercased, and the values are capitalized without any quotes around them. 
    
4. start a container with gisops Valhalla docker image:
    
    `docker run -dt --env-file ~/.valhalla.env -v /data/custom_files:/custom_files -p 8002:8002 --name valhalla gisops/valhalla:latest`
    
5. confirm the container is running with `docker container ls` and `docker ps -a`. Confirm that the `use_tiles_ignore_pbf` variable is set to False with `docker inspect valhalla | grep 'pbf'` 
6. Download the OpenStreetMap data into the custom_data directory you made in step 2
    
    <aside>
    💡 To download the OpenStreetMap data for the US I used this site: [http://download.geofabrik.de/north-america/us.html](http://download.geofabrik.de/north-america/us.html) 
    
    Puerto Rico needed to be downloaded separately from:
    [https://download.geofabrik.de/north-america/us/puerto-rico.html](https://download.geofabrik.de/north-america/us/puerto-rico.html)
    
    </aside>
    

1. Restart the docker container. When the container restarts, the Valhalla instance will scan the custom_data directory for any changes that have occurred - including to the configuration file `valhalla.json` and any OSM data files. Then it will rebuild the necessary data it uses for routing. This process can take several hours, for the full US OSM data, it took over three hours. Do not attempt to use the docker container until Valhalla has completed its rebuild. To monitor the status of the container, read the log file for the container. The log file can be found with `docker inspect valhalla | grep 'log'`. To restart the docker container:
    
    `docker restart valhalla`
    
    You should see an active process with a command like `valhalla_build_tiles -c ...` with `top` 
    

## **Usage and Testing**

Valhalla is interfaced through an HTTP API on the port defined in the `docker run` command from step 3 of the installation instructions above. The documentation for the API can be found on [Valhalla’s web page](https://valhalla.readthedocs.io/en/latest/api/). 

To test that Valhalla is working, submit a request for routing with `curl`:

`curl [http://localhost:8002/route](http://localhsot:8002/route) --data '{"locations": [{"lat": 38.3, "lon":-121.4},{"lat":40.3,"lon":-120.4}],"costing":"auto","directions_options":{"units":"miles"}}'`

The response, which will print to your console, will be a large JSON document. If Valhalla isn’t properly configured you may get an error message as the response which may say that it could not find the nearest node, or something along those terms. This probably means that the locations requested are outside of the area that Valhalla has data for, double check the OSM data and the locations in the request. Then restart the container and wait for the build to finish, see steps 5 and 6 above. 

If you get a response that is a networking error reported by `curl`, i.e the request didn’t get through, then this means that there was an issue with the container itself. To debug this, look at the messages in the container’s log file, see step 6 above. Additionally, use `docker ps` and `docker ps -a` to confirm that the container is up and running. In my experience, when Valhalla wasn’t properly built, submitting requests would sometimes shut down the container.

If you are on the library’s network, e.g on the library staff VPN, you should be able to interact with the docker container on the `[datasci.library.ucdavis.edu](http://datasci.library.ucdavis.edu)` server. Simply replace `[localhost](http://localhost)` in any request with `datasci.library.ucdavis.edu`

## Useful Links

Valhalla Overview - [https://valhalla.readthedocs.io/en/latest/valhalla-intro/](https://valhalla.readthedocs.io/en/latest/valhalla-intro/)

Valhalla API Documentation - [https://valhalla.readthedocs.io/en/latest/api/](https://valhalla.readthedocs.io/en/latest/api/)

Docker Images Repository - https://github.com/gis-ops/docker-valhalla
