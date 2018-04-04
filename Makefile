all: compile

deps:
	mix deps.get

docs:
	mix docs

compile: deps
	mix compile

clean:
	mix clean
	rm -rf _build deps

dialyzer: 
	mix dialyzer

test:
	mix coveralls.html --exclude examplefs

test_examples:
	mix coveralls.html --only examplefs

test_all:
	mix coveralls.html

.PHONY: test
