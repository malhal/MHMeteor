//
//  MHMongoLiveQueryHandle.m
//  CoreMeteor
//
//  Created by Malcolm Hall on 12/05/2014.
//  Copyright (c) 2014 Malcolm Hall. All rights reserved.
//

#import "MHMongoLiveQueryHandle.h"

@implementation MHMongoLiveQueryHandle

- (instancetype)_initWithType:(NSString*)type block:(id)block meteor:(MHMeteor*)meteor value:(JSValue*)value{
    self = [super initWithMeteor:meteor value:value];
    if(self) {
        _block = block;
        _type = type;
    }
    return self;
}

-(void)stop{
    [self invokeMethod:@"stop" withArguments:nil];
}

-(void)dealloc{
    [self stop];
}

@end
