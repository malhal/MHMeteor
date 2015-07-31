//
//  MHMeteorJSManagedValue.h
//  CoreMeteor
//
//  Created by Malcolm Hall on 12/05/2014.
//  Copyright (c) 2014 Malcolm Hall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@class MHMeteor;

@interface MHMeteorJSManagedValue : NSObject

@property (nonatomic, strong, readonly) MHMeteor* meteor;

//convenience access to self.value.context
@property (nonatomic, strong, readonly) JSContext* context;

@property (nonatomic, strong) JSValue* value;

- (instancetype)initWithMeteor:(MHMeteor*)meteor value:(JSValue*)value;

// convenience and importantly prevents the Web Thread [CFRunLoopTimer release] crash.
- (JSValue *)invokeMethod:(NSString *)method withArguments:(NSArray *)arguments;

@end