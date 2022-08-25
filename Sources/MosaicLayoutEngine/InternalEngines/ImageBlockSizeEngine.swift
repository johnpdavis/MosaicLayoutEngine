//
//  ImageBlockSizeEngine.swift
//  MosaicLayoutEngine
//
//  Created by John Davis on 5/16/22.
//

import CoreGraphics
import Foundation

class ImageBlockSizeEngine {
    // Provided on init
    let pageWidth: CGFloat
    let numberOfColumns: Int
    let userIntendedPercent: CGFloat

    let pixelSizeOfBlock: CGSize
    
    init(numberOfColumns: Int,
         pageWidth: CGFloat,
         pixelSizeOfBlock: CGSize,
         userIntendedPercent percent: CGFloat) {
        self.numberOfColumns = numberOfColumns
        self.pageWidth = pageWidth
        self.userIntendedPercent = percent
    
        self.pixelSizeOfBlock = pixelSizeOfBlock
    }
    
    func calculateBlockSize(of sizeProviding: LayoutSizeProviding) -> ImageBlockSize {
        let width = calculateBlockWidth(of: sizeProviding)
        let height = calculateBlockHeight(of: sizeProviding, forWidth: width)
        
        return ImageBlockSize(width: width, height: height, sizeProvider: sizeProviding)
    }
    
    func reduce(imageBlockSize: ImageBlockSize) {
        imageBlockSize.reduce()
        //recalculate the height now.
        let height = self.calculateBlockHeight(of: imageBlockSize.sizeProvider, forWidth: imageBlockSize.width)
        imageBlockSize.height = height
    }

    func forceWidth(_ width: Int, of imageBlockSize: ImageBlockSize) {
        imageBlockSize.width = width
        let height = self.calculateBlockHeight(of: imageBlockSize.sizeProvider, forWidth: imageBlockSize.width)
        imageBlockSize.height = height
    }
    
    func calculateBlockWidth(of sizeProviding: LayoutSizeProviding) -> Int {
        
        // Divide by zero prevention
        guard sizeProviding.width > 0 && sizeProviding.height > 0 else {
            return 1
        }
        
        //what's the width to height ratio.
        let whRatio = sizeProviding.width / sizeProviding.height
        let widthDominates = whRatio >= 1.25 ? true : false
        
        var widthBlocks = Int(round(sizeProviding.width)) / Int(round(pixelSizeOfBlock.width))
        
        //************************************************************************
        // first we determine the widthblocks of the asset.
        //************************************************************************
        if numberOfColumns > 1 {
            //we have more than one column to work with.
            //determine if the image is very wide.
            
            //Based on the user's desiredDisplayPercent, we need to figure out if we should CAP the size of our asset.
            
            /*
             //The user's intention will shrink the maximum size of the image as the user lowers the zoom slider
             // by asking for a smaller percentage of the columns.
             
             //However at larger sizes the user's Intension will end up asking for ALL the columns.
             //At the point the "max size based on viewSize" takes over, and prevents items from taking up too many columns
             //based on how large the user has made the window!
             */
            
            let maxWidthBasedOnViewWidth = self.maxWidthBasedOnPageWidth()
            let maxWidthBasedOnUserIntention = self.maxWidthBasedOnUserIntendedZoom()
            
            var maxWidth: Int
            //take the smaller.
            maxWidth = maxWidthBasedOnViewWidth < maxWidthBasedOnUserIntention ? maxWidthBasedOnViewWidth : maxWidthBasedOnUserIntention
            if widthDominates {
                maxWidth += 1
            }

            if widthBlocks > maxWidth {
                widthBlocks = maxWidth
            }
        }
        
        //prevent 0 returned width.
        if widthBlocks < 1 {
            widthBlocks = 1
        }
        
        // prevent exceding the available size
        if widthBlocks > numberOfColumns {
            widthBlocks = numberOfColumns
        }
        
        return widthBlocks
    }
    
    func maxWidthBasedOnPageWidth() -> Int {
        var maxWidth: Int = 0
        
        if self.pageWidth <= 500.0 {
            maxWidth = numberOfColumns
        } else if self.pageWidth <= 1_000 {
            maxWidth = Int(ceil(Float(numberOfColumns) / 2.0))
        } else {
            maxWidth = Int(ceil(Float(numberOfColumns) / 2.0))
        }
        
        //Make sure the max width we calculated is NOT 0.
        if maxWidth < 1 {
            maxWidth = 1
        }
        
        return maxWidth
    }
    
    func maxWidthBasedOnUserIntendedZoom() -> Int {
        var maxWidth = Int( floor(CGFloat(numberOfColumns) * self.userIntendedPercent) )
        
        if maxWidth < 1 {
            maxWidth = 1
        }
        
        return maxWidth
    }
    
    func calculateBlockHeight(of sizeProviding: LayoutSizeProviding, forWidth blockWidth: Int) -> Int {
        let height = sizeProviding.height
        let width = sizeProviding.width
        
        guard width > 0 else {
            return 1
        }
        
        let ratioWH = Double(width) / Double(height)
        let ratioHeightByWidgth = Double(height) / Double(width)
        var heightBlocks: Int = 0
        
        //Based on the size of the width block, calculate the height blocks.
        //first, calculate the height of the image with the width of the blocks.
        
//        if ratioHeightByWidgth >= 1.25 {
//            heightBlocks = Int( round(Double(blockWidth) * 1.25) )
//        } else if ratioWH > 1.25 {
//            heightBlocks = Int( round(Double(blockWidth) * 0.75) )
//        } else {
//            heightBlocks = blockWidth
//        }
        
        let pixelWidth = floor( Double(pixelSizeOfBlock.width) * Double(blockWidth))
        let pixelheightForBlockWidth = pixelWidth / ratioWH

        heightBlocks = Int( round(pixelheightForBlockWidth / Double(pixelSizeOfBlock.height)))
        
        if heightBlocks < 1 {
            heightBlocks = 1
        }
        
        return heightBlocks
    }
}
