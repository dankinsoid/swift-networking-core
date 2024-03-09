# swift-networking-core
Lightweight core of the [swift-networking](https://github.com/dankinsoid/swift-networking.git) library.

`swift-networking-core` is a comprehensive, and modular client networking library for Swift.

## Main goals of the library
- Minimalistic and intuitive syntax.
- Reusability, injection of configurations through all requests.
- Extensebility and modularity.
- Simple core with a wide range of possibilities.
- Testability and mockability.

## Usage
Core of the library is `NetworkClient` struct. It is a request builder and a request executor at the same time. It is a generic struct, so you can use it for any task associated with `URLRequest`.\
While full example is in [Example folder](/Example/) here is a simple example of usage:
```swift
let client = NetworkClient(url: baseURL)
  .auth(.bearer(token))
  .bodyDecoder(.json(dateDecodingStrategy: .iso8601))
  .bodyEncoder(.json(dateEncodingStrategy: .iso8601))
  .errorDecoder(.decodable(APIError.self))

// Create a client instance for /users path
let usersClient = client("users")

// GET /users?name=John&limit=1
let john: User = try await usersClient
  .query(["name": "John", "limit": 1])
  .auth(enabled: false)
  .get()

// Create a client instance for /users/{userID} path
let johnClient = usersClient(john.id)

// GET /user/{userID}
let user: User = try await johnClient.get()

// PUT /user/{userID}
try await johnClient.body(updatedUser).put()

// DELETE /user/{userID}
try await johnClient.delete()
```

## Built-in `NetworkClient` modifiers
### Request building
There are a lot of methods to modify a `URLRequest` such as `query`, `body`, `header`, `headers`, `method`, `path`, `timeout`, `cachePolicy`, `body`, `bodyStream`.\
Full list of modifiers is in [RequestModifiers.swift](/Sources/SwiftNetworkingCore/Modifiers/RequestModifiers.swift)\
All of them are based on `modifyRequest` modifier.

Some non-obvious modifiers are:
- `.callAsFunction(path...)` - the shorthand for `.path(path...)` modifier, which allow to write `client("path")` instead of `client.path("path")`.
- `.get`, `.post`, `.put`, `.delete`, `.patch` - shorthands for `method(method)` modifiers.

### Request execution
There is a `call(_ caller: NetworkClientCaller<...>, as serializer: Serializer<...>)`.
Examples:
```swift
try await client.call(.http, as: .decodable)
try await client.call(.http, as: .void)
try client.call(.httpPublisher, as: .decodable)
```
Also there are shorthands for built-in callers and serializers:
- `call()` - the equivalent of `call(.http, as: .decodable)` or `call(.http, as: .void)`
- `callAsFunction()` - the equivalent of `call()`. It allows to write `client.delete()` instead of `client.delete.call()`. Or  `client()` instead of `client.call()`.

#### NetworkClientCaller
`NetworkClientCaller` is a struct that describes a request execution.
There are several built-in callers:
- `.http` - for HTTP requests with `try await` syntax.
- `.httpPublisher` - for HTTP requests with Combine syntax.
- `.httpDownload` - for HTTP download requests with `try await` syntax.
- `.httpUpload` - for HTTP upload requests with `try await` syntax.

All built-in http callers use `.httpClient` configuration that can be customized with `.httpClient()` modifier. Default `.httpClient` is `URLSession.shared`. It's possiible to wrap a current `.httpClient` instance.

It's possible to create custom callers for different types of requests such as WebSocket, GraphQL, etc.

#### Serializer
`Serializer` is a struct that describes a response serialization.
There are several built-in serializers:
- `.decodable` - for decoding a response to a Decodable type.
- `.data` - for getting a raw Data response.
- `.void` - for ignoring a response.
- `.instance` - for getting a response the same type as `NetworkClientCaller` returns. For http requests it is `Data`.

`.decodable` serializer uses `.bodyDecoder` configuration that can be customized with `.bodyDecoder` modifier. Default `bodyDecoder` is `JSONDecoder()`.

### Encoding and decoding
There are several built-in configurations for encoding and decoding:
- `.bodyEncoder` - for encoding a request body. Built-in encoders are `.json`, `.formURL`.
- `.bodyDecoder` - for decoding a request body. Built-in decoder is `.json`.
- `.queryEncoder` - for encoding a query. Built-in encoder is `.query`.
- `.errorDecoder` - for decoding an error response. Built-in decoder is `.decodable(type)`.

All these encoders and decoders can be customized with eponymous modifiers.

### Auth

### Testing

### Logging

## How to extend `NetworkClient`

`NetworkClient` struct is a combination of two components: a closure to create a URLReauest and a typed dictionory of configs. So there is two ways to extend a NetworkClient.

## Installation

1. [Swift Package Manager](https://github.com/apple/swift-package-manager)

Create a `Package.swift` file.
```swift
// swift-tools-version:5.7
import PackageDescription

let package = Package(
  name: "SomeProject",
  dependencies: [
    .package(url: "https://github.com/dankinsoid/swift-networking-core.git", from: "0.19.0")
  ],
  targets: [
    .target(
      name: "SomeProject",
      dependencies: [
        .product(name:  "SwiftNetworkingCore", package: "swift-networking-core"),
      ]
    )
  ]
)
```
```ruby
$ swift build
```

## Author

dankinsoid, voidilov@gmail.com

## License

swift-networking-core is available under the MIT license. See the LICENSE file for more info.

## Contributing
We welcome contributions to Swift-Networking! Please read our contributing guidelines to get started.
