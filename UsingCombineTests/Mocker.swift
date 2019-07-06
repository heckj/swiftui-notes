//
//  Mocker.swift
//  Rabbit
//
//  Created by Antoine van der Lee on 04/05/2017.
//  Copyright © 2017 WeTransfer. All rights reserved.
//

import Foundation

/// Can be used for registering Mocked data, returned by the `MockingURLProtocol`.
public struct Mocker {
    
    public enum HTTPVersion: String {
        case http1_0 = "HTTP/1.0"
        case http1_1 = "HTTP/1.1"
        case http2_0 = "HTTP/2.0"
    }
    
    /// The shared instance of the Mocker, can be used to register and return mocks.
    internal static var shared = Mocker()
    
    /// The HTTP Version to use in the mocked response.
    public static var httpVersion: HTTPVersion = HTTPVersion.http1_1
    
    /// The registrated mocks.
    private(set) var mocks: [Mock] = []
    
    /// URLs to ignore for mocking.
    private(set) var ignoredURLs: [URL] = []
    
    private init() {
        // Whenever someone is requesting the Mocker, we want the URL protocol to be activated.
        URLProtocol.registerClass(MockingURLProtocol.self)
    }
    
    /// Register new Mocked data. If a mock for the same URL and HTTPMethod exists, it will be overwritten.
    ///
    /// - Parameter mock: The Mock to be registered for future requests.
    public static func register(_ mock: Mock) {
        /// Delete the Mock if it was already registered.
        shared.mocks.removeAll(where: { $0 == mock })
        shared.mocks.append(mock)
    }
    
    /// Register an URL to ignore for mocking. This will let the URL work as if the Mocker doesn't exist.
    ///
    /// - Parameter url: The URL to mock.
    public static func ignore(_ url: URL) {
        shared.ignoredURLs.append(url)
    }
    
    /// Checks if the passed URL should be handled by the Mocker. If the URL is registered to be ignored, it will not handle the URL.
    ///
    /// - Parameter url: The URL to check for.
    /// - Returns: `true` if it should be mocked, `false` if the URL is registered as ignored.
    public static func shouldHandle(_ url: URL) -> Bool {
        return !shared.ignoredURLs.contains(url)
    }

    /// Removes all registered mocks. Use this method in your tearDown function to make sure a Mock is not used in any other test.
    public static func removeAll() {
        shared.mocks.removeAll()
    }
    
    /// Retrieve a Mock for the given request. Matches on `request.url` and `request.httpMethod`.
    ///
    /// - Parameter request: The request to search for a mock.
    /// - Returns: A mock if found, `nil` if there's no mocked data registered for the given request.
    static func mock(for request: URLRequest) -> Mock? {
        /// First check for specific URLs
        if let specificMock = shared.mocks.first(where: { $0 == request && $0.fileExtensions == nil }) {
            return specificMock
        }
        /// Second, check for generic file extension Mocks
        return shared.mocks.first(where: { $0 == request })
    }
}
