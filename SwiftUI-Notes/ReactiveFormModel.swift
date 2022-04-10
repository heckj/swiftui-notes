//
//  ReactiveFormModel.swift
//  SwiftUI-Notes
//
//  Created by Joseph Heck on 2/5/20.
//  Copyright © 2020 SwiftUI-Notes. All rights reserved.
//

import Combine
import Foundation

class ReactiveFormModel: ObservableObject {
    @Published var firstEntry: String = ""
    @Published var secondEntry: String = ""
    @Published var validationMessages = [String]()

    private var cancellableSet: Set<AnyCancellable> = []

    var submitAllowed: AnyPublisher<Bool, Never>!

    init() {
        let validationPipeline = Publishers.CombineLatest($firstEntry, $secondEntry)
            .map { arg -> [String] in
                var diagMsgs = [String]()
                let (value, value_repeat) = arg
                if !(value_repeat == value) {
                    diagMsgs.append("Values for fields must match.")
                }
                if value.count < 5 || value_repeat.count < 5 {
                    diagMsgs.append("Please enter values of at least 5 characters.")
                }
                return diagMsgs
            }
            .share()

        submitAllowed = validationPipeline
            .map { stringArray in
                stringArray.count < 1
            }
            .eraseToAnyPublisher()

        _ = validationPipeline
            .assign(to: \.validationMessages, on: self)
            .store(in: &cancellableSet)
    }
}
