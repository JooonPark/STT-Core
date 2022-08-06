#!/bin/bash
############################# parameter #############################
callbackurl=$1
corpus_filedir=$2
svc=$3
lmtype=$4

lmtooldir=/home/asr1/lm-tools-newtest                   ## 필요시 변경
origin_path=/home/asr1/smp/t-agent/train                ## 필요시 변경
output_modelpath=$origin_path/trainedModel/svc

domaindir=`cat $lmtooldir/call.json | jq .domain_corpus |sed 's/\"//g'`
basedir1=`cat $lmtooldir/call.json | jq .modeldir |sed 's/\"//g'`
basedir2=`cat $lmtooldir/call.json | jq .version |sed 's/\"//g'`
basedir="${basedir1}_${basedir2}"

classdir=$lmtooldir/models/call/class
servicedir=$lmtooldir/corpus

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
    curl $callbackurl -H "Content-Type: application/json" -d '{"resultCode":"E9000","resultMsg":"Already In Use(Training)","serviceCode":"'"$svc"'","lmtype":"'"$lmtype"'"}'
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

cd $lmtooldir

if [[ "$lmtype" == "SERVICE" ]];then
    cp -rf $corpus_filedir $domaindir/
    echo "Copy $corpus_filedir to $domaindir" >> $logdir/$svc/log_learning_${svc}_${date}

    mkbase=`cat $lmtooldir/call.json | jq .mk_base |sed 's/\"//g'`

    sed -i 's@'"$mkbase"'@'"True"'@' $lmtooldir/call.json

    $origin_path/train-slm.sh $callbackurl $svc $lmtype $date $lmtooldir $origin_path 

else
    cp -rf $corpus_filedir $classdir/class.txt
    echo "Copy $corpus_filedir to $classdir/class.txt" >> $logdir/$svc/log_learning_${svc}_${date}

    mkbase=`cat $lmtooldir/call.json | jq .mk_base |sed 's/\"//g'`
    sed -i 's@'"$mkbase"'@'"False"'@' $lmtooldir/call.json

    $origin_path/train-clm.sh $callbackurl $svc $lmtype $date $lmtooldir $origin_path

fi

rm -rf $domaindir/* $corpus_filedir $classdir/*

exit 0 



