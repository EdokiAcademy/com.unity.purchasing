#if !MAC_APPSTORE
#import "UnityEarlyTransactionObserver.h"
#import "UnityPurchasing.h"

void Log(NSString *message)
{
    NSLog(@"UnityIAP UnityEarlyTransactionObserver: %@\n", message);
}

@implementation UnityEarlyTransactionObserver

static UnityEarlyTransactionObserver *s_Observer = nil;

+ (void)load
{
    if (!s_Observer)
    {
        s_Observer = [[UnityEarlyTransactionObserver alloc] init];
        Log(@"Created");

        [s_Observer registerLifeCycleListener];
    }
}

+ (UnityEarlyTransactionObserver*)defaultObserver
{
    return s_Observer;
}

- (void)registerLifeCycleListener
{
    UnityRegisterLifeCycleListener(self);
    Log(@"Registered for lifecycle events");
}

- (void)didFinishLaunching:(NSNotification*)notification
{
    Log(@"Added to the payment queue");
    [[SKPaymentQueue defaultQueue] addTransactionObserver: self];
}

- (void)setDelegate:(id<UnityEarlyTransactionObserverDelegate>)delegate
{
    _delegate = delegate;
    [self sendQueuedPaymentsToInterceptor];
}

- (BOOL)paymentQueue:(SKPaymentQueue *)queue shouldAddStorePayment:(SKPayment *)payment forProduct:(SKProduct *)product
{
    Log(@"Payment queue shouldAddStorePayment");
    if (self.readyToReceiveTransactionUpdates && !self.delegate)
    {
        return YES;
    }
    else
    {
        if (m_QueuedPayments == nil)
        {
            m_QueuedPayments = [[NSMutableSet alloc] init];
        }
        // If there is a delegate and we have not seen this payment yet, it means we should intercept promotional purchases
        // and just return the payment to the delegate.
        // Do not try to process it now.
        if (self.delegate && [m_QueuedPayments member: payment] == nil)
        {
            [self.delegate promotionalPurchaseAttempted: payment];
        }
        [m_QueuedPayments addObject: payment];
        return NO;
    }
    return YES;
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {}

- (void)initiateQueuedPayments
{
    Log(@"Request to initiate queued payments");
    if (m_QueuedPayments != nil)
    {
        Log(@"Initiating queued payments");
        for (SKPayment *payment in m_QueuedPayments)
        {
            [[SKPaymentQueue defaultQueue] addPayment: payment];
        }
        [m_QueuedPayments removeAllObjects];
    }
}

- (void)sendQueuedPaymentsToInterceptor
{
    Log(@"Request to send queued payments to interceptor");
    if (m_QueuedPayments != nil)
    {
        Log(@"Sending queued payments to interceptor");
        for (SKPayment *payment in m_QueuedPayments)
        {
            if (self.delegate)
            {
                [self.delegate promotionalPurchaseAttempted: payment];
            }
        }
    }
}

///////////////////////////////////// Edoki custom change start here /////////////////////////////////////
extern "C"
{
    // user to set some user varible to be use later in UnityPurchasing.m
    void SetNativeDiscountData(const char *identifier, const char *keyIdentifier, const char *nonce, const char *signature, const char* timestamp)
    {
        if (@available(iOS 12.2, *))
        {
            Log(@"Discount data set");
            
            NSString* identifierString = [NSString stringWithUTF8String:identifier];
            NSString* keyIdentifierString = [NSString stringWithUTF8String:keyIdentifier];
            NSString* nonceString = [NSString stringWithUTF8String:nonce];
            NSString* signatureString = [NSString stringWithUTF8String:signature];
            NSString* timestampString = [NSString stringWithUTF8String:timestamp];
            
            [[NSUserDefaults standardUserDefaults] setObject:identifierString forKey:@"DiscountIdentifier"];
            [[NSUserDefaults standardUserDefaults] setObject:keyIdentifierString forKey:@"DiscountKeyIdentifier"];
            [[NSUserDefaults standardUserDefaults] setObject:nonceString forKey:@"DiscountNonce"];
            [[NSUserDefaults standardUserDefaults] setObject:signatureString forKey:@"DiscountSignature"];
            [[NSUserDefaults standardUserDefaults] setObject:timestampString forKey:@"DiscountTimestamp"];
        }
    }
    
    // Remove the data set by SetNativeDiscountData
    void FlushNativeDiscountData()
    {
        if (@available(iOS 12.2, *))
        {
            Log(@"Discount data flush");
            
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"DiscountIdentifier"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"DiscountKeyIdentifier"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"DiscountNonce"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"DiscountSignature"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"DiscountTimestamp"];
        }
    }
}
///////////////////////////////////// Edoki custom change end here /////////////////////////////////////

@end
#endif
