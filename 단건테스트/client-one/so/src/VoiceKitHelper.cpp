/****************************************************************************************
 * INCLUDE
****************************************************************************************/
#include "VoiceKitHelper.h"


/****************************************************************************************
 * DEFINE
****************************************************************************************/
#define CLIENT_MAX 1024
#define THREAD_MAX 50


/****************************************************************************************
 * VARIABLE
****************************************************************************************/
int epoll_fd = 0;
struct epoll_event *epoll_events = (struct epoll_event *)malloc(sizeof(epoll_event) * CLIENT_MAX);
pthread_mutex_t mThreadMsgMutex;
deque<ST_MSG_CALLBACK *> dequeMsg[THREAD_MAX];
int indexQueue = 0;
int isMsgInit = false;
int isMsgIndex[THREAD_MAX];
pthread_t mThreadMsg[THREAD_MAX];
pthread_t mThreadHelp = 0;


/****************************************************************************************
 * FUNCTION
****************************************************************************************/
void *threadWrite(void *value);
void msgPush(int index, ST_MSG_CALLBACK *value);
ST_MSG_CALLBACK *msgPop(int index);
void *threadMsg(void *value);
void *threadHelper(void *value);

VoiceKitHelper::VoiceKitHelper(void *instance, VoiceKitClientCallbackFunc interface) {
	this->instance = instance;
	this->interface = interface;

	this->buffer = new VoiceKitBuffer();

	if(isMsgInit == false) {
		isMsgInit = true;
		for(int i = 0; i < THREAD_MAX; ++i) {
			isMsgIndex[i] = i;
			startThread(&mThreadMsg[i], threadMsg, (void *)&isMsgIndex[i]);
		}

		startThread(&mThreadHelp, threadHelper, 0);
		usleep(100000);
	}

	memset(this->ip, 0, 256);
	this->port = 0;
	this->svc = -1;
	this->txrx = 2;
	memset(this->phoneType, 0, 20);
	memset(this->callkey, 0, 64);
	memset(this->devId, 0, 44);
	this->packet = 700;
	this->nSocket = 0;
	this->mThreadWrite = 0;
	this->nTotalDataSize = 0;
	this->index = indexQueue = (indexQueue + 1) % THREAD_MAX;
	this->isStop = true;
}

VoiceKitHelper::~VoiceKitHelper() {
	stopThread(&this->mThreadWrite);

	if(this->buffer != NULL) {
		delete this->buffer;
		this->buffer = NULL;
	}
}

int VoiceKitHelper::setData(const char *ip, int port, const char *svc, int txrx, const char *phoneType, const char *callkey, const char *devId) {
	if(ip != NULL) {
		memcpy(this->ip, ip, strlen(ip));
	}

	this->port = port;
	
    // delete SVC HASH code
    //this->svc = certificationToSvcKey(svc);
	
    this->svc = atoi(svc);
	this->txrx = txrx;
	if(phoneType != NULL) {
		memcpy(this->phoneType, phoneType, strlen(phoneType));
	}
	if(callkey != NULL) {
		memcpy(this->callkey, callkey, strlen(callkey));
	}
	if(devId != NULL) {
		memcpy(this->devId, devId, strlen(devId));
	}
	this->packet = 700;

	return true;
}

int VoiceKitHelper::start() {
	this->isStop = false;

	if(this->svc == -1) {
		ST_MSG_CALLBACK sendData;

		memset(&sendData, 0, sizeof(ST_MSG_CALLBACK));

		sendData.type = RESULT_VOICEKIT_SERVICEKEY_ERROR;
		sendData.mVoiceKitHelper = this;

		msgPush(this->index, &sendData);

		return false;
	}

	if(openClient(&this->nSocket, epoll_fd, this->ip, this->port, (void *)this) == false) {
		ST_MSG_CALLBACK sendData;

		memset(&sendData, 0, sizeof(ST_MSG_CALLBACK));

		sendData.type = RESULT_VOICEKIT_CONNECT_ERROR;
		sendData.mVoiceKitHelper = this;

		msgPush(this->index, &sendData);

		return false;
	} else {
		ST_MSG_RGW msg;

		memset(&msg, 0, sizeof(ST_MSG_RGW));

		msg.stHead.cFrame[0] = 0xFE;
		msg.stHead.cFrame[1] = 0xFE;
		msg.stHead.usLength = sizeof(_MSG_HEAD) + sizeof(ST_MSG_RGW_REQ_START);
		msg.stHead.unMsg = MSG_RGW_REQ_START;

		msg.stD.stReqStart.nResultCode = RESULT_VOICEKIT_SUCCESS;
		msg.stD.stReqStart.nServiceCode = this->svc;
		msg.stD.stReqStart.nTxRxType = this->txrx;
		sprintf(msg.stD.stReqStart.cPhoneType, "%s", this->phoneType);
		sprintf(msg.stD.stReqStart.cCallKey, "%s", this->callkey);
		sprintf(msg.stD.stReqStart.cDeviceID, "%s", this->devId);

		writeData(&this->nSocket, epoll_fd, (void *)&msg, msg.stHead.usLength);
	}

	return true;
}

