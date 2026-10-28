//------------------------------------------------------------------------------
//  File:          ResetDataView.swift
//  Author(s):     Bread Financial
//
//  Description:   Screen with a button that clears the test app's persisted data.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import SwiftUI

struct ResetDataView: View {
    @State private var didReset = false

    var body: some View {
        Form {
            Section {
                Button("Reset App Data", role: .destructive) {
                    AppDataReset.clear()
                    didReset = true
                }
            }
            if didReset {
                Section {
                    Text("App data cleared.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
        }.onDisappear {
            didReset = false
        }
    }
}
