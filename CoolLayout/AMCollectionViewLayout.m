//
//  Copyright (c) 2014 REAGroup. All rights reserved.
//

#import "AMCollectionViewLayout.h"

NSString * const AMCollectionViewLayoutElementKindTopMainHeader = @"AMCollectionViewLayoutElementKindTopMainHeader";
NSString * const AMCollectionViewLayoutElementKindListBackground = @"AMCollectionViewLayoutElementKindListBackground";
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
        attrributesFrame.size = [self referenceSizeForCollectionTopMainHeader];
        
        CGFloat yOrigin = 0;
        if ([self hasStickyTopMainHeader])
        {
            yOrigin = [self adjustedCollectionViewContentOffset];
            
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
            
            CGFloat maxY = MAX([self adjustedCollectionViewContentOffset] + elementsYdiff,
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

#pragma mark - Layout Attributes for Decoration View

- (UICollectionViewLayoutAttributes *)precomputedLayoutAttributesForDecorationViewOfKind:(NSString*)decorationViewKind atIndexPath:(NSIndexPath *)indexPath inRect:(CGRect)rect
{
    UICollectionViewLayoutAttributes *layoutAttributes = nil;
    
    if ([decorationViewKind isEqualToString:AMCollectionViewLayoutElementKindListBackground])
    {
        layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForDecorationViewOfKind:decorationViewKind withIndexPath:indexPath];
        layoutAttributes.zIndex = -1024;
        layoutAttributes.frame = rect;
    }
    
    return layoutAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString*)decorationViewKind atIndexPath:(NSIndexPath *)indexPath
{
    return self.layoutInformation[decorationViewKind][indexPath];
}

#pragma mark - Utilities

- (CGFloat)adjustedCollectionViewContentOffset
{
    return self.collectionView.contentOffset.y + self.collectionView.contentInset.top;
}

- (CGRect)updatedRect:(CGRect)rect forMinMaxBasedOnLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
    CGFloat minCellHeaderFooterX = 0.f;
    CGFloat maxCellHeaderFooterX = 0.f;
    CGFloat minCellHeaderFooterY = 0.f;
    CGFloat maxCellHeaderFooterY = 0.f;
    
    if (CGRectIsEmpty(rect))
    {
        minCellHeaderFooterX = CGFLOAT_MAX;
        maxCellHeaderFooterX = 0.f;
        minCellHeaderFooterY = CGFLOAT_MAX;
        maxCellHeaderFooterY = 0.f;
    }
    else
    {
        minCellHeaderFooterX = CGRectGetMinX(rect);
        maxCellHeaderFooterX = CGRectGetMaxX(rect);
        minCellHeaderFooterY = CGRectGetMinY(rect);
        maxCellHeaderFooterY = CGRectGetMaxY(rect);
    }
    
    minCellHeaderFooterY = MIN(minCellHeaderFooterY, CGRectGetMinY(layoutAttributes.frame));
    maxCellHeaderFooterY = MAX(maxCellHeaderFooterY, CGRectGetMaxY(layoutAttributes.frame));
    minCellHeaderFooterX = MIN(minCellHeaderFooterX, CGRectGetMinX(layoutAttributes.frame));
    maxCellHeaderFooterX = MAX(maxCellHeaderFooterX, CGRectGetMaxX(layoutAttributes.frame));
    
    CGRect updatedRect = CGRectMake(minCellHeaderFooterX, minCellHeaderFooterY, maxCellHeaderFooterX - minCellHeaderFooterX, maxCellHeaderFooterY - minCellHeaderFooterY);
    
    return updatedRect;
}

#pragma mark - Collection View Top Main Header

- (BOOL)shouldDisplayCollectionViewTopMainHeader
{
    return[self referenceSizeForCollectionTopMainHeader].height >= 0;
}

- (CGSize)referenceSizeForCollectionTopMainHeader
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
        return [self referenceSizeForCollectionTopMainHeader].height;
    }
    
    return 0;
}