void VoiceKitHelper::stop() {
	ST_MSG_CALLBACK sendData;

	memset(&sendData, 0, sizeof(ST_MSG_CALLBACK));

	sendData.type = RESULT_VOICEKIT_STOP;
	sendData.mVoiceKitHelper = this;

	msgPush(this->index, &sendData);
}

int VoiceKitHelper::isSpeak() {
	return (this->nSocket != 0) ? true : false;
}

void VoiceKitHelper::putData(char *data, int size, int bLast) {
	if(this->isSpeak() == true && this->buffer != NULL) {
		this->buffer->appendBuffer(data, size, bLast);
	}
}

void VoiceKitHelper::callEnd() {
	ST_MSG_RGW sendData;

	memset(&sendData, 0, sizeof(ST_MSG_RGW));

	sendData.stHead.cFrame[0] = 0xFE;
	sendData.stHead.cFrame[1] = 0xFE;
	sendData.stHead.usLength = sizeof(_MSG_HEAD) + sizeof(ST_MSG_RGW_REQ_END);
	sendData.stHead.unMsg = MSG_RGW_REQ_END;

	sendData.stD.stReqEnd.nResultCode = RESULT_VOICEKIT_SUCCESS;

	writeData(&this->nSocket, epoll_fd, (void *)&sendData, sendData.stHead.usLength);
}

void *threadWrite(void *value) {
	VoiceKitHelper *data = (VoiceKitHelper *)value;

	ST_MSG_RGW sendData;
	int packet = data->packet;
	char sendByte[packet];

	while(data->isSpeak() == true) {
		usleep(10000);
		memset(sendByte, 0, packet);
		int nLast = data->buffer->getLast();
		int size = data->buffer->readBuffer(sendByte, packet);

		if(size > 0 || nLast == 1) {
			memset(&sendData, 0, sizeof(ST_MSG_RGW));

			sendData.stHead.cFrame[0] = 0xFE;
			sendData.stHead.cFrame[1] = 0xFE;
			sendData.stHead.usLength = sizeof(_MSG_HEAD) + sizeof(ST_MSG_RGW_REQ_MEDIA) - 8000 + size;
			sendData.stHead.unMsg = MSG_RGW_REQ_MEDIA;

			sendData.stD.stReqMedia.nIndex = data->buffer->getReadPos();
			sendData.stD.stReqMedia.nLast = nLast;
			sendData.stD.stReqMedia.nPacketSize = size;
			memcpy(sendData.stD.stReqMedia.cData, sendByte, size);

			writeData(&data->nSocket, epoll_fd, (void *)&sendData, sendData.stHead.usLength);

			if(nLast == 1) {
				LogR("[SND] Last packet : size(%d)\n", size);

				if(data->buffer != NULL) {
					data->buffer->finish();
				}

				data->mThreadWrite = 0;
				data->callEnd();

				return 0;
			}
		}
	}

	if(data->buffer != NULL) {
		data->buffer->finish();
	}

	data->mThreadWrite = 0;

	return 0;
}

void msgPush(int index, ST_MSG_CALLBACK *value) {
	ST_MSG_CALLBACK *pushData = new ST_MSG_CALLBACK;

	memset(pushData, 0, sizeof(ST_MSG_CALLBACK));
	memcpy(pushData, value, sizeof(ST_MSG_CALLBACK));

	pthread_mutex_lock(&mThreadMsgMutex);
	dequeMsg[index].push_back(pushData);
	pthread_mutex_unlock(&mThreadMsgMutex);
}

ST_MSG_CALLBACK *msgPop(int index) {
	ST_MSG_CALLBACK *popData = NULL;

	pthread_mutex_lock(&mThreadMsgMutex);
	if(dequeMsg[index].size() > 0) {
		popData = dequeMsg[index].front();
		dequeMsg[index].pop_front();
	}
	pthread_mutex_unlock(&mThreadMsgMutex);

	return popData;
}

