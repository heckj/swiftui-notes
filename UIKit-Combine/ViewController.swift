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

    var activityIndicator: UIActivityIndicatorView?

    /// creates a one-shot publisher that provides a GithubAPI User object as the end result
    /// - Parameter username: username to be retrieved from the Github API
    static func retrieveGithubUser(username: String) -> AnyPublisher<GithubAPIUser, Never> {

        if username.count < 3 {
            return Publishers.Empty<GithubAPIUser, Never>().eraseToAnyPublisher()
        }
        let assembledURL = String("https://api.github.com/users/\(username)")
        let publisher = URLSession.shared.dataTaskPublisher(for: URL(string: assembledURL)!)
            //Instance method 'flatMap(maxPublishers:_:)' requires the types 'Published<Value>.Publisher.Failure' (aka 'Never') and
            //'URLSession.DataTaskPublisher.Failure' (aka 'URLError') be equivalent
//            .handleEvents(receiveSubscription: { _ in
//                DispatchQueue.main.async {
//                    self.activityIndicator.startAnimating()
//                }
//            }, receiveCompletion: { _ in
//                DispatchQueue.main.async {
//                    self.activityIndicator.stopAnimating()
//                }
//            }, receiveCancel: {
//                DispatchQueue.main.async {
//                    self.activityIndicator.stopAnimating()
//                }
//            })
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                    httpResponse.statusCode == 200 else {
                        throw APIFailureCondition.invalidServerResponse
                }
                return data
            }
            .decode(type: GithubAPIUser.self, decoder: JSONDecoder())
//            if we wanted to make the return failure type exclude Error (e.g. <Never>) this is how we might do it
            .catch { err in
                return Publishers.Empty<GithubAPIUser, Never>()
            }
            .eraseToAnyPublisher()
        return publisher
    }

}

class ViewController: UIViewController {

    @IBOutlet weak var github_id_entry: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var repositoryCountLabel: UILabel!
    @IBOutlet weak var githubAvatarImageView: UIImageView!

    var repositoryCountSubscriber: AnyCancellable?
//    var avatarViewSubscriber: AnyCancellable?
    var usernameSubscriber: AnyCancellable?

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

        let usernameSub = $username
            .throttle(for: 0.5, scheduler: myBackgroundQueue, latest: true) // scheduler myBackGroundQueue publishes resulting elements into that queue...
            .removeDuplicates()
            .print("username pipeline: ")
            .map { username -> AnyPublisher<GithubAPIUser, Never> in
                return GithubAPI.retrieveGithubUser(username: username)
            }
            // type returned in the pipeline is a Publisher, so we use switchToLatest to flatten the values out of that
            // pipline to return down the chain, rather than returning a publisher down the pipeline.
            .switchToLatest()
            // using a sink to get the results from the API search lets us get not only
            // the user, but also any errors attempting to get it.
            .receive(on: RunLoop.main)
            .sink { someValue in
                self.githubUserData = someValue
            }
        usernameSubscriber = AnyCancellable(usernameSub)

        // using .assign() on the other hand (which returns an AnyCancellable) *DOES* require a Failure type of <Never>
        repositoryCountSubscriber = $githubUserData
            .print("github user data: ")
            .map { userData -> String in
                if let userData = userData {
                    return String(userData.public_repos)
                }
                return "unknown"
            }
            .receive(on: RunLoop.main)
            .assign(to: \.text, on: repositoryCountLabel)

        let _ = $githubUserData
            .filter({ possibleUser -> Bool in
                possibleUser != nil
            })
            .print("avatar image for user")
            .map { userData -> AnyPublisher<UIImage, Never> in
                guard let userData = userData else {
                    return Just(UIImage()).eraseToAnyPublisher()
                }
                return URLSession.shared.dataTaskPublisher(for: URL(string: userData.avatar_url)!)
                    .map { $0.data }
                    .map { UIImage(data: $0)!}
                    .subscribe(on: self.myBackgroundQueue)
                    .catch { err in
                        return Just(UIImage())
                    }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .subscribe(on: myBackgroundQueue)
            .receive(on: RunLoop.main)
            // .assign(to: \.image, on: self.githubAvatarImageView) // getting compiler error: Type of expression is ambiguous without more context
            .sink(receiveValue: { image in
                self.githubAvatarImageView.image = image
            })
    }

}

