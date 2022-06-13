#!/bin/bash

################## input parameter #############################
svc=$1
response_check=$2
testfile_dir=$3
callbackurl=$4

origin_path=/home/gosh2/smp/c-agent/test
date=`echo "$(date +'%F-%H-%M-%S-%N')"`

log_PFile=$origin_path/log/$svc/log_checkone_${svc}_${date}
log_TFile=$origin_path/log/$svc/log_checkone_already_${svc}_${date}


##############################################################

testfile_format=`echo $testfile_dir | awk -F '/' '{print $NF}'| awk -F '.' '{print $NF}'`

if [ $testfile_format == "wav" ];then
	testfile_key=`echo $testfile_dir | awk -F '/' '{print $NF}'| awk -F '.wav' '{print $1}'`
	testfile_result=$testfile_key.pcm.stt
elif [ $testfile_format == "pcm" ];then
    testfile_key=`echo $testfile_dir | awk -F '/' '{print $NF}'| awk -F '.pcm' '{print $1}'`
    testfile_result=$testfile_key.pcm.stt
else 
	echo ""
fi

resultfile=$origin_path/client-one/svc/$svc/$testfile_result
logdir=$origin_path/log

if [ ! -d $origin_path/tmp ];then
   mkdir $origin_path/tmp
fi

if [ ! -d $logdir ];then
   mkdir $logdir
fi

if [ ! -d $logdir/$svc ];then
   mkdir $logdir/$svc
fi
###############################################################
# 30 Days over file Delete

find $logdir/$svc -mtime +30 -print -exec rm -f {} \;

################### check Already  #############################

ps -ef | grep check-one | grep -v grep |grep -v tail |grep -v vi > $origin_path/tmp/checkone-check_$svc

ch_svc=`awk '{print $10}' $origin_path/tmp/checkone-check_$svc`
if [ "$svc" == "$ch_svc" ];then
	if [ $response_check -eq "0" ];then
		echo "Already In Use(Check-one)" > $log_PFile
		curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E0009","resultMsg":"Already In Use(Check-one)","serviceCode":"'"$svc"'"}'
        echo "[-------------------------------]" >> $log_PFile
        echo "END :$(date +'%F-%H-%M-%S-%N')" >> $log_PFile

	    exit 0
	elif [ $response_check -eq "1" ];then
        result='{"resultCode":"E0009","resultMsg":"Already In Use(Check-one)"}'
        echo $result
        echo $result >> $log_PFile
		echo "Already In Use(Check-one)" > $log_PFile
        echo "[-------------------------------]" >> $log_PFile
        echo "END :$(date +'%F-%H-%M-%S-%N')" >> $log_PFile

		exit 0
	fi
fi

#################################################################
process_kill()
{
ps -ef | grep -E "check-one" |grep -v grep |grep -v tail |grep -v vi > $origin_path/tmp/chkoneprogtemp_$svc
if [ ! -z `awk '{print $2}' $origin_path/tmp/chkoneprogtemp_$svc` ];then
	while read line
	do
		uui=`awk '{print $10}' $origin_path/tmp/chkoneprogtemp_$svc`
		if [ $svc == $uui ];then
			kill -9 `awk '{print $2}' $line`
			echo "$svc process kill " >> $log_PFile
	        exit 0
		fi
	done < $origin_path/tmp/chkoneprogtemp_$svc 
fi
exit 0
}

#####################   START   ###################################

echo "" > $log_PFile
echo "START :$(date +'%F-%H-%M-%S-%N')" >> $log_PFile
echo "[-------------------------------]" >> $log_PFile
echo "[---Stage 1 - PARAMETER Check---]" >> $log_PFile
echo "SVC           : "$svc >> $log_PFile
echo "Response_Type : "$response_check >> $log_PFile
echo "TestFile_Dir  : "$testfile_dir >> $log_PFile
echo "CallbackUrl   : "$callbackurl >> $log_PFile


##################### input file check ###############################
echo "[-------------------------------]" >> $log_PFile
echo "[---Stage 2 - Input File Check--]" >> $log_PFile

