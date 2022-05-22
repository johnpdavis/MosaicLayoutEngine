//
//  ImageBlockSizeEngineTests.swift
//  
//
//  Created by John Davis on 5/22/22.
//

@testable import MosaicLayoutEngine
import XCTest

class ImageBlockSizeEngineTests: XCTestCase {
    var engine: ImageBlockSizeEngine!
    
    override func setUp() async throws {
        engine = ImageBlockSizeEngine(numberOfColumns: 5,
                                      pageWidth: 2000,
                                      pixelSizeOfBlock: CGSize(width: 100, height: 300),
                                      userIntendedPercent: 1.0)
    }
    
    func testCalculateBlockSizeOf_boundedByColumnCount() throws {
        let mockSizeProviding = MockSizeProviding(width: 1000, height: 3000)
        
        let calculatedSize = engine.calculateBlockSize(of: mockSizeProviding)
        
        XCTAssertEqual(calculatedSize.width, 3)
        XCTAssertEqual(calculatedSize.height, 3)
    }

    func testCalculateBlockSizeOf_unboundedByColumnCount() throws {
        engine = ImageBlockSizeEngine(numberOfColumns: 5,
                                      pageWidth: 500,
                                      pixelSizeOfBlock: CGSize(width: 10, height: 30),
                                      userIntendedPercent: 1.0)
        
        let mockSizeProviding = MockSizeProviding(width: 50, height: 150)
        
        let calculatedSize = engine.calculateBlockSize(of: mockSizeProviding)
        
        XCTAssertEqual(calculatedSize.width, 5)
        XCTAssertEqual(calculatedSize.height, 5)
    }
    
    func testCalculateBlockSizeOf_widerItem_UnboundedByColumnCount() throws {
        engine = ImageBlockSizeEngine(numberOfColumns: 5,
                                      pageWidth: 500,
                                      pixelSizeOfBlock: CGSize(width: 10, height: 30),
                                      userIntendedPercent: 1.0)
        
        let mockSizeProviding = MockSizeProviding(width: 40, height: 10)
        
        let calculatedSize = engine.calculateBlockSize(of: mockSizeProviding)
        
        XCTAssertEqual(calculatedSize.width, 5) // 5 instead of 4 cause it's wide???
        XCTAssertEqual(calculatedSize.height, 1)
    }
    
    // Zoom Based Max Width Tests
    func test_maxWidthBasedOnUserIntendedZoom() {
        let engine = ImageBlockSizeEngine(numberOfColumns: 5,
                                          pageWidth: 2000,
                                          pixelSizeOfBlock: CGSize(width: 100, height: 300),
                                          userIntendedPercent: 1.0)
        
        let maxWidth = engine.maxWidthBasedOnUserIntendedZoom()
        XCTAssertEqual(maxWidth, 5)
    }
    
    func test_maxWidthBasedOnUserIntendedZoom_half() {
        let engine = ImageBlockSizeEngine(numberOfColumns: 5,
                                          pageWidth: 2000,
                                          pixelSizeOfBlock: CGSize(width: 100, height: 300),
                                          userIntendedPercent: 0.5)
        
        let maxWidth = engine.maxWidthBasedOnUserIntendedZoom()
        XCTAssertEqual(maxWidth, 2)
    }
    
    func test_maxWidthBasedOnUserIntendedZoom_zero() {
        let engine = ImageBlockSizeEngine(numberOfColumns: 5,
                                          pageWidth: 2000,
                                          pixelSizeOfBlock: CGSize(width: 100, height: 300),
                                          userIntendedPercent: 0.0)
        
        let maxWidth = engine.maxWidthBasedOnUserIntendedZoom()
        XCTAssertEqual(maxWidth, 1)
    }
    
    // PageWidth Max Width Tests
    func test_maxWidthBasedOnCollectionViewWidth_boundedByWidth() {
        let engine = ImageBlockSizeEngine(numberOfColumns: 5,
                                          pageWidth: 2000,
                                          pixelSizeOfBlock: CGSize(width: 100, height: 300),
                                          userIntendedPercent: 0.0)
        
        let maxWidth = engine.maxWidthBasedOnPageWidth()
        XCTAssertEqual(maxWidth, 3)
    }
    
    func test_maxWidthBasedOnCollectionViewWidth_unboundedByWidth() {
        let engine = ImageBlockSizeEngine(numberOfColumns: 5,
                                          pageWidth: 500,
                                          pixelSizeOfBlock: CGSize(width: 100, height: 300),
                                          userIntendedPercent: 0.0)
        
        let maxWidth = engine.maxWidthBasedOnPageWidth()
        XCTAssertEqual(maxWidth, 5)
    }
}

// Block Calculations
extension ImageBlockSizeEngineTests {
    func test_calculateBlockHeight() {
        let engine = ImageBlockSizeEngine(numberOfColumns: 5,
                                          pageWidth: 500,
                                          pixelSizeOfBlock: CGSize(width: 100, height: 300),
                                          userIntendedPercent: 0.0)
        
        let sizeProviding = MockSizeProviding(width: 1000, height: 3000)
        
        let heightForWidth_10 = engine.calculateBlockHeight(of: sizeProviding, forWidth: 10)
        XCTAssertEqual(10, heightForWidth_10)
        
        let heightForWidth_5 = engine.calculateBlockHeight(of: sizeProviding, forWidth: 5)
        XCTAssertEqual(5, heightForWidth_5)
        
        let heightForWidth_0 = engine.calculateBlockHeight(of: sizeProviding, forWidth: 0)
        XCTAssertEqual(1, heightForWidth_0)
    }
    
    func test_calculateWidth_square_idealGrid() {
        let engine = ImageBlockSizeEngine(numberOfColumns: 10,
                                          pageWidth: 500,
                                          pixelSizeOfBlock: CGSize(width: 100, height: 300),
                                          userIntendedPercent: 1.0)
        
        let sizeProviding = MockSizeProviding(width: 1000, height: 1000)
        let width = engine.calculateBlockWidth(of: sizeProviding)
        XCTAssertEqual(width, 10)
    }
    
    func test_calculateWidth_wideRectangle_idealGrid() {
        let engine = ImageBlockSizeEngine(numberOfColumns: 10,
                                          pageWidth: 500,
                                          pixelSizeOfBlock: CGSize(width: 100, height: 300),
                                          userIntendedPercent: 1.0)
        
        let sizeProviding = MockSizeProviding(width: 500, height: 100)
        let width = engine.calculateBlockWidth(of: sizeProviding)
        XCTAssertEqual(width, 6) // capped by maxWidth
    }
}
