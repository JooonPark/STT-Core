#!/bin/bash
############################# parameter #############################
callbackurl=$1
corpus_filedir=$2
svc=$3
lmtype=$4

lmtooldir=/home/asr1/lm-tools-$svc								## 필요시 변경
origin_path=/home/asr1/smp/t-agent/train						## 필요시 변경
output_modelpath=/home/asr1/smp/t-agent/train/trainedModel/svc	## 필요시 변경

domaindir=`cat $lmtooldir/call.json | jq .domain_corpus |sed 's/\"//g'`
basedir1=`cat $lmtooldir/call.json | jq .modeldir |sed 's/\"//g'`
basedir2=`cat $lmtooldir/call.json | jq .version |sed 's/\"//g'`
basedir="${basedir1}_${basedir2}"

lndir=$lmtooldir/models/call/class
logdir=$origin_path/log
date=`echo "$(date +'%F-%H-%M-%S-%N')"`
##########################################################

if [ ! -d $origin_path/tmp ];then
   mkdir $origin_path/tmp
fi

if [ ! -d $logdir ];then
   mkdir $logdir
fi

if [ ! -d $logdir/$svc ];then
   mkdir $logdir/$svc
fi

if [ ! -d $lmtooldir/$domaindir ];then
	mkdir $lmtooldir/$domaindir
fi

##########################################################

############################# check learning #############################
ps -ef | grep build_asr_model | grep -v grep > $origin_path/tmp/lm-check
if [ ! -z `awk '{print $2}' $origin_path/tmp/lm-check` ];then
	learnsvc=`awk '{print $NF}' $origin_path/tmp/lm-check`
	echo "This Server is Already learning" > $logdir/$svc/log_learning_already_$svc
	curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E9000","resultMsg":"Already In Use(Training)","serviceCode":"'"$svc"'","lmtype":"'"$lmtype'""}'
	exit 0
fi

##########################################################
echo "" > $logdir/$svc/log_learning_${svc}_${date}
echo "START :$(date +'%F-%H-%M-%S-%N')" >> $logdir/$svc/log_learning_${svc}_${date}
echo "[-------------------------------]" >> $logdir/$svc/log_learning_${svc}_${date}
echo "[------Stage 1 - PARAMETER------]" >> $logdir/$svc/log_learning_${svc}_${date}
echo "SVC             : "$svc >> $logdir/$svc/log_learning_${svc}_${date}
echo "LM_type         : "$lmtype >> $logdir/$svc/log_learning_${svc}_${date}
echo "Corpus_filedir  : "$corpus_filedir >> $logdir/$svc/log_learning_${svc}_${date}
echo "CallbackUrl     : "$callbackurl >> $logdir/$svc/log_learning_${svc}_${date}
echo "[-------------------------------]" >> $logdir/$svc/log_learning_${svc}_${date}

############ learning ###############
echo "[------Stage 2 - Learning ------]" >> $logdir/$svc/log_learning_${svc}_${date}

cp -rf $corpus_filedir $lndir/class.txt 
echo "Copy $corpus_filedir to $lndir/class.txt" >> $logdir/$svc/log_learning_${svc}_${date}
cd $lmtooldir 

nohup ./build_asr_model call.json > $logdir/$svc/log_$svc & 
sleep 2

#result_foldername=`head -6 $logdir/$svc/log_$svc |tail -1 |cut -d'/' -f2- |awk -F '/' '{print $NF}' | sed 's/.$//g'`
str1=`head -9 $logdir/$svc/log_$svc |tail -1 |awk '{print $3}'|sed 's/-//g'|sed 's/://g'`
result_foldername=`echo ${str1:2}`

