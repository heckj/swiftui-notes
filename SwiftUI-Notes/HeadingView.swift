//
//  HeadingView.swift
//  SwiftUI-Notes
//
//  Created by Joseph Heck on 2/18/20.
//  Copyright © 2020 SwiftUI-Notes. All rights reserved.
//

import CoreLocation
import SwiftUI

struct HeadingView: View {
    @ObservedObject var locationModel: LocationProxy
    @State var lastHeading: CLHeading?
    @State var lastLocation: CLLocation?

    var body: some View {
        VStack {
            HStack {
                Text("authorization status:")
                Text(locationModel.authorizationStatusString())
            }
            if locationModel.authorizationStatus == .notDetermined {
                Button(action: {
                    self.locationModel.requestAuthorization()
                }) {
                    Image(systemName: "lock.shield")
                    Text("Request location authorization")
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 1)
                )
            }
            if self.lastHeading != nil {
                Text("Heading: ") + Text(String(self.lastHeading!.description))
            }
            if self.lastLocation != nil {
                Text("Location: ") + Text(lastLocation!.description)
                ZStack {
                    Circle()
                        .stroke(Color.blue, lineWidth: 1)

                    GeometryReader { geometry in
                        Path { path in
                            let minWidthHeight = min(geometry.size.height, geometry.size.width)

                            path.move(to: CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2))
                            path.addLine(to: CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2 - minWidthHeight / 2 + 5))
                        }
                        .stroke()
                        .rotation(Angle(degrees: self.lastLocation!.course))
                        .animation(.linear)
                    }
                }
            }
        }
        .onReceive(self.locationModel.headingPublisher) { heading in
            self.lastHeading = heading
        }
        .onReceive(self.locationModel.locationPublisher, perform: {
            self.lastLocation = $0
        })
    }
}

// MARK: - SwiftUI VIEW DEBUG

#if DEBUG
    var locproxy = LocationProxy()

    struct HeadingView_Previews: PreviewProvider {
        static var previews: some View {
            HeadingView(locationModel: locproxy)
        }
    }
#endif
