import Foundation
import Logging
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A generic structure for handling network requests and their responses.
public struct APIClientCaller<Response, Value, Result> {

	private let _call: (
		UUID,
		HTTPRequest,
		RequestBody?,
		APIClient.Configs,
		@escaping (Response, () throws -> Void) throws -> Value
	) throws -> Result
	private let _mockResult: (_ value: Value) throws -> Result

	/// Initializes a new `APIClientCaller`.
	/// - Parameters:
	///   - call: A closure that performs the network call.
	///   - mockResult: A closure that handles mock results.
	public init(
		call: @escaping (
			_ uuid: UUID,
			_ request: HTTPRequest,
			_ body: RequestBody?,
			_ configs: APIClient.Configs,
			_ serialize: @escaping (Response, _ validate: () throws -> Void) throws -> Value
		) throws -> Result,
		mockResult: @escaping (_ value: Value) throws -> Result
	) {
		_call = call
		_mockResult = mockResult
	}

	/// Performs the network call with the provided request, configurations, and serialization closure.
	/// - Parameters:
	///   - request: The `URLRequest` for the network call.
	///   - configs: The configurations for the network call.
	///   - serialize: A closure that serializes the response.
	/// - Returns: The result of the network call.
	public func call(
		uuid: UUID,
		request: HTTPRequest,
		body: RequestBody?,
		configs: APIClient.Configs,
		serialize: @escaping (Response, _ validate: () throws -> Void) throws -> Value
	) throws -> Result {
		try _call(uuid, request, body, configs, serialize)
	}

	/// Returns a mock result for a given value.
	/// - Parameter value: The value to convert into a mock result.
	/// - Returns: The mock result.
	public func mockResult(for value: Value) throws -> Result {
		try _mockResult(value)
	}

	/// Maps the result to another type using the provided mapper.
	/// - Parameter mapper: A closure that maps the result to a different type.
	/// - Returns: A `APIClientCaller` with the mapped result type.
	///
	/// Example
	/// ```swift
	/// try await client.call(.http, as: .decodable)
	/// ```
	public func map<T>(_ mapper: @escaping (Result) throws -> T) -> APIClientCaller<Response, Value, T> {
		APIClientCaller<Response, Value, T> {
			try mapper(_call($0, $1, $2, $3, $4))
		} mockResult: {
			try mapper(_mockResult($0))
		}
	}
}

public extension APIClientCaller where Result == Value {

	/// A caller with a mocked response.
	static func mock(_ response: Response) -> APIClientCaller {
		APIClientCaller { _, _, _, _, serialize in
			try serialize(response) {}
		} mockResult: { value in
			value
		}
	}
}

public extension APIClient {

	/// Asynchronously performs a network call using the provided caller and serializer.
	/// - Parameters:
	///   - caller: A `APIClientCaller` instance.
	///   - serializer: A `Serializer` to process the response.
	/// - Returns: The result of the network call.
	///
	/// Example
	/// ```swift
	/// let value: SomeModel = try await client.call(.http, as: .decodable)
	/// ```
	func call<Response, Value, Result>(
		_ caller: APIClientCaller<Response, Value, AsyncThrowingValue<Result>>,
		as serializer: Serializer<Response, Value>,
		fileID: String = #fileID,
		line: UInt = #line
	) async throws -> Result {
		try await call(caller, as: serializer, fileID: fileID, line: line)()
	}

	/// Asynchronously performs a network call using the provided caller and serializer.
	/// - Parameters:
	///   - caller: A `APIClientCaller` instance.
	/// - Returns: The result of the network call.
	///
	/// Example
	/// ```swift
	/// let url = try await client.call(.httpDownload)
	/// ```
	func call<Value, Result>(
		_ caller: APIClientCaller<Value, Value, AsyncThrowingValue<Result>>,
		fileID: String = #fileID,
		line: UInt = #line
	) async throws -> Result {
		try await call(caller, as: .identity, fileID: fileID, line: line)()
	}

	/// Asynchronously performs a network call using the http caller and decodable serializer.
	/// - Returns: The result of the network call.
	func call<Result: Decodable>(fileID: String = #fileID, line: UInt = #line) async throws -> Result {
		try await call(.http, as: .decodable, fileID: fileID, line: line)
	}

