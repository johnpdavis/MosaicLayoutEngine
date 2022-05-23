//
//  BlockSlot.swift
//  
//
//  Created by John Davis on 5/22/22.
//

@testable import MosaicLayoutEngine
import XCTest

class BlockSlotTests: XCTestCase {
    func testProperties_zeroOrigin() throws {
        let slot = BlockSlot(originColumn: 0, originRow: 0, blockSize: .init(width: 4, height: 5))
        
        XCTAssertEqual(5, slot.maxY)
        XCTAssertEqual(4, slot.maxX)
    }
    
    func testProperties_nonZeroOrigin() throws {
        let slot = BlockSlot(originColumn: 1, originRow: 1, blockSize: .init(width: 4, height: 5))
        
        XCTAssertEqual(6, slot.maxY)
        XCTAssertEqual(5, slot.maxX)
    }
    
    func testOverlap_leftside() {
        // 1: [  ,  ,  ]
        // 2:    [  ,  ,  ]
        let slot1 = BlockSlot(originColumn: 0, originRow: 0, blockSize: .init(width: 3, height: 3))
        let slot2 = BlockSlot(originColumn: 1, originRow: 1, blockSize: .init(width: 3, height: 3))
        
        let overlaps = slot1.horizontallyOverlaps(slot2)
        XCTAssertTrue(overlaps)
    }
    
    func testOverlap_middle() {
        // 1: [  ,  ,  ]
        // 2:    [  ]
        let slot1 = BlockSlot(originColumn: 0, originRow: 0, blockSize: .init(width: 3, height: 3))
        let slot2 = BlockSlot(originColumn: 1, originRow: 1, blockSize: .init(width: 1, height: 1))
        
        let overlaps = slot1.horizontallyOverlaps(slot2)
        XCTAssertTrue(overlaps)
    }
    
    func testOverlap_off() {
        // 1: [  ]
        // 2:    [  ]
        let slot1 = BlockSlot(originColumn: 0, originRow: 0, blockSize: .init(width: 1, height: 1))
        let slot2 = BlockSlot(originColumn: 1, originRow: 1, blockSize: .init(width: 1, height: 1))
        
        let overlaps = slot1.horizontallyOverlaps(slot2)
        XCTAssertFalse(overlaps)
    }
}
