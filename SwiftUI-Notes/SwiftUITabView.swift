//
//  SwiftUITabView.swift
//  SwiftUI-Notes
//
//  Created by Joseph Heck on 2/5/20.
//  Copyright © 2020 SwiftUI-Notes. All rights reserved.
//

import SwiftUI

struct SwiftUITabView: View {
    var body: some View {
        TabView {
            SampleView()
                .tabItem {
                    Image(systemName: "1.circle")
                    Text("Reactive Form")
                }
            Text("Second Tab")
                .tabItem {
                    Image(systemName: "2.square.fill")
                    Text("Dos")
                }
        }
        .font(.headline)
    }
}

struct SwiftUITabView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUITabView()
    }
}
