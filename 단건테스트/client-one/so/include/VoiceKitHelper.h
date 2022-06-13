#ifndef __VOICEKIT_HELPER_H__
#define __VOICEKIT_HELPER_H__


/****************************************************************************************
 * INCLUDE
****************************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/epoll.h>
#include <unistd.h>

using namespace std;

#include <deque>

#include "VoiceKitBuffer.h"
#include "VoiceKitClient.h"
#include "VoiceKitDef.h"
#include "VoiceKitUtil.h"


/****************************************************************************************
 * STRUCT
****************************************************************************************/
typedef struct _ST_MSG_CALLBACK {
	int type;
	void *mVoiceKitHelper;
	ST_MSG_RGW recvData;
} ST_MSG_CALLBACK;


/****************************************************************************************
 * CLASS
****************************************************************************************/
class VoiceKitHelper {
public:
	VoiceKitHelper(void *instance, VoiceKitClientCallbackFunc interface);
	~VoiceKitHelper();

	int setData(const char *ip, int port, const char *svc, int txrx, const char *phoneType, const char *callkey, const char *devId);
	int start();
	void stop();
	int isSpeak();
	void putData(char *data, int size, int bLast);
	void callEnd();

	VoiceKitClientCallbackFunc interface;
	void *instance;
	VoiceKitBuffer *buffer;
	char ip[256];
	int port;
	int svc;
	int txrx;
	char phoneType[20];
	char callkey[64];
	char devId[44];
	int packet;
	int nSocket;
	pthread_t mThreadWrite;
	int	nTotalDataSize;
	int index;
	int isStop;
};


#endif /* __VOICEKIT_HELPER_H__ */
