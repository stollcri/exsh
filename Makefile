default: run

build:
	mix escript.build

run: build
	./exsh

