//
//  Created by Daniel Thorpe on 20/04/2015.
//

#import "UITableView+TaylorSource.h"

@implementation UITableView (TaylorSource)

- (void)tay_performBatchUpdates:(void (^)(void))updates {
    @try {
        [self beginUpdates];
        updates();
        [self endUpdates];
    }
    @catch (NSException *exception) {
        [self reloadData];
    }
}

@end
