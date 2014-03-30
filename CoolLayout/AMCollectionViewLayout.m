//
//  Copyright (c) 2014 REAGroup. All rights reserved.
//

#import "AMCollectionViewLayout.h"

NSString * const AMCollectionViewLayoutElementKindTopMainHeader = @"AMCollectionViewLayoutElementKindTopMainHeader";
NSString * const AMCollectionViewLayoutInformationCellKey = @"cell";

@interface AMCollectionViewLayout ()
@property (nonatomic) NSDictionary *layoutInformation;
@end

@implementation AMCollectionViewLayout

#pragma mark - Layout attributes for item

- (UICollectionViewLayoutAttributes *)precomputedLayoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *layoutAttributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    if ([self shouldDisplayCollectionViewTopMainHeader])
    {
        CGRect frame = layoutAttributes.frame;
        frame.origin.y += [self elementsYDiffForCollectionViewTopMainHeader];
        layoutAttributes.frame = frame;
    }
    
    return layoutAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.layoutInformation[AMCollectionViewLayoutInformationCellKey][indexPath];
}

#pragma mark - Layout attributes for supplementary view

- (UICollectionViewLayoutAttributes *)precomputedLayoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *layoutAttributes = nil;
    if ([kind isEqualToString:AMCollectionViewLayoutElementKindTopMainHeader])
    {
        layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:kind withIndexPath:indexPath];
        layoutAttributes.zIndex = 2048;
        
        CGRect attrributesFrame = CGRectZero;
        attrributesFrame.size = [self referenceSizeForCollectionHeader];
        
        CGFloat yOrigin = 0;
        if ([self hasStickyTopMainHeader])
        {
            yOrigin = self.collectionView.contentOffset.y + self.collectionView.contentInset.top;
        
            if ([self isTopMainHeaderCollapsible])
            {
                yOrigin += [self collectionViewTopMainHeaderIntersectionYDiff];
            }
        }
        
        attrributesFrame.origin.y = yOrigin;
        layoutAttributes.frame = attrributesFrame;
    }
    else if ([kind isEqualToString:UICollectionElementKindSectionHeader])
    {
        layoutAttributes = [super layoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath];
        
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
            firstObjectAttrs = [self precomputedLayoutAttributesForItemAtIndexPath:firstObjectIndexPath];
            lastObjectAttrs = [self precomputedLayoutAttributesForItemAtIndexPath:lastObjectIndexPath];
        }
        else
        {
            // else use the header and footer
            cellsExist = NO;
            firstObjectAttrs = [self precomputedLayoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                               atIndexPath:firstObjectIndexPath];
            lastObjectAttrs = [self precomputedLayoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                                                                              atIndexPath:lastObjectIndexPath];
        }
        
        CGPoint origin = layoutAttributes.frame.origin;
        CGFloat topHeaderHeight = (cellsExist) ? CGRectGetHeight(layoutAttributes.frame) : 0;
        
        if ([self hasStickyHeader])
        {
            CGFloat bottomHeaderHeight = CGRectGetHeight(layoutAttributes.frame);
            
            CGFloat elementsYdiff = MAX(0, [self elementsYDiffForCollectionViewTopMainHeader] + [self collectionViewTopMainHeaderIntersectionYDiff]);
            
            CGFloat maxY = MAX(self.collectionView.contentOffset.y + self.collectionView.contentInset.top + elementsYdiff,
                               (CGRectGetMinY(firstObjectAttrs.frame) - topHeaderHeight)
                               );
            
            CGFloat minY = MIN(maxY,
                               (CGRectGetMaxY(lastObjectAttrs.frame) - bottomHeaderHeight)
                               );
            origin.y = minY;
        }
        else
        {
            origin.y = (CGRectGetMinY(firstObjectAttrs.frame) - topHeaderHeight);
        }
        
        layoutAttributes.zIndex = 1024;

        
        layoutAttributes.frame = (CGRect){
            .origin = origin,
            .size = layoutAttributes.frame.size
        };
    }
    else
    {
        layoutAttributes = [super layoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath];
        if ([self shouldDisplayCollectionViewTopMainHeader])
        {
            CGRect frame = layoutAttributes.frame;
            frame.origin.y += [self elementsYDiffForCollectionViewTopMainHeader];
            layoutAttributes.frame = frame;
        }
    }
    
    return layoutAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    return self.layoutInformation[kind][indexPath];
}
#pragma mark - Collection View Top Main Header

