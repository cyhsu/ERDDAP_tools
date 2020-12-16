#!/bin/bash
#--- 
#---  Program:  Check4ERDDAP.sh
#---
#---  Usage  :  Check4ERDDAP.sh "your_netCDF_file"
#---  
#---  Goals  :
#--- 
#---            Bash Functions for ERDDAP use.
#--- 
#---            This bash program attempts to provide notification messages by i
#---                 building up a pre-checkpoint before submitting the netCDF file to ERDDAP
#--- 
#--- 
#---  Updates: 2020-12-15
#---  CopyRight: Chuan-Yuan Hsu, Ph.D. @GCOOS/GRIIDC

#---------------------------
#----- SubFunction -----

#-- Check variable type
#-- Usage: 
#--     vartype newtest
#--     :> ARRAY
vartype() {
    local var=$( declare -p $1 )
    local reg='^declare -n [^=]+=\"([^\"]+)\"$'
    while [[ $var =~ $reg ]]; do
            var=$( declare -p ${BASH_REMATCH[1]} )
    done

    case "${var#declare -}" in
    a*)
            echo "ARRAY" > /dev/tty
            ;;
    A*)
            echo "HASH" > /dev/tty
            ;;
    i*)
            echo "INT" > /dev/tty
            ;;
    x*)
            echo "EXPORT" > /dev/tty
            ;;
    *)
            echo "OTHER" > /dev/tty
            ;;
    esac
}

#-- Function: time_elapsed()
#-- Usage: 		
#--           startTime=$(date +%s)
#--           echo "      " `time_elapsed "$(($(date +%s) - ${startTime}))"`

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

CheckCaseSensitive(){
	if (( "$1" == "$2" )); then 
		echo '1'
	fi
}

getNetCDFVariables() {
	local NCDFfid=$1
	echo $(ncdump -h $NCDFfid|grep "(.*)"|grep -v ":"|sed 's/(.*$//'|awk '{print $NF}')
}


Check4ERDDAP (){
	local NCDFfid=$1
	local FileHead=`ncdump -h $NCDFfid`				#-- Text
	local Vars=($(getNetCDFVariables $NCDFfid))		#-- Arrays


	FILE=$(echo $NCDFfid|rev|cut -d'/' -f1|rev)
	FDIR=$(echo $NCDFfid|sed "s/\/$FILE//")
	printf "\n" > /dev/tty
	printf "........................................................................................................\n" > /dev/tty
	printf "Check netCDF FILE: $FILE  \t\t\t\t\t\t........ \n" > /dev/tty
	printf "             PATH: $FDIR  \t\t\t\t\t\t........ \n" > /dev/tty
	printf "\n" > /dev/tty
	printf "\t What will be checked: \n" > /dev/tty
	printf "\t      1. Check global attribute: cf_data_type \n" > /dev/tty
	printf "\t      2. Check global attribute: cf_xxxxx_variables \n" > /dev/tty
	printf "\t      3. ... To be continued ...\n\n" > /dev/tty


	cdm_data_type_inFile=$(ncdump -h $NCDFfid|grep 'cdm_data_type'|cut -d'"' -f2)
	#cdm_data_type_inFile=$(echo $FileHead|grep 'cdm_data_type'|cut -d'"' -f2)
	if [ ! $cdm_data_type_inFile ]; then 
	   printf "\t\t\t Warning! the global attribute "cdm_data_type" is not assigned.\n" > /dev/tty
		break
	else 
		case $cdm_data_type_inFile in 
			[pP]rofile)
				cdm_data_type='Profile'
				cdm_role='cdm_profile_variables'
			;;
	   	[tT]rajectory)
				cdm_data_type='Trajectory'
				cdm_role='cdm_trajectory_variables'
			;;
	   	[tT]ime[sS]eries)
				cdm_data_type='TimeSeries'
				cdm_role='cdm_timeseries_variables'
			;;
	   	[tT]imeSeries[pP]rofile)
				cdm_data_type='TimeSeriesProfile'
				cdm_role='cdm_timeseries_variables cdm_profile_variables'
			;;
	     	[tT]rajectory[pP]rofile)
				cdm_data_type='TrajectoryProfile'
				cdm_role='cdm_trajectory_variables cdm_profile_variables'
			;;
			*)		
			;;
		esac

		cdm_data_type_status=$(CheckCaseSensitive $cdm_data_type_inFile $cdm_data_type)

		if [[ $cdm_data_type_status -ne '1' ]]; then 
		#if [[ $cdm_data_type_status =~ '1' ]]; then 
			printf "\t Warning! The attribute value \"$cdm_data_type_inFile\" has the capitalization issue. \n" > /dev/tty
			printf "\t          The value has to be \"${cdm_data_type}\".\n\n" > /dev/tty
		fi
		cdm_check_status=$(CheckCDM)
		#cdm_check_status=$(CheckCDM $cdm_data_type $cdm_role)
	fi
}