void *threadMsg(void *value) {
	pthread_mutex_init(&mThreadMsgMutex, NULL);
	int index = *(int *) value;

	ST_MSG_CALLBACK *msg = NULL;
	int type = 0;
	VoiceKitHelper *mVoiceKitHelper = NULL;
	ST_MSG_RGW *recvData = NULL;
	int nMsgType = 0;
	ST_MSG_VOICEKIT sendData;

	while(1) {
		usleep(100000);

		msg = msgPop(index);

		if(msg) {
			type = msg->type;
			mVoiceKitHelper = (VoiceKitHelper *)msg->mVoiceKitHelper;
			recvData = &msg->recvData;
			memset(&sendData, 0, sizeof(ST_MSG_VOICEKIT));

			switch (type) {
				case RESULT_VOICEKIT_SUCCESS: {
					nMsgType = recvData->stHead.unMsg;

					switch (nMsgType) {
						case MSG_RGW_RSP_START: {
							if(recvData->stD.stRspStart.nResultCode != 0) {
								sendData.type = MSG_VOICEKIT_STOP;
								sendData.stStop.nResultCode = RESULT_VOICEKIT_UNKOWN_ERROR;
								if(mVoiceKitHelper->isStop == false) {
									mVoiceKitHelper->isStop = true;
									mVoiceKitHelper->interface(mVoiceKitHelper->instance, &sendData);
								}
							} else {
								mVoiceKitHelper->packet = recvData->stD.stRspStart.nPacketSize;
								mVoiceKitHelper->buffer->ready(mVoiceKitHelper->packet);

								if(startThread(&mVoiceKitHelper->mThreadWrite, threadWrite, mVoiceKitHelper) == false) {
									mVoiceKitHelper->buffer->setLast();
									mVoiceKitHelper->callEnd();
									closeClient(&mVoiceKitHelper->nSocket, epoll_fd);
									sendData.type = MSG_VOICEKIT_STOP;
									sendData.stStop.nResultCode = RESULT_VOICEKIT_UNKOWN_ERROR;
									if(mVoiceKitHelper->isStop == false) {
										mVoiceKitHelper->isStop = true;
										mVoiceKitHelper->interface(mVoiceKitHelper->instance, &sendData);
									}
								} else {
									sendData.type = MSG_VOICEKIT_START;
									sendData.stStop.nResultCode = RESULT_VOICEKIT_SUCCESS;
									mVoiceKitHelper->interface(mVoiceKitHelper->instance, &sendData);
								}
							}
							break;
						}
						case MSG_RGW_RPT_STT_START: {
							sendData.type = MSG_VOICEKIT_STT_START;
							sendData.stSttStart.nResultCode = recvData->stD.stRptSttStart.nResultCode;
							sendData.stSttStart.nPos = recvData->stD.stRptSttStart.nPos;
							sendData.stSttStart.nIdx = recvData->stD.stRptSttStart.nIdx;
							mVoiceKitHelper->interface(mVoiceKitHelper->instance, &sendData);
							break;
						}
						case MSG_RGW_RPT_PARTIAL: {
							if(recvData->stD.stRptPartial.nResultCode == 0) {
								sendData.type = MSG_VOICEKIT_PARTIAL;
								sendData.stPartial.nResultCode = recvData->stD.stRptPartial.nResultCode;
								sendData.stPartial.nResultSize = recvData->stD.stRptPartial.nResultSize;
								sendData.stPartial.nIdx = recvData->stD.stRptPartial.nIdx;
								memcpy(sendData.stPartial.cResult, recvData->stD.stRptPartial.cResult, sendData.stPartial.nResultSize);
								// if(mVoiceKitHelper->isStop == false) {
									mVoiceKitHelper->interface(mVoiceKitHelper->instance, &sendData);
								// }
							}
							break;
						}

						case MSG_RGW_RPT_RESULT: {
							if(recvData->stD.stRptResult.nResultCode == 0) {
								sendData.type = MSG_VOICEKIT_RESULT;
								sendData.stResult.nResultCode = recvData->stD.stRptResult.nResultCode;
								sendData.stResult.nTxRxType = recvData->stD.stRptResult.nTxRxType;
								sendData.stResult.fStartTime = recvData->stD.stRptResult.fStartTime;
								sendData.stResult.fEndTime = recvData->stD.stRptResult.fEndTime;
								sendData.stResult.bLast = recvData->stD.stRptResult.bLast;
								sendData.stResult.nResultSize = recvData->stD.stRptResult.nResultSize;
								sendData.stResult.nIdx = recvData->stD.stRptResult.nIdx;
								memcpy(sendData.stResult.cResult, recvData->stD.stRptResult.cResult, sendData.stResult.nResultSize);
								sendData.stResult.nResultSize = strlen(sendData.stResult.cResult);
								sendData.stResult.nDataSize = (sendData.stResult.fEndTime - sendData.stResult.fStartTime) * (mVoiceKitHelper->packet * 10);
								mVoiceKitHelper->nTotalDataSize += sendData.stResult.nDataSize;
								sendData.stResult.nTotalDataSize = mVoiceKitHelper->nTotalDataSize;
								// if(mVoiceKitHelper->isStop == false) {
									mVoiceKitHelper->interface(mVoiceKitHelper->instance, &sendData);
								// }
							}
							break;
						}
						case MSG_RGW_RSP_END: {
							mVoiceKitHelper->buffer->setLast();
							closeClient(&mVoiceKitHelper->nSocket, epoll_fd);
							sendData.type = MSG_VOICEKIT_STOP;
							sendData.stStop.nResultCode = RESULT_VOICEKIT_SVCEND;
							if(mVoiceKitHelper->isStop == false) {
								mVoiceKitHelper->isStop = true;
								mVoiceKitHelper->interface(mVoiceKitHelper->instance, &sendData);
							}
							break;
						}
						default: {
							LogE("Othre MSG : nMsgType(%d)\n", nMsgType);
							break;
						}
					}
					break;
				}
				case RESULT_VOICEKIT_NO_DATA: {
					break;
				}
				case RESULT_VOICEKIT_SERVICEKEY_ERROR:
				case RESULT_VOICEKIT_CONNECT_ERROR:
				case RESULT_VOICEKIT_DISCONNECTED: {
					sendData.type = MSG_VOICEKIT_STOP;
					sendData.stStop.nResultCode = type;
					if(mVoiceKitHelper->isStop == false) {
						mVoiceKitHelper->isStop = true;
						mVoiceKitHelper->interface(mVoiceKitHelper->instance, &sendData);
					}
					break;
				}
				default: {
					mVoiceKitHelper->buffer->setLast();
					mVoiceKitHelper->callEnd();
					closeClient(&mVoiceKitHelper->nSocket, epoll_fd);
					sendData.type = MSG_VOICEKIT_STOP;
					sendData.stStop.nResultCode = type;
					if(mVoiceKitHelper->isStop == false) {
						mVoiceKitHelper->isStop = true;
						mVoiceKitHelper->interface(mVoiceKitHelper->instance, &sendData);
					}
					break;
				}
			}

			delete msg;
		}
	}

	pthread_mutex_destroy(&mThreadMsgMutex);

	return 0;
}

