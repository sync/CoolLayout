//
//  Copyright (c) 2014 REAGroup. All rights reserved.
//

#import "AMCollectionViewLayout.h"

NSString * const AMCollectionViewLayoutElementKindHeader = @"AMCollectionViewLayoutElementKindHeader";

@implementation AMCollectionViewLayout

#pragma mark - Layout attributes for item

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *layoutAttributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    if ([self shouldDisplayCollectionViewHeader])
    {
        CGRect frame = layoutAttributes.frame;
        frame.origin.y += [self elementsYDiffForCollectionViewHeader];
        layoutAttributes.frame = frame;
    }
    
    return layoutAttributes;
}

#pragma mark - Layout attributes for supplementary view

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *layoutAttributes = nil;
    if ([kind isEqualToString:AMCollectionViewLayoutElementKindHeader])
    {
        layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:kind withIndexPath:indexPath];
        layoutAttributes.zIndex = 2048;
        
        CGRect attrributesFrame = CGRectZero;
        attrributesFrame.origin.y = self.collectionView.contentOffset.y + self.collectionView.contentInset.top;
        attrributesFrame.size = [self referenceSizeForCollectionHeader];
        
        layoutAttributes.frame = attrributesFrame;
    }
    else
    {
        layoutAttributes = [super layoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath];
        if ([self shouldDisplayCollectionViewHeader])
        {
            CGRect frame = layoutAttributes.frame;
            frame.origin.y += [self elementsYDiffForCollectionViewHeader];
            layoutAttributes.frame = frame;
        }
    }
    
    return layoutAttributes;
}

#pragma mark - Collection View header

- (BOOL)shouldDisplayCollectionViewHeader
{
    return (CGSizeEqualToSize([self referenceSizeForCollectionHeader], CGSizeZero) == NO);
}

- (CGSize)referenceSizeForCollectionHeader
{
    id <AMCollectionViewLayoutDelegate> delegate = (id<AMCollectionViewLayoutDelegate>)self.collectionView.delegate;
    if ([delegate respondsToSelector:@selector(collectionView:referenceSizeForHeaderInlayout:)])
    {
        return [delegate collectionView:self.collectionView referenceSizeForHeaderInlayout:self];
    }
    
    return CGSizeZero;
}

- (CGFloat)elementsYDiffForCollectionViewHeader
{
    if ([self shouldDisplayCollectionViewHeader])
    {
        return CGRectGetHeight([self layoutAttributesForSupplementaryViewOfKind:AMCollectionViewLayoutElementKindHeader atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]].frame);
    }
    
    return 0;
}

#pragma mark - Layout

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray *layoutAttributes = [NSMutableArray arrayWithArray:[super layoutAttributesForElementsInRect:rect]];
    
    for (UICollectionViewLayoutAttributes *attributes in layoutAttributes)
    {
        if (attributes.representedElementCategory == UICollectionElementCategoryCell)
        {
            attributes.frame = [self layoutAttributesForItemAtIndexPath:attributes.indexPath].frame;
        }
        else if (attributes.representedElementCategory == UICollectionElementCategorySupplementaryView)
        {
            attributes.frame = [self layoutAttributesForSupplementaryViewOfKind:attributes.representedElementKind atIndexPath:attributes.indexPath].frame;
        }
    }
    
    if ([self shouldDisplayCollectionViewHeader])
    {
        [layoutAttributes addObject:[self layoutAttributesForSupplementaryViewOfKind:AMCollectionViewLayoutElementKindHeader atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]]];
    }
    
    if ([self hasStickyHeader])
    {
        layoutAttributes = [[self updateLayoutAttributesforFloatingHeadersInRect:rect withCurrentElementsAttributes:layoutAttributes] mutableCopy];
    }
    
    return [layoutAttributes copy];
}

#pragma mark - Floating Headers

- (NSArray *)updateLayoutAttributesforFloatingHeadersInRect:(CGRect)rect withCurrentElementsAttributes:(NSArray *)layoutAttributesForElements
{
    NSMutableArray *layoutAttributesToUpdate = [NSMutableArray arrayWithArray:layoutAttributesForElements];
    
    NSMutableSet *missingSections = [NSMutableSet set];
    for (UICollectionViewLayoutAttributes *layoutAttributes in layoutAttributesToUpdate)
    {
        if (layoutAttributes.representedElementCategory == UICollectionElementCategoryCell)
        {
            [missingSections addObject:@(layoutAttributes.indexPath.section)];
        }
    }
    
    for (UICollectionViewLayoutAttributes *layoutAttributes in layoutAttributesToUpdate)
    {
        if (layoutAttributes.representedElementKind == UICollectionElementKindSectionHeader)
        {
            [missingSections removeObject:@(layoutAttributes.indexPath.section)];
        }
    }
    
    for (NSNumber *section in missingSections)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:section.integerValue];
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
            
            CGFloat maxY = MAX(self.collectionView.contentOffset.y + self.collectionView.contentInset.top + [self elementsYDiffForCollectionViewHeader],
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

#pragma mark - Content size

- (CGSize)collectionViewContentSize
{
    CGSize contentSize = [super collectionViewContentSize];
    if ([self shouldDisplayCollectionViewHeader])
    {
        contentSize.height += [self referenceSizeForCollectionHeader].height;
    }
    
    return contentSize;
}

@end