CheckCDM () {
	for cdm in $cdm_role #-- 表示 cdm_xxx_variables
	do
		num_cf_role=0
		printf "\t @ Checking $cdm ...\n" > /dev/tty
		for cdm_var in $(ncdump -h $NCDFfid| grep $cdm| cut -d'"' -f2| tr ', ' '\n') #-- cdm_traj_var, cdm_prof_var
		do
			#-- ex:
			#--     :cdm_trajectory_variables = "trajectory, latitude, longitude" ;
			#--     cdm_data_var = 'trajectory' 'latitude' 'longitude'
			#-- 
			printf "\t            variable: %s \n" $cdm_var > /dev/tty
#			if [[ "${Vars[*]}" =~ *"${cdm_var}"* ]]; then 
			if [[ ${Vars[*]} == *$cdm_var* ]]; then
				printf "\t                    ... 1. Variable Name Found!\n" > /dev/tty
			else
				printf "\t                    ... 1. Variable Name NOT Found!\n" > /dev/tty
				printf "\t                    ...    Is not matching any of the netCDF variables in the file\n" > /dev/tty
				if ncdump -h $NCDFfid|grep -qi "${cdm_var}(.*;"; then
					name=$(ncdump -h $NCDFfid|grep -i "${cdm_var}(.*;"|sed 's/(.*//'|awk '{print $NF}')
					printf "\t                    ...       Do find similarity\n" > /dev/tty
					printf "\t                    ...       Capitalization issue could occur\n" > /dev/tty
					printf "\t                    ...       Plese check the spell of the variable.\n" > /dev/tty
					printf "\t                    ...       Possible used variable name in the file is    \"%s\"   \n" $name > /dev/tty
				fi
			fi

			if [[ $(ncdump -h $NCDFfid| grep -i ".*\t${cdm_var}:"| grep "cf_role") ]]; then 
				((num_cf_role+=1))
				printf "\t                    ... 2. attribute \"cf_role\" exist\n" > /dev/tty
			else
				printf "\t                    ... 2. attribute \"cf_role\" does not exist\n" > /dev/tty
			fi
		done

		printf "\n" > /dev/tty
		case $num_cf_role in 
			0)
				printf "\t            ___ %-50s  ___ \n" "Variable attribute \"cf_role\" found $num_cf_role times" > /dev/tty
				printf "\t            ___ %-50s  ___ Bad!\n" "None of the variable attribute \"cf_role\" is found" > /dev/tty
			;;
			1)
				printf "\t            ___ %-50s  ___ \n" "Variable attribute \"cf_role\" found $num_cf_role times" > /dev/tty
				printf "\t            ___ %-50s  ___ Good! \n" > /dev/tty
			;;
			*)
				printf "\t            ___ %-50s ___ \n" "Variable attribute \"cf_role\" found $num_cf_role times" > /dev/tty
				printf "\t            ___ %-50s ___ Bad!\n" "Too many variable attribute \"cf_role\" are found" > /dev/tty
			;;
		esac
		printf "\n\t @ Checking $cdm ... done\n" > /dev/tty
	done
}


#--------------------------------------------------------
#------------------  Main Program   ---------------------
#--------------------------------------------------------
startTime=$(date +%s)
Check4ERDDAP $1
echo " "
echo " " `time_elapsed "$(($(date +%s) - ${startTime}))"`
echo "  Check Completed!" 
echo " "

