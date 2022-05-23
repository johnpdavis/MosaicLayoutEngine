//
//  BlockSlot.swift
//  MosaicLayoutEngine
//
//  Created by John Davis on 5/22/22.
//

import Foundation

class BlockSlot {
    var originColumn: Int
    var originRow: Int
    var blockSize: BlockSize
    
    init(originColumn: Int, originRow: Int, blockSize: BlockSize) {
        self.originColumn = originColumn
        self.originRow = originRow
        self.blockSize = blockSize
    }
    
    var maxY: Int { originRow + blockSize.height }
    var maxX: Int { originColumn + blockSize.width }

    func horizontallyOverlaps(_ other: BlockSlot) -> Bool {
        // Given:
        // A---B and
        // C---D
        
        // D < A  If either case is true the lines are not overlapping.
        // B < C
        
        let otherStart = other.originColumn
        let otherEnd = other.originColumn + other.blockSize.width
        
        let slotStart = originColumn
        let slotEnd = originColumn + blockSize.width
        
        let notOverlapping = slotEnd <= otherStart || otherEnd <= slotStart
        return !notOverlapping
    }
}

extension BlockSlot: CustomStringConvertible {
    var description: String {
        "ColumOrigin: X\(originColumn),Y\(originRow) -0- BlockSize: W\(blockSize.width)xH\(blockSize.height)"
    }
}

extension BlockSlot: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(originColumn)
        hasher.combine(originRow)
        hasher.combine(blockSize)
    }
    
    static func == (lhs: BlockSlot, rhs: BlockSlot) -> Bool {
        return lhs.originColumn == rhs.originColumn &&
            lhs.originRow == rhs.originRow &&
            lhs.blockSize == rhs.blockSize
    }
}
