//
//  MosaicLayoutEngine.swift
//  MosaicLayoutEngine
//
//  Created by John Davis on 5/17/22.
//

import CoreGraphics
import Foundation

public class MosaicLayoutEngine {
    // Provided on init
    private let pageHeight: CGFloat
    private let pageWidth: CGFloat
    private let numberOfColumns: Int
    private let numberOfPages: Int
    private let interItemSpacing: CGFloat
    private let userIntendedPercent: CGFloat
    
    private let itemsPerPage: Int
    
    private lazy var pixelSizeOfBlock: CGSize = {
        actualBlockSize() ?? .zero
    }()

    private lazy var columnWidth: CGFloat = {
        guard numberOfColumns > 0 else { return 1 }
        
        let gutterTotal = CGFloat(numberOfColumns + 2) * interItemSpacing
        
        return (pageWidth - gutterTotal) / CGFloat(numberOfColumns)
    }()
    
    private var pages: [Int: PageState] = [:]
    
    lazy var pageLayoutEngine: PageLayoutEngine = {
        PageLayoutEngine(numberOfColumns: numberOfColumns, pageWidth: pageWidth, pageHeight: pageHeight, pixelSizeOfBlock: pixelSizeOfBlock, interItemSpacing: interItemSpacing, itemsPerPage: itemsPerPage, userIntendedPercent: userIntendedPercent)
    }()
    
    public init(numberOfColumns: Int, numberOfPages: Int, pageWidth: CGFloat, pageHeight: CGFloat, interItemSpacing: CGFloat, itemsPerPage: Int, userIntendedPercent percent: CGFloat) {
        self.numberOfColumns = numberOfColumns
        self.numberOfPages = numberOfPages
        self.pageWidth = pageWidth
        self.pageHeight = pageHeight
        self.interItemSpacing = interItemSpacing
        self.userIntendedPercent = percent
        self.itemsPerPage = itemsPerPage
        
        resetAllPages()
    }
    
    public func resetAllPages() {
        guard pageWidth != 0.0 else {
            print("<><><><><><><>CRITICAL: Tried to lay out a 0 width collection view. ")
            return
        }
        
        // Remove all page tracking
        pages.removeAll(keepingCapacity: true)
    }
    
    private func cachedPageFor(index: Int) -> PageState? {
        return pages[index]
    }
    
    public func resetPage(index: Int) {
        pages.removeValue(forKey: index)
    }
    
    func computedPage(for itemSizes: [LayoutSizeProviding], inPage pageIndex: Int) -> PageState! {
        if let page = cachedPageFor(index: pageIndex), !page.itemBlockSlots.isEmpty {
            return page
        } else {
            let page = pageLayoutEngine.layoutPageWithItems(itemSizes)
            pages[pageIndex] = page
            return page
        }
    }
    
    private func heightOfPage(index: Int) -> CGFloat {
        // find the page's largest column
        if let page = pages[index] {
            let largestColumnheight = page.largestColumnHeight()
            
            let height = (pixelSizeOfBlock.height * CGFloat(largestColumnheight)) + (interItemSpacing * CGFloat(largestColumnheight))
            
            return height
        } else {
            return pageHeight
        }
    }
    
    private func minYOfPage(index: Int) -> CGFloat {
        // the top of a page is the sum of all page heights above it.
        let topOfPage = (0..<index).reduce(0.0) { result, pageIndex in
            result + heightOfPage(index: pageIndex)
        }
        
        return topOfPage
    }
    
    public func pageFrame(index: Int) -> CGRect {
        return CGRect(x: 0,
                      y: minYOfPage(index: index),
                      width: pageWidth,
                      height: heightOfPage(index: index))
    }
    
    public func layoutSizes(for itemSizes: [LayoutSizeProviding], inPage pageIndex: Int) -> [Int: CGRect] {
        let computedPage = computedPage(for: itemSizes, inPage: pageIndex)
        let pageMinY = minYOfPage(index: pageIndex)
        
        var itemFrames: [Int: CGRect] = [:]
        computedPage?.itemBlockSlots.forEach { index, slot in
            let blockSizeHeight = pixelSizeOfBlock.height
            let blockSizeWidth = pixelSizeOfBlock.width
            
            let localOffsetX: CGFloat = (interItemSpacing * CGFloat(slot.originColumn + 1)) + (CGFloat(slot.originColumn) * blockSizeWidth)
            let localOffsetY: CGFloat = (interItemSpacing * CGFloat(slot.originRow + 1)) + (CGFloat(slot.originRow) * blockSizeHeight)
            
            let width = blockSizeWidth * CGFloat(slot.blockSize.width) + (interItemSpacing * CGFloat(slot.blockSize.width - 1))
            let height = (blockSizeHeight * CGFloat(slot.blockSize.height)) + (interItemSpacing * CGFloat(slot.blockSize.height - 1))
            
            let frame = CGRect(x: localOffsetX, y: localOffsetY + pageMinY, width: width, height: height)
            
            itemFrames[index] = frame
        }
        
        return itemFrames
    }
}

private extension MosaicLayoutEngine {
//    func actualBlockSize() -> CGSize? {
//        var actualBlockSize: CGSize?
//
//        guard columnWidth != 0 else { return actualBlockSize }
//        guard numberOfColumns > 0 else { return actualBlockSize }
//
////        var remainingSpace: CGFloat = 0
////        remainingSpace = pageWidth - (CGFloat(numberOfColumnsInPage) * columnWidth)
//
//        //This is an experiment regarding setting the height of a block unit as a ratio of the width. and it works awesome.
//        var secondaryBlockDimension: CGFloat = columnWidth
//
////        if self.adaptsSecondaryBlockDimension {
////            assertionFailure("Because we now calculate the block sizes of image based on image ratio it's not wise to use this")
////            secondaryBlockDimension *= 0.75
////        } else {
//        secondaryBlockDimension *= 0.5
////        }
//
////        if remainingSpace > 0 {
////            let blockSizeIncrease = remainingSpace / CGFloat(numberOfColumnsInPage)
////            actualBlockSize = CGSize(width: columnWidth + blockSizeIncrease, height: secondaryBlockDimension)
////        } else {
//            actualBlockSize = CGSize(width: columnWidth, height: secondaryBlockDimension)
////        }
//
//        guard actualBlockSize?.width != CGFloat.infinity && actualBlockSize?.height != CGFloat.infinity else { return nil }
//
//        return actualBlockSize
//    }
    
    func actualBlockSize() -> CGSize? {
        let actualBlockSize = CGSize(width: columnWidth, height: round(columnWidth / 2))
        
        guard actualBlockSize.width != CGFloat.infinity && actualBlockSize.height != CGFloat.infinity else { return nil }
        return actualBlockSize
    }
}
