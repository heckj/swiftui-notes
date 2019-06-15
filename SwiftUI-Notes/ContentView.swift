//
//  ContentView.swift
//  SwiftUI-Notes
//
//  Created by Joseph Heck on 6/12/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import SwiftUI

/// the sample ContentView
struct ContentView : View {
    @ObjectBinding var model: ExampleModel
    
    var body: some View {
        Text(model.foo)
    }
}

// MARK: - SwiftUI VIEW DEBUG

#if DEBUG
var blah = ExampleModel()

struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView(model: blah)
    }
}
#endif
