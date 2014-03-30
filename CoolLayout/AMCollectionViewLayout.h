//
//  Copyright (c) 2014 REAGroup. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const AMCollectionViewLayoutElementKindHeader;

@protocol AMCollectionViewLayoutDelegate <UICollectionViewDelegateFlowLayout>
@optional
- (CGSize)collectionView:(UICollectionView *)collectionView referenceSizeForHeaderInlayout:(UICollectionViewLayout*)collectionViewLayout;
@end

@interface AMCollectionViewLayout : UICollectionViewFlowLayout

@property (nonatomic, assign, getter = hasStickyCollectionHeader) BOOL stickyCollectionHeader;
@property (nonatomic, assign, getter = hasStickyHeader) BOOL stickyHeader;

@end