void *threadHelper(void *value) {
	int event_cnt = 0;
	int *nSocket = 0;
	int nHeaderSize = sizeof(_MSG_HEAD);
	int nBodySize = 0;
	ST_MSG_CALLBACK sendData;
	int i = 0;
	int nIndex = 0;

	while((epoll_fd = epoll_create(CLIENT_MAX)) == -1) {
		usleep(3000000);
		LogR("[HLP] EPOLL CREATE ERROR RETRY\n");
	}

	while(1) {
		usleep(10000);

		event_cnt = epoll_wait(epoll_fd, epoll_events, CLIENT_MAX, 10);
		if(event_cnt < 0) {
			LogR("[HLP] epoll_wait ERROR : event_cnt(%d)\n", event_cnt);
		} else if(event_cnt == 0) {
			continue;
		} else {
			for(i = 0; i < event_cnt; ++i) {
				memset(&sendData, 0, sizeof(ST_MSG_CALLBACK));

				sendData.mVoiceKitHelper = epoll_events[i].data.ptr;
				nSocket = &((VoiceKitHelper *)sendData.mVoiceKitHelper)->nSocket;
				nIndex = ((VoiceKitHelper *)sendData.mVoiceKitHelper)->index;

				if(readHeader(nSocket, epoll_fd, (void *)&sendData.recvData.stHead) == true) {
					nBodySize = sendData.recvData.stHead.usLength - nHeaderSize;

					if(readData(nSocket, epoll_fd, (void *)&sendData.recvData.stD, nBodySize) >= 0) {
						sendData.type = RESULT_VOICEKIT_SUCCESS;
					} else {
						((VoiceKitHelper *)sendData.mVoiceKitHelper)->buffer->setLast();
						sendData.type = RESULT_VOICEKIT_DISCONNECTED;
					}
				} else {
					((VoiceKitHelper *)sendData.mVoiceKitHelper)->buffer->setLast();
					sendData.type = RESULT_VOICEKIT_DISCONNECTED;
				}

				msgPush(nIndex, &sendData);
			}
		}
	}

	return 0;
}
