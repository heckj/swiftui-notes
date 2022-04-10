//
//  MockingURLProtocol.swift
//  Rabbit
//
//  Created by Antoine van der Lee on 04/05/2017.
//  Copyright © 2017 WeTransfer. All rights reserved.
//

import Foundation

/// The protocol which can be used to send Mocked data back. Use the `Mocker` to register `Mock` data
public final class MockingURLProtocol: URLProtocol {
    enum Error: Swift.Error {
        case missingMockedData(url: String)
        case explicitMockFailure(url: String)
    }

    /// Returns Mocked data based on the mocks register in the `Mocker`. Will end up in an error when no Mock data is found for the request.
    override public func startLoading() {
        guard
            let mock = Mocker.mock(for: request),
            let response = HTTPURLResponse(url: mock.url, statusCode: mock.statusCode, httpVersion: Mocker.httpVersion.rawValue, headerFields: mock.headers),
            let data = mock.data(for: request)
        else {
            // swiftlint:disable nslog_prohibited
            print("\n\n 🚨 No mocked data found for url \(String(describing: request.url?.absoluteString)) method \(String(describing: request.httpMethod)). Did you forget to use `register()`? 🚨 \n\n")
            client?.urlProtocol(self, didFailWithError: Error.missingMockedData(url: String(describing: request.url?.absoluteString)))
            return
        }

        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).asyncAfter(deadline: .now() + (mock.delay ?? DispatchTimeInterval.seconds(0))) {
            if let redirectLocation = data.redirectLocation {
                self.client?.urlProtocol(self, wasRedirectedTo: URLRequest(url: redirectLocation), redirectResponse: response)
            } else {
                if mock.reportFailure {
                    self.client?.urlProtocol(self, didFailWithError: Error.explicitMockFailure(url: String(describing: self.request.url?.absoluteString)))
                } else {
                    self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    self.client?.urlProtocol(self, didLoad: data)
                    self.client?.urlProtocolDidFinishLoading(self)
                }
            }
            mock.completion?()
        }
    }

    /// Overrides needed to define a valid inheritance of URLProtocol.
    override public class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url else { return false }
        return Mocker.shouldHandle(url)
    }

    /// Implementation does nothing, but is needed for a valid inheritance of URLProtocol.
    override public func stopLoading() {
        // No implementation needed
    }

    /// Simply sends back the passed request. Implementation is needed for a valid inheritance of URLProtocol.
    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
}

private extension Data {
    /// Returns the redirect location from the raw HTTP response if exists.
    var redirectLocation: URL? {
        let locationComponent = String(data: self, encoding: String.Encoding.utf8)?.components(separatedBy: "\n").first(where: { value -> Bool in
            value.contains("Location:")
        })

        guard let redirectLocationString = locationComponent?.components(separatedBy: "Location:").last, let redirectLocation = URL(string: redirectLocationString.trimmingCharacters(in: NSCharacterSet.whitespaces)) else {
            return nil
        }
        return redirectLocation
    }
}