- (CGFloat)collectionViewTopMainHeaderIntersectionYDiff
{
    CGFloat yDiff = 0;
    
    if ([self.collectionView numberOfSections] > 0 && [self isTopMainHeaderCollapsible])
    {
        CGFloat topSectionInset = [self insetForSection:0].top;
        yDiff = MAX(0, [self adjustedCollectionViewContentOffset] - topSectionInset) * -1;
    }
    
    return yDiff;
}

- (UIEdgeInsets)insetForSection:(NSInteger)section
{
    id <AMCollectionViewLayoutDelegate> delegate = (id<AMCollectionViewLayoutDelegate>)self.collectionView.delegate;
    return [delegate collectionView:self.collectionView layout:self insetForSectionAtIndex:section];
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
    NSMutableDictionary *decorationListBackgroundInformation = [NSMutableDictionary dictionary];
    
    CGRect backgroundRect = CGRectZero;
    
    NSIndexPath *indexPath = nil;
    UICollectionViewLayoutAttributes *attributes = nil;
    NSInteger sectionsCount = [self.collectionView numberOfSections];
    for (NSInteger section = 0; section < sectionsCount; section++)
    {
        NSInteger itemsCount = [self.collectionView numberOfItemsInSection:section];
        for (NSInteger item = 0; item < itemsCount; item++)
        {
            indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            
            // cell
            attributes = [self precomputedLayoutAttributesForItemAtIndexPath:indexPath];
            if (attributes)
            {
                [cellInformation setObject:attributes forKey:indexPath];
                backgroundRect = [self updatedRect:backgroundRect forMinMaxBasedOnLayoutAttributes:attributes];
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
                    backgroundRect = [self updatedRect:backgroundRect forMinMaxBasedOnLayoutAttributes:attributes];
                }
            }
            
            // footer
            if (item == itemsCount - 1 && [self shouldDisplayFooterInSection:0])
            {
                attributes = [self precomputedLayoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter atIndexPath:indexPath];
                if (attributes)
                {
                    [supplementaryFooterInformation setObject:attributes forKey:indexPath];
                    backgroundRect = [self updatedRect:backgroundRect forMinMaxBasedOnLayoutAttributes:attributes];
                }
            }
        }
        
        // even if a section has no content (cell) header still need to be displayed when sticky
        if (sectionsCount == 0 && [self hasStickyHeader] && [self shouldDisplayHeaderInSection:0])
        {
            indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
            attributes = [self precomputedLayoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:indexPath];
            if (attributes)
            {
                [supplementaryHeaderInformation setObject:attributes forKey:indexPath];
            }
        }
    }
    
    // insert list backgorund
    if (sectionsCount > 0 && !CGRectIsEmpty(backgroundRect))
    {
        attributes = [self precomputedLayoutAttributesForDecorationViewOfKind:AMCollectionViewLayoutElementKindListBackground atIndexPath:indexPath inRect:backgroundRect];
        if (attributes)
        {
            [decorationListBackgroundInformation setObject:attributes forKey:indexPath];
        }
    }
    
    [layoutInformation setObject:cellInformation forKey:AMCollectionViewLayoutInformationCellKey];
    [layoutInformation setObject:supplementaryMainHeaderInformation forKey:AMCollectionViewLayoutElementKindTopMainHeader];
    [layoutInformation setObject:supplementaryHeaderInformation forKey:UICollectionElementKindSectionHeader];
    [layoutInformation setObject:supplementaryFooterInformation forKey:UICollectionElementKindSectionFooter];
    [layoutInformation setObject:decorationListBackgroundInformation forKey:AMCollectionViewLayoutElementKindListBackground];
    
    self.layoutInformation = layoutInformation;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray *layoutAttributesForElementsInRect = [NSMutableArray arrayWithCapacity:self.layoutInformation.count];
    
    for (NSString *key in self.layoutInformation)
    {
        NSDictionary *attributesDict = [self.layoutInformation objectForKey:key];
        for (NSIndexPath *key in attributesDict)
        {
            UICollectionViewLayoutAttributes *attributes = [attributesDict objectForKey:key];
            if (CGRectIntersectsRect(rect, attributes.frame))
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
        contentSize.height += [self referenceSizeForCollectionTopMainHeader].height;
    }
    
    return contentSize;
}

@end
