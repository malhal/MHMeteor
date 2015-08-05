//
//  MHMeteor.m
//  CoreMeteor
//
//  Created by Malcolm Hall on 12/05/2014.
//  Copyright (c) 2014 Malcolm Hall. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "MHMeteor.h"
#import "MHMongoCollection.h"
#import "MHSession.h"

NSString* const MHMeteorErrorDomain = @"MHMeteorErrorDomain";

static int kLoadRequestRetryDelay = 3; // seconds

@interface MHMongoCollection(Private)

- (instancetype)_initWithMeteor:(MHMeteor*)meteor name:(NSString*)name;

@end

@interface MHMeteor()<UIWebViewDelegate>
// because the value can change we cant subclass JSManagedValue fortunately theres only one method invokeMethod needs duplicated.
@property (nonatomic, strong) JSValue* value;
@property (strong, readonly) UIWebView* webView;
@end

@implementation MHMeteor{
    //MHMongoCollections
    NSMutableDictionary* _collectionsByName;
    NSMutableDictionary* _collectionsByGlobalID;
    NSMutableDictionary* _subscriptionHandlesByRecordSet;
    void(^_startedUp)();
    NSURLRequest* _request;
    MHSession* _session;
}

+ (void)initialize
{
    if (self == [MHMeteor class]) {
  //    experimental cache settings
        /*
        int cacheSizeMemory = 4*1024*1024; // 4MB
        int cacheSizeDisk = 128*1024*1024; // 128MB
        NSURLCache *urlCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:cacheSizeDisk diskPath:@"nsurlcache5"];
        [NSURLCache setSharedURLCache:urlCache];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
         */
    }
}

+(void)startupWithRequest:(NSURLRequest*)request startedUpHandler:(void(^)(MHMeteor*, BOOL))startedUpHandler{
    __block MHMeteor* meteor;
    __block BOOL isRestart;
    meteor = [[MHMeteor alloc] _initWithRequest:request startedUp:^{
        startedUpHandler(meteor, isRestart);
        isRestart = YES;
    }];
}

+(void)startupMeteorWithURL:(NSURL*)url startedUpHandler:(void(^)(MHMeteor*, BOOL))startedUpHandler{
    [self startupWithRequest:[NSURLRequest requestWithURL:url] startedUpHandler:startedUpHandler];
}

- (instancetype)_initWithRequest:(NSURLRequest*)request startedUp:(void(^)())startedUp{
    self = [super init];
    if (self) {
        _startedUp = startedUp;
        _collectionsByGlobalID = [NSMutableDictionary dictionary];
        _collectionsByName = [NSMutableDictionary dictionary];
        // hang on to the webview so we can wake it up when we need to invoke the context.
        _webView = [[UIWebView alloc] init];
        _webView.delegate = self;
        // copy the request so we can retry if we failed or got a 404. _webView reload and loadRequest:_webView.request does not work.
        _request = request.copy;
        [_webView loadRequest:_request];
    }
    return self;
}

#pragma mark - UIWebViewDelegate
    
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"webViewDidFinishLoad");

    JSContext* context = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    // set up exception handling
#ifdef DEBUG
    [context setExceptionHandler:^(JSContext *context, JSValue *value) {
        NSLog(@"Meteor JS: %@", value);
    }];
#endif

    JSValue* meteor = context[@"Meteor"];
    // unfortunately when the web view 404s it calls finish load so we'll check if Meteor exists to validate.
    if(meteor.isUndefined){
        NSLog(@"Meteor is undefined, retrying...");
        // retry after 1 second
        [webView performSelector:@selector(loadRequest:) withObject:_request afterDelay:kLoadRequestRetryDelay];
        return;
    }
    self.value = meteor;
    [self _startedUp:^{
        _startedUp();
    }];
    
    // required for groundDB to work when starting offline.
    [[UIApplication sharedApplication].keyWindow addSubview:_webView];
}

