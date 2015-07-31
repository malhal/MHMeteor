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
}

-(void)setValue:(JSValue *)value{
    //refresh all the collections
    for(NSString* globalID in _collectionsByGlobalID.allKeys){
        MHMongoCollection* collection = _collectionsByGlobalID[globalID];
        collection.value = value.context[globalID];
    }
    for(NSString* name in _collectionsByName){
        MHMongoCollection* collection = _collectionsByGlobalID[name];
        collection.value = [value.context[@"Mongo"][@"Collection"]  constructWithArguments:@[name]];
    }
    _value = value;
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

-(void)_startedUp:(void(^)())startedUp{
    NSAssert(startedUp, @"startedUp cannot be null");
    [self invokeMethod:@"startup" withArguments:@[startedUp]];
}

-(void)disconnect{
    [self invokeMethod:@"disconnect" withArguments:nil];
}

-(void)reconnect{
    [self invokeMethod:@"reconnect" withArguments:nil];
}

-(void)subscribeToRecordSet:(NSString*)recordSet completionHandler:(void(^)())completionHandler{
    NSAssert(recordSet, @"recordSet cannot be null");
    [self invokeMethod:@"subscribe" withArguments:@[recordSet,completionHandler]];
}

-(void)dealloc{
    NSLog(@"dealloc");
}
@end
