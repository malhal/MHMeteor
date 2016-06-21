//
//  MHSession.h
//  CoreMeteorDemo
//
//  Created by Malcolm Hall on 04/08/2015.
//  Copyright (c) 2015 Malcolm Hall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MHMeteor/MHMJSManagedValue.h>

@interface MHMSession : MHMJSManagedValue

- (id)objectForKeyedSubscript:(NSString*)key;

- (void)setObject:(id)object forKeyedSubscript:(NSString*)key;

@end
