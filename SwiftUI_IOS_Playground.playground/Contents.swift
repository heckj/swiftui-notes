import SwiftUI
import PlaygroundSupport

struct MyView: View {
    var body: some View {
        Text("Hello, world!")
    }
}

let vc = UIHostingController(rootView: MyView())

// Present the view controller in the Live View window
PlaygroundPage.current.liveView = vc
