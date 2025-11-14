//
//  PageLayoutEngine.swift
//  MosaicLayoutEngine
//
//  Created by John Davis on 5/17/22.
//

import CoreGraphics

public class PageLayoutEngine {
    
    public enum BottomEdgeBehavior {
        case flushIfNotFull
        case flush
        case notFlush
    }
     
    // Provided on init
    let pageWidth: CGFloat
    let numberOfColumns: Int
    let interItemSpacing: CGFloat
    let userIntendedPercent: CGFloat
    let itemsPerPage: Int
    
    let pixelSizeOfBlock: CGSize
    
    let columnWidth: CGFloat
    
    let bottomEdgeBehavior: BottomEdgeBehavior
    
    var staircaseThreshold: Int {
        return 3
    }
    
    lazy var imageBlockSizeEngine: ImageBlockSizeEngine = {
        ImageBlockSizeEngine(numberOfColumns: numberOfColumns,
                             pageWidth: pageWidth,
                             pixelSizeOfBlock: pixelSizeOfBlock,
                             userIntendedPercent: userIntendedPercent)
    }()
    
    init(numberOfColumns: Int, pageWidth: CGFloat, pixelSizeOfBlock: CGSize, interItemSpacing: CGFloat, itemsPerPage: Int, userIntendedPercent percent: CGFloat, bottomEdgeBehavior: BottomEdgeBehavior) {
        self.numberOfColumns = numberOfColumns
        self.pageWidth = pageWidth
        self.pixelSizeOfBlock = pixelSizeOfBlock
        self.interItemSpacing = interItemSpacing
        self.itemsPerPage = itemsPerPage
        self.userIntendedPercent = percent
        self.bottomEdgeBehavior = bottomEdgeBehavior
        
        // Computed Properties
        let gutterTotal = CGFloat(numberOfColumns + 1) * interItemSpacing
        let columnWidth = (pageWidth - gutterTotal) / CGFloat(numberOfColumns)
        self.columnWidth = columnWidth
    }
    
    public func layoutPageWithItems(_ itemSizes: [LayoutSizeProviding]) -> PageState {
        let itemBlockSizes = itemSizes.map { imageBlockSizeEngine.calculateBlockSize(of: $0) }
        
        // We now have the block sizes of everything we want to layout on a page.
        let pageState = PageState(numberOfColumns: numberOfColumns)
        
        for (index, element) in itemBlockSizes.enumerated() {
            // calculate the blocksize for the asset.
            let assetBlockSize = element
            
            //If the height of the lowest column is getting to be too large, then we need to shrink this element to fit into a smaller spot.
            if pageState.largestColumnHeight() - pageState.smallestColumnHeight() > staircaseThreshold {
                //gotta shrink the element's blockwidth to premeptively fit in the best slot situation we can find.
                
                let idealSet: ColumnSet = pageState.widestColumnSetWithSmallestHeight()
                if assetBlockSize.width > idealSet.columns.count {
                    imageBlockSizeEngine.forceWidth(idealSet.columns.count, of: assetBlockSize)
                }
            }

            //            shrink this item till we find a spot for it.
            while !self.placeBlockSlotForItem(item: element, index: index, pageState: pageState) {
                element.reduce()
            }
        }
        
        // We've laid each item into it's place to form the mosaic, but the page, if full, NEEDS to have a flush bottom.
        if bottomEdgeBehavior == .flushIfNotFull && itemSizes.count != itemsPerPage {
            makeBottomFlush(pageState)
        } else if bottomEdgeBehavior == .flush {
            makeBottomFlush(pageState)
        }

        return pageState
    }
    
    func makeBottomFlush(_ page: PageState) {
        // find bottom items that can be pulled downward.
        let largestColumnHeight = Int(page.largestColumnHeight())
        
        let downwardExpandableSlots = page.downwardExpandableBlockSlots()
        print(downwardExpandableSlots)
        downwardExpandableSlots.forEach { expandingSlot in
            let amount = largestColumnHeight - expandingSlot.originRow - expandingSlot.blockSize.height
            let newHeight = expandingSlot.blockSize.height + amount
            print("Setting height of \(expandingSlot) to: \(newHeight)")
            expandingSlot.blockSize.height = newHeight
        }
        
        page.recomputeColumnSizes()
        
        // find items that can be pulled rightward.
        let rightwardExpandableSlots = page.rightwardExpandableBlockSlots()
        
        rightwardExpandableSlots.forEach { expandingSlot in
            let columnHeights = page.columnSizes.map { Int($0.height) }
            
            let maxX = expandingSlot.maxX
            let maxY = expandingSlot.maxY
            var stretchableDistance: Int = 0
            
            for height in columnHeights[maxX...] {
                if height < maxY {
                    stretchableDistance += 1
                } else {
                    break
                }
            }
            
            expandingSlot.blockSize.width = expandingSlot.blockSize.width + stretchableDistance
        }
        
        print(page)
    }
    
    func placeBlockSlotForItem(item: ImageBlockSize, index: Int, pageState: PageState) -> Bool {
        var possibleColumnSets: [Int: ColumnSet] = Dictionary(minimumCapacity: numberOfColumns)
        var currentColumnHeight = pageState.heightForColumn(0)
        var currentColumnSet = pageState.columnSetForStartingColumn(0, dictionary: &possibleColumnSets)
        
        currentColumnSet.addColumn(0, settingHeightOfSet: currentColumnHeight)
        
        // Build a dictionary of all current possible columnSets
        for index in 1..<self.numberOfColumns {
            if pageState.heightForColumn(index) == currentColumnHeight {
                //heights are equal, add to current group column set.
                currentColumnSet.addColumn(index)
            } else {
                //it's time to move on to a new group.
                //lets find out if the one we just finished making can hold the new item, otherwise we need to remove it and keep going.
                if currentColumnSet.columns.count < item.width {
                    let startingColumn = currentColumnSet.columnStartIndex
                    //Remove the column set that's too small.
                    possibleColumnSets.removeValue(forKey: startingColumn)
                }
                
                // Update iteration state
                currentColumnSet = pageState.columnSetForStartingColumn(index, dictionary: &possibleColumnSets)
                currentColumnSet.addColumn(index, settingHeightOfSet: pageState.heightForColumn(index) )
                currentColumnHeight = pageState.heightForColumn(index)
            }
        }
        
        
        //Now that we have a dictionary of all possible column sets. We need to find the "best" match.
        //Best is defined by the one with the smallest height.
        
        guard !possibleColumnSets.isEmpty else { return false }
        
        var bestColumnSet = ColumnSet()
        bestColumnSet = possibleColumnSets.values.reduce(ColumnSet.worstColumnSet) { left, right in
            if right.height < left.height {
                return right
            } else if right.height == left.height {
                return right.columnStartIndex < left.columnStartIndex ? right : left
            } else {
                return left
            }
        }
        
        guard bestColumnSet.columns.count >= item.width else {
            return false
        }
        
        let widthToUse = min(item.width, bestColumnSet.columns.count)
        
        imageBlockSizeEngine.forceWidth(widthToUse, of: item)
        let slot = BlockSlot(originColumn: bestColumnSet.columnStartIndex, originRow: Int(bestColumnSet.height), blockSize: item)
        
//        print(slot)
        pageState.setSlot(slot, for: index)
        
        return true
    }
}
