//
//  Created by Daniel Thorpe on 20/04/2015.
//

#import "UICollectionView+TaylorSource.h"

@implementation UICollectionView (TaylorSource)

- (void)tay_performBatchUpdates:(void (^)(void))updates completion:(void (^)(BOOL))completion {
    @try {
        [self performBatchUpdates:updates completion:completion];
    }
    @catch (NSException *exception) {
        [self reloadData];
    }
}

@end
