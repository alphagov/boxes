VEEWEE = bundle exec veewee vbox
VERSION := $(shell date +'%Y%m%d')

all: precise

precise: govuk_dev_precise64_$(VERSION).box

govuk_dev_precise64_$(VERSION).box: govuk_dev_precise64.box
	cp -p govuk_dev_precise64.box govuk_dev_precise64_$(VERSION).box

govuk_dev_precise64.box: definitions/govuk_dev_precise64/*
	$(VEEWEE) build -f govuk_dev_precise64
	$(VEEWEE) export -f govuk_dev_precise64

clean:
	$(VEEWEE) destroy -f govuk_dev_precise64
	rm -f *.box

sync-precise: precise
	s3cmd sync --acl-public govuk_dev_precise64_$(VERSION).box 's3://gds-boxes/'

sync: sync-precise
