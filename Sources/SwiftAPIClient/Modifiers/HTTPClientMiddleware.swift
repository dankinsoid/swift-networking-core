import Foundation

public protocol HTTPClientMiddleware {

	func execute<T>(
		request: HTTPRequest,
		body: RequestBody?,
		configs: APIClient.Configs,
		next: (HTTPRequest, RequestBody?, APIClient.Configs) async throws -> (T, HTTPResponse)
	) async throws -> (T, HTTPResponse)
}

public extension APIClient {

	/// Add a modifier to the HTTP client.
	func httpClientMiddleware(_ middleware: some HTTPClientMiddleware) -> APIClient {
		configs {
			$0.httpClientArrayMiddleware.middlewares.append(middleware)
		}
	}
}

public extension APIClient.Configs {

	var httpClientMiddleware: HTTPClientMiddleware {
		httpClientArrayMiddleware
	}
}

private extension APIClient.Configs {

	var httpClientArrayMiddleware: HTTPClientArrayMiddleware {
		get { self[\.httpClientArrayMiddleware] ?? HTTPClientArrayMiddleware() }
		set { self[\.httpClientArrayMiddleware] = newValue }
	}
}

private struct HTTPClientArrayMiddleware: HTTPClientMiddleware {

	var middlewares: [HTTPClientMiddleware] = []

	func execute<T>(
		request: HTTPRequest,
		body: RequestBody?,
		configs: APIClient.Configs,
		next: (HTTPRequest, RequestBody?, APIClient.Configs) async throws -> (T, HTTPResponse)
	) async throws -> (T, HTTPResponse) {
		var next = next
		for middleware in middlewares {
			next = { [next] in try await middleware.execute(request: $0, body: $1, configs: $2, next: next) }
		}
		return try await next(request, body, configs)
	}
}
