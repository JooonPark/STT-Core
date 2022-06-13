#!/bin/bash

modeldir=$1
svc=$2
lmtype=$3

origin_path=/home/gosh2/smp/r-agent/deploy ## 필요시 변경
date=`echo "$(date +'%F-%H-%M-%S-%N')"`

if [ ! -d $origin_path/tmp ];then
   mkdir $origin_path/tmp
fi

if [ ! -d $origin_path/log ];then
   mkdir $origin_path/log
fi

if [ ! -d $origin_path/log/$svc ];then
   mkdir $origin_path/log/$svc
fi


##################################################

# 30 Days over file Delete

find $logdir/$svc -mtime +30 -print -exec rm -f {} \;

################### Model check ###################
## CLASS LM ##
class_info="HCLG.class"
phone_info="phones.txt"
symbo_info="symbols.enc"
words_info="words.txt"
tmp_info="tmp"

## SERVICE LM ##
AM_model="final.mdl"
LM_model="HCLG.fst"
conf="decode.conf"
sym="symbols.enc"
ivector="ivector_extractor"
class_dir="classlms"

echo "" > $origin_path/log/$svc/log_deploy_${svc}_${date}

################### Check Already ###################
ps -ef | grep model_deploy_class | grep -v grep |grep -v tail |grep -v vi  > $origin_path/tmp/deploymodel-check
if [ ! -z `awk '{print $11}' $origin_path/tmp/deploymodel-check` ];then
	cat $origin_path/tmp/deploy-check |awk '{print $11}' > $origin_path/tmp/running_deploy_svc
	while read line
	do
		if [ $svc == $line ];then
			echo "SVC $svc is ruuning" > $origin_path/log/$svc/log_deploy_already_$svc
			result='{"resultCode":"E0900","resultMsg":"Already in use(deploying)","serviceCode":"'"$svc"'","lmType":"'"$lmtype"'"}'
			echo $result >> $origin_path/log/$svc/log_deploy_${svc}_${date}
			echo $result
			exit 0
		fi
	done < $origin_path/tmp/running_deploy_svc
fi
#########################################################

################### Model Check ###################
if [ $lmtype == "CLASS" ];then
	ft=`echo $modeldir | awk -F '/' '{print $NF}'`
	rt=`echo $modeldir | sed 's@'"\/$ft"'@'""'@'` 

	cd $rt && tar -zxvf $ft > tar_info
	gt=`cat tar_info | head -1 | sed 's/\///g'`

	class_real_dir=$rt/$gt
	if [ ! -e $class_real_dir/$class_info ] || [ ! -e $class_real_dir/$phone_info ] || [ ! -e $class_real_dir/$words_info ] || [ ! -e $class_real_dir/$symbo_info ] || [ ! -d $class_real_dir/$tmp_info ];then
		result='{"resultCode":"E0100","resultMsg":"Model File Error","serviceCode":"'"$svc"'","lmType":"'"$lmtype"'"}'
		echo $result >> $origin_path/log/$svc/log_deploy_${svc}_${date}
		echo $result
		exit 0
	fi

elif [ $lmtype == "SERVICE" ];then
	echo "Service lm will support" >> $origin_path/log/$svc/log_deploy_${svc}_${date}
    result='{"resultCode":"E0300","resultMsg":"Service lm will support","serviceCode":"'"$svc"'","lmType":"'"$lmtype"'"}'
    echo $result >> $origin_path/log/$svc/log_deploy_${svc}_${date}
    echo $result

	exit 0

else
	echo "Invalid lmtype" >> $origin_path/log/$svc/log_deploy_${svc}_${date}
    result='{"resultCode":"E0300","resultMsg":"Invalid lmtype","serviceCode":"'"$svc"'"}'
    echo $result >> $origin_path/log/$svc/log_deploy_${svc}_${date}
    echo $result

	exit 0
fi

#########################################################

##################################################################
if [ $lmtype == "CLASS" ];then
	$origin_path/model_deploy_class $class_real_dir $svc $lmtype $date
	
elif [ $lmtype == "SERVICE" ];then
#	/home/gosh2/smp/r-agent/deploy/model_deploy_service $rt/enc-out/classlms/new_class $svc $date
	echo "Deploying ServiceLM will support" >> $origin_path/log/$svc/log_deploy_${svc}_${date}
	result='{"resultCode":"E0300","resultMsg":"Deploying ServiceLM will support","serviceCode":"'"$svc"'","lmType":"'"$lmtype"'"}'
    echo $result >> $origin_path/log/$svc/log_deploy_${svc}_${date}
    echo $result
	
	echo "[-------------------------------]" >> $origin_path/log/$svc/log_deploy_${svc}_${date}
	echo "END :$(date +'%F-%H-%M-%S-%N')" >> $origin_path/log/$svc/log_deploy_${svc}_${date}

	exit 0
fi

exit 0
