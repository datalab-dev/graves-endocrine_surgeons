<!--
DataLab Project Template

Replace allcaps text with your project details. PROJECT_NAME should be your
project's short name.

In the listing of directories, delete anything that isn't relevant to your
project.
-->

# Claire Graves' (et al.) Endocrine Surgery Access Project

This repository contains code for Claire Graves' **Endocrine Surgery Access** project. The
project uses surgeon address data as well as population, demographic, and socioeconomic data from the US Census to understand the distribution of endocrine surgeons in relation to the US population. The goal of our collaboration is is to better understand the distribution of endocrine surgery centers in the United States and who has access to these centers.  The larger goal of this work is to reduce the barriers for patients to access care requiring an endocrine surgeon.

## Collaborators

### Domain Team

Claire Graves, M.D. - Department of Surgery, University of California Davis

Maeve Alterio - Washington State University Elson S. Floyd College of Medicine

Alexis Woods, M.D. - Department of Surgery, University of California Davis

Kiyomi Sun - Department of Surgery, University of California Davis

Michael Campbell, M.D. - Department of Surgery, University of California Davis


### DataLab Team

Michele Tobias, PhD - Geospatial Data Specialist 

Arthur Koehl - Data Scientist

Alison Wong - Student Employee

Sebastian Lopez - Student Employee


## GitHub Repository File and Directory Structure

The directory structure for the project is:

```
LICENSE                                         Currently unvavailable
README.md                                       Project overview document
.gitignore                                      A file listing files to ignore for version control (git) processes
data/                                           Data sets (files > 1MB go on Google Drive)
  |--- geocoded_addresses_2022-06-29_144609.csv Surgeon's office addresses geocoded by Geocodio and by hand using Google Maps; output from combine_geocoding_results.R
  |--- isochrones_120_min.rds                   120-minute isochrone (access boundary); output from compute_isochrones.R
  |--- isochrones_60_min.rds                    60-minute isochrone (access boundary); output from compute_isochrones.R
  |--- isochrones_90_min.rds                    90-minute isochrone (access boundary); output from compute_isochrones.R
  |--- tract_population.rds                     Census tracts containing population calculation for each isochrone; output from access_calculation.R
docs/                                           Supporting documents - documentation of the process of setting up Valhalla with Docker on the DataLab server
  |--- census_variables.csv                     Variables downloaded in the second stage of this project from the R TidyCensus package
  |--- docker_installation.md                   Instructions for how to set up docker on the DataLab server
  |--- valhalla_installation.md                 Instructions for how to set up Valhalla on the DataLab server
R/                                              R source code
  |--- access_calculation.R                     Calculates the intersection of the isochrone boundaries and the census tracts, then calculates the population in each polygon created
  |--- census_data.R                            Downloads the census data from the TidyCensus package
  |--- combine_geocoding_results.R              A script to join the output from Geocodio and the hand geocoding process
  |--- compute_isochrones.R                     Computes the isochrone boundaries using Valhalla
  |--- distance_method_demo.R                   A script used at the beginning of this project to communicate the proposed methods
  |--- write_isochrone_to_geopackage.R          Combines the data in the isochrone .rds files to make one geopackage for ease of use in QGIS for mapmaking
```

<!--
The files in the `data/` directory are:

```

```
-->


## Google Drive File and Directory Structure

Data and supporting documents for this project will be stored in a [Google Drive](https://drive.google.com/drive/u/1/folders/1POVnOPgrcC_XViM0zDdMv2O-9B8ixRGT) folder on DataLab's account.

The directory stucture for the files on Google Drive is:

```
data/                                         Data sets
documentation                                 Documentation for the workflow and methods used in the analysis
literature                                    Published papers related to the work at hand
support_documents/                            Project proposal, collaboration agreement, scoping document, etc.
weekly_updates/                               Weekly progress reports from the DataLab team
meeting_notes_graves_2022_endocrine_surgery   Running meeting notes

```
