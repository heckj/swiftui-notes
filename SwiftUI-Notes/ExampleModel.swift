//
//  ExampleModel.swift
//  SwiftUI-Notes
//
//  Created by Joseph Heck on 6/15/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import SwiftUI
import Combine

class ExampleModel : BindableObject {
    typealias PublisherType = PassthroughSubject<Void, Never>

    var willChange = PassthroughSubject<Void, Never>()
    var didChange = PassthroughSubject<Void, Never>()

    var foo: String = "Ola, world!" // { didSet { didChange.send() }}
    var bar: Int = 3 // { didSet { didChange.send() }}
}
