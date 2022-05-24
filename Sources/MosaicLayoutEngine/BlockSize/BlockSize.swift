//
//  BlockSize.swift
//  MosaicLayoutEngine
//
//  Created by John Davis on 5/16/22.
//

import Foundation

public class BlockSize: CustomDebugStringConvertible {
    
    // MARK: -Properties
    var width: Int
    var height: Int
    
    public var debugDescription: String {
        return "BlockSize: \(width)x\(height)"
    }
    
    //MARK: -  Initialization
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
    
    static var zero: BlockSize {
        BlockSize(width: 0, height: 0)
    }
}

// MARK: - Size Modifiers
extension BlockSize {
    //************************************************************************
    // reduce will subtract one from the width of the block and height until
    // only 1 remains.
    //************************************************************************
    public func reduce() {
        if self.width > 1 {
            self.width -= 1
        }
        
        if self.height > 1 {
            self.height -= 1
        }
    }
}

// MARK: - Hashable
extension BlockSize: Hashable {
    public static func == (lhs: BlockSize, rhs: BlockSize) -> Bool {
        return lhs.width == rhs.width && lhs.height == rhs.height
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(width)
        hasher.combine(height)
    }
}
