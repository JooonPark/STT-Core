/****************************************************************************************
 * INCLUDE
****************************************************************************************/
#include "VoiceKitUtil.h"


/****************************************************************************************
 * VARIABLE
****************************************************************************************/
#ifdef ENC_MODE
unsigned char g_voice_enc_key[32] = { 0x60, 0x3a, 0xec, 0x10, 0x15, 0xca, 0x73, 0xbe, 0x2b, 0x73, 0xa1, 0xf0, 0x85, 0x7d, 0x77, 0x81, 0x1f, 0x35, 0x2c, 0x07, 0x3b, 0x61, 0x08, 0xd7, 0x2d, 0x98, 0x10, 0xa3, 0x09, 0x14, 0xdf, 0xf4 };
#endif


/****************************************************************************************
 * FUNCTION
****************************************************************************************/
#ifdef ENC_MODE
void get_random(uchar *ptr, int len) {
	FILE *urd = fopen("/dev/urandom", "r");
	int cnt = fread((void *)ptr, 1, len, urd);

	if(cnt != len) {
		LogR("[CLI] cannot read from /dev/urandom\n");
	}

	fclose(urd);
}

int encryptDataAes256(uchar *key, char *indata, int insize, char *outdata) {
	uchar ctr[16];
	gcry_cipher_hd_t handle;

	gcry_cipher_open(&handle, GCRYP_CIPHER_AES256, GCRY_CIPHER_MODE_GCM, 0);

	if(handle == NULL) {
		LogR("[CLI] encrypt handle null\n");
		return -1;
	}

	get_random(ctr, 16);
	gcry_cipher_setkey(handle, key, 32);
	gcry_cipher_setctr(handle, ctr, 16);
	gcry_cipher_encrypt(handle, outdata, insize, indata, insize);
	gcry_cipher_close(handle);

	return 0;
}

int decryptDataAes256(uchar *key, char *indata, int insize, char *outdata) {
	uchar ctr[16];
	gcry_cipher_hd_t handle;

	gcry_cipher_open(&handle, GCRYP_CIPHER_AES256, GCRY_CIPHER_MODE_GCM, 0);

	if(handle == NULL) {
		LogR("[CLI] decrypt handle null\n");
		return -1;
	}

	get_random(ctr, 16);
	gcry_cipher_setkey(handle, key, 32);
	gcry_cipher_setctr(handle, ctr, 16);
	gcry_cipher_decrypt(handle, outdata, insize, indata, insize);
	gcry_cipher_close(handle);

	return 0;
}
#endif

int openClient(int *sock, int epoll_fd, const char *ip, int port, void *ptr) {
	int result = 0;

	if(*sock != 0) {
		closeClient(sock, epoll_fd);
		usleep(100000);
	}

	if((*sock = socket(AF_INET, SOCK_STREAM, 0)) > 0) {
		struct timeval timeout;
		struct sockaddr_in addr;

		memset(&addr, 0, sizeof(addr));
		addr.sin_family = AF_INET;
		addr.sin_addr.s_addr = inet_addr(ip);
		addr.sin_port = htons(port);

		timeout.tv_sec = 3;
		timeout.tv_usec = 0;

		// setsockopt(*sock, SOL_SOCKET, SO_RCVTIMEO, (char *)&timeout, sizeof(timeout));
		setsockopt(*sock, SOL_SOCKET, SO_SNDTIMEO, (char *)&timeout, sizeof(timeout));

		if((result = connect(*sock, (struct sockaddr *)&addr, sizeof(addr))) >= 0) {
			struct epoll_event event;
			event.events = EPOLLIN;
			event.data.ptr = ptr;
			epoll_ctl(epoll_fd, EPOLL_CTL_ADD, *sock, &event);

			LogG("[CLI] [OPEN] result(%d), socket(%d), ip(%s), port(%d)\n", result, *sock, ip, port);
			usleep(100000);
			return true;
		} else {
			LogR("[CLI] connect error : result(%d), socket(%d), ip(%s), port(%d)\n", result, *sock, ip, port);
		}
	} else {
		LogR("[CLI] socket error : socket(%d), ip(%s), port(%d)\n", *sock, ip, port);
	}

	closeClient(sock, epoll_fd);
	usleep(100000);

	return false;
}

