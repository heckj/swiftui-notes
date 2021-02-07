//
//  PublisherView.swift
//  SwiftUI-Notes
//
//  Created by Joseph Heck on 2/7/21.
//  Copyright © 2021 SwiftUI-Notes. All rights reserved.
//

import SwiftUI
import Combine

struct PublisherBindingExampleView: View {
    
    @State private var filterText = ""
    @State private var delayed = ""
    
    private var relay = PassthroughSubject<String,Never>()
    private var debouncedPublisher: AnyPublisher<String, Never>
    
    init() {
        self.debouncedPublisher = relay
            .debounce(for: 1, scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    var body: some View {
        VStack {
            TextField("filter", text: $filterText)
                .onChange(of: filterText, perform: { value in
                    relay.send(value)
                })
            Text("Delayed result: \(delayed)")
                .onReceive(debouncedPublisher, perform: { value in
                    delayed = value
                })
        }
    }
}

struct PublisherView_Previews: PreviewProvider {
    static var previews: some View {
        PublisherBindingExampleView()
    }
}
