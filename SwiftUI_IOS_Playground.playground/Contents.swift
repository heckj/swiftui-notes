import Combine
import PlaygroundSupport
import SwiftUI

struct MyView: View {
    var body: some View {
        Text("Hello, world!")
    }
}

let vc = UIHostingController(rootView: MyView())

let foo = Publishers.Sequence<[String], Never>(sequence: ["foo", "bar", "baz"])
// this publishes the stream combo: <String>,<Never>

let reader = foo.sink { data in
    print(data)
}

// Present the view controller in the Live View window
PlaygroundPage.current.liveView = vc
