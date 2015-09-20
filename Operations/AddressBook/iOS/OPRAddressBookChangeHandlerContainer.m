//
//  OPRAddressBookChangeHandlerContainer.m
//  
//
//  Created by Daniel Thorpe on 06/09/2015.
//
//

#import "OPRAddressBookChangeHandlerContainer.h"

void AddressBookChangedCallback(ABAddressBookRef addressBook, CFDictionaryRef info, void *context) {
    OPRAddressBookChangeHandlerContainer *container = (__bridge OPRAddressBookChangeHandlerContainer *)context;
    [container addressBookChanged:(__bridge NSDictionary *)info];
}

@interface OPRAddressBookChangeHandlerContainer (/* Private */)
@property (nonatomic) __nonnull ABAddressBookRef addressBook;
@end

@implementation OPRAddressBookChangeHandlerContainer

- (OPRAddressBookChangeHandlerContainer *__nonnull)initWithDidChangeHandler:(__nonnull AddressBookDidChange)handler {
    self = [super init];
    if (self) {
        _didChangeHandler = handler;
    }
    return self;
}

- (void)dealloc {
    ABAddressBookUnregisterExternalChangeCallback(self.addressBook, AddressBookChangedCallback, (__bridge void *)(self));
}

- (void)registerForChangesInAddressBook:(__nonnull ABAddressBookRef)addressBookRef {
    self.addressBook = addressBookRef;
    ABAddressBookRegisterExternalChangeCallback(self.addressBook, AddressBookChangedCallback, (__bridge void *)(self));
}

- (void)addressBookChanged:(NSDictionary *__nonnull)info {
    ABAddressBookRevert(self.addressBook);
    self.didChangeHandler(info);
}

@end
