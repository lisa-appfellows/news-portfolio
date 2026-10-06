//
//  ImageLoadPhase.swift
//  NewsPortfolio
//
//  Created by Lisa Fellows on 2026-10-05.
//

import UIKit

enum ImageLoadPhase: @unchecked Sendable {
    case loading
    case success(UIImage)
    case error
}