void closeClient(int *sock, int epoll_fd) {
	LogR("[CLI] closeClient(%d)\n", *sock);
	if(*sock > 0) {
		close(*sock);
		epoll_ctl(epoll_fd, EPOLL_CTL_DEL, *sock, NULL);
	}
	*sock = 0;
}

int readHeader(int *sock, int epoll_fd, void *data) {
	if(*sock > 0) {
		if(data != NULL) {
			int size = sizeof(_MSG_HEAD);
			int readSize = 0;
			int resultSize = 0;
			int frame = 0;

			do {
				resultSize = read(*sock, ((char *)data) + readSize, 1);
				if(resultSize == 0) {
					closeClient(sock, epoll_fd);
					return false;
				}
				if(resultSize == -1) {
					if(errno == EINTR) {
						usleep(10000);
						continue;
					}
					closeClient(sock, epoll_fd);
					return false;
				}
				frame = ((char *)data)[0] & 0xFF;
			} while(frame != 0xFE && frame != 0xFF && frame != 0xAF && frame != 0x1A);

			readSize += resultSize;

			while(1) {
				resultSize = read(*sock, ((char *)data) + readSize, 1);
				if(resultSize == 0) {
					closeClient(sock, epoll_fd);
					return false;
				}
				if(resultSize == -1) {
					if(errno == EINTR) {
						usleep(10000);
						continue;
					}
					closeClient(sock, epoll_fd);
					return false;
				}
				frame = ((char *)data)[1] & 0xFF;
				if(frame != 0xFE && frame != 0xFF && frame != 0xAF && frame != 0x1A) {
					closeClient(sock, epoll_fd);
					return false;
				}
				break;
			}

			readSize += resultSize;

			do {
				resultSize = read(*sock, ((char *)data) + readSize, size - readSize);
				if(resultSize == 0) {
					closeClient(sock, epoll_fd);
					return false;
				}
				if(resultSize == -1) {
					if(errno == EINTR) {
						usleep(10000);
						continue;
					}
					closeClient(sock, epoll_fd);
					return false;
				}
				readSize += (resultSize > 0) ? resultSize : 0;
			} while(size != readSize);

			return (readSize == size);
		}
	}

	return false;
}

int readData(int *sock, int epoll_fd, void *data, int size) {
	if(size > 0) {
		if(data != NULL) {
			int readSize = 0;
			int resultSize = 0;
			int retry = 0;

#ifdef ENC_MODE
			char cRecvData[MSG_SIZE];
			char cDecData[MSG_SIZE];

			memset(cRecvData, 0, sizeof(cRecvData));
			memset(cDecData, 0, sizeof(cDecData));

			do {
				if(*sock > 0) {
					resultSize = read(*sock, ((char *)cRecvData) + readSize, size - readSize);
				} else {
					return -1;
				}
				if(resultSize == 0) {
					closeClient(sock, epoll_fd);
					return -1;
				}
				if(resultSize == -1) {
					if(errno == EINTR) {
						usleep(10000);
						continue;
					}
					closeClient(sock, epoll_fd);
					return -1;
				}
				readSize += (resultSize > 0) ? resultSize : 0;
			} while(size != readSize);

			if(resultSize > 0) {
				decryptDataAes256(g_voice_enc_key, cRecvData, readSize, cDecData);
				memcpy(data, cDecData, readSize);
			}
#else
			do {
				if(*sock > 0) {
					resultSize = read(*sock, ((char *)data) + readSize, size - readSize);
				} else {
					return -1;
				}
				if(resultSize == 0) {
					closeClient(sock, epoll_fd);
					return -1;
				}
				if(resultSize == -1) {
					if(errno == EINTR) {
						usleep(10000);
						continue;
					}
					closeClient(sock, epoll_fd);
					return -1;
				}
				readSize += (resultSize > 0) ? resultSize : 0;
			} while(size != readSize);
#endif
			return (resultSize > 0) ? readSize : -1;
		}
	} else if(size == 0) {
		return 0;
	}

	return -1;
}

