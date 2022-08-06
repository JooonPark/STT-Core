#!/bin/bash
############################# parameter #############################
callbackurl=$1
svc=$2
lmtype=$3
date=$4
lmtooldir=$5
origin_path=$6

output_modelpath=$origin_path/trainedModel/svc

domaindir=`cat $lmtooldir/call.json | jq .domain_corpus |sed 's/\"//g'`
basedir1=`cat $lmtooldir/call.json | jq .modeldir |sed 's/\"//g'`
basedir2=`cat $lmtooldir/call.json | jq .version |sed 's/\"//g'`
basedir="${basedir1}_${basedir2}"

lndir=$lmtooldir/models/call
logdir=$origin_path/log

##########################################################

cd $lmtooldir 

nohup ./build_asr_model call.json > $logdir/$svc/log_$svc & 
sleep 2

tail $logdir/$svc/log_$svc -n0 -F | while read line;
do
    abcde=`ps -ef |grep "tail $logdir/$svc/log_$svc"|grep -v grep |awk '{print $2}'`
    if [[ "$line" =~ 'ABORT' ]];then
        t1=`tail -2 $logdir/$svc/log_$svc |head -1`
        if [[ "$t1" == *characters* ]];then
            echo "ERROR : invalid characters included" >> $logdir/$svc/log_learning_${svc}_${date}
            rm -rf $class_output_dir/$result_foldername $lmtooldir/$basedir/enc-out/classlms/$result_foldername
            curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E1000", "resultMsg":"'"$t1"'","serviceCode":"'"$svc"'","lmType":"'"$lmtype"'"}'
            echo "Callback Success" >> $logdir/$svc/log_learning_${svc}_${date}
            echo "[-------------------------------]" >> $logdir/$svc/log_learning_${svc}_${date}
            echo "END :$(date +'%F-%H-%M-%S-%N')" >> $logdir/$svc/log_learning_${svc}_${date}
            kill -9 $abcde
            break
       
        elif [[ "$t1" == *prepare_dict* ]];then
            echo "ERROR : Prepare_dich.sh Error!" >> $logdir/$svc/log_learning_${svc}_${date}
            rm -rf $class_output_dir/$result_foldername $lmtooldir/$basedir/enc-out/classlms/$result_foldername
            curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E6000", "resultMsg":"'"$t1"'","serviceCode":"'"$svc"'","lmType":"'"$lmtype"'"}'
            echo "Callback Success" >> $logdir/$svc/log_learning_${svc}_${date}
            echo "[-------------------------------]" >> $logdir/$svc/log_learning_${svc}_${date}
            echo "END :$(date +'%F-%H-$M-$S')" >> $logdir/$svc/log_learning_${svc}_${date}
            kill -9 $abcde
            break

        elif [[ "$t1" == *mt_koma* ]];then
            echo "ERROR : mt_koma Error!" >> $logdir/$svc/log_learning_${svc}_${date}
            rm -rf $class_output_dir/$result_foldername $lmtooldir/$basedir/enc-out/classlms/$result_foldername
            curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E2000", "resultMsg":"'"$t1"'","serviceCode":"'"$svc"'","lmType":"'"$lmtype"'"}'
            echo "Callback Success" >> $logdir/$svc/log_learning_${svc}_${date}
            echo "[-------------------------------]" >> $logdir/$svc/log_learning_${svc}_${date}
            echo "END :$(date +'%F-%H-%M-%S-%N')" >> $logdir/$svc/log_learning_${svc}_${date}
            kill -9 $abcde
            break

        elif [[ "$t1" == *big-lm-creator* ]];then
            echo "ERROR : big-lm-creator Error!" >> $logdir/$svc/log_learning_${svc}_${date}
            rm -rf $class_output_dir/$result_foldername $lmtooldir/$basedir/enc-out/classlms/$result_foldername
            curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E4000", "resultMsg":"'"$t1"'","serviceCode":"'"$svc"'","lmType":"'"$lmtype"'"}'
            echo "Callback Success" >> $logdir/$svc/log_learning_${svc}_${date}
            echo "[-------------------------------]" >> $logdir/$svc/log_learning_${svc}_${date}
            echo "END :$(date +'%F-%H-%M-%S-%N')" >> $logdir/$svc/log_learning_${svc}_${date}
            kill -9 $abcde
            break
   
        elif [[ "$t1" == *mkgraph* ]];then
            echo "ERROR : mkgraph Error!" >> $logdir/$svc/log_learning_${svc}_${date}
            rm -rf $class_output_dir/$result_foldername $lmtooldir/$basedir/enc-out/classlms/$result_foldername
            curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E6000", "resultMsg":"'"$t1"'","serviceCode":"'"$svc"'","lmType":"'"$lmtype"'"}'
            echo "Callback Success" >> $logdir/$svc/log_learning_${svc}_${date}
            echo "[-------------------------------]" >> $logdir/$svc/log_learning_${svc}_${date}
            echo "END :$(date +'%F-%H-%M-%S-%N')" >> $logdir/$svc/log_learning_${svc}_${date}
            kill -9 $abcde
            break
   
        elif [[ "$t1" == *prepare_lm* ]];then
            echo "ERROR : prepare_lm.sh Error!" >> $logdir/$svc/log_learning_${svc}_${date}
            rm -rf $class_output_dir/$result_foldername $lmtooldir/$basedir/enc-out/classlms/$result_foldername
            curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E6000", "resultMsg":"'"$t1"'","serviceCode":"'"$svc"'","lmType":"'"$lmtype"'"}' 
            echo "Callback Success" >> $logdir/$svc/log_learning_${svc}_${date}
            echo "[-------------------------------]" >> $logdir/$svc/log_learning_${svc}_${date}
            echo "END :$(date +'%F-%H-%M-%S-%N')" >> $logdir/$svc/log_learning_${svc}_${date}
            kill -9 $abcde
            break

        else
            echo "ERROR : Unkown Server Error!" >> $logdir/$svc/log_learning_${svc}_${date}
            curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E9999", "resultMsg":"Unknown Server Error","serviceCode":"'"$svc"'","lmType":"'"$lmtype"'"}'
            echo "Callback Success" >> $logdir/$svc/log_learning_${svc}_${date}
            echo "[-------------------------------]" >> $logdir/$svc/log_learning_${svc}_${date}
            echo "END :$(date +'%F-%H-%M-%S-%N')" >> $logdir/$svc/log_learning_${svc}_${date}
            rm -rf $class_output_dir/$result_foldername $lmtooldir/$basedir/enc-out/classlms/$result_foldername
            kill -9 $abcde
            break
        fi
    elif  [[ "$line" == *end* ]];then
            sleep 5

            cd $lmtooldir/$basedir
            cp $lndir/decode.conf enc-out
            tar -zcf model_${svc}.tar.gz enc-out
            mv model_${svc}.tar.gz $output_modelpath/$svc/
            chmod 777 $output_modelpath/$svc/model_$svc.tar.gz

            echo "Complete & Success" >> $logdir/$svc/log_learning_${svc}_${date}
            echo "MODEL_PATH : $output_modelpath/$svc/model_$svc.tar.gz" >> $logdir/$svc/log_learning_${svc}_${date}
            curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"C1000","resultMsg":"Success","serviceCode":"'"$svc"'","modelPath":"'"$origin_path/trainedModel/svc/$svc/model_$svc.tar.gz"'","lmType":"'"$lmtype"'"}'
            echo "[-------------------------------]" >> $logdir/$svc/log_learning_${svc}_${date}
            echo "END :$(date +'%F-%H-%M-%S-%N')" >> $logdir/$svc/log_learning_${svc}_${date}
            kill -9 $abcde
            break

    fi

done;

exit 0
