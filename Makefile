.PHONY: install_deps test

.DEFAULT_GOAL := test

install_deps:
	shards install

test:
	crystal spec --rand
