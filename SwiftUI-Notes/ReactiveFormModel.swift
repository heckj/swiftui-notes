//
//  ReactiveFormModel.swift
//  SwiftUI-Notes
//
//  Created by Joseph Heck on 2/5/20.
//  Copyright © 2020 SwiftUI-Notes. All rights reserved.
//

import Foundation
import Combine

class ReactiveFormModel : ObservableObject {

    @Published var firstEntry: String = "" {
        didSet {
            firstEntryPublisher.send(self.firstEntry)
        }
    }
    private let firstEntryPublisher = CurrentValueSubject<String, Never>("")
    
    // NOTE(heckj): this didSet {} structure and the CurrentValueSubject
    // firstEntryPublisher could be removed.
    //
    // The @Published property wrapper presents a publisher
    // for the values as they change.
    //
    // It's not entirely obvious, but the relevant publisher is
    // _firstEntry.projectedValue which is an instance of the type
    // Published<String>.Publisher - with an Output type of String
    // and a failure type of Never.

    @Published var secondEntry: String = "" {
        didSet {
            secondEntryPublisher.send(self.secondEntry)
        }
    }
    private let secondEntryPublisher = CurrentValueSubject<String, Never>("")

    @Published var validationMessages = [String]()
    private var cancellableSet: Set<AnyCancellable> = []

    var submitAllowed: AnyPublisher<Bool, Never>
    
    init() {

        let validationPipeline = Publishers.CombineLatest(firstEntryPublisher, secondEntryPublisher)
            .map { (arg) -> [String] in
                var diagMsgs = [String]()
                let (value, value_repeat) = arg
                if !(value_repeat == value) {
                    diagMsgs.append("Values for fields must match.")
                }
                if (value.count < 5 || value_repeat.count < 5) {
                    diagMsgs.append("Please enter values of at least 5 characters.")
                }
                return diagMsgs
            }

        submitAllowed = validationPipeline
            .map { stringArray in
                return stringArray.count < 1
            }
            .eraseToAnyPublisher()

        let _ = validationPipeline
            .assign(to: \.validationMessages, on: self)
            .store(in: &cancellableSet)
    }
}
