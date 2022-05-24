//
//  PageState.swift
//  MosaicLayoutEngine
//
//  Created by John Davis on 5/22/22.
//

import Foundation

public class PageState: Equatable {
    let numberOfColumns: Int
    
    //This array maintains the state of the layout as all item frames are calculated.
    public private(set) var columnSizes: [BlockSize] = []
    
    public private(set) var itemBlockSlots: [Int: BlockSlot] = [:]
    
    init(numberOfColumns: Int) {
        self.numberOfColumns = numberOfColumns
        
        populateColumns(numberOfColumns: numberOfColumns)
    }
    
    func setSlot(_ slot: BlockSlot, for index: Int) {
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
    
    public static func == (lhs: PageState, rhs: PageState) -> Bool {
        lhs.numberOfColumns == rhs.numberOfColumns &&
        lhs.columnSizes == rhs.columnSizes &&
        lhs.itemBlockSlots == rhs.itemBlockSlots
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
    
    func heightForColumn(_ index: Int) -> Int {
        assert(index < self.columnSizes.count, "Cannot access height for column that does not exist")
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
