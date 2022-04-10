//
//  ContentView.swift
//  SwiftUI-Notes
//
//  Created by Joseph Heck on 6/12/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import SwiftUI

/// the sample ContentView
struct ContentView: View {
    @ObservedObject var model: ReactiveFormModel

    var body: some View {
        TabView {
            ReactiveForm(model: model)
                .tabItem {
                    Image(systemName: "1.circle")
                    Text("Reactive Form")
                }

            HeadingView(locationModel: LocationProxy())
                .tabItem {
                    Image(systemName: "mappin.circle")
                    Text("Location")
                }
        }
    }
}

// MARK: - SwiftUI VIEW DEBUG

#if DEBUG
    var blah = ReactiveFormModel()

    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView(model: blah)
        }
    }
#endif
