//
//  MosaicLayoutEngine.swift
//  MosaicLayoutEngine
//
//  Created by John Davis on 5/17/22.
//

import CoreGraphics

class MosaicLayoutEngine {
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
    
    private lazy var numberOfRows: Int = {
        guard numberOfColumns > 0 else { return 1 }
        guard itemsPerPage > 0 else { return 1 }
        
        let approximateNumberOfPageBlocksGivenItems = Double(itemsPerPage) * 2.5
        // divide by the number of columns, and round up to get the number of rows
        let numberOfRows = Int(ceil(approximateNumberOfPageBlocksGivenItems / Double(numberOfColumns)))
        
        return max(numberOfRows, 1)
    }()
    
    private lazy var rowHeight: CGFloat = {
        let totalVerticalGutter = interItemSpacing * CGFloat(numberOfRows + 2)
        let rowHeight = round((pageHeight - totalVerticalGutter) / CGFloat(numberOfRows))
        return rowHeight
    }()
    
    private lazy var columnWidth: CGFloat = {
        guard numberOfColumns > 0 else { return 1 }
        
        let gutterTotal = CGFloat(numberOfColumns + 2) * interItemSpacing
        
        return (pageWidth - gutterTotal) / CGFloat(numberOfColumns)
    }()
    
    private var pages: [PageState] = []
    
    lazy var pageLayoutEngine: PageLayoutEngine = {
        PageLayoutEngine(numberOfColumns: numberOfColumns, pageWidth: pageWidth, pageHeight: pageHeight, pixelSizeOfBlock: pixelSizeOfBlock, interItemSpacing: interItemSpacing, itemsPerPage: itemsPerPage, userIntendedPercent: userIntendedPercent)
    }()
    
    init(numberOfColumns: Int, numberOfPages: Int, pageWidth: CGFloat, pageHeight: CGFloat, interItemSpacing: CGFloat, itemsPerPage: Int, userIntendedPercent percent: CGFloat) {
        self.numberOfColumns = numberOfColumns
        self.numberOfPages = numberOfPages
        self.pageWidth = pageWidth
        self.pageHeight = pageHeight
        self.interItemSpacing = interItemSpacing
        self.userIntendedPercent = percent
        self.itemsPerPage = itemsPerPage
        
        resetAllPages()
    }
    
    func resetAllPages() {
        guard pageWidth != 0.0 else {
            print("<><><><><><><>CRITICAL: Tried to lay out a 0 width collection view. ")
            return
        }
        
        // Remove all page tracking
        pages.removeAll(keepingCapacity: true)
        
        // Add new page states
        (0..<numberOfPages).forEach { _ in
            let page = PageState(numberOfColumns: numberOfColumns)
            pages.append(page)
        }
    }
    
    func pageFor(index: Int) -> PageState? {
        guard index >= 0 && index < pages.count else { return nil }
        
        return pages[index]
    }
    
    func resetPage(index: Int) {
        guard index >= 0 && index < pages.count else { return }
        
        pages[index] = PageState(numberOfColumns: numberOfColumns)
    }
    
    func layoutItems(_ itemSizes: [BlockSize], inPage pageIndex: Int) {
        guard pageIndex >= 0 && pageIndex < pages.count else { return }
        
        
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
        let actualBlockSize = CGSize(width: columnWidth, height: rowHeight)
        
        guard actualBlockSize.width != CGFloat.infinity && actualBlockSize.height != CGFloat.infinity else { return nil }
        return actualBlockSize
    }
}
