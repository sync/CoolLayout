//
//  Copyright 2014 REAGroup. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "AMTimeAgoHeaderView.h"

@interface AMTimeAgoHeaderView (AMTimeAgoHeaderViewSpec)
@property (nonatomic, strong) IBOutlet UILabel *textLabel;
@end

SPEC_BEGIN(AMTimeAgoHeaderViewSpec)

describe(@"AMTimeAgoHeaderView", ^{
    context(@"defaultReuseIdentifier", ^{
        it(@"should be non nil", ^{
            [[[AMTimeAgoHeaderView defaultReuseIdentifier] should] beNonNil];
        });
    });
    
    context(@"configureWithName", ^{
        
        __block AMTimeAgoHeaderView *headerView = nil;
        __block NSString *name = nil;
        
        beforeEach(^{
            UINib *nib = [UINib nibWithNibName:@"AMTimeAgoHeaderView" bundle:nil];
            NSArray *elements = [nib instantiateWithOwner:nil options:nil];
            headerView = [elements firstObject];
            
            name = @"Test name";
            
            [headerView configureWithName:name];
        });
        
        it(@"should setup it's text label text", ^{
            [[headerView.textLabel.text should] equal:name];
        });
    });
});

SPEC_END
