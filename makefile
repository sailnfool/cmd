.PHONY: all scripts
.ONESHELL:
all: scripts
scripts:
	cd scripts
	make uninstall install
	cd ..