int writeData(int *sock, int epoll_fd, void *data, int size) {
	if(size > 0) {
		if(data != NULL) {
			int writeSize = 0;
			int resultSize = 0;
#ifdef ENC_MODE
			int headerSize = sizeof(_MSG_HEAD);
			int encSize = 0;
			char cSendData[MSG_SIZE];
			char cInData[MSG_SIZE];
			char cEncData[MSG_SIZE];
			
			memset(cSendData, 0, sizeof(cSendData));
			memset(cInData, 0, sizeof(cInData));
			memset(cEncData, 0, sizeof(cEncData));
			memcpy(cSendData, data, headerSize);

			if(size > headerSize) {
				encSize = size - headerSize;

				if(encSize > MSG_SIZE) {
					encSize = MSG_SIZE;
				}

				memcpy(cInData, (char *)data + headerSize, encSize);
				encryptDataAes256(g_voice_enc_key, cInData, encSize, cEncData);
				memcpy(cSendData, cEncData, encSize);
			}

			while(resultSize != -1 && size != writeSize) {
				try {
					if(*sock > 0) {
						resultSize = write(*sock, ((char *)cSendData) + writeSize, size - writeSize);
					} else {
						return -1;
					}
				} catch(int e) {
					return -1;
				}
				writeSize += (resultSize > 0) ? resultSize : 0;
			}
#else
			while(resultSize != -1 && size != writeSize) {
				try {
					if(*sock > 0) {
						resultSize = write(*sock, ((char *)data) + writeSize, size - writeSize);
					} else {
						return -1;
					}
				} catch(int e) {
					return -1;
				}
				writeSize += (resultSize > 0) ? resultSize : 0;
			}
#endif
			return (resultSize > 0) ? writeSize : -1;
		}
	} else if(size == 0) {
		return 0;
	}

	return -1;
}

int startThread(pthread_t *thread, void *(*start_routine)(void *), void *arg) {
	pthread_attr_t attr;

	if(pthread_attr_init(&attr) != 0) {
		stopThread(thread);
		return false;
	}

	if(pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED) != 0) {
		stopThread(thread);
		return false;
	}

	if(pthread_create(thread, &attr, start_routine, arg) < 0) {
		stopThread(thread);
		return false;
	}

	if(pthread_attr_destroy(&attr) != 0) {
		stopThread(thread);
		return false;
	}

	return true;
}

void stopThread(pthread_t *thread) {
	if(*thread != 0) {
		pthread_cancel(*thread);
		*thread = 0;
	}
}

int	getAtoI(const char *src, int start, int length) {
	char tmp[11];

	memcpy(tmp, &src[start], length);
	tmp[length] = '\0';

	return atoi(tmp);
}

int certificationToSvcKey(const char *szCertification) {
	int nTemp;
	char szTemp[10];
	int nFirstSet;
	int nLastSet;
	int nServiceKeyLen;
	int nServviceKeySt;
	int nServiceKey;

	if(strlen(szCertification) != 10) {
		return -1;
	}

	nFirstSet = getAtoI(szCertification, 0, 2);
	nLastSet = getAtoI(szCertification, 6, 4);
	nServiceKeyLen = getAtoI(szCertification, 2, 1);
	nServviceKeySt = 3 + (3 - nServiceKeyLen);

	nServiceKey = getAtoI(szCertification, nServviceKeySt, nServiceKeyLen);
	sprintf(szTemp, "%ld", (long)(nServiceKey + 12));

	if(strlen(szTemp) > 2) {
		int len = strlen(szTemp);
		nTemp = getAtoI(szTemp, len - 2, 2);
	} else {
		nTemp = atoi(szTemp);
	}

	if(nFirstSet != nTemp) {
		return -1;
	}

	sprintf(szTemp, "%ld", (long)(nServiceKey + 3156));

	if(strlen(szTemp) > 4) {
		int len = strlen(szTemp);
		nTemp = getAtoI(szTemp, len - 4, 4);
	} else {
		nTemp = atoi(szTemp);
	}

	if(nLastSet != nTemp) {
		return -1;
	}

	return nServiceKey;
}