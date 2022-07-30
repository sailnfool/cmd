SHELL=/bin/bash
PREFIX?=$(HOME)
.sh:
	@rm -f $@
	cp $< $@
INSTALL =		countfiles \
		hashcreatecanonical \
		dohashes \
		find_sim \
		getgitroot \
		histogram \
		mypr \
		mysourcedate \
		mynl \
		nowinUCT \
		pinger \
		pinger2 \
		proj_setup \
		pathmunge \
		uuid
#		func.kkbytes \
#		func.kerrecho \
#		func.knice2num \
#		func.kinsufficient \

EXECDIR := $(PREFIX)/bin
LEXECDIR := $(LPREFIX)/bin


.PHONY: clean uninstall all
all: $(INSTALL)
install: $(INSTALL)
	mkdir -p $(EXECDIR)
	install -o $(USER) -C $? $(EXECDIR)
	rm -f $?
clean: 
	@for execfile in $(INSTALL); do \
		echo rm -f $$execfile; \
		rm -f $$execfile; \
	done
uninstall: 
	@for execfile in $(INSTALL); do \
		echo rm -f $(EXECDIR)/$$execfile; \
		rm -f $(EXECDIR)/$$execfile; \
	done
$(EXECDIR):
	mkdir -p $(EXECDIR)
