#!/bin/bash
#-
#-	  Usage:
#-      ./FromTar2ERDDAP.sh
#-
#-   The goals of this program are
#-      1. 解壓縮 並且 根據檔案名存擋
#-      2. 準備 ERDDAP GeneratedXml.sh 的 輸入
#-
#-   Updates: 2020-12-08
#-   CopyRight: Chuan-Yuan Hsu, GCOOS/GRIIDC

clear

#SRC_DIR=$PWD
SRC_DIR='/usr/local/tomcat8/data/marion/wait4test'
XML_DIR='/usr/local/tomcat8/webapps/erddap/WEB-INF'
LOG_DIR='/usr/local/tomcat8/data/logs'
ERD_DIR='/usr/local/tomcat8/content/erddap'



#---------------------------
#----- SubFunction -----
time_elapsed() {
    if [[ -z ${1} || ${1} -lt 60 ]] ;then
        min=0 ; secs="${1}"
    else
        time_mins=$(echo "scale=2; ${1}/60" | bc)
        min=$(echo ${time_mins} | cut -d'.' -f1)
        secs="0.$(echo ${time_mins} | cut -d'.' -f2)"
        secs=$(echo ${secs}*60|bc|awk '{print int($1+0.5)}')
    fi
    echo "Time Elapsed : ${min} minutes and ${secs} seconds."
}

#----- End SubFunction -----
#---------------------------

GeneratedXMLscript="GenerateDatasetsXml.sh"
GeneratedXMLoutput="$LOG_DIR/GenerateDatasetsXml.out"
GeneratedXMLexecut="$SRC_DIR/GenerateDatasetsXMLexecute.sh"
if [ -f $GeneratedXMLexecut ]; then rm $GeneratedXMLexecut; fi
if [ -d "${SRC_DIR}/XML" ]; then rm -rf "${SRC_DIR}/XML"; fi
mkdir -p "${SRC_DIR}/XML"

touch $GeneratedXMLexecut
echo "cd $XML_DIR" >> $GeneratedXMLexecut
echo " " >> $GeneratedXMLexecut
chmod +x $GeneratedXMLexecut


