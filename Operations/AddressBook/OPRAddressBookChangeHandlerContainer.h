@import Foundation;
@import AddressBook;

typedef void (^AddressBookDidChange)(NSDictionary *__nullable info);

@interface OPRAddressBookChangeHandlerContainer : NSObject

@property (nonatomic, strong) __nonnull AddressBookDidChange didChangeHandler;

- (OPRAddressBookChangeHandlerContainer *__nonnull)initWithDidChangeHandler:(__nonnull AddressBookDidChange)handler;

- (void)registerForChangesInAddressBook:(__nonnull ABAddressBookRef)addressBookRef;

- (void)addressBookChanged:(NSDictionary * __nonnull)info;

@end
