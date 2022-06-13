#ifndef __VOICEKIT_BUFFER_H__
#define __VOICEKIT_BUFFER_H__


/****************************************************************************************
 * DEFINE
****************************************************************************************/
#define MAX_QUEUE_SIZE 200


/****************************************************************************************
 * INCLUDE
****************************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>

#include "VoiceKitDef.h"


/****************************************************************************************
 * CLASS
****************************************************************************************/
class VoiceKitBuffer {
public:
	VoiceKitBuffer();
	~VoiceKitBuffer();

	int ready(int packet);
	void finish();
	int getLast();
	void setLast();
	void appendBuffer(char *data, int length, int bLast);
	int readBuffer(char *data, int size);
	int getReadPos();
	int isFull();
	int isEmpty();

private:
	pthread_mutex_t buffer_mutex;
	char *data;
	int front;
	int rear;
	int position;
	int packet;
	int readPos;
	int isLast;
};


#endif /* __VOICEKIT_BUFFER_H__ */