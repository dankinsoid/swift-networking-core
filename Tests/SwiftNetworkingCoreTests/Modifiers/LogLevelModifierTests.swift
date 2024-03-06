import Foundation
import Logging
@testable import SwiftNetworkingCore
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest

final class LogLevelModifierTests: XCTestCase {

	func testLogLevel() {
		let client = NetworkClient(baseURL: URL(string: "https://example.com")!)
		let modifiedClient = client.log(level: .debug)

        XCTAssertEqual(modifiedClient.configs().logger.logLevel, .debug)
	}

	func testLogger() {
		let client = NetworkClient(baseURL: URL(string: "https://example.com")!)
		let modifiedClient = client.log(level: .info)

		XCTAssertEqual(modifiedClient.configs().logger.logLevel, .info)
	}
}
