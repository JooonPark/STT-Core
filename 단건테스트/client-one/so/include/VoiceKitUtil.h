#ifndef __VOICEKIT_UTIL_H__
#define __VOICEKIT_UTIL_H__


/****************************************************************************************
 * INCLUDE
****************************************************************************************/
#include <arpa/inet.h>
#include <errno.h>
#include <gcrypt.h>
#include <netinet/in.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/epoll.h>
#include <sys/socket.h>
#include <unistd.h>

#include "VoiceKitDef.h"


/****************************************************************************************
 * DEFINE
****************************************************************************************/
// #define ENC_MODE
#define MSG_SIZE (sizeof(ST_MSG_RGW))


/****************************************************************************************
 * TYPEDEF
****************************************************************************************/
#ifdef ENC_MODE
typedef unsigned char uchar;
#endif


/****************************************************************************************
 * FUNCTION
****************************************************************************************/
#ifdef ENC_MODE
void get_random(uchar *ptr, int len);
int encryptDataAes256(uchar *key, char *indata, int insize, char *outdata);
int decryptDataAes256(uchar *key, char *indata, int insize, char *outdata);
#endif
int openClient(int *sock, int epoll_fd, const char *ip, int port, void *ptr);
void closeClient(int *sock, int epoll_fd);
int readHeader(int *sock, int epoll_fd, void *data);
int readData(int *sock, int epoll_fd, void *data, int size);
int writeData(int *sock, int epoll_fd, void *data, int size);
int startThread(pthread_t *thread, void *(*start_routine)(void *), void *arg);
void stopThread(pthread_t *thread);
int	getAtoI(const char *src, int start, int length);
int certificationToSvcKey(const char *szCertification);


#endif /* __VOICEKIT_UTIL_H__ */