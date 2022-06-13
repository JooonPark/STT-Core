/****************************************************************************************
* INCLUDE
****************************************************************************************/
#include "VoiceKitClient.h"
#include "VoiceKitHelper.h"


/****************************************************************************************
* FUNCTION
****************************************************************************************/
VoiceKitClient::VoiceKitClient(VoiceKitClientCallbackFunc callback_func) {
	this->mVoiceKitHelper = (VoiceKitHelper *)new VoiceKitHelper(this, callback_func);
}

VoiceKitClient::~VoiceKitClient() {
	if(this->mVoiceKitHelper != NULL) {
		delete ((VoiceKitHelper *)this->mVoiceKitHelper);
		this->mVoiceKitHelper = NULL;
	}
}

int VoiceKitClient::setData(const char *ip, int port, const char *svc, int txrx, const char *phoneType, const char *callkey, const char *devId) {
	if (this != NULL && this->mVoiceKitHelper != NULL) {
		if(((VoiceKitHelper *)this->mVoiceKitHelper)->setData(ip, port, svc, txrx, phoneType, callkey, devId) == true) {
			return true;
		}
	}
	return false;
}

void VoiceKitClient::start() {
	if (this != NULL && this->mVoiceKitHelper != NULL) {
		((VoiceKitHelper *)this->mVoiceKitHelper)->start();
	}
}

void VoiceKitClient::stop() {
	if (this != NULL && this->mVoiceKitHelper != NULL) {
		((VoiceKitHelper *)this->mVoiceKitHelper)->stop();
	}
}

int VoiceKitClient::isSpeak() {
	if(this != NULL && this->mVoiceKitHelper != NULL) {
		return ((VoiceKitHelper *)this->mVoiceKitHelper)->isSpeak();
	}
	return false;
}

void VoiceKitClient::putData(char *data, int size, int bLast) {
	if (this != NULL && this->mVoiceKitHelper != NULL) {
		if(this->isSpeak() == true) {
			((VoiceKitHelper *)this->mVoiceKitHelper)->putData(data, size, bLast);
		}
	}
}