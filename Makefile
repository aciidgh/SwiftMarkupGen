build:
	swift build -Xlinker -undefined -Xlinker dynamic_lookup

runExample: build
	.build/debug/MarkupGen-bin "func abc(foo: Int, bar: Type) throws AType {}"
