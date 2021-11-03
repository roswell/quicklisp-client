VERSION ?= 2021-02-13
ROSWELL ?= ros
GH_OWNER ?= roswell
GH_REPO ?= quicklisp-client
include .env
export $(shell sed 's/=.*//' .env)

all: archives/$(VERSION)/client.tar.bz2 archives/$(VERSION)/client.cab
	
versions:
	@git ls-remote --tags https://github.com/quicklisp/quicklisp-client.git|sed -E "s/^.*version-(.*)\$$/\1/g"

archives/$(VERSION)/client.tar.gz:
	curl -f -L -s --create-dirs --output $@ https://github.com/quicklisp/quicklisp-client/archive/refs/tags/version-$(VERSION).tar.gz

archives/$(VERSION)/client.tar.bz2: archives/$(VERSION)/client.tar.gz
	tar pxf $<
	mv quicklisp-client-version-$(VERSION) quicklisp
	rm -f quicklisp/.gitignore
	tar jcvf $@ quicklisp
	rm -rf quicklisp

archives/$(VERSION)/client.cab: archives/$(VERSION)/client.tar.gz
	tar pxf $<
	mv quicklisp-client-version-$(VERSION) quicklisp
	rm -f quicklisp/.gitignore
	lcab -r quicklisp $@
	rm -rf quicklisp
	# to extract on windows 'expand.exe /r "-F:*" client.cab .'

upload.ros:
	curl -f -L -s --create-dirs --output $@ https://raw.githubusercontent.com/roswell/quicklisp/54f02d23c6a382737468bd7b9ab9e7dc904e8f56/upload.ros

upload: upload.ros
	ros build $<

upload-archives: upload
	./upload upload archives/$(VERSION)/client.tar.bz2 $(VERSION) $(GH_OWNER) $(GH_REPO)
	./upload upload archives/$(VERSION)/client.cab $(VERSION) $(GH_OWNER) $(GH_REPO)

client-versions.txt:
	make -s versions > client-versions.txt

version.txt:
	echo $(VERSION) > $@

upload-version.txt: version.txt
	./upload upload version.txt dist $(GH_OWNER) $(GH_REPO)

iterate-versions: client-versions.txt
	cat $<| sed -E "s/(.*)/VERSION=\1 make $(ACTION)/g"|sh

show:
	@echo owner=$(GH_OWNER) repo=$(GH_REPO) VERSION=$(VERSION)
