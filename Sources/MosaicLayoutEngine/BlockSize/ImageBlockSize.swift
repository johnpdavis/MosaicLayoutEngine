//
//  ImageBlockSize.swift
//  MosaicLayoutEngine
//
//  Created by John Davis on 5/17/22.
//

import Foundation

class ImageBlockSize: BlockSize {
    let sizeProvider: LayoutSizeProviding
    
    init(width: Int, height: Int, sizeProvider: LayoutSizeProviding) {
        self.sizeProvider = sizeProvider
        super.init(width: width, height: height)
    }
}
