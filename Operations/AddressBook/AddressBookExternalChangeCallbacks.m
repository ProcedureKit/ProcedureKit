@import AddressBook;

typedef void (^ExternalChangeHandler)(NSDictionary *__nullable info);
typedef void (^ExternalChangeHandlerToken)(void);

static void OPRAddressBookChangedCallback(ABAddressBookRef addressBookRef, CFDictionaryRef info, void *context) {
    ExternalChangeHandler block = (__bridge ExternalChangeHandler)context;
    block((__bridge NSDictionary *)info);
}

__attribute__((used, visibility("hidden")))
__nonnull ExternalChangeHandlerToken OPRAddressBookRegisterExternalChangeHandler(__nonnull ABAddressBookRef addressBookRef, __nonnull ExternalChangeHandler handler) {

    ABAddressBookRegisterExternalChangeCallback(addressBookRef, OPRAddressBookChangedCallback, (__bridge void *)handler);
    __block dispatch_once_t predicate;
    ExternalChangeHandlerToken token = ^{
        dispatch_once(&predicate, ^{
            ABAddressBookUnregisterExternalChangeCallback(addressBookRef, OPRAddressBookChangedCallback, (__bridge void *)handler);
        });
    };
    return [token copy];
}

