#!/bin/bash

################### input parameter ###################
origin_path=/home/gosh2/smp/c-agent/verify  ### 필요시 변경

callbackurl=$1
svc=$2
testfile_dir=$3
answer_dir=$4

logdir=$origin_path/log
date=`echo "$(date +'%F-%H-%M-%S-%N')"`

if [ ! -d $logdir ];then
   mkdir $logdir
fi
if [ ! -d $logdir/$svc ];then
   mkdir $logdir/$svc
fi
if [ ! -d $origin_path/tmp ];then
   mkdir $origin_path/tmp
fi

log_PFile=$origin_path/log/$svc/log_verify_${svc}_${date}
log_TFile=$origin_path/log/$svc/log_verify_already_${svc}_${date}

######################################################
# 30 Days over file Delete

if [ ! -z $logdir ];then
	find $logdir/$svc -mtime +30 -print -exec rm -f {} \;
fi

#########################################################
process_kill()
{
ps -ef | grep -E "check-verify" |grep -v grep |grep -v tail |grep -v vi > $origin_path/tmp/progtemp_$svc
if [ ! -z `awk '{print $2}' $origin_path/tmp/progtemp_$svc` ];then
	while read line
	do
		uui=`awk '{print $9}' $origin_path/tmp/progtemp_$svc`
		if [ $svc == $uui ];then
			kill -9 `awk '{print $2}' $line`
			echo "$svc process kill " >> $log_PFile
			exit 0
		fi
	done < $origin_path/tmp/progtemp_$svc
fi
}


################### check already all ############
ps -ef | grep check-verify | grep -v grep |grep -v tail |grep -v vi > $origin_path/tmp/checkverify-check_$svc

ch_svc=`awk '{print $10}' $origin_path/tmp/checkverify-check_$svc`
if [ "$svc" == "$ch_svc" ];then
	echo "Alread In Use" > $log_TFile
	curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E0090","resultMsg":"Already In Use(Verifying)","serviceCode":"'"$svc"'"}'
	exit 0
fi

#########################################################
echo "" > $log_PFile
echo "START :$(date +'%F-%H-%M-%S-%N')" >> $log_PFile
echo "[-------------------------------]" >> $log_PFile
echo "Stage 1 : PARAMETER Check" >> $log_PFile
echo "CallbackUrl  : "$callbackurl >> $log_PFile
echo "SVC          : "$svc >> $log_PFile
echo "Testfile_Dir : "$testfile_dir >> $log_PFile
echo "Answer_Dir   : "$answer_dir >> $log_PFile
echo "[-------------------------------]" >> $log_PFile

################### check input-parameter ###################
if [ ! -d $testfile_dir ] || [ ! -e $answer_dir ];then
	echo "Check Parameter" >> $log_PFile
	curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E0010","resultMsg":"Check parameter","serviceCode":"'"$svc"'"}'
	process_kill
	exit 0
fi

################### input file check ###################
echo "Stage 2: Input File Check" >> $log_PFile
for tst1 in $testfile_dir/*
do	
	if [ ! -d $tst1 ];then
		ft=`echo $tst1 | awk -F '.' '{print $NF}'`
		if [ "$ft" == "wav" ] || [ "$ft" == "pcm" ];then
			echo $tst1 "is ok" >> $log_PFile
			continue
		else
			echo $tst1 "is not wav or pcm" >> $log_PFile
			curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E0020","resultMsg":"Inputfile is not wav or pcm","serviceCode":"'"$svc"'"}'
			process_kill
			exit 0
		fi
	else
		echo "$tst1 is directory" >> $log_PFile
		curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E0030","resultMsg":"Input is directory","serviceCode":"'"$svc"'"}'
		process_kill
		exit 0
	fi
done

################### START verify ###################
echo "[-------------------------------]" >> $log_PFile
echo "Stage 3: Compute RecognitionRate" >> $log_PFile

echo "start check-verfiy" >> $log_PFile

$origin_path/check-verify-wer $svc $testfile_dir $answer_dir $date >> $log_PFile 

while [ 1 ]
do
	nj=`tail -1 $logdir/$svc/log_verify_${svc}_${date} |head -1`
	if [ "$nj" == "dirsim Error" ];then
		echo "dirsim Error" >> $log_PFile
		curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E0050","resultMsg":"dirsim Error","serviceCode":"'"$svc"'"}'
		echo "{"resultCode":"E0050","resultMsg":"dirsim Error","serviceCode":""$svc""} done" >> $log_PFile
		break

	elif [ "$nj" == "Answer File Error" ];then
		echo "Answer File Error!!" >> $log_PFile
		curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E0040","resultMsg":"Answer File Error","serviceCode":"'"$svc"'"}'
		echo "{"resultCode":"E0040","resultMsg":"Answer File Error","serviceCode":""$svc""} done" >> $log_PFile
		break

	elif [ "$nj" == "contain F sttresult error" ];then
		echo "contain F sttresult error" >> $log_PFile
		curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E0060","resultMsg":"STT Result Error","serviceCode":"'"$svc"'"}'
		echo "{"resultCode":"E0060","resultMsg":"STT Result Error","serviceCode":""$svc""} done" >> $log_PFile
		break

	elif [[ "$nj" =~ "score" ]];then
		echo "$nj" > $origin_path/tmp/recogRate_$svc
		cer1=`awk '{print $3}' $origin_path/tmp/recogRate_$svc`
		wer1=`awk '{print $4}' $origin_path/tmp/recogRate_$svc`
		echo "CER : $cer1 , WER : $wer1"  >> $log_PFile
		curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"C0010","resultMsg":"success","serviceCode":"'"$svc"'","cerRate":"'"$cer1"'","werRate":"'"$wer1"'"}'
		echo "{"resultCode":"C0010","resultMsg":"success","serviceCode":""$svc"","cerRate":""$cer1"","werRate":""$wer1""} done" >> $log_PFile
		
		break	
	elif [ "$nj" == "filetype" ];then
        echo "Check File type" >> $log_PFile
        curl -k $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E0020","resultMsg":"Check File type","serviceCode":"'"$svc"'"}'

        break
	fi
done

### 검증이 끝나고 사용한 음성 데이터 및 정답지 삭제
rm -rf $testfile_dir/* $answer_dir 

echo "[-------------------------------]" >> $log_PFile
echo "END :$(date +'%F-%H-%M-%S-%N')" >> $log_PFile

exit 0 
