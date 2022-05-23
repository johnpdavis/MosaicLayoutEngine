//
//  PageStateTests.swift
//  
//
//  Created by John Davis on 5/22/22.
//

@testable import MosaicLayoutEngine
import XCTest

class PageStateTests: XCTestCase {

    func testPopulatesColumnsOnInit() {
        let pageState = PageState(numberOfColumns: 5)
        
        XCTAssertEqual(5, pageState.numberOfColumns)
        XCTAssertEqual(5, pageState.columnSizes.count)
        
        let totalHeightOfAllColumns = pageState.columnSizes.reduce(0, { $0 + $1.height })
        XCTAssertEqual(0, totalHeightOfAllColumns) // all columns are inited with zero height so the sum of all should be zero.
    }
    
    func testSetSlot() {
        let pageState = PageState(numberOfColumns: 5)
        let slot = BlockSlot(originColumn: 0, originRow: 0, blockSize: .init(width: 3, height: 3))
        pageState.setSlot(slot, for: 0)

        XCTAssertEqual(3, pageState.heightForColumn(0))
        XCTAssertEqual(3, pageState.heightForColumn(1))
        XCTAssertEqual(3, pageState.heightForColumn(2))
    }
    
    func testSmallestColumnHeight() {
        let pageState = PageState(numberOfColumns: 5)
        XCTAssertEqual(0, pageState.smallestColumnHeight())
        
        let slot = BlockSlot(originColumn: 0, originRow: 0, blockSize: .init(width: 3, height: 3))
        let slot2 = BlockSlot(originColumn: 3, originRow: 0, blockSize: .init(width: 2, height: 1))
        
        pageState.setSlot(slot, for: 0)
        pageState.setSlot(slot2, for: 1)
        
        XCTAssertEqual(1, pageState.smallestColumnHeight())
    }
    
    func testLargestColumnHeight() {
        let pageState = PageState(numberOfColumns: 5)
        XCTAssertEqual(0, pageState.largestColumnHeight())
        
        let slot = BlockSlot(originColumn: 0, originRow: 0, blockSize: .init(width: 3, height: 3))
        let slot2 = BlockSlot(originColumn: 3, originRow: 0, blockSize: .init(width: 2, height: 1))
        pageState.setSlot(slot, for: 0)
        pageState.setSlot(slot2, for: 1)
        
        XCTAssertEqual(3, pageState.largestColumnHeight())
    }
    
    func test_slotsClosestToBottomForEachColumn() {
        let pageState = PageState(numberOfColumns: 5)
        XCTAssertEqual(0, pageState.largestColumnHeight())
        
        let slot = BlockSlot(originColumn: 0, originRow: 0, blockSize: .init(width: 3, height: 3))
        let slot2 = BlockSlot(originColumn: 3, originRow: 0, blockSize: .init(width: 2, height: 1))
        pageState.setSlot(slot, for: 0)
        pageState.setSlot(slot2, for: 1)
        
        let slotsClosetToBottomForEachColumn = pageState.slotsClosestToBottomForEachColumn()
        XCTAssertEqual(slot, slotsClosetToBottomForEachColumn[0])
        XCTAssertEqual(slot, slotsClosetToBottomForEachColumn[1])
        XCTAssertEqual(slot, slotsClosetToBottomForEachColumn[2])
        XCTAssertEqual(slot2, slotsClosetToBottomForEachColumn[3])
        XCTAssertEqual(slot2, slotsClosetToBottomForEachColumn[4])
    }
}
