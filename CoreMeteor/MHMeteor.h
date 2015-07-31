//
//  MHMeteor.h
//  CoreMeteor
//
//  Created by Malcolm Hall on 12/05/2014.
//  Copyright (c) 2014 Malcolm Hall. All rights reserved.
//

// Main entry point into Meteor.

#import <JavaScriptCore/JavaScriptCore.h>

extern NSString* const MHMeteorErrorDomain;

@class MHMongoCollection;

@interface MHMeteor : NSObject

@property (nonatomic, strong, readonly) JSValue* value;

//loads Meteor with default caching, timeouts for 30 seconds.
//It will keep trying to connect and call the completion handler when ready.
+(void)startupMeteorWithURL:(NSURL*)url startedUpHandler:(void(^)(MHMeteor*, BOOL isRestart))startedUpHandler;

//Use if perfer to specify request using custom caching.
+(void)startupWithRequest:(NSURLRequest*)request startedUpHandler:(void(^)(MHMeteor*, BOOL isRestart))startedUpHandler;

// use if the collection is already declared in the javascript's isClient code. Usually starts with an uppercase letter, e.g. Tasks
- (MHMongoCollection*)collectionForGlobalID:(NSString*)globalID;

// use for constructing a collection that is not already constructed in the javascript's isClient code, but must be in its isServer code. Usually all lower case.
- (MHMongoCollection*)collectionNamed:(NSString*)name;

-(void)disconnect;

-(void)reconnect;

@end
