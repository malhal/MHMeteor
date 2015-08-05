//
//  MHSession.m
//  CoreMeteorDemo
//
//  Created by Malcolm Hall on 04/08/2015.
//  Copyright (c) 2015 Malcolm Hall. All rights reserved.
//

#import "MHSession.h"

@implementation MHSession

-(void)setValue:(id)value forUndefinedKey:(NSString *)key{
    [self invokeMethod:@"set" withArguments:@[key, value]];
}

-(id)valueForUndefinedKey:(NSString *)key{
    return [self invokeMethod:@"get" withArguments:@[key]].toObject;
}

- (id)objectForKeyedSubscript:(NSString*)key{
    return [self valueForKey:key];
}

- (void)setObject:(id)object forKeyedSubscript:(NSString*)key{
    [self setValue:object forKey:key];
}

@end
