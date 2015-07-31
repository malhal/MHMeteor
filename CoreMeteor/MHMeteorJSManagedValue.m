//
//  MHMeteorJSManagedValue.m
//  CoreMeteor
//
//  Created by Malcolm Hall on 12/05/2014.
//  Copyright (c) 2014 Malcolm Hall. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "MHMeteorJSManagedValue.h"
#import "MHMeteor.h"

@interface MHMeteor()

@property (strong, readonly) UIWebView* webView;

@end

@implementation MHMeteorJSManagedValue{
    JSManagedValue* _managedValue;
}

- (instancetype)initWithMeteor:(MHMeteor*)meteor value:(JSValue*)value{
    self = [super init];
    if (self) {
        _meteor = meteor;
        self.value = value;
    }
    return self;
}

-(void)setValue:(JSValue *)value{
    _managedValue = [[JSManagedValue alloc] initWithValue:value];
    [self.context.virtualMachine addManagedReference:_managedValue withOwner:_meteor];
}

-(JSContext*)context{
    return self.value.context;
}

-(JSValue*)value{
    return _managedValue.value;
}

-(void)dealloc{
    NSLog(@"MHMeteorJSManagedValue dealloc");
    [self.context.virtualMachine removeManagedReference:self.value withOwner:_meteor];
}

- (JSValue *)invokeMethod:(NSString *)method withArguments:(NSArray *)arguments{
    // Took a year or for me to figure out this workaround so it has a fun name:
    // http://stackoverflow.com/questions/23168779/ios-cfrunlooptimer-release-message-sent-to-deallocated-instance-error-debug/31673605#31673605
    [self.meteor.webView stringByEvaluatingJavaScriptFromString:nil];
    return [self.value invokeMethod:method withArguments:arguments];
}

@end