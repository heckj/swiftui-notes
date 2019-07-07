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

class ViewController: UIViewController {

    @IBOutlet weak var github_id_entry: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var repositoryCountLabel: UILabel!

    // username from the github_id_entry field, updated via IBAction
    @Published var username: String = ""
    // publisher reference for this is $username, of type <String, Never>

    var myBackgroundQueue: DispatchQueue = DispatchQueue(label: "viewControllerBackgroundQueue")

    var APIwarning: PassthroughSubject = PassthroughSubject<String, Never>()
    var foo: AnyCancellable?

    private var githubUserData: AnyPublisher<GithubAPIUser, Never> {
        return $username
            .throttle(for: 0.5, scheduler: myBackgroundQueue, latest: true)
            .removeDuplicates()
            .map { username -> String in
                String("https://api.github.com/users/\(username)")
            }
            .flatMap { assembledURL in
                return URLSession.shared.dataTaskPublisher(for: URL(string: assembledURL)!)
                //Instance method 'flatMap(maxPublishers:_:)' requires the types 'Published<Value>.Publisher.Failure' (aka 'Never') and 'URLSession.DataTaskPublisher.Failure' (aka 'URLError') be equivalent
//                    .mapError({ err in
//                        // type in is URLError
//                        APIwarning.send(err.localizedDescription)
//                        return err
//                    })
                .tryMap { data, response -> Data in
                    guard let httpResponse = response as? HTTPURLResponse,
                        httpResponse.statusCode == 200 else {
                            throw APIFailureCondition.invalidServerResponse
                    }
                    return data
                }
                .decode(type: GithubAPIUser.self, decoder: JSONDecoder())
                .catch { err in
                    // the following lines cause a compiler failure:
                    /*
                     /Users/heckj/src/swiftui-notes/UIKit-Combine/ViewController.swift:45:35: error: ambiguous reference to member 'dataTaskPublisher(for:)'
                     return URLSession.shared.dataTaskPublisher(for: URL(string: assembledURL)!)
                     ~~~~~~~~~~~^~~~~~
                     Foundation.URLSession:3:17: note: found this candidate
                     public func dataTaskPublisher(for url: URL) -> URLSession.DataTaskPublisher
                     ^
                     Foundation.URLSession:4:17: note: found this candidate
                     public func dataTaskPublisher(for request: URLRequest) -> URLSession.DataTaskPublisher
                     ^
                     */
//                    if let myError = err as APIFailureCondition {
//                        APIwarning.send("No user with that name")
//                    } else {
//                        APIwarning.send("Unable to communicate with Github API")
//                    }
                    return Publishers.Empty()
                }
                .subscribe(on: self.myBackgroundQueue)
        }
        .eraseToAnyPublisher()
    }

    // MARK - Actions

    @IBAction func githubIdChanged(_ sender: UITextField) {
        username = sender.text ?? ""
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        //NOTE(heckj):
        // seems that if we use .sink() here to process the data, we can also capture and work on errors here
        // at the sink, rather than filtering them in the stream.
        _ = githubUserData
            .receive(on: RunLoop.main)
            .sink { user in
                print(user)
            }

        // using .assign() on the other hand (which returns an AnyCancellable) *DOES* require a Failure type of <Never>
        foo = githubUserData
            .map {
                String($0.public_repos)
        }
        .assign(to: \.text, on: repositoryCountLabel)

    }

}

