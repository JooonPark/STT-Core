/****************************************************************************************
 * INCLUDE
****************************************************************************************/
#include <execinfo.h>
#include <pthread.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/time.h>
#include <unistd.h>

#include "VoiceKitClient.h"


/****************************************************************************************
 * DEFINE
****************************************************************************************/
#define PRINTF_BOLD(fmt, ...) printf("\x1b[1m[%s] "fmt"\x1b[0m", timeToString(), ## __VA_ARGS__)
#define PRINTF_GRAY(fmt, ...) printf("\x1b[1m\x1b[30m[%s] "fmt"\x1b[0m", timeToString(), ## __VA_ARGS__)
#define PRINTF_RED(fmt, ...) printf("\x1b[1m\x1b[31m[%s] "fmt"\x1b[0m", timeToString(), ## __VA_ARGS__)
#define PRINTF_GREEN(fmt, ...) printf("\x1b[1m\x1b[32m[%s] "fmt"\x1b[0m", timeToString(), ## __VA_ARGS__)
#define PRINTF_YELLOW(fmt, ...) printf("\x1b[1m\x1b[33m[%s] "fmt"\x1b[0m", timeToString(), ## __VA_ARGS__)
#define PRINTF_BLUE(fmt, ...) printf("\x1b[1m\x1b[34m[%s] "fmt"\x1b[0m", timeToString(), ## __VA_ARGS__)
#define PRINTF_SKYBLUE(fmt, ...) printf("\x1b[1m\x1b[36m[%s] "fmt"\x1b[0m", timeToString(), ## __VA_ARGS__)

#define STT_IP "127.0.0.1"
#define STT_PORT 37171
#define STT_SVC "1416523158"
#define STT_PHONETYPE "AI-IVR"
#define STT_DEVICEID "DEVICE"
#define THREAD_MAX 1
#define PATH_SIZE 1024

/****************************************************************************************
 * STRUCT
****************************************************************************************/
typedef struct _THREAD_INFO {
	int threadNum;
	int isEnd;
	char path[PATH_SIZE];
	pthread_t mThread;
	VoiceKitClient *mVoiceKitClient;
} THREAD_INFO;


/****************************************************************************************
 * VARIABLE
****************************************************************************************/
static THREAD_INFO info[THREAD_MAX];
FILE *result_fp;

/****************************************************************************************
 * FUNCTION
****************************************************************************************/
int help()
{
    printf("Usage: ./client [OPTION] [FILE]\n" 
            "  -i [ip]      ip\n" 
            "  -p [port]    port\n"
            "  -s [SVC]     svc code\n"
            "  -k [KEY]     call key\n"
            "  -f [file]    input pcm file\n"); 
    exit(0); 
}


inline char* timeToString() {
	static char s[20];
	char szCurrentMili[32];
	struct tm *t;
	time_t timer;
	struct timeval tv;

	gettimeofday(&tv, NULL);
	timer = time(NULL);
	t = localtime(&timer);

	sprintf(szCurrentMili, "%03d", (int)tv.tv_usec / 1000);

	// sprintf(s, "%04d-%02d-%02d %02d:%02d:%02d.%s", t->tm_year + 1900, t->tm_mon + 1, t->tm_mday, t->tm_hour, t->tm_min, t->tm_sec, szCurrentMili);
	sprintf(s, "%02d:%02d:%02d.%s", t->tm_hour, t->tm_min, t->tm_sec, szCurrentMili);

	return s;
}

int createThread(pthread_t *thread, void *(*start_routine)(void *), void *arg) {
	pthread_attr_t attr;

	if(pthread_attr_init(&attr) != 0) {
		return false;
	}

	if(pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED) != 0) {
		return false;
	}

	if(pthread_create(thread, &attr, start_routine, arg) < 0) {
		return false;
	}

	if(pthread_attr_destroy(&attr) != 0) {
		return false;
	}

	return true;
}
/*
void stopThread(pthread_t *thread) {
	if(*thread != 0) {
		pthread_cancel(*thread);
		*thread = 0;
	}
}
*/
void Sigh(int n) {
	PRINTF_RED("[SIG] Catch The Sigh %d\n", n);

	void *array[10];
	size_t size;
	char **strings;
	size = backtrace(array, 10);
	strings = backtrace_symbols(array, size);
	for(int i = 2; i < (int)size; i++) {
		PRINTF_RED("[SIG] %d: %s\n", (i - 2), strings[i]);
	}
	free(strings);

	exit(0);
}

