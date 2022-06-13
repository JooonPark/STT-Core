#ifndef __VOICEKIT_DEF_H__1
#define __VOICEKIT_DEF_H__1

// #define _VOICEKIT_DEBUG

#ifdef _VOICEKIT_DEBUG

#include <stdio.h>
#include <time.h>

inline char* timeToString() {
	static char s[20];
	struct tm *t;
	time_t timer;

	timer = time(NULL);
	t = localtime(&timer);

	sprintf(s, "%04d-%02d-%02d %02d:%02d:%02d", t->tm_year + 1900, t->tm_mon + 1, t->tm_mday, t->tm_hour, t->tm_min, t->tm_sec);

	return s;
}

	#define LogC(fmt, ...) printf("\x1b[1m[%s] "fmt"\x1b[0m", timeToString(), ## __VA_ARGS__)
	#define LogE(fmt, ...) printf("\x1b[1m\x1b[31m[%s][%s : %d] "fmt"\x1b[0m", timeToString(), __func__, __LINE__, ## __VA_ARGS__)
	#define LogG(fmt, ...) printf("\x1b[1m\x1b[32m[%s] "fmt"\x1b[0m", timeToString(), ## __VA_ARGS__)
	#define LogR(fmt, ...) printf("\x1b[1m\x1b[31m[%s] "fmt"\x1b[0m", timeToString(), ## __VA_ARGS__)
#else
	#define LogC(fmt, ...)
	#define LogE(fmt, ...)
	#define LogG(fmt, ...)
	#define LogR(fmt, ...)
#endif


/****************************************************************************************
 * ENUM
 ****************************************************************************************/
enum _enMsgRgwType {
	MSG_RGW_REQ_START = 1000,
	MSG_RGW_RSP_START,
	MSG_RGW_REQ_MEDIA = 2000,
	MSG_RGW_RPT_RESULT,
	MSG_RGW_RPT_PARTIAL,
	MSG_RGW_RPT_STT_START,
	MSG_RGW_REQ_END = 3000,
	MSG_RGW_RSP_END,
	MSG_RGW_RSP_ERROR = 9999
};


/****************************************************************************************
 * STRUCT
 ****************************************************************************************/
typedef struct TagMsgHeader {
	char cFrame[2];
	unsigned short usLength;
	unsigned int unMsg;
	unsigned int unSeqID;
	char cVer[2];
	unsigned char cUser;
	char cFiller;
} _MSG_HEAD;

typedef struct _ST_MSG_RGW_REQ_START {
	int nResultCode;
	int nServiceCode;
	int nTxRxType;
	char cPhoneType[20];
	char cCallKey[64];
	char cDeviceID[44];
} ST_MSG_RGW_REQ_START;

typedef struct _ST_MSG_RGW_RSP_START {
	int nResultCode;
	int nPacketSize;
} ST_MSG_RGW_RSP_START;

typedef struct _ST_MSG_RGW_REQ_MEDIA {
	int nIndex;
	int nLast;
	int nPacketSize;
	char cData[8000];
} ST_MSG_RGW_REQ_MEDIA;

typedef struct _ST_MSG_RGW_RPT_RESULT {
	int nResultCode;
	int nTxRxType;
	float fStartTime;
	float fEndTime;
	int bLast;
	int nResultSize;
	int nIdx;
	char cResult[8000];
} ST_MSG_RGW_RPT_RESULT;

typedef struct _ST_MSG_RGW_RPT_PARTIAL {
	int nResultCode;
	int nResultSize;
	int nIdx;
	char cResult[8000];
} ST_MSG_RGW_RPT_PARTIAL;

typedef struct _ST_MSG_RGW_RPT_STT_START {
	int nResultCode;
	int nPos;
	int nIdx;
} ST_MSG_RGW_RPT_STT_START;

typedef struct _ST_MSG_RGW_REQ_END {
	int nResultCode;
} ST_MSG_RGW_REQ_END;

typedef struct _ST_MSG_RGW_RSP_END {
	int nResultCode;
} ST_MSG_RGW_RSP_END;

typedef struct _ST_MSG_RGW {
	_MSG_HEAD stHead;

	union {
		ST_MSG_RGW_REQ_START stReqStart;
		ST_MSG_RGW_RSP_START stRspStart;
		ST_MSG_RGW_REQ_MEDIA stReqMedia;
		ST_MSG_RGW_RPT_RESULT stRptResult;
		ST_MSG_RGW_RPT_PARTIAL stRptPartial;
		ST_MSG_RGW_RPT_STT_START stRptSttStart;
		ST_MSG_RGW_REQ_END stReqEnd;
		ST_MSG_RGW_RSP_END stRspEnd;
		char cData[8*1024 - sizeof(_MSG_HEAD)];
	} stD;
} ST_MSG_RGW;


#endif /* __VOICEKIT_DEF_H__ */
