//
//  ColumnSet.swift
//  MosaicLayoutEngine
//
//  Created by John Davis on 5/16/22.
//

import CoreGraphics

// MARK: - ColumnSet
class ColumnSet {
    
    // MARK: - Properties
    private(set) var columns: Set<Int>
    private(set) var height: Int
    private(set) var columnStartIndex: Int
    
    // MARK: - Initialization
    init(minimumCapacity: Int) {
        self.columns = Set<Int>(minimumCapacity: minimumCapacity)
        self.height = 0
        self.columnStartIndex = Int.max
    }
    
    static func worstColumnSet(minimumCapacity: Int) -> ColumnSet {
        let worstSet = ColumnSet(minimumCapacity: minimumCapacity)
        worstSet.height = Int.max
        worstSet.columnStartIndex = Int.max
        
        return worstSet
    }
    
    // MARK: - Set Manipulation
    func addColumn(_ columnIndex: Int) {
        self.columns.insert(columnIndex)
        self.updateColumnStartIndex(columnIndex)
    }
    
    func addColumn(_ columnIndex: Int, settingHeightOfSet height: Int) {
        self.height = height
        self.addColumn(columnIndex)
        
        self.updateColumnStartIndex(columnIndex)
    }
    
    // MARK: - Internal State Maintenance
    private func updateColumnStartIndex( _ columnIndex: Int) {
        if columnIndex < columnStartIndex {
            self.columnStartIndex = columnIndex
        }
    }
}

// MARK: - CustomStringConvertible
extension ColumnSet: CustomStringConvertible {
    var description: String {
        return "Height: \(self.height)  ColumnSet: \(self.columns)"
    }
}
