//
//  LayoutSizeProviding.swift
//  MosaicLayoutEngine
//
//  Created by John Davis on 5/16/22.
//

import CoreGraphics

public protocol LayoutSizeProviding {
    var sizeForLayout: CGSize { get }
}

extension LayoutSizeProviding {
    var width: CGFloat {
        return sizeForLayout.width
    }
    
    var height: CGFloat {
        return sizeForLayout.height
    }
}