class_output_dir=$lmtooldir/$basedir/class-fst-dir/
###########  Class LM #############
if [ $lmtype == "CLASS" ];then

	while [ 1 ]
	do
	  	t2=`tail -1 $logdir/$svc/log_$svc`

	    if [[ "$t2" == *ABORT* ]];then
			t1=`tail -2 $logdir/$svc/log_$svc |head -1`
			if [[ "$t1" == *characters* ]];then
				echo "ERROR : invalid characters included" >> $logdir/$svc/log_learning_${svc}_${date}
				rm -rf $class_output_dir/$result_foldername $lmtooldir/$basedir/enc-out/classlms/$result_foldername
				curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E1000", "resultMsg":"'"$t1"'","serviceCode":"'"$svc"'","lmType":"'"$lmtype"'"}'
				echo "Callback Success" >> $logdir/$svc/log_learning_${svc}_${date}
				echo "[-------------------------------]" >> $logdir/$svc/log_learning_${svc}_${date}
				echo "END :$(date +'%F-%H-%M-%S-%N')" >> $logdir/$svc/log_learning_${svc}_${date}
				break
		   
			elif [[ "$t1" == *prepare_dict* ]];then
				echo "ERROR : Prepare_dich.sh Error!" >> $logdir/$svc/log_learning_${svc}_${date}
				rm -rf $class_output_dir/$result_foldername $lmtooldir/$basedir/enc-out/classlms/$result_foldername
				curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E6000", "resultMsg":"'"$t1"'","serviceCode":"'"$svc"'","lmType":"'"$lmtype"'"}'
				echo "Callback Success" >> $logdir/$svc/log_learning_${svc}_${date}
				echo "[-------------------------------]" >> $logdir/$svc/log_learning_${svc}_${date}
				echo "END :$(date +'%F-%H-$M-$S')" >> $logdir/$svc/log_learning_${svc}_${date}
				break

			elif [[ "$t1" == *mt_koma* ]];then
				echo "ERROR : mt_koma Error!" >> $logdir/$svc/log_learning_${svc}_${date}
				rm -rf $class_output_dir/$result_foldername $lmtooldir/$basedir/enc-out/classlms/$result_foldername
				curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E2000", "resultMsg":"'"$t1"'","serviceCode":"'"$svc"'","lmType":"'"$lmtype"'"}'
				echo "Callback Success" >> $logdir/$svc/log_learning_${svc}_${date}
				echo "[-------------------------------]" >> $logdir/$svc/log_learning_${svc}_${date}
				echo "END :$(date +'%F-%H-%M-%S-%N')" >> $logdir/$svc/log_learning_${svc}_${date}
				break

			elif [[ "$t1" == *big-lm-creator* ]];then
				echo "ERROR : big-lm-creator Error!" >> $logdir/$svc/log_learning_${svc}_${date}
				rm -rf $class_output_dir/$result_foldername $lmtooldir/$basedir/enc-out/classlms/$result_foldername
				curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E4000", "resultMsg":"'"$t1"'","serviceCode":"'"$svc"'","lmType":"'"$lmtype"'"}'
				echo "Callback Success" >> $logdir/$svc/log_learning_${svc}_${date}
				echo "[-------------------------------]" >> $logdir/$svc/log_learning_${svc}_${date}
				echo "END :$(date +'%F-%H-%M-%S-%N')" >> $logdir/$svc/log_learning_${svc}_${date}
				break
	   
			elif [[ "$t1" == *mkgraph* ]];then
				echo "ERROR : mkgraph Error!" >> $logdir/$svc/log_learning_${svc}_${date}
				rm -rf $class_output_dir/$result_foldername $lmtooldir/$basedir/enc-out/classlms/$result_foldername
				curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E6000", "resultMsg":"'"$t1"'","serviceCode":"'"$svc"'","lmType":"'"$lmtype"'"}'
				echo "Callback Success" >> $logdir/$svc/log_learning_${svc}_${date}
				echo "[-------------------------------]" >> $logdir/$svc/log_learning_${svc}_${date}
				echo "END :$(date +'%F-%H-%M-%S-%N')" >> $logdir/$svc/log_learning_${svc}_${date}
				break
	   
			elif [[ "$t1" == *prepare_lm* ]];then
				echo "ERROR : prepare_lm.sh Error!" >> $logdir/$svc/log_learning_${svc}_${date}
				rm -rf $class_output_dir/$result_foldername $lmtooldir/$basedir/enc-out/classlms/$result_foldername
				curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E6000", "resultMsg":"'"$t1"'","serviceCode":"'"$svc"'","lmType":"'"$lmtype"'"}' 
				echo "Callback Success" >> $logdir/$svc/log_learning_${svc}_${date}
				echo "[-------------------------------]" >> $logdir/$svc/log_learning_${svc}_${date}
				echo "END :$(date +'%F-%H-%M-%S-%N')" >> $logdir/$svc/log_learning_${svc}_${date}
				break

			else
				echo "ERROR : Unkown Server Error!" >> $logdir/$svc/log_learning_${svc}_${date}
				curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E9999", "resultMsg":"Unknown Server Error","serviceCode":"'"$svc"'","lmType":"'"$lmtype"'"}'
				echo "Callback Success" >> $logdir/$svc/log_learning_${svc}_${date}
				echo "[-------------------------------]" >> $logdir/$svc/log_learning_${svc}_${date}
				echo "END :$(date +'%F-%H-%M-%S-%N')" >> $logdir/$svc/log_learning_${svc}_${date}
				rm -rf $class_output_dir/$result_foldername $lmtooldir/$basedir/enc-out/classlms/$result_foldername
				break
			fi
		elif  [[ "$t2" == *end* ]];then
	        sleep 5

		    cd $lmtooldir/$basedir/enc-out/classlms
			model_time=`echo "$(date +'%y%m%d%H%M%S')"`
			echo $result_foldername $model_time
			
			mv $result_foldername $model_time
			tar -zcf model_$svc.tar.gz $model_time
	        mv model_$svc.tar.gz $output_modelpath/$svc/
			chmod 777 $output_modelpath/$svc/model_$svc.tar.gz

			rm -rf $class_output_dir/$result_foldername $lmtooldir/$basedir/enc-out/classlms/$model_time $lmtooldir/$basedir/class-text-dir/$result_foldername
		    echo "Complete & Success" >> $logdir/$svc/log_learning_${svc}_${date}
			echo "MODEL_PATH : $output_modelpath/$svc/model_$svc.tar.gz" >> $logdir/$svc/log_learning_${svc}_${date}
			curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"C1000","resultMsg":"Success","serviceCode":"'"$svc"'","modelPath":"'"$origin_path/trainedModel/svc/$svc/model_$svc.tar.gz"'","lmType":"'"$lmtype"'"}'
			echo "[-------------------------------]" >> $logdir/$svc/log_learning_${svc}_${date}
			echo "END :$(date +'%F-%H-%M-%S-%N')" >> $logdir/$svc/log_learning_${svc}_${date}
	        break

		fi
	done
fi

exit 0
