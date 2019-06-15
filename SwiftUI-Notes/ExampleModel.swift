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

    var foo: String = "Ola, world!" // { didSet { didChange.send() }}
    var bar: Int = 3 // { didSet { didChange.send() }}

    var didChange = PassthroughSubject<Void, Never>()
    
}
