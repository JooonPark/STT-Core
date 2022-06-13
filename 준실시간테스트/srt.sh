#!/bin/bash

################## input parameter #############################
srtid=$1
svc=$2
testfile_dir=$3
callbackurl=$4

origin_path=/home/gosh2/smp/srt-agent/srt  ## 필요시 변경
date=`echo "$(date +'%F-%H-%M-%S-%N')"`
##############################################################

testfile_format=`echo $testfile_dir | awk -F '/' '{print $NF}'| awk -F '.' '{print $NF}'`

if [ $testfile_format == "wav" ];then
#	testfile_key=`echo $testfile_dir | awk -F '/' '{print $NF}'| awk -F '.wav' '{print $1}'`
	testfile_result="wav"
elif [ $testfile_format == "pcm" ];then
#	testfile_key=`echo $testfile_dir | awk -F '/' '{print $NF}'| awk -F '.pcm' '{print $1}'`
    testfile_result="pcm"
else 
	echo ""
fi

resultfile=$origin_path/test_file/$svc/$srtid.sttresult/${svc}_${srtid}.${testfile_result}.stt
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

#################################################################
process_kill()
{
ps -ef | grep -E "check-srt" |grep -v grep |grep -v tail |grep -v vi > $origin_path/tmp/chksrtprogtemp_$svc
if [ ! -z `awk '{print $2}' $origin_path/tmp/chksrtprogtemp_$svc` ];then
	while read line
	do
		uui=`awk '{print $10}' $origin_path/tmp/chksrtprogtemp_$svc`
		if [ $svc == $uui ];then
			kill -9 `awk '{print $2}' $line`
			echo "$svc process kill " >> $origin_path/log/$svc/log_checksrt_${svc}_${date}
	        exit 0
		fi
	done < $origin_path/tmp/chksrtprogtemp_$svc 
fi
exit 0
}

#####################   START   ###################################

echo "" > $origin_path/log/$svc/log_checksrt_${svc}_${date}
echo "START :$(date +'%F-%H-%M-%S-%N')" >> $origin_path/log/$svc/log_checksrt_${svc}_${date}
echo "[-------------------------------]" >> $origin_path/log/$svc/log_checksrt_${svc}_${date}
echo "[---Stage 1 - PARAMETER Check---]" >> $origin_path/log/$svc/log_checksrt_${svc}_${date}
echo "SrtID         : "$srtid >> $origin_path/log/$svc/log_checksrt_${svc}_${date}
echo "ServiceCode   : "$svc >> $origin_path/log/$svc/log_checksrt_${svc}_${date}
echo "TestFile_Dir  : "$testfile_dir >> $origin_path/log/$svc/log_checksrt_${svc}_${date}
echo "CallbackUrl   : "$callbackurl >> $origin_path/log/$svc/log_checksrt_${svc}_${date}


##################### input file check ###############################
echo "[-------------------------------]" >> $origin_path/log/$svc/log_checksrt_${svc}_${date}
echo "[---Stage 2 - Input File Check--]" >> $origin_path/log/$svc/log_checksrt_${svc}_${date}

if [ -f $testfile_dir ];then
	if [ $testfile_format != "wav" ] &&  [ $testfile_format != "pcm" ];then
		echo "Inputfile is not wav or pcm" >> $origin_path/log/$svc/log_checksrt_already_${svc}_${date}
		curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E0011","resultMsg":"Check File type","srtId":"'"$srtid"'","serviceCode":"'"$svc"'"}'
		exit 0
	fi

else
	echo "$testfile_dir is not file" >> $origin_path/log/$svc/log_checksrt_already_${svc}_${date}
	curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E0012","resultMsg":"Input is directory","srtId":"'"$srtid"'","serviceCode":"'"$svc"'"}'
	process_kill
	exit 0
fi


echo "[-------------------------------]" >> $origin_path/log/$svc/log_checksrt_${svc}_${date}
echo "[---Stage 3 - Start Check One---]" >> $origin_path/log/$svc/log_checksrt_${svc}_${date}

################## runfile check ####################
if [ -e $origin_path/check-srt ];then
	echo "RunFile exist" >> $origin_path/log/$svc/log_checksrt_${svc}_${date}

else
	echo "Runfile is not exist" >> $origin_path/log/$svc/log_checksrt_already_${svc}_${date}
	curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E0014","resultMsg":"Run file Error","srtId":"'"$srtid"'","serviceCode":"'"$svc"'"}'
	process_kill
	exit 0
fi
#####################################################


### callback type 0 ###
$origin_path/check-srt $srtid $svc $testfile_dir $date >> $origin_path/log/$svc/log_checksrt_${svc}_${date}

while [ 1 ]
do
	nj=`tail -1 $origin_path/log/$svc/log_checksrt_${svc}_${date} |head -1`
	echo $nj
	if [ "$nj" == "dirsim Error" ];then
        echo "dirsim Error" >> $origin_path/log/$svc/log_checksrt_${svc}_${date}
        curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E0013","resultMsg":"dirsim Error","srtId":"'"$srtid"'","serviceCode":"'"$svc"'"}'
        echo "{"resultCode":"E0013","resultMsg":"dirsim Error","srtId":"'"$srtid"'","serviceCode":"'"$svc"'"} done" >> $origin_path/log/$svc/log_checksrt_${svc}_${date}
        break

	elif [ "$nj" == "filename" ];then
		echo "success" >> $origin_path/log/$svc/log_checksrt_${svc}_${date}

		cp $resultfile $origin_path/svc/$svc/sttResult/
		result_filename=`echo $resultfile | awk -F '/' '{print $NF}'`
		result_file_path=$origin_path/svc/$svc/sttResult/$result_filename

		echo $result_file_path >> $origin_path/log/$svc/log_checksrt_${svc}_${date}
		curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"C0011","resultMsg":"Success","srtId":"'"$srtid"'","serviceCode":"'"$svc"'","sttResultFilePath":"'"$result_file_path"'"}'
		break

	elif [ "$nj" == "contain F sttresult error" ];then
		echo "Single action verification Fail" >> $origin_path/log/$svc/log_checksrt_${svc}_${date}
		curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E0022","resultMsg":"Single action verification Fail","srtId":"'"$srtid"'","serviceCode":"'"$svc"'"}'
		break
	fi
done

rm -rf $origin_path/test_file/$svc/$srtid*

#### response type 1 ####

echo "[-------------------------------]" >> $origin_path/log/$svc/log_checksrt_${svc}_${date}
echo "END :$(date +'%F-%H-%M-%S-%N')" >> $origin_path/log/$svc/log_checksrt_${svc}_${date}

exit 0 