if [ -f $testfile_dir ];then
	if [ $testfile_format != "wav" ] &&  [ $testfile_format != "pcm" ];then
		if [ $response_check -eq "0" ];then
			echo "Inputfile is not wav or pcm" >> $log_PFile
			curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E0002","resultMsg":"Check File type","serviceCode":"'"$svc"'"}'
            echo "[-------------------------------]" >> $log_PFile
            echo "END :$(date +'%F-%H-%M-%S-%N')" >> $log_PFile

			exit 0
		elif [ $response_check -eq "1" ];then
			result='{"resultCode":"E0002","resultMsg":"Check File type"}'
			echo $result
			echo $result >> $log_PFile
			echo "Inputfile is not wav or pcm" >> $log_PFile
            echo "[-------------------------------]" >> $log_PFile
            echo "END :$(date +'%F-%H-%M-%S-%N')" >> $log_PFile
			exit 0
		fi
	fi

else
	if [ $response_check -eq "0" ];then
		echo "$testfile_dir is not file" >> $log_TFile
		curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E0003","resultMsg":"Input is directory","serviceCode":"'"$svc"'"}'
        echo "[-------------------------------]" >> $log_PFile
        echo "END :$(date +'%F-%H-%M-%S-%N')" >> $log_PFile
		process_kill
		exit 0
	elif [ $response_check -eq "1" ];then
		result='{"resultCode":"E0003","resultMsg":"Input is directory"}'
		echo $result >> $log_PFile
		echo $result
		echo "$testfile_dir is not file" >> $log_TFile
        echo "[-------------------------------]" >> $log_PFile
        echo "END :$(date +'%F-%H-%M-%S-%N')" >> $log_PFile
		process_kill
		exit 0
	fi
fi


echo "[-------------------------------]" >> $log_PFile
echo "[---Stage 3 - Start Check One---]" >> $log_PFile

################## runfile check ####################
if [ -e $origin_path/check-one ];then
	echo "RunFile exist" >> $log_PFile

else
    if [ $response_check -eq "0" ];then
        echo "Runfile is not exist" >> $log_PFile
        curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E0004","resultMsg":"Run file Error","serviceCode":"'"$svc"'"}'
        echo "[-------------------------------]" >> $log_PFile
        echo "END :$(date +'%F-%H-%M-%S-%N')" >> $log_PFile
        process_kill
        exit 0
    
    elif [ $response_check -eq "1" ];then
        result='{"resultCode":"E0004","resultMsg":"Runfile Error"}'
        echo $result >> $log_PFile
        echo $result
        echo "Runfile is not exist" >> $log_PFile
        echo "[-------------------------------]" >> $log_PFile
        echo "END :$(date +'%F-%H-%M-%S-%N')" >> $log_PFile
        process_kill
        exit 0
    fi
fi
#####################################################


### callback type 0 ###
if [ $response_check -eq "0" ];then
	$origin_path/check-one $svc $response_check $testfile_dir $date >> $log_PFile

	while [ 1 ]
	do
		nj=`tail -1 $log_PFile |head -1`
		echo $nj
		if [ "$nj" == "Client Error" ];then
			echo "Client Error" >> $log_PFile
			curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E0005","resultMsg":"Client Error","serviceCode":"'"$svc"'"}'
			break

		elif [ "$nj" == "filename" ];then
			echo "success" >> $log_PFile

			cp $resultfile $origin_path/svc/$svc/sttResult/
			result_filename=`echo $resultfile | awk -F '/' '{print $NF}'`
			result_file_path=$origin_path/svc/$svc/sttResult/$result_filename

			echo $result_file_path >> $log_PFile
			curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"C0001","resultMsg":"Success","serviceCode":"'"$svc"'","sttResultFilePath":"'"$result_file_path"'"}'
			break

		elif [ "$nj" == "contain F sttresult error" ];then
			echo "Single action verification Fail" >> $log_PFile
			curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E0001","resultMsg":"Single action verification Fail","serviceCode":"'"$svc"'"}'
			break
		fi
	done

#### response type 1 ####
else

	$origin_path/check-one $svc $response_check $testfile_dir $date

fi

echo "[-------------------------------]" >> $log_PFile
echo "END :$(date +'%F-%H-%M-%S-%N')" >> $log_PFile

exit 0 
