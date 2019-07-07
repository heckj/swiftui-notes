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

    @Published var username: String = ""

    var myBackgroundQueue: DispatchQueue = DispatchQueue(label: "viewControllerBackgroundQueue")

    var APIwarning: PassthroughSubject = PassthroughSubject<String, Never>()

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
                .catch { _ in
                    Publishers.Empty()
                }
                .subscribe(on: self.myBackgroundQueue)
        }
        .eraseToAnyPublisher()
    }

    @IBAction func githubIdChanged(_ sender: UITextField) {
        username = sender.text ?? ""
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

    }

}

