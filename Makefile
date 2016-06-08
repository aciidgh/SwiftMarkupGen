build:
	swift build -Xlinker -undefined -Xlinker dynamic_lookup

release:
	swift build -c release -Xlinker -undefined -Xlinker dynamic_lookup

install: release
	cp .build/release/MarkupGen-bin	/usr/local/bin

runExample: build
	.build/debug/MarkupGen-bin "func abc(foo: Int, bar: Type) throws AType {}"