const char *getStopMsg(int type) {
	switch(type) {
		case RESULT_VOICEKIT_SUCCESS: return "RESULT_VOICEKIT_SUCCESS";
		case RESULT_VOICEKIT_CONNECT_ERROR: return "RESULT_VOICEKIT_CONNECT_ERROR";
		case RESULT_VOICEKIT_DISCONNECTED: return "RESULT_VOICEKIT_DISCONNECTED";
		case RESULT_VOICEKIT_TIMEOUT: return "RESULT_VOICEKIT_TIMEOUT";
		case RESULT_VOICEKIT_NO_DATA: return "RESULT_VOICEKIT_NO_DATA";
		case RESULT_VOICEKIT_SERVICEKEY_ERROR: return "RESULT_VOICEKIT_SERVICEKEY_ERROR";
		case RESULT_VOICEKIT_STOP: return "RESULT_VOICEKIT_STOP";
		case RESULT_VOICEKIT_SVCEND: return "RESULT_VOICEKIT_SVCEND";
		case RESULT_VOICEKIT_UNKOWN_ERROR: return "RESULT_VOICEKIT_UNKOWN_ERROR";
	}
	return "UNKOWN ERROR";
}

void *thread_main(void *value) {
	VoiceKitClient *mVoiceKitClient = (VoiceKitClient *)value;
	THREAD_INFO *userData = (THREAD_INFO *)mVoiceKitClient->userData;
	int i = userData->threadNum;
	char read_buffer[32000];
	int read_size = 0;
	int nCount = 0;
	FILE *fp = NULL;

	while(true) {
		usleep(100000);

		if(userData->isEnd == 1) {
			userData->isEnd = 2;
			fp = fopen(userData->path, "r");

            char result_path[PATH_SIZE + 4];
            strcpy(result_path, userData->path);
            strcat(result_path, ".stt");
			result_fp = fopen(result_path, "w");

			PRINTF_SKYBLUE("IDX[%03d][R STA] : path(%s)\n", i, userData->path);

			int bLast = false;
			if(fp > 0) {
				memset(read_buffer, 0, 32000);
				nCount = 0;

				fseek(fp, 0, 0);

				while((read_size = fread(read_buffer, sizeof(char), 1600, fp)) > 0) {
					if(feof(fp)) {
						PRINTF_SKYBLUE("STEP1 IDX[%03d][R LST]\n", i);
						bLast = true;
						mVoiceKitClient->putData(NULL, 0, true);
					} else {
						bLast = false;
						mVoiceKitClient->putData(read_buffer, read_size, false);
						usleep(50000);
					}
				}

				fclose(fp);
			} else {
				PRINTF_SKYBLUE("IDX[%03d][R OPN] : fp(%d)\n", i, fp);
			}

			if(bLast == false)
			{
				PRINTF_SKYBLUE("STEP2 IDX[%03d][R LST]\n", i);
				mVoiceKitClient->putData(NULL, 0, true);
			}

			PRINTF_SKYBLUE("IDX[%03d][R END]\n", i);
		}
	}
}

