# ERDDAP_tools
ERDDAP Tools

Regarding my job duty, I spent lots of time dealing with human-generated netCDF files and passed files into the ERDDAP system. Although the files I received should pass the IOOS compliance; however, some of the small/tiny bugs run everywhere, making it difficult to generate the automatic submission program. 

Currently, the only way to debug the ERDDAP submission (at least this is the only way I knew) is to submit the dataset and use ERDDAP DasDds.sh to check the error message. Well, this is not a too bad idea by using DasDds.sh to do the debugging if you only have few files. BUT, in my working scenario, I have tons of datasets from the observation and numerical model simulation, laboratory, and even the fishery. Meanwhile, I am using docker to execute the ERDDAP; I don't want to spend too much time on the traffic between the docker container or local-end. I also don't want to check the error after the submission since I wrote a script to work on it, and this script grabs all of the datasets I have. I do not want to go into the loop....find the datasetID, input it on DasDds.sh, check the response, locate errors... 

It is soooooo time wasted.

Thus, in this repository, I try to create some bash scripts function to determine the bugs before submitting the dataset to the system. This repository just started, so I don't know how many updates will be made. 

If you would like to make a test run, I am appreciated it. 
If you meet any error or think there is something to update, please raise the issue with detailed information. I will work on it.


* Check4ERDDAP.sh
This is the bash script to check whether netCDF is okay to used in the ERDDAP server. (Before tarball)
  
* FromTar2ERDDAP.sh
 This is the bash script to untar the files in the tarz directory and generate the ERDDAP XML file. (After tarball)


  
  
Writen by  
   Chuan-Yuan Hsu, Ph.D., 2020-12-15
       Postdoc Data Scientist/Manager, Gulf of Mexico Coastal Ocean Observing System
       Postdoc Research Associate, Department of Oceanography, Texas A&M University
