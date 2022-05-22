//
//  PageLayoutEngine.swift
//  MosaicLayoutEngine
//
//  Created by John Davis on 5/17/22.
//

import UIKit

class PageState: Equatable {
    let numberOfColumns: Int
    
    //This array maintains the state of the layout as all item frames are calculated.
    var columnSizes: [BlockSize] = []
    
    private(set) var itemBlockSlots: [IndexPath: BlockSlot] = [:]
    
    init(numberOfColumns: Int) {
        self.numberOfColumns = numberOfColumns
        
        populateColumns(numberOfColumns: numberOfColumns)
    }
    
    func setSlot(_ slot: BlockSlot, for index: IndexPath) {
        itemBlockSlots[index] = slot
        recomputeColumnSizes()
    }
    
    func recomputeColumnSizes() {
        var newSizes: [BlockSize] = Array(repeating: .zero, count: numberOfColumns)
        
        itemBlockSlots.values.forEach { slot in
            for index in slot.originColumn..<slot.maxX {
                if Int(newSizes[index].height) < slot.maxY {
                    newSizes[index] = BlockSize(width: 1, height: slot.maxY)
                }
            }
        }
        
        columnSizes = newSizes
    }
    
    static func == (lhs: PageState, rhs: PageState) -> Bool {
        lhs.numberOfColumns == rhs.numberOfColumns &&
        lhs.columnSizes == rhs.columnSizes &&
        lhs.itemBlockSlots == rhs.itemBlockSlots
    }
}

class BlockSlot: CustomStringConvertible, Hashable {
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
    
    var description: String {
        "ColumOrigin: X\(originColumn),Y\(originRow) -0- BlockSize: W\(blockSize.width)xH\(blockSize.height)"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(originColumn)
        hasher.combine(originRow)
        hasher.combine(blockSize)
    }
    
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
    
    static func == (lhs: BlockSlot, rhs: BlockSlot) -> Bool {
        return lhs.originColumn == rhs.originColumn &&
            lhs.originRow == rhs.originRow &&
            lhs.blockSize == rhs.blockSize
    }
}

class PageLayoutEngine {
     
    // Provided on init
    let pageWidth: CGFloat
    let pageHeight: CGFloat
    let numberOfColumns: Int
    let interItemSpacing: CGFloat
    let userIntendedPercent: CGFloat
    let itemsPerPage: Int
    
    let pixelSizeOfBlock: CGSize
    
    let columnWidth: CGFloat
    
    var staircaseThreshold: Int {
        return 3
    }
    
    lazy var imageBlockSizeEngine: ImageBlockSizeEngine = {
        ImageBlockSizeEngine(numberOfColumns: numberOfColumns,
                             pageWidth: pageWidth,
                             pixelSizeOfBlock: pixelSizeOfBlock,
                             userIntendedPercent: userIntendedPercent)
    }()
    
    init(numberOfColumns: Int, pageWidth: CGFloat, pageHeight: CGFloat, pixelSizeOfBlock: CGSize, interItemSpacing: CGFloat, itemsPerPage: Int, userIntendedPercent percent: CGFloat) {
        self.numberOfColumns = numberOfColumns
        self.pageWidth = pageWidth
        self.pageHeight = pageHeight
        self.pixelSizeOfBlock = pixelSizeOfBlock
        self.interItemSpacing = interItemSpacing
        self.itemsPerPage = itemsPerPage
        self.userIntendedPercent = percent
        
        // Computed Properties
        let gutterTotal = CGFloat(numberOfColumns + 1) * interItemSpacing
        let columnWidth = (pageWidth - gutterTotal) / CGFloat(numberOfColumns)
        self.columnWidth = columnWidth
    }
    
    func layoutPageWithItems(_ itemSizes: [LayoutSizeProviding]) -> PageState {
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
            while !self.placeBlockSlotForItem(item: element, index: IndexPath(item: index, section: 0), pageState: pageState) {
                element.reduce()
            }
        }
        
