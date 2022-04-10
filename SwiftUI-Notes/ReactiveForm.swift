//
//  ReactiveForm.swift
//  SwiftUI-Notes
//
//  Created by Joseph Heck on 2/5/20.
//  Copyright © 2020 SwiftUI-Notes. All rights reserved.
//

import SwiftUI

struct ReactiveForm: View {
    @ObservedObject var model: ReactiveFormModel
    // $model is a ObservedObject<ExampleModel>.Wrapper
    // and $model.objectWillChange is a Binding<ObservableObjectPublisher>
    @State private var buttonIsDisabled = true
    // $buttonIsDisabled is a Binding<Bool>

    var body: some View {
        VStack {
            Text("Reactive Form")
                .font(.headline)

            Form {
                TextField("first entry", text: $model.firstEntry)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                    .padding()

                TextField("second entry", text: $model.secondEntry)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .multilineTextAlignment(.center)
                    .padding()

                VStack {
                    ForEach(model.validationMessages, id: \.self) { msg in
                        Text(msg)
                            .foregroundColor(.red)
                            .font(.callout)
                    }
                }
            }

            Button(action: {}) {
                Text("Submit")
            }.disabled(buttonIsDisabled)
                .onReceive(model.submitAllowed) { submitAllowed in
                    self.buttonIsDisabled = !submitAllowed
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 1)
                )

            Spacer()
        }
    }
}

// MARK: - SwiftUI VIEW DEBUG

#if DEBUG
    var localModel = ReactiveFormModel()

    struct ReactiveForm_Previews: PreviewProvider {
        static var previews: some View {
            ReactiveForm(model: localModel)
        }
    }
#endif