	/// Asynchronously performs a network call using the http caller and decodable serializer.
	/// - Returns: The result of the network call.
	func callAsFunction<Result: Decodable>(fileID: String = #fileID, line: UInt = #line) async throws -> Result {
		try await call(fileID: fileID, line: line)
	}

	/// Asynchronously performs a network call using the http caller and void serializer.
	/// - Returns: The result of the network call.
	func call(fileID: String = #fileID, line: UInt = #line) async throws {
		try await call(.http, as: .void, fileID: fileID, line: line)
	}

	/// Asynchronously performs a network call using the http caller and void serializer.
	/// - Returns: The result of the network call.
	func callAsFunction(fileID: String = #fileID, line: UInt = #line) async throws {
		try await call(fileID: fileID, line: line)
	}

	/// Performs a network call using the provided caller and serializer.
	/// - Parameters:
	///   - caller: A `APIClientCaller` instance.
	/// - Returns: The result of the network call.
	///
	/// Example
	/// ```swift
	/// try client.call(.httpPublisher).sink { data in ... }
	/// ```
	func call<Value, Result>(
		_ caller: APIClientCaller<Value, Value, Result>,
		fileID: String = #fileID,
		line: UInt = #line
	) throws -> Result {
		try call(caller, as: .identity, fileID: fileID, line: line)
	}

	/// Performs a network call using the provided caller and serializer.
	/// - Parameters:
	///   - caller: A `APIClientCaller` instance.
	///   - serializer: A `Serializer` to process the response.
	/// - Returns: The result of the network call.
	///
	/// Example
	/// ```swift
	/// try client.call(.httpPublisher, as: .decodable).sink { ... }
	/// ```
	func call<Response, Value, Result>(
		_ caller: APIClientCaller<Response, Value, Result>,
		as serializer: Serializer<Response, Value>,
		fileID: String = #fileID,
		line: UInt = #line
	) throws -> Result {
		let uuid = UUID()
		do {
			return try withRequest { request, configs in
				let fileIDLine = configs.fileIDLine ?? FileIDLine(fileID: fileID, line: line)

				let bodyData = try configs.body?(configs)
				let body: RequestBody?
				if let bodyData {
					body = .data(bodyData)
				} else if let file = configs.file?(configs) {
					body = .file(file)
				} else {
					body = nil
				}

				if !configs.loggingComponents.isEmpty {
					let message = configs.loggingComponents.requestMessage(for: request, body: body, uuid: uuid, fileIDLine: fileIDLine)
					configs.logger.log(level: configs.logLevel, "\(message)")
				}

				if let mock = try configs.getMockIfNeeded(for: Value.self, serializer: serializer) {
					return try caller.mockResult(for: mock)
				}

				return try caller.call(uuid: uuid, request: request, body: body, configs: configs) { response, validate in
					do {
						try validate()
						return try serializer.serialize(response, configs)
					} catch {
						if let data = response as? Data, let failure = configs.errorDecoder.decodeError(data, configs) {
							throw failure
						}
						throw error
					}
				}
			}
		} catch {
			withConfigs { configs in
				let fileIDLine = configs.fileIDLine ?? FileIDLine(fileID: fileID, line: line)
				if !configs.loggingComponents.isEmpty {
					let message = configs.loggingComponents.errorMessage(
						uuid: uuid,
						error: error,
						fileIDLine: fileIDLine
					)
					configs.logger.error("\(message)")
				}
			}
			throw error
		}
	}

	/// Sets a closure to be executed before making a network call.
	///
	/// - Parameters:
	///   - closure: The closure to be executed before making a network call. It takes in an `inout URLRequest` and `APIClient.Configs` as parameters and can modify the request.
	/// - Returns: The `APIClient` instance.
	func beforeCall(_ closure: @escaping (inout URLRequest, APIClient.Configs) throws -> Void) -> APIClient {
		configs {
			let beforeCall = $0.beforeCall
			$0.beforeCall = { request, configs in
				try beforeCall(&request, configs)
				try closure(&request, configs)
			}
		}
	}
}

public extension APIClient.Configs {

	var beforeCall: (inout URLRequest, APIClient.Configs) throws -> Void {
		get { self[\.beforeCall] ?? { _, _ in } }
		set { self[\.beforeCall] = newValue }
	}
}