- (BOOL)shouldDisplayCollectionViewTopMainHeader
{
    return[self referenceSizeForCollectionHeader].height >= 0;
}

- (CGSize)referenceSizeForCollectionHeader
{
    id <AMCollectionViewLayoutDelegate> delegate = (id<AMCollectionViewLayoutDelegate>)self.collectionView.delegate;
    if ([delegate respondsToSelector:@selector(collectionView:referenceSizeForTopMainHeaderInLayout:)])
    {
        return [delegate collectionView:self.collectionView referenceSizeForTopMainHeaderInLayout:self];
    }
    
    return CGSizeZero;
}

- (CGFloat)elementsYDiffForCollectionViewTopMainHeader
{
    if ([self shouldDisplayCollectionViewTopMainHeader])
    {
        return [self referenceSizeForCollectionHeader].height;
    }
    
    return 0;
}

- (CGFloat)collectionViewTopMainHeaderIntersectionYDiff
{
    CGFloat yDiff = 0;
    
    if ([self.collectionView numberOfSections] > 0 && [self isTopMainHeaderCollapsible])
    {
        UICollectionViewLayoutAttributes *cellOrHeaderAttributes = [self firstHeaderFooterOrCellLayoutAttributes];
        
        CGFloat minYelement = CGRectGetMinY(cellOrHeaderAttributes.frame);
        
        CGFloat topSectionInset = [self insetForSection:0].top;
        CGFloat headerHeight = CGRectGetHeight([self layoutAttributesForSupplementaryViewOfKind:AMCollectionViewLayoutElementKindTopMainHeader atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]].frame);
        if (minYelement > topSectionInset + headerHeight)
        {
            yDiff = topSectionInset + headerHeight - minYelement;
        }
    }
    
    return yDiff;
}

- (UIEdgeInsets)insetForSection:(NSInteger)section
{
    id <AMCollectionViewLayoutDelegate> delegate = (id<AMCollectionViewLayoutDelegate>)self.collectionView.delegate;
    return [delegate collectionView:self.collectionView layout:self insetForSectionAtIndex:section];
}

- (UICollectionViewLayoutAttributes *)firstHeaderFooterOrCellLayoutAttributes
{
    NSInteger numberOfSections = [self.collectionView numberOfSections];
    
    UICollectionViewLayoutAttributes *firstObjectAttrs = nil;
    for (NSInteger section = 0; section < numberOfSections; section++) {
        NSIndexPath *firstObjectIndexPath = [NSIndexPath indexPathForItem:0 inSection:section];
        
        // use the header
        firstObjectAttrs = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                atIndexPath:firstObjectIndexPath];
        
        if (!firstObjectAttrs)
        {
            // use the footer
            firstObjectAttrs = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                    atIndexPath:firstObjectIndexPath];
        }
        
        if (!firstObjectAttrs)
        {
            // use cell data
            firstObjectAttrs = [self layoutAttributesForItemAtIndexPath:firstObjectIndexPath];
        }
        
        if (firstObjectAttrs)
        {
            break;
        }
    }
    
    return firstObjectAttrs;
}

#pragma mark - Header and Footer

- (BOOL)shouldDisplayHeaderInSection:(NSInteger)section
{
    CGSize headerReferenceSize = self.headerReferenceSize;
    
    id <AMCollectionViewLayoutDelegate> delegate = (id<AMCollectionViewLayoutDelegate>)self.collectionView.delegate;
    if ([delegate respondsToSelector:@selector(collectionView:layout:referenceSizeForHeaderInSection:)])
    {
        headerReferenceSize = [delegate collectionView:self.collectionView layout:self referenceSizeForHeaderInSection:section];
    }
    
    return (headerReferenceSize.height > 0);
}

- (BOOL)shouldDisplayFooterInSection:(NSInteger)section
{
    CGSize footerReferenceSize = self.footerReferenceSize;
    
    id <AMCollectionViewLayoutDelegate> delegate = (id<AMCollectionViewLayoutDelegate>)self.collectionView.delegate;
    if ([delegate respondsToSelector:@selector(collectionView:layout:referenceSizeForFooterInSection:)])
    {
        footerReferenceSize = [delegate collectionView:self.collectionView layout:self referenceSizeForFooterInSection:section];
    }
    
    return (footerReferenceSize.height > 0);
}