num_files=0
tids=`ls ./tarz/*tar.gz`
for tid in $tids
do
	((num_tid+=1))
	TaskID=`echo $tid| cut -d'_' -f1|cut -d'/' -f3`
	TaskID="${TaskID:0:11}.${TaskID:11:15}"
   case $tid in
   	*_[pP]rofile*)
			title_front="Profile - $TaskID"
			data_path="Untar/Profile/$TaskID"
		;;
   	*_[tT]rajectory*)
			title_front="Trajectory - $TaskID"
			data_path="Untar/Trajectory/$TaskID"
		;;
   	*_[tT]ime[sS]eries*)
			title_front="TimeSeries - $TaskID"
			data_path="Untar/TimeSeries/$TaskID"
		;;
   	*_[tT]imeSeries[pP]rofile*)
			title_front="TimeSeriesProfile - $TaskID"
			data_path="Untar/TimeSeriesProfile/$TaskID"
		;;
     	*_[tT]rajectory[pP]rofile*)
			title_front="Trajectory-Profile - $TaskID"
			data_path="Untar/TrajectoryProfile/$TaskID"
		;;
		*)
			title_front="no category found file - $TaskID"
			data_path="Untar/no_category/$TaskID"
		;;
   esac

	data_path=$SRC_DIR/$data_path
	if [ ! -d "${data_path}" ]; then 
		echo 'untar: ... Yes ...'
		echo "${data_path}"
		echo " break loop "
		exit 

		mkdir -p $data_path
		tar xf $tid --strip-components=1 -C $data_path
	fi
	
	#--- Prepare for questions of ERDDAP GenerateDatasetsXml.sh 
	fids=`ls ${data_path}/*.nc`
	for fid in $fids
	do
		startTime=`date +%s`
		#--- dataID
		dataID=`echo $fid|rev|cut -d'/' -f2|rev`"-"`echo $fid|sed 's/.nc$//'|sed 's/.*\///'`
		datasetID=`echo $dataID|sed 's/\./-/g'`

		#--- geo-location
		lat_min=`ncdump -h $fid|grep lat_min|cut -d'=' -f2|sed 's/ ;//'`
		lat_max=`ncdump -h $fid|grep lat_max|cut -d'=' -f2|sed 's/ ;//'`
		lon_min=`ncdump -h $fid|grep lon_min|cut -d'=' -f2|sed 's/ ;//'`
		lon_max=`ncdump -h $fid|grep lon_max|cut -d'=' -f2|sed 's/ ;//'`
		lat=$(bc <<< "scale=3; ($lat_min + $lat_max)/2")
		lon=$(bc <<< "scale=3; ($lon_min + $lon_max)/2")
		geoloc="${lat}N `echo $lon|sed 's/-//'`W"

		#--- institution
		creator_institution=`ncdump -h $fid|grep 'creator_institution'| sed 's/.*= "//'| sed 's/" ;//'`

		title=\'"$title_front - $dataID - $geoloc - $datemin"\'

		#--------------------------------------
		((num_files+=1))
		echo 'num: ' $num_tid $num_files
		echo 'tid: ' $tid
		echo "      fid: " $fid
		echo "      dataID: " $dataID
		echo "      datasetID: " $datasetID
		#echo "      data Path: " $data_path
		#echo '      title: ' $title
      #echo '      institution: ' $creator_institution
		#--------------------------------------

		#--- ERDDAP GenerateDatasetsXml.sh arguments
		###---   EDDType='EDDTableFromNcFiles'
		###---   StartingDirectory=$data_path
		###---   FileRegex=`echo $fid|sed 's/.*\///'`
		###---   #FileRegex=$fid
		###---   FullFileName=$fid
		###---   DimensionsCSV='default'
		###---   ReloadMin=10080
		###---   PreRegex='default'
		###---   PostRegex='default'
		###---   ExtRegex='default'
		###---   ColNameExt='default'
		###---   SortColSrcName='default'
		###---   SortFileSrcName='default'
		###---   infoUrl='default'
		###---   Institution=\'$creator_institution\'
		###---   Summary='default'
		###---   Title='modification'
		###---   Standard='default'
		###---   Cache='default'
		###---   ERDDAP_Args="$EDDType $StartingDirectory $FileRegex $FullFileName $DimensionsCSV"
		###---   ERDDAP_Args="$ERDDAP_Args $ReloadMin $PreRegex $PostRegex $ExtRegex $ColNameExt"
		###---   ERDDAP_Args="$ERDDAP_Args $SortColSrcName $SortFileSrcName $infoUrl $Institution "
		###---   ERDDAP_Args="$ERDDAP_Args $Summary $Title $Standard $Cache"


		EDDType='EDDTableFromMultidimNcFiles'
		StartingDirectory=$data_path
		FileRegex=`echo $fid|sed 's/.*\///'`
		FullFileName=$fid
		DimensionsCSV='default'
		ReloadMin=10080
		PreRegex='default'
		PostRegex='default'
		ExtRegex='default'
		ColNameExt='default'
		RemoveMissing='true'
		SortFileSrcName='default'
		infoUrl='default'
		Institution=\'$creator_institution\'
		Summary='default'
		Title='modification'
		Standard='default'
		treatDim='default'
		Cache='default'
		ERDDAP_Args="$EDDType $StartingDirectory $FileRegex $FullFileName $DimensionsCSV"
		ERDDAP_Args="$ERDDAP_Args $ReloadMin $PreRegex $PostRegex $ExtRegex $ColNameExt"
		ERDDAP_Args="$ERDDAP_Args $RemoveMissing $SortFileSrcName $infoUrl $Institution "
		ERDDAP_Args="$ERDDAP_Args $Summary $Title $Standard $treatDim $Cache"

		###---   #-----
		###---   echo ' '
		###---   echo '            CHECK variable: StartingDirectory ' $StartingDirectory
		###---   echo '            CHECK variable: FileRegex         ' $FileRegex
		###---   echo '            CHECK variable: FullFileName      ' $FullFileName
		###---   echo '            CHECK variable: Institution       ' $Institution
		###---   #-----
		
		echo "bash $GeneratedXMLscript $ERDDAP_Args" >> $GeneratedXMLexecut
		echo "sed -i \"s/datasetID=\\\".*\\\" active/datasetID=\\\"$datasetID\\\" active/\" $GeneratedXMLoutput" >> $GeneratedXMLexecut
      echo "sed -i \"s/title\\\">.*modification.*<\\/att>/title\\\">$title<\\/att>/\" $GeneratedXMLoutput" >> $GeneratedXMLexecut
		echo "cp $GeneratedXMLoutput ${SRC_DIR}/XML/${dataID}.xml " >> $GeneratedXMLexecut
		echo " " >> $GeneratedXMLexecut 

		#--------------------------------------
		echo "      " `time_elapsed "$(($(date +%s) - ${startTime}))"`
      echo '      done ********' 
		echo " "
		if [ $num_tid == 3 ]; then 
#		if [ $num_files == 140 ]; then 
			break 2
			#exit 1
		fi
		#--------------------------------------
	done
done
find ./* -name ".DS_Store" -delete

bash $GeneratedXMLexecut

#--
echo " " 
echo " " 
echo " Start to merge XML files to datasets.xml" 
echo " " 
echo " " 
#-------------------------
if [ -f ${SRC_DIR}/new.xml ]; then rm -rf ${SRC_DIR}/new.xml; fi
cat ${SRC_DIR}/XML/*xml >> ${SRC_DIR}/new.xml
cd $ERD_DIR
cp datasets.xml datasets.xml_`date +"%Y-%m-%dT%H:%M:00"`

cat datasets_header.xml | cat - ${SRC_DIR}/new.xml | cat - datasets_ender.xml > temp && mv temp datasets.xml
#head -n -3 datasets.xml | cat - ${SRC_DIR}/new.xml | cat - datasets_ender.xml > temp && mv temp datasets.xml


echo " Process completed!"
