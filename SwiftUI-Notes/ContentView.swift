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
    var body: some View {
        Text("Hello World")
    }
}

// MARK: - SwiftUI VIEW DEBUG

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
