//
//  RemoteImageView.swift
//  NewsPortfolio
//
//  Created by Lisa Fellows on 2026-10-05.
//

import SwiftUI
import UIKit

private struct ImageLoaderKey: EnvironmentKey {
    static let defaultValue: ImageLoader? = nil
}

extension EnvironmentValues {
    var imageLoader: ImageLoader? {
        get { self[ImageLoaderKey.self] }
        set { self[ImageLoaderKey.self] = newValue }
    }
}

/// Loads via shared `ImageLoader`. Cancelling `task` drops this subscription only.
struct RemoteImageView<Placeholder: View>: View {
    let url: URL
    let loader: ImageLoader
    @ViewBuilder var placeholder: () -> Placeholder

    @State private var phase: ImageLoadPhase = .loading

    var body: some View {
        Group {
            switch phase {
            case .loading, .error:
                placeholder()
            case .success(let image):
                Color.clear
                    .overlay {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
            }
        }
        .task(id: url) {
            for await next in loader.load(url) {
                phase = next
            }
        }
    }
}
