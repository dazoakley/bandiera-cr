.PHONY: install_deps test lint

.DEFAULT_GOAL := test

install_deps:
	shards install

test: lint
	crystal spec --rand

lint:
	./bin/ameba
