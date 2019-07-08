//
//  ViewController.swift
//  UIKit-Combine
//
//  Created by Joseph Heck on 7/7/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import UIKit
import Combine

enum APIFailureCondition: Error {
    case invalidServerResponse
}

private struct GithubAPIUser: Decodable {
    let login: String
    let public_repos: Int
    let avatar_url: String
}

private struct GithubAPI {
    // I've also seen this kind of example setup with a class and func's on the class, rather than a struct...

    /// creates a one-shot publisher that provides a GithubAPI User object as the end result
    /// - Parameter username: username to be retrieved from the Github API
    static func retrieveGithubUser(username: String) -> AnyPublisher<GithubAPIUser, Error> {

        if username.count < 3 {
            return Publishers.Empty<GithubAPIUser, Error>().eraseToAnyPublisher()
        }
        let assembledURL = String("https://api.github.com/users/\(username)")
        let publisher = URLSession.shared.dataTaskPublisher(for: URL(string: assembledURL)!)
                //Instance method 'flatMap(maxPublishers:_:)' requires the types 'Published<Value>.Publisher.Failure' (aka 'Never') and 'URLSession.DataTaskPublisher.Failure' (aka 'URLError') be equivalent
                .tryMap { data, response -> Data in
                    guard let httpResponse = response as? HTTPURLResponse,
                        httpResponse.statusCode == 200 else {
                            throw APIFailureCondition.invalidServerResponse
                    }
                    return data
            }
            .decode(type: GithubAPIUser.self, decoder: JSONDecoder())
//            if we wanted to make the return failure type exclude Error (e.g. <Never>) this is how we might do it
//            .catch { err in
//                return Publishers.Empty<GithubAPIUser, Never>()
//            }
            .eraseToAnyPublisher()
        return publisher
    }

}

class ViewController: UIViewController {

    @IBOutlet weak var github_id_entry: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var repositoryCountLabel: UILabel!
    var repositoryCountSubscriber: AnyCancellable?

    // username from the github_id_entry field, updated via IBAction
    @Published var username: String = ""

    // github user retrieved from the API publisher. As it's updated, it is "wired" to update UI elements
    @Published private var githubUserData: GithubAPIUser? = nil

    // publisher reference for this is $username, of type <String, Never>
    var myBackgroundQueue: DispatchQueue = DispatchQueue(label: "viewControllerBackgroundQueue")

    // MARK - Actions

    @IBAction func githubIdChanged(_ sender: UITextField) {
        username = sender.text ?? ""
        print("Set username to ", username)
    }

    // MARK - lifecycle methods

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        _ = $username
            .throttle(for: 0.5, scheduler: myBackgroundQueue, latest: true) // scheduler myBackGroundQueue publishes resulting elements into that queue...
            .removeDuplicates()
            .print("username pipeline: ")
            .tryMap { username -> AnyPublisher<GithubAPIUser, Error> in
                return GithubAPI.retrieveGithubUser(username: username)
            }
            // type returned in the pipeline is a Publisher, so we use switchToLatest to flatten the values out of that
            // pipline to return down the chain, rather than returning a publisher down the pipeline.
            .switchToLatest()
            // using a sink to get the results from the API search lets us get not only
            // the user, but also any errors attempting to get it.
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                //NOTE(heckj): whenever sink receives a failure completion message it sends
                // a cancel() back up the pipe, stopping any further updates...
                switch completion {
                case .failure(let anError):
                    print("received error: ", anError)
                    self.repositoryCountLabel.text = ""

                    if let error = anError as? APIFailureCondition {
                        switch error {
                        case .invalidServerResponse:
                            print("Unable to retrieve the user from Github API")
                        }
                    } else {
                        // error returned wasn't one we interpretted
                        print("Unable to communicate with GitHub API to get the user")
                    }

                case .finished:
                    break
                }

            }, receiveValue: { someValue in
                self.githubUserData = someValue
            })

        // using .assign() on the other hand (which returns an AnyCancellable) *DOES* require a Failure type of <Never>
        repositoryCountSubscriber = $githubUserData
            .map { userData -> String in
                if let userData = userData {
                    return String(userData.public_repos)
                }
                return "unknown"

            }
            .receive(on: RunLoop.main)
            .assign(to: \.text, on: repositoryCountLabel)

    }

}

