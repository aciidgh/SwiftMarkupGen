# SwiftMarkupGen

SwiftMarkupGen is a swift package to generate swift documentation markup template given a function signature. 
It uses `sourcekitd.framework` to parse the function signature.

This is useful to write plugins for text editors.

[![Build Status](https://travis-ci.org/aciidb0mb3r/SwiftMarkupGen.svg?branch=master)](https://travis-ci.org/aciidb0mb3r/SwiftMarkupGen)

## Requirements:
* Latest Swift 3 snapshot from https://swift.org/download/#snapshots
* Currently SourceKit only works on OSX so Linux is not supported for now.

Installation:

    $ make install
    
## Usage: 

```swift
$ MarkupGen-bin "public func hello(cool a: Int, abc b: FooType) throws -> FooType {"
/// hello(cool:abc:)
///
/// - Parameters:
///     - cool:
///     - abc:
///
/// - Throws:
///
/// - Returns:
```

## Build:

    $ make
    or
    $ swift build -Xlinker -undefined -Xlinker dynamic_lookup

## License

MIT