#pragma mark - UICollectionViewLayout

- (void)prepareLayout
{
    [super prepareLayout];
    
    NSMutableDictionary *layoutInformation = [NSMutableDictionary dictionary];
    NSMutableDictionary *cellInformation = [NSMutableDictionary dictionary];
    NSMutableDictionary *supplementaryMainHeaderInformation = [NSMutableDictionary dictionary];
    NSMutableDictionary *supplementaryHeaderInformation = [NSMutableDictionary dictionary];
    NSMutableDictionary *supplementaryFooterInformation = [NSMutableDictionary dictionary];
    
    NSIndexPath *indexPath = nil;
    UICollectionViewLayoutAttributes *attributes = nil;
    NSInteger numSections = [self.collectionView numberOfSections];
    for(NSInteger section = 0; section < numSections; section++)
    {
        NSInteger numItems = [self.collectionView numberOfItemsInSection:section];
        for(NSInteger item = 0; item < numItems; item++)
        {
            indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            
            // cell
            attributes = [self precomputedLayoutAttributesForItemAtIndexPath:indexPath];
            if (attributes)
            {
                [cellInformation setObject:attributes forKey:indexPath];
            }
            
            // supplementary
            
            // main header
            if (section == 0 && item == 0 && [self shouldDisplayCollectionViewTopMainHeader])
            {
                attributes = [self precomputedLayoutAttributesForSupplementaryViewOfKind:AMCollectionViewLayoutElementKindTopMainHeader atIndexPath:indexPath];
                if (attributes)
                {
                    [supplementaryMainHeaderInformation setObject:attributes forKey:indexPath];
                }
            }
            
            // header
            if (item == 0 && [self shouldDisplayHeaderInSection:0])
            {
                attributes = [self precomputedLayoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:indexPath];
                if (attributes)
                {
                    [supplementaryHeaderInformation setObject:attributes forKey:indexPath];
                }
            }
            
            // footer
            if (item == numItems - 1 && [self shouldDisplayFooterInSection:0])
            {
                attributes = [self precomputedLayoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter atIndexPath:indexPath];
                if (attributes)
                {
                    [supplementaryFooterInformation setObject:attributes forKey:indexPath];
                }
            }
        }
        
        // even if a section has no content (cell) header still need to be displayed when sticky
        if (numSections == 0 && [self hasStickyHeader] && [self shouldDisplayHeaderInSection:0])
        {
            attributes = [self precomputedLayoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:indexPath];
            if (attributes)
            {
                [supplementaryHeaderInformation setObject:attributes forKey:indexPath];
            }
        }
    }
    
    [layoutInformation setObject:cellInformation forKey:AMCollectionViewLayoutInformationCellKey];
    [layoutInformation setObject:supplementaryMainHeaderInformation forKey:AMCollectionViewLayoutElementKindTopMainHeader];
    [layoutInformation setObject:supplementaryHeaderInformation forKey:UICollectionElementKindSectionHeader];
    [layoutInformation setObject:supplementaryFooterInformation forKey:UICollectionElementKindSectionFooter];
    
    self.layoutInformation = layoutInformation;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray *layoutAttributesForElementsInRect = [NSMutableArray arrayWithCapacity:self.layoutInformation.count];
    
    for(NSString *key in self.layoutInformation)
    {
        NSDictionary *attributesDict = [self.layoutInformation objectForKey:key];
        for(NSIndexPath *key in attributesDict)
        {
            UICollectionViewLayoutAttributes *attributes = [attributesDict objectForKey:key];
            if(CGRectIntersectsRect(rect, attributes.frame))
            {
                [layoutAttributesForElementsInRect addObject:attributes];
            }
        }
    }
    
    return layoutAttributesForElementsInRect;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBound
{
    return YES;
}

#pragma mark - Content size

- (CGSize)collectionViewContentSize
{
    CGSize contentSize = [super collectionViewContentSize];
    if ([self shouldDisplayCollectionViewTopMainHeader])
    {
        contentSize.height += [self referenceSizeForCollectionHeader].height;
    }
    
    return contentSize;
}

@end