// update everything created on previous load
-(void)setValue:(JSValue *)value{
    _value = value;
    
    //refresh all the collections
    for(NSString* globalID in _collectionsByGlobalID.allKeys){
        MHMongoCollection* collection = _collectionsByGlobalID[globalID];
        collection.value = value.context[globalID];
    }
    for(NSString* name in _collectionsByName){
        MHMongoCollection* collection = _collectionsByGlobalID[name];
        collection.value = [value.context[@"Mongo"][@"Collection"]  constructWithArguments:@[name]];
    }
    
    if(_session){
        [_session setValue:value.context[@"Session"]];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [webView performSelector:@selector(loadRequest:) withObject:webView.request afterDelay:kLoadRequestRetryDelay];
}

- (MHMongoCollection*)collectionForGlobalID:(NSString*)globalID{
    JSValue* global = self.value.context[globalID];
    if(global.isUndefined){
        NSLog(@"globalID is undefined in javascript");
        return nil;
    }
    JSValue* nameValue = [global valueForProperty:@"_name"];
    if(nameValue.isUndefined){
        NSLog(@"collection from globalID '%@' didn't have a _name", globalID);
        return nil;
    }
    MHMongoCollection* collection = _collectionsByGlobalID[globalID];
    if(collection){
        return collection;
    }
    // creates a collection from an existing JSValue
    // the managed reference that is added in the init is overkill but keeps our design nice.
    collection = [[MHMongoCollection alloc] initWithMeteor:self value:global];
    _collectionsByGlobalID[globalID] = collection;
    return collection;
}


- (MHMongoCollection*)collectionNamed:(NSString*)name{
    MHMongoCollection* collection = _collectionsByName[name];
    if(collection){
        return collection;
    }
    collection = [[MHMongoCollection alloc] initWithMeteor:self
                                                     value:[self.value.context[@"Mongo"][@"Collection"]  constructWithArguments:@[name]]];
    _collectionsByName[name] = collection;
    return collection;
}

-(void)wakeyWakey{
    [_webView stringByEvaluatingJavaScriptFromString:nil];
}

- (JSValue *)invokeMethod:(NSString *)method withArguments:(NSArray *)arguments{
    [self wakeyWakey];
    return [self.value invokeMethod:method withArguments:arguments];
}

/*
-(NSString*)newObjectID{
    [self wakeyWakey];
    JSValue* objectIDValue = [self.value.context[@"Mongo"][@"ObjectID"] constructWithArguments:nil];
    JSValue* documentIDValue = [objectIDValue invokeMethod:@"toHexString" withArguments:nil];
    return documentIDValue.toString;
}
 */

-(NSString*)newRandomID{
    [self wakeyWakey];
    JSValue* documentIDValue = [self.value.context[@"Random"] invokeMethod:@"id" withArguments:nil];
    return documentIDValue.toString;
}

-(void)_startedUp:(void(^)())startedUp{
    NSAssert(startedUp, @"startedUp cannot be null");
    id startupBlock = ^(){
        dispatch_async(dispatch_get_main_queue(), ^{
            startedUp();
        });
    };
    [self invokeMethod:@"startup" withArguments:@[startupBlock]];
}

-(void)disconnect{
    [self invokeMethod:@"disconnect" withArguments:nil];
}

-(void)reconnect{
    [self invokeMethod:@"reconnect" withArguments:nil];
}

-(void)subscribeWithName:(NSString*)subscriptionName readyHandler:(void(^)())readyHandler{
    NSAssert(subscriptionName, @"subscriptionName cannot be null");
    id readyBlock = ^() {
        NSLog(@"ready");
        // push to next event loop
        dispatch_async(dispatch_get_main_queue(),^{
            readyHandler();
        });
    };
    // ready isnt called when offline
    [self invokeMethod:@"subscribe" withArguments:@[subscriptionName, readyBlock]];
}

-(MHSession*)session{
    if(_session){
        return _session;
    }
    _session = [[MHSession alloc] initWithMeteor:self value:self.value.context[@"Session"]];
    return _session;
}

@end
