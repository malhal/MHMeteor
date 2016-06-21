//
//  MHMeteorIncrementalStore.h
//  CoreMeteor
//
//  Created by Malcolm Hall on 26/07/2015.
//  Copyright (c) 2015 Malcolm Hall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

extern NSString* const MHMIncrementalStoreContainerKey;

@interface MHMIncrementalStore : NSIncrementalStore

+(NSString*)type;

@end
