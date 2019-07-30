//
//  ContentView.swift
//  SwiftUI-Notes
//
//  Created by Joseph Heck on 6/12/19.
//  Copyright © 2019 SwiftUI-Notes. All rights reserved.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {

    func makeUIView(context: Context) -> MKMapView {
        MKMapView(frame: .zero)
    }

    func updateUIView(_ view: MKMapView, context: Context) {
        let coordinate = CLLocationCoordinate2D(
            latitude: 47.6418507, longitude: -122.3479701)
        let span = MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        view.setRegion(region, animated: true)
    }

}

/// the sample ContentView
struct ContentView : View {
    @ObservedObject var model: ExampleModel

    func clickityButton() {

    }

    var body: some View {
        VStack {
            Text(model.foo)
                .font(.title)
                .foregroundColor(.blue)

            Text("so here's something simpler")
                .font(.caption)
                .foregroundColor(.black)

            Spacer()

            MapView()
        }
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
