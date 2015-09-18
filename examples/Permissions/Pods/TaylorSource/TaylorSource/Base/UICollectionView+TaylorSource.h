//
//  Created by Daniel Thorpe on 20/04/2015.
//

#import <UIKit/UIKit.h>

@interface UICollectionView (TaylorSource)

- (void)tay_performBatchUpdates:(void (^)(void))updates completion:(void (^)(BOOL))completion;

@end