void voiceKitFunc(void *instance, ST_MSG_VOICEKIT *data) {
	VoiceKitClient *mVoiceKitClient = (VoiceKitClient *)instance;
	THREAD_INFO *userData = (THREAD_INFO *)mVoiceKitClient->userData;
	int i = userData->threadNum;

	switch(data->type) {
		case MSG_VOICEKIT_START: {
			PRINTF_BLUE("IDX[%03d][START] : result(%d)\n", i, data->stStart.nResultCode);
			userData->isEnd = 1;
			break;
		}
		case MSG_VOICEKIT_PARTIAL: {
			// PRINTF_GRAY("IDX[%03d][PARTL] : nIdx(%d), result(%d), size(%d), text(%s)\n", i, data->stPartial.nIdx, data->stPartial.nResultCode, data->stPartial.nResultSize, data->stPartial.cResult);
			break;
		}
		case MSG_VOICEKIT_STT_START: {
			// PRINTF_GRAY("IDX[%03d][STTST] : nIdx(%d)\n", i, data->stSttStart.nIdx);
			break;
		}
		case MSG_VOICEKIT_RESULT: {
            PRINTF_GRAY("IDX[%03d][RESLT] : MO - nIdx(%d), tm(%03.03lf - %03.03lf), [LST : %d][%s]\n", i, data->stResult.nIdx, data->stResult.fStartTime, data->stResult.fEndTime, data->stResult.bLast, data->stResult.cResult);
			fprintf(result_fp, data->stResult.cResult);
            fprintf(result_fp, "\n");
            break;
		}
		case MSG_VOICEKIT_STOP: {
			PRINTF_RED("IDX[%03d][ STOP] : result(%s)\n", i, getStopMsg(data->stStop.nResultCode));
			fflush(result_fp);
            fclose(result_fp);
            userData->isEnd = 3;
			break;
		}
	}
}

#define PCM_PATH "../../sound/0_%d.pcm"

int main(int argc, char *argv[]) {
	
    //?????
    for(int i = 0; i < 20; i++) {
		if(i == 17) continue;
		if(i == SIGALRM) continue;
		signal(i, Sigh);
	}
    
    int error = 0;
    char ip[16] = {0,};
    int port;
    char callkey[64] = {0,};
    char svc[16] = {0,};
    int opt;
    char path[1024] = {0,};
    while((opt = getopt(argc, argv, "hs:i:f:p:k:")) != -1)  
    { 
        switch(opt)  
        {  
            case 'h': 
                help();  
                break;  
            
            case 'i': 
                memcpy(ip, optarg, strlen(optarg));
                error = 1; 
                break;

            case 'p':
                {
                    char s_port[10] = {0,};
                    memcpy(s_port, optarg, strlen(optarg));
                    port = atoi(s_port);
                    error = 1; 
                    break;
                }
            case 'k':
                memcpy(callkey, optarg, strlen(optarg));
                error = 1;
                break;
            
            case 'f':
                memcpy(path, optarg, strlen(optarg));
                error = 1;
                break;
            case 's':
                memcpy(svc, optarg, strlen(optarg));
                error = 1;
                break;

        } 
    }  
    if ( error != 1 )
    {
        help();
        exit(0);
    }
    if (access(path, R_OK) != 0)
    {
        printf(" -f path file is not existed");
        exit(0);
    }

	signal(SIGHUP, SIG_IGN);
	signal(SIGPIPE, SIG_IGN);

	PRINTF_GREEN("==================== [MAIN START] ====================\n");
	PRINTF_GREEN("IP : %s, PORT : %d, SVC : %s, PHONETYPE : %s, CALLKEY : %s, DEVICEID : %s\n", ip, port, svc, STT_PHONETYPE, callkey, STT_DEVICEID);
	PRINTF_GREEN("======================================================\n");

	char szCallKey[32];

	for(int i = 0; i < THREAD_MAX; i++) {

		info[i].threadNum = i;
		info[i].isEnd = 0;
		sprintf(info[i].path, path);
		info[i].mThread = 0;
		info[i].mVoiceKitClient = new VoiceKitClient(voiceKitFunc);
		info[i].mVoiceKitClient->setData(ip, port, svc, 0, STT_PHONETYPE, callkey, STT_DEVICEID);
		info[i].mVoiceKitClient->userData = &info[i];

		PRINTF_GREEN("IDX[%03d][ INIT] : path(%s), calley(%s)\n", info[i].threadNum, info[i].path, callkey);

        info[i].mVoiceKitClient->start();
        createThread(&info[i].mThread, thread_main, (void *) info[i].mVoiceKitClient);
    }
    while(1) {
            if (info[0].isEnd == 3)
            {
                break;   
            }
        usleep(100000);
    }
    for(int i = 0; i < THREAD_MAX; i++) {
		delete info[i].mVoiceKitClient;
	}

	PRINTF_GREEN("==================== [ MAIN END ] ====================\n");

	return 0;
}
