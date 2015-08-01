//
//  MHMongoCollection.m
//  CoreMeteor
//
//  Created by Malcolm Hall on 12/05/2014.
//  Copyright (c) 2014 Malcolm Hall. All rights reserved.
//

#import "MHMongoCollection.h"
#import "MHMongoCursor.h"
#import "MHMeteor.h"
#import <CoreFoundation/CoreFoundation.h>
#import "MongoDBPredicateAdaptor.h"

 NSString * const MHMongoCollectionSortOption = @"sort";
 NSString * const MHMongoCollectionSkipOption = @"skip";
 NSString * const MHMongoCollectionLimitOption = @"limit";
 NSString * const MHMongoCollectionFieldsOption = @"fields";
 NSString * const MHMongoCollectionReactiveOption = @"reactive";
 NSString * const MHMongoCollectionTransformOption = @"transform";

@interface MHMongoCursor(Private)

- (instancetype)_initWithSelector:(id)selector options:(id)options meteor:(MHMeteor*)meteor value:(JSValue*)value;

@end

@implementation MHMongoCollection{
    NSMutableArray* _cursors;
}

- (instancetype)initWithMeteor:(MHMeteor*)meteor value:(JSValue*)value{
    self = [super initWithMeteor:meteor value:value];
    if(self) {
        _cursors = [NSMutableArray array];
    }
    return self;
}

-(void)setValue:(JSValue *)value{
    [super setValue:value];
    //refresh all the cursors
    for(MHMongoCursor* cursor in _cursors){
        cursor.value = [self invokeMethod:@"find" withArguments:@[cursor.selector,cursor.options]];
    }
}

-(MHMongoCursor*)find{
    return [self findWithMongoSelector:nil options:nil];
}

-(MHMongoCursor*)findWithMongoSelector:(NSDictionary*)mongoSelector options:(NSDictionary*)options{
    if(!mongoSelector){
        mongoSelector = [NSDictionary dictionary];
    }
    return [self _findWithSelector:mongoSelector options:options];
}

// selector could either be a dictionary or a string
-(MHMongoCursor*)_findWithSelector:(id)selector options:(NSDictionary*)options{
    NSAssert(selector, @"selector cannot be null"); // because a nil would end the arguments array.
    if(!options){
        options = [NSDictionary dictionary];
    }
    
    MHMongoCursor* cursor = [[MHMongoCursor alloc] _initWithSelector:selector
                                                             options:options
                                                              meteor:self.meteor
                                                               value:[self invokeMethod:@"find" withArguments:@[selector,options]]];
    [_cursors addObject:cursor];
    return cursor;
}

-(void)_updateDocumentWithSelector:(id)selector modifier:(NSDictionary*)modifier{
    NSAssert(selector, @"selector cannot be nil");
    if(!modifier){
        modifier = [NSDictionary dictionary];
    }
    [self invokeMethod:@"update" withArguments:@[selector, modifier]];
}

-(void)updateDocumentWithID:(NSString*)documentID modifier:(NSDictionary*)modifier{
    return [self _updateDocumentWithSelector:documentID modifier:modifier];
}

-(void)updateDocumentWithID:(NSString*)documentID setFields:(NSDictionary*)fields{
    return [self updateDocumentWithID:documentID modifier:@{@"$set" : fields}];
}

-(void)removeDocumentWithID:(NSString*)documentID documentRemoved:(MHMongoCollectionDocumentRemoved)documentRemoved{
     NSAssert(documentID, @"documentID cannot be nil");
    [self invokeMethod:@"remove" withArguments:@[documentID]];
}

-(void)insertDocument:(NSDictionary*)document documentInserted:(MHMongoCollectionDocumentInserted)documentInserted{
    NSAssert(document, @"document cannot be nil");
    [self invokeMethod:@"insert" withArguments:@[document]];
}



@end
