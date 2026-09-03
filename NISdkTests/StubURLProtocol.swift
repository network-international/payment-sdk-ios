//
//  StubURLProtocol.swift
//  NISdkTests
//
//  Intercepts the SDK's outgoing requests so the transaction service can be exercised without a
//  network. Install it by pointing `HTTPClient.sharedSession` at `StubURLProtocol.makeSession()`.
//

import Foundation
import XCTest
@testable import NISdk

final class StubURLProtocol: URLProtocol {

    struct Stub {
        var statusCode: Int = 200
        var headers: [String: String] = [:]
        var body: Data? = nil
        var error: Error? = nil

        static func json(_ raw: String, status: Int = 200, headers: [String: String] = [:]) -> Stub {
            Stub(statusCode: status,
                 headers: headers.merging(["Content-Type": "application/json"]) { a, _ in a },
                 body: Data(raw.utf8))
        }

        static func failure(_ error: Error) -> Stub {
            Stub(error: error)
        }
    }

    /// Answered for every request that has no more specific stub queued.
    static var defaultStub = Stub.json("{}")

    /// Consumed in order — lets a test drive a retry/poll sequence.
    private static var queue: [Stub] = []

    /// Every request the SDK made, in order, for assertions.
    private(set) static var recorded: [URLRequest] = []

    /// Bodies keyed by request index — `URLProtocol` strips `httpBody` from the request it hands
    /// back, so it has to be read off the body stream at intercept time.
    private(set) static var recordedBodies: [Data?] = []

    static func reset() {
        queue = []
        recorded = []
        recordedBodies = []
        defaultStub = .json("{}")
    }

    static func enqueue(_ stub: Stub) {
        queue.append(stub)
    }

    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: config)
    }

    // MARK: request accessors

    static var lastRequest: URLRequest? { recorded.last }
    static var lastBody: Data? { recordedBodies.last ?? nil }
    static var lastBodyString: String? { lastBody.flatMap { String(data: $0, encoding: .utf8) } }

    static var lastBodyJSON: [String: Any]? {
        guard let data = lastBody else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    static var requestCount: Int { recorded.count }

    // MARK: URLProtocol

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        StubURLProtocol.recorded.append(request)
        StubURLProtocol.recordedBodies.append(StubURLProtocol.body(of: request))

        let stub = StubURLProtocol.queue.isEmpty
            ? StubURLProtocol.defaultStub
            : StubURLProtocol.queue.removeFirst()

        if let error = stub.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        let response = HTTPURLResponse(url: request.url!,
                                       statusCode: stub.statusCode,
                                       httpVersion: "HTTP/1.1",
                                       headerFields: stub.headers)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        if let body = stub.body {
            client?.urlProtocol(self, didLoad: body)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    /// `URLSession` moves `httpBody` into `httpBodyStream` before the protocol sees it.
    private static func body(of request: URLRequest) -> Data? {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        let size = 4096
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: size)
            if read <= 0 { break }
            data.append(buffer, count: read)
        }
        return data.isEmpty ? nil : data
    }
}

/// Base class that installs the stub session and restores the real one afterwards.
class TransactionServiceTestCase: XCTestCase {

    private var realSession: URLSession!
    var sut: TransactionServiceAdapter!

    override func setUp() {
        super.setUp()
        StubURLProtocol.reset()
        realSession = HTTPClient.sharedSession
        HTTPClient.sharedSession = StubURLProtocol.makeSession()
        sut = TransactionServiceAdapter()
    }

    override func tearDown() {
        HTTPClient.sharedSession = realSession
        StubURLProtocol.reset()
        sut = nil
        super.tearDown()
    }

    /// Runs `work`, waiting for it to call back. The adapter completes on a background queue.
    @discardableResult
    func awaitResponse(_ description: String = "response",
                       file: StaticString = #filePath,
                       line: UInt = #line,
                       _ work: (@escaping HttpResponseCallback) -> Void) -> (Data?, URLResponse?, Error?) {
        let expectation = expectation(description: description)
        var result: (Data?, URLResponse?, Error?) = (nil, nil, nil)
        work { data, response, error in
            result = (data, response, error)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2) { error in
            if error != nil {
                XCTFail("\(description): completion was never called", file: file, line: line)
            }
        }
        return result
    }

    var lastRequest: URLRequest {
        guard let request = StubURLProtocol.lastRequest else {
            XCTFail("no request was made")
            return URLRequest(url: URL(string: "about:blank")!)
        }
        return request
    }

    func header(_ name: String) -> String? {
        lastRequest.value(forHTTPHeaderField: name)
    }
}
