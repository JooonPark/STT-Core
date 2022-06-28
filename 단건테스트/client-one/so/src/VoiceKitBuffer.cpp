/****************************************************************************************
 * INCLUDE
****************************************************************************************/
#include "VoiceKitBuffer.h"


/****************************************************************************************
 * FUNCTION
****************************************************************************************/
VoiceKitBuffer::VoiceKitBuffer() {
	pthread_mutex_init(&this->buffer_mutex, NULL);
	this->data = NULL;
	this->front = 0;
	this->rear = 0;
	this->position = 0;
	this->packet = 0;
	this->readPos = 0;
	this->isLast = false;
}

VoiceKitBuffer::~VoiceKitBuffer() {
	pthread_mutex_lock(&this->buffer_mutex);
	if(this->data != NULL) {
		free(this->data);
		this->data = NULL;
	}
	pthread_mutex_unlock(&this->buffer_mutex);
	pthread_mutex_destroy(&this->buffer_mutex);
}

int VoiceKitBuffer::ready(int packet) {
	pthread_mutex_lock(&this->buffer_mutex);
	if(this->data != NULL) {
		free(this->data);
		this->data = NULL;
	}
	this->data = (char *)malloc(sizeof(char) * packet * (MAX_QUEUE_SIZE + 1));
	if(this->data == NULL) {
		pthread_mutex_unlock(&this->buffer_mutex);
		return -1;
	}
	pthread_mutex_unlock(&this->buffer_mutex);
	this->front = 0;
	this->rear = 0;
	this->position = 0;
	this->packet = packet;
	this->readPos = 0;
	this->isLast = false;
	return 0;
}

void VoiceKitBuffer::finish() {
	pthread_mutex_lock(&this->buffer_mutex);
	if(this->data != NULL) {
		free(this->data);
		this->data = NULL;
	}
	pthread_mutex_unlock(&this->buffer_mutex);
	this->front = 0;
	this->rear = 0;
}

int VoiceKitBuffer::getLast() {
	if(this->data == NULL) {
		return true;
	}
	return this->isLast;
}

void VoiceKitBuffer::setLast() {
	this->isLast = true;
}

void VoiceKitBuffer::appendBuffer(char *data, int length, int bLast) {
	if(this->isLast == false) {
		pthread_mutex_lock(&this->buffer_mutex);
		this->isLast = bLast;

		if(this->data == NULL) {
			LogR("[VoiceKit] this->data == NULL\n");
		}
		if(data == NULL) {
			LogR("[VoiceKit] data == NULL\n");
		}
		if(length <= 0) {
			LogR("[VoiceKit] length <= 0\n");
		}
		if(this->isFull() == true) {
			LogR("[VoiceKit] this->isFull() == true\n");
		}

		if(this->data != NULL && data != NULL && length > 0 && this->isFull() == false) {
			char *tmp = (char *)data;

			for(int i = 0; i < length; ++i) {
				this->data[this->rear * this->packet + this->position] = tmp[i];
				this->position++;

				if(this->position == this->packet) {
					this->rear = (this->rear + 1) % MAX_QUEUE_SIZE;
					this->position = 0;
				}
			}
		}
		pthread_mutex_unlock(&this->buffer_mutex);
	}
}

int VoiceKitBuffer::readBuffer(char *data, int size) {
	int result = 0;

	try {
		pthread_mutex_lock(&this->buffer_mutex);
		if(this->data != NULL && data != NULL && size > 0) {
			if(this->isEmpty() == false) {
				for(int i = 0; i < this->packet && i < size; ++i) {
					data[i] = this->data[this->front * this->packet + i];
				}
				this->front = (this->front + 1) % MAX_QUEUE_SIZE;
				this->readPos++;
				result = this->packet;
			} else {
				if(this->isLast == true) {
					if(this->position > 0) {
						for(int i = 0; i < this->position && i < size; ++i) {
							data[i] = this->data[this->front * this->packet + i];
						}
						result = this->position;
						this->position = 0;
					}
					this->readPos++;
				}
			}
		}
		pthread_mutex_unlock(&this->buffer_mutex);
	} catch (int e) {
		pthread_mutex_unlock(&this->buffer_mutex);
	}
	return result;
}

int VoiceKitBuffer::getReadPos() {
	return this->readPos;
}

int VoiceKitBuffer::isFull() {
	if(this->data != NULL) {
		return (this->front == (this->rear + 1) % MAX_QUEUE_SIZE);
	}
	return true;
}

int VoiceKitBuffer::isEmpty() {
	if(this->data != NULL) {
		return this->front == this->rear;
	}
	return true;
}