# --------------------------------------------- #
# Description : stt_client makefile             #
# --------------------------------------------- #
SUBDIR = so main

all :
	@for i in $(SUBDIR); do (cd $$i && $(MAKE) all) || exit 1; done;
clean :
	@for i in $(SUBDIR); do (cd $$i && $(MAKE) clean) || exit 1; done;
