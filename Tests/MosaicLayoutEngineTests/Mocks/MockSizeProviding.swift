//
//  MockSizeProviding.swift
//  
//
//  Created by John Davis on 5/22/22.
//

import CoreGraphics
import MosaicLayoutEngine

struct MockSizeProviding: LayoutSizeProviding{
    var sizeForLayout: CGSize { return CGSize(width: width, height: height) }
    
    let width: CGFloat
    let height: CGFloat
}
