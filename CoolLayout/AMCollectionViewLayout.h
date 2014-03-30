//
//  Copyright (c) 2014 REAGroup. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const AMCollectionViewLayoutElementKindTopMainHeader;

@protocol AMCollectionViewLayoutDelegate <UICollectionViewDelegateFlowLayout>
@optional
- (CGSize)collectionView:(UICollectionView *)collectionView referenceSizeForTopMainHeaderInLayout:(UICollectionViewLayout*)collectionViewLayout;
@end

@interface AMCollectionViewLayout : UICollectionViewFlowLayout

@property (nonatomic, assign, getter = hasStickyTopMainHeader) BOOL stickyTopMainHeader;
@property (nonatomic, assign, getter = isTopMainHeaderCollapsible) BOOL topMainHeaderCollapsible;

@property (nonatomic, assign, getter = hasStickyHeader) BOOL stickyHeader;

@end
