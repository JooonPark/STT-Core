#!/bin/bash
############################# parameter #############################
callbackurl=$1
svc=$2
lmtype=$3
date=$4
lmtooldir=$5
origin_path=$6

output_modelpath=$origin_path/trainedModel/svc					## 필요시 변경

domaindir=`cat $lmtooldir/call.json | jq .domain_corpus |sed 's/\"//g'`
basedir1=`cat $lmtooldir/call.json | jq .modeldir |sed 's/\"//g'`
basedir2=`cat $lmtooldir/call.json | jq .version |sed 's/\"//g'`
basedir="${basedir1}_${basedir2}"

logdir=$origin_path/log

#####################################################

cd $lmtooldir 

nohup ./build_asr_model call.json > $logdir/$svc/log_$svc & 
sleep 2

result_foldername=`head -6 $logdir/$svc/log_$svc |tail -1 |cut -d'/' -f2- |awk -F '/' '{print $NF}' | sed 's/.$//g'`
#str1=`head -6 $logdir/$svc/log_$svc |tail -1 |awk '{print $3}'|sed 's/-//g'|sed 's/://g'`
#echo $str1 >> $logdir/$svc/log_learning_${svc}_${date}
#result_foldername=`echo ${str1:2}`
echo $result_foldername >> $logdir/$svc/log_learning_${svc}_${date}

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
				rm -rf $corpus_filedir
				echo "[-------------------------------]" >> $logdir/$svc/log_learning_${svc}_${date}
				echo "END :$(date +'%F-%H-%M-%S-%N')" >> $logdir/$svc/log_learning_${svc}_${date}
				break

		fi
	done
fi

exit 0
