//
//  GithubAPI.swift
//  UIKit-Combine
//
//  Created by Joseph Heck on 7/13/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import Combine
import Foundation

enum APIFailureCondition: Error {
    case invalidServerResponse
}

struct GithubAPIUser: Decodable {
    // A very *small* subset of the content available about
    //  a github API user for example:
    // https://api.github.com/users/heckj
    let login: String
    let public_repos: Int
    let avatar_url: String
}

enum GithubAPI {
    // NOTE(heckj): I've also seen this kind of API access
    // object set up with with a class and static methods on the class.
    // I don't know that there's a specific benefit to make this a value
    // type/struct with a function on it.

    /// externally accessible publsher that indicates that network activity is happening in the API proxy
    static let networkActivityPublisher = PassthroughSubject<Bool, Never>()

    /// creates a one-shot publisher that provides a GithubAPI User
    /// object as the end result. This method was specifically designed to
    /// return a list of 1 object, as opposed to the object itself to make
    /// it easier to distinguish a "no user" result (empty list)
    /// representation that could be dealt with more easily in a Combine
    /// pipeline than an optional value. The expected return types is a
    /// Publisher that returns either an empty list, or a list of one
    /// GithubAPUser, and with a failure return type of Never, so it's
    /// suitable for recurring pipeline updates working with a @Published
    /// data source.
    /// - Parameter username: username to be retrieved from the Github API
    static func retrieveGithubUser(username: String) -> AnyPublisher<[GithubAPIUser], Never> {
        if username.count < 3 {
            return Just([]).eraseToAnyPublisher()
            // return Publishers.Empty<GithubAPIUser, Never>()
            //    .eraseToAnyPublisher()
        }
        let assembledURL = String("https://api.github.com/users/\(username)")
        let publisher = URLSession.shared.dataTaskPublisher(for: URL(string: assembledURL)!)
            .handleEvents(receiveSubscription: { _ in
                networkActivityPublisher.send(true)
            }, receiveCompletion: { _ in
                networkActivityPublisher.send(false)
            }, receiveCancel: {
                networkActivityPublisher.send(false)
            })
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200
                else {
                    throw APIFailureCondition.invalidServerResponse
                }
                return data
            }
            .decode(type: GithubAPIUser.self, decoder: JSONDecoder())
            .map {
                [$0]
            }
            .replaceError(with: [])
            // ^^ when I originally wrote this method, I was returning
            // a GithubAPIUser? optional, and then a GithubAPIUser without
            // optional. I ended up converting this to return an empty
            // list as the "error output replacement" so that I could
            // represent that the current value requested didn't *have* a
            // correct github API response.
            .eraseToAnyPublisher()
        return publisher
    }
}
