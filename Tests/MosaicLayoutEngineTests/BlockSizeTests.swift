//
//  BlockSizeTests.swift
//  
//
//  Created by John Davis on 5/22/22.
//

@testable import MosaicLayoutEngine
import XCTest

class BlockSizeTests: XCTestCase {

    func testReduce() {
        let blockSize = BlockSize(width: 3, height: 2)
        
        blockSize.reduce()
        XCTAssertEqual(blockSize.width, 2)
        XCTAssertEqual(blockSize.height, 1)
        
        blockSize.reduce()
        XCTAssertEqual(blockSize.width, 1)
        XCTAssertEqual(blockSize.height, 1)
    }
}
