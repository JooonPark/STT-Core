# --------------------------------------------- #
# Description : stt_client makefile             #
# --------------------------------------------- #

# DEFAULT PATH
PROC_NAME=stt_client
OBJECT_PATH=./result
VOICEKIT_OBJECT_PATH=../so/result
EXS=${OBJECT_PATH}/${PROC_NAME}

# INCLUDE PATH
INC_PATH=-I./include
LIB_PATH=-L../so/result -L/usr/local/lib
# LINK_OPT=-lpthread -lvoicekitclient
LINK_OPT=-lpthread

# DEFINE
DEF_OPT=-g

# FLAGS
FLAGS_EXS= ${DEF_OPT}
FLAGS_C= ${DEF_OPT}
FLAGS_CPP= ${DEF_OPT}

# SRC
SRCS_C=
SRCS_CPP=Main.cpp
OBJS_C=${SRCS_C:%.c=${OBJECT_PATH}/%.o}
OBJS_VOICEKIT=${VOICEKIT_OBJECT_PATH}/*.o
OBJS_CPP=${SRCS_CPP:%.cpp=${OBJECT_PATH}/%.o}
OBJS=${OBJS_CPP} ${OBJS_C} ${OBJS_VOICEKIT}

all: dir ${EXS}

${EXS}: ${OBJS}
	g++ ${FLAGS_EXS} ${OBJS} ${LINK_OPT} ${LIB_PATH} -o $@
${OBJECT_PATH}/%.o: src/%.c
	gcc ${FLAGS_C} -c -o $@ ${INC_PATH} $<
${OBJECT_PATH}/%.o: src/%.cpp
	g++ ${FLAGS_CPP} -c -o $@ ${INC_PATH} $<
	ls ${OBJS}
clean:
	rm -f ${OBJECT_PATH}/*

dir:
	if [ ! -f ${OBJECT_PATH} ] ; then mkdir -p ${OBJECT_PATH}; fi
