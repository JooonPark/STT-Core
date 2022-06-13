#ifndef __VOICEKIT_CLIENT_H__
#define __VOICEKIT_CLIENT_H__


/****************************************************************************************
 * ENUM
****************************************************************************************/
enum VOICEKIT_RESULT_TYPE {
	MSG_VOICEKIT_START = 1000,
	MSG_VOICEKIT_RESULT = 2000,
	MSG_VOICEKIT_PARTIAL,
	MSG_VOICEKIT_STT_START,
	MSG_VOICEKIT_STOP = 3000,
};

enum VOICEKIT_RESULT_CODE_TYPE {
	RESULT_VOICEKIT_SUCCESS = 0,
	RESULT_VOICEKIT_CONNECT_ERROR,
	RESULT_VOICEKIT_DISCONNECTED,
	RESULT_VOICEKIT_TIMEOUT,
	RESULT_VOICEKIT_NO_DATA,
	RESULT_VOICEKIT_SERVICEKEY_ERROR,
	RESULT_VOICEKIT_STOP,
	RESULT_VOICEKIT_SVCEND,
	RESULT_VOICEKIT_UNKOWN_ERROR = 9999,
};


/****************************************************************************************
 * STRUCT
****************************************************************************************/
typedef struct _ST_MSG_VOICEKIT_START {
	int nResultCode;
} ST_MSG_VOICEKIT_START;

typedef struct _ST_MSG_VOICEKIT_RESULT {
	int nResultCode;
	int nResultSize;
	int nTxRxType;
	float fStartTime;
	float fEndTime;
	int nDataSize;
	int nTotalDataSize;
	int bLast;
	int nIdx;
	char cResult[8000];
} ST_MSG_VOICEKIT_RESULT;

typedef struct _ST_MSG_VOICEKIT_PARTIAL {
	int nResultCode;
	int nResultSize;
	int nIdx;
	char cResult[8000];
} ST_MSG_VOICEKIT_PARTIAL;

typedef struct _ST_MSG_VOICEKIT_STT_START {
	int nResultCode;
	int nPos;
	int nIdx;
} ST_MSG_VOICEKIT_STT_START;

typedef struct _ST_MSG_VOICEKIT_STOP {
	int nResultCode;
} ST_MSG_VOICEKIT_STOP;

typedef struct _ST_MSG_VOICEKIT {
	int type;

	union {
		ST_MSG_VOICEKIT_START stStart;
		ST_MSG_VOICEKIT_RESULT stResult;
		ST_MSG_VOICEKIT_PARTIAL stPartial;
		ST_MSG_VOICEKIT_STT_START stSttStart;
		ST_MSG_VOICEKIT_STOP stStop;
	};
} ST_MSG_VOICEKIT;


/****************************************************************************************
 * TYPEDEF
****************************************************************************************/
typedef void (* VoiceKitClientCallbackFunc)(void *instance, ST_MSG_VOICEKIT *data);


/****************************************************************************************
 * CLASS
****************************************************************************************/
class VoiceKitClient {
public:
	VoiceKitClient(VoiceKitClientCallbackFunc callback_func);
	~VoiceKitClient();

	int setData(const char *ip, int port, const char *svc, int txrx, const char *phoneType, const char *callkey, const char *devId);
	void start();
	void stop();
	int isSpeak();
	void putData(char *data, int size, int bLast);

	void *userData;
private:
	void *mVoiceKitHelper;
};


#endif /* __VOICEKIT_CLIENT_H__ */
