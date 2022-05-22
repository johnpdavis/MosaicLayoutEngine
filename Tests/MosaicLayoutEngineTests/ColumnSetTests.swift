//
//  ColumnSetTests.swift
//  
//
//  Created by John Davis on 5/22/22.
//

@testable import MosaicLayoutEngine
import XCTest

class ColumnSetTests: XCTestCase {
    
    func testAddColumn() throws {
        let set = ColumnSet()
        
        set.addColumn(1)
        XCTAssertEqual(1, set.columns.count)
        XCTAssertEqual(1, set.columnStartIndex)
        
        set.addColumn(1)
        XCTAssertEqual(1, set.columns.count)
        
        set.addColumn(0)
        XCTAssertEqual(2, set.columns.count)
        XCTAssertEqual(0, set.columnStartIndex)
    }
    
    func testAddColumn_settingHeight() throws {
        let set = ColumnSet()
        
        set.addColumn(0)
        XCTAssertEqual(0, set.height)
        
        set.addColumn(0, settingHeightOfSet: 200)
        XCTAssertEqual(200, set.height)
    }
}
