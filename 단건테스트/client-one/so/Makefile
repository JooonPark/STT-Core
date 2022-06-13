# --------------------------------------------- #
# Description : libvoicekitclient.so makefile   #
# --------------------------------------------- #

# DEFAULT PATH
PROC_NAME=libvoicekitclient.so
OBJECT_PATH=result
EXS=${OBJECT_PATH}/${PROC_NAME}

# INCLUDE PATH
INC_PATH=-I./include
LIB_PATH=
LINK_OPT=-lpthread -lgcrypt

# DEFINE
DEF_OPT=

# FLAGS
FLAGS_EXS=-shared -Wl,-soname,${PROC_NAME} ${DEF_OPT}
FLAGS_C=-fPIC ${DEF_OPT}
FLAGS_CPP=-fPIC ${DEF_OPT}

# SRC
SRCS_C=
SRCS_CPP= \
	VoiceKitBuffer.cpp \
	VoiceKitClient.cpp \
	VoiceKitHelper.cpp \
	VoiceKitUtil.cpp

OBJS_C=${SRCS_C:%.c=${OBJECT_PATH}/%.o}
OBJS_CPP=${SRCS_CPP:%.cpp=${OBJECT_PATH}/%.o}
OBJS=${OBJS_CPP} ${OBJS_C}

all: dir ${EXS}

${EXS}: ${OBJS}
	g++ ${FLAGS_EXS} ${OBJS} ${LINK_OPT} ${LIB_PATH} -o $@

${OBJECT_PATH}/%.o: src/%.c
	gcc ${FLAGS_C} -c -o $@ ${INC_PATH} $<

${OBJECT_PATH}/%.o: src/%.cpp
	g++ ${FLAGS_CPP} -c -o $@ ${INC_PATH} $<

clean:
	rm -f ${OBJECT_PATH}/*

dir:
	if [ ! -f ${OBJECT_PATH} ] ; then mkdir -p ${OBJECT_PATH}; fi
