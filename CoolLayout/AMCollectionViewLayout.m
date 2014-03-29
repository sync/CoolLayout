//
//  Copyright (c) 2014 REAGroup. All rights reserved.
//

#import "AMCollectionViewLayout.h"

@implementation AMCollectionViewLayout

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray *updatedAttributes = [super layoutAttributesForElementsInRect:rect];
    
    if ([self hasStickyHeader])
    {
        updatedAttributes = [self updateLayoutAttributesforFloatingHeadersInRect:rect withCurrentElementsAttributes:updatedAttributes];
    }
    
    return updatedAttributes;
}

- (NSArray *)updateLayoutAttributesforFloatingHeadersInRect:(CGRect)rect withCurrentElementsAttributes:(NSArray *)layoutAttributesForElements
{
    NSMutableArray *layoutAttributesToUpdate = [NSMutableArray arrayWithArray:layoutAttributesForElements];
    
    NSMutableIndexSet *missingSections = [NSMutableIndexSet indexSet];
    for (UICollectionViewLayoutAttributes *layoutAttributes in layoutAttributesToUpdate)
    {
        if (layoutAttributes.representedElementCategory == UICollectionElementCategoryCell)
        {
            [missingSections addIndex:layoutAttributes.indexPath.section];
        }
    }
    
    for (UICollectionViewLayoutAttributes *layoutAttributes in layoutAttributesToUpdate)
    {
        if ([layoutAttributes.representedElementKind isEqualToString:UICollectionElementKindSectionHeader])
        {
            [missingSections removeIndex:layoutAttributes.indexPath.section];
        }
    }
    
    for (NSInteger idx = 0; idx < missingSections.count; idx++)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:idx];
        UICollectionViewLayoutAttributes *layoutAttributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:indexPath];
        [layoutAttributesToUpdate addObject:layoutAttributes];
    }
    
    for (UICollectionViewLayoutAttributes *layoutAttributes in layoutAttributesToUpdate)
    {
        if ([layoutAttributes.representedElementKind isEqualToString:UICollectionElementKindSectionHeader])
        {
            NSInteger section = layoutAttributes.indexPath.section;
            NSInteger numberOfItemsInSection = [self.collectionView numberOfItemsInSection:section];
            
            NSIndexPath *firstObjectIndexPath = [NSIndexPath indexPathForItem:0 inSection:section];
            NSIndexPath *lastObjectIndexPath = [NSIndexPath indexPathForItem:MAX(0, (numberOfItemsInSection - 1)) inSection:section];
            
            BOOL cellsExist = NO;
            UICollectionViewLayoutAttributes *firstObjectAttrs = nil;
            UICollectionViewLayoutAttributes *lastObjectAttrs = nil;
            
            if (numberOfItemsInSection > 0)
            {
                // use cell data if items exist
                cellsExist = YES;
                firstObjectAttrs = [self layoutAttributesForItemAtIndexPath:firstObjectIndexPath];
                lastObjectAttrs = [self layoutAttributesForItemAtIndexPath:lastObjectIndexPath];
            }
            else
            {
                // else use the header and footer
                cellsExist = NO;
                firstObjectAttrs = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                        atIndexPath:firstObjectIndexPath];
                lastObjectAttrs = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                                                                       atIndexPath:lastObjectIndexPath];
                
            }
            
            CGPoint origin = layoutAttributes.frame.origin;
            CGFloat topHeaderHeight = (cellsExist) ? CGRectGetHeight(layoutAttributes.frame) : 0;
            CGFloat bottomHeaderHeight = CGRectGetHeight(layoutAttributes.frame);
            
            CGFloat maxY = MAX(self.collectionView.contentOffset.y + self.collectionView.contentInset.top,
                               (CGRectGetMinY(firstObjectAttrs.frame) - topHeaderHeight)
                               );
            
            CGFloat minY = MIN(maxY,
                               (CGRectGetMaxY(lastObjectAttrs.frame) - bottomHeaderHeight)
                               );
            
            origin.y = minY;
            
            layoutAttributes.zIndex = 1024;
            
            layoutAttributes.frame = (CGRect){
                .origin = origin,
                .size = layoutAttributes.frame.size
            };
        }
    }
    
    return [layoutAttributesToUpdate copy];
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBound
{
    return YES;
}

@end