        // We've laid each item into it's place to form the mosaic, but the page, if full, NEEDS to have a flush bottom.
        if itemSizes.count == itemsPerPage {
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
    
    func placeBlockSlotForItem(item: ImageBlockSize, index: IndexPath, pageState: PageState) -> Bool {
        var possibleColumnSets: [Int: ColumnSet] = [:]
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

extension PageState {
    private func populateColumns(numberOfColumns: Int) {
        columnSizes = []
        var numberOfColumns: Int = numberOfColumns
        
        if numberOfColumns == 0 {
            //there's always one column.
            numberOfColumns = 1
        }
        
        (0..<numberOfColumns).forEach { _ in
            columnSizes.append(BlockSize(width: 1, height: 0))
        }
    }
    
    func heightForColumn( _ index: Int ) -> Int {
        assert( index < self.columnSizes.count, "Cannot access height for column that does not exist")
        return self.columnSizes[index].height
    }
    
    func smallestColumnHeight() -> Int {
        var returnVal = Int.max
        
        self.columnSizes.forEach { value in
            let newHeight = value.height
            
            if newHeight < returnVal {
                returnVal = newHeight
            }
        }
        
        return returnVal
    }
    
    func largestColumnHeight() -> Int {
        let returnVal = columnSizes.map { $0.height }.max() ?? 0
        
        if Float(returnVal) != floorf(Float(returnVal)) {
            print("CRITICAL: Missed a floor method call when calculating cell frame height")
        }
        
        return returnVal
    }
    
    // MARK: - WorkingWith ColumnSets
    //A Column set is a group of columns all sharing the same height.
    
    func widestColumnSetWithSmallestHeight() -> ColumnSet {
        var columnDict: [Int: ColumnSet] = [:]
        var currentColumnHeight: Int = self.heightForColumn(0) //start with column 0
        
        //Initialize the Dictionary for just column 0. We will add to it and create new groups as need be.
        var currentColumnSet: ColumnSet = self.columnSetForStartingColumn(0, dictionary: &columnDict)
        currentColumnSet.addColumn(0, settingHeightOfSet: currentColumnHeight)
        
        for index in 1..<self.numberOfColumns {
            if self.heightForColumn(index) == currentColumnHeight {
                currentColumnSet.addColumn(index)
            } else {
                //noticed a height difference, create another group!
                //start a new column set!
                currentColumnSet = self.columnSetForStartingColumn(index, dictionary: &columnDict)
                currentColumnSet.addColumn(index, settingHeightOfSet: self.heightForColumn(index))
                currentColumnHeight = self.heightForColumn(index)
            }
        }
        
        //NOW! Find the largest set with the shortest height
        
        var bestColumnSet: ColumnSet = ColumnSet.worstColumnSet
        for set in columnDict.values {
            if set.height < bestColumnSet.height {
                bestColumnSet = set
            } else if set.height == bestColumnSet.height && set.columns.count > bestColumnSet.columns.count {
                bestColumnSet = set
            }
        }
        
        //        let bestColumnSet = columnDict.values.array.reduce(ColumnSet.worstColumnSet(), combine: { return $1.height < $0.height && $1.columns.count >= $0.columns.count ? $1 : $0  } )
        
        return bestColumnSet
    }
    
    func columnSetForStartingColumn(_ startingColumn: Int, dictionary: inout [Int: ColumnSet]) -> ColumnSet {
        let columnSet: ColumnSet
        
        if let presentSet = dictionary[startingColumn] {
            columnSet = presentSet
        } else {
            columnSet = ColumnSet()
            dictionary[startingColumn] = columnSet
        }
        
        return columnSet
    }
    
    func rightwardExpandableBlockSlots() -> [BlockSlot] {
        let largestColumnHeight = Int(largestColumnHeight())
        
        let slotsClosestToBottomForEachColumn = slotsClosestToBottomForEachColumn()
        print(slotsClosestToBottomForEachColumn.count)
        
        let uniqueSlotsClosestToBottom = Set<BlockSlot>(slotsClosestToBottomForEachColumn)
        print(uniqueSlotsClosestToBottom.count)
        print(uniqueSlotsClosestToBottom)
        
        let slotsNotOnTheBottom = uniqueSlotsClosestToBottom.filter { slot in
            let maxY = slot.originRow + slot.blockSize.height
            return maxY != largestColumnHeight
        }
        
        var slotsBelowSlotsNotOnTheBottom: [BlockSlot: [BlockSlot]] = [:]
        slotsNotOnTheBottom.forEach { slot in
            let slotsBelow: [BlockSlot] = uniqueSlotsClosestToBottom.filter { other in
                guard other != slot else { return false }
                guard other.originRow >= slot.originRow else { return false }
                return slot.horizontallyOverlaps(other)
            }
            
            slotsBelowSlotsNotOnTheBottom[slot] = slotsBelow
        }
        
        let allExpandableSlots = slotsBelowSlotsNotOnTheBottom.reduce([]) { result, slotToSlots in
            result + slotToSlots.value
        }
        
        let uniqueExpandableSlots = Set<BlockSlot>(allExpandableSlots)
        
        return Array(uniqueExpandableSlots)
    }
    
    
    func downwardExpandableBlockSlots() -> [BlockSlot] {
        let slotsClosestToBottomForEachColumn = slotsClosestToBottomForEachColumn()
        print(slotsClosestToBottomForEachColumn.count)
        
        let uniqueSlotsClosestToBottom = Set<BlockSlot>(slotsClosestToBottomForEachColumn)
        print(uniqueSlotsClosestToBottom.count)
        print(uniqueSlotsClosestToBottom)
        
        // remove the overlappers that are unable to be drawn downward because another lowest slot is in the way
        let expandableSlots = uniqueSlotsClosestToBottom.filter { slot in
            let otherSlots = uniqueSlotsClosestToBottom.filter { $0 != slot }
            
            // if there is a slot below this card, then we exclude it.
            let otherSlotExistsBelowThisSlot = otherSlots.contains(where: { other in
//                // if the otherSlot is above, or equal then it's not an intersection
                guard other.originRow >= slot.originRow else { return false }
                return slot.horizontallyOverlaps(other)
            })
            
            return !otherSlotExistsBelowThisSlot
        }
        
        return Array(expandableSlots)
    }
    
    func slotsClosestToBottomForEachColumn() -> [BlockSlot] {
        let slotsClosestToBottomForEachColumn: [BlockSlot] = (0..<numberOfColumns).compactMap { column in
            // for each column, look upward for the item within that column that has the largest origin + height
            let slotsItersectingColumn = itemBlockSlots.values.filter { slot in
                if slot.originColumn == column {
                    return true
                } else if slot.originColumn < column && (slot.originColumn + slot.blockSize.width) > column {
                    return true
                }
                
                return false
            }
            
            guard slotsItersectingColumn.count > 0 else { return nil }
            
            let intersectingSlotClosestToBottom = slotsItersectingColumn.reduce(slotsItersectingColumn[0]) { result, slot in
                return (result.originRow + result.blockSize.height) > (slot.originRow + slot.blockSize.height) ? result : slot
            }
            
            return intersectingSlotClosestToBottom
        }
        
        return slotsClosestToBottomForEachColumn
    }
}
