//
//  MHMCollection.m
//  CoreMeteor
//
//  Created by Malcolm Hall on 12/05/2014.
//  Copyright (c) 2014 Malcolm Hall. All rights reserved.
//

#import "MHMCollection.h"
#import "MHMCursor.h"
#import "MHMContainer.h"
//#import "MongoDBPredicateAdaptor.h"

 NSString * const MHMCollectionSortOption = @"sort";
 NSString * const MHMCollectionSkipOption = @"skip";
 NSString * const MHMCollectionLimitOption = @"limit";
 NSString * const MHMCollectionFieldsOption = @"fields";
 NSString * const MHMCollectionReactiveOption = @"reactive";
 NSString * const MHMCollectionTransformOption = @"transform";

@interface MHMCursor(Private)

- (instancetype)_initWithSelector:(id)selector options:(id)options container:(MHMContainer*)container value:(JSValue*)value;

@end

@implementation MHMCollection{
    NSMutableArray* _cursors;
}

- (instancetype)initWithContainer:(MHMContainer*)container value:(JSValue*)value{
    self = [super initWithContainer:container value:value];
    if(self) {
        _cursors = [NSMutableArray array];
    }
    return self;
}

-(void)setValue:(JSValue *)value{
    [super setValue:value];
    //refresh all the cursors
    for(MHMCursor* cursor in _cursors){
        cursor.value = [self invokeMethod:@"find" withArguments:@[cursor.selector,cursor.options]];
    }
}

-(MHMCursor*)find{
    return [self findWithMongoSelector:nil options:nil];
}

-(MHMCursor*)findWithMongoSelector:(NSDictionary*)mongoSelector options:(NSDictionary*)options{
    if(!mongoSelector){
        mongoSelector = [NSDictionary dictionary];
    }
    return [self _findWithSelector:mongoSelector options:options];
}

// selector could either be a dictionary or a string
-(MHMCursor*)_findWithSelector:(id)selector options:(NSDictionary*)options{
    NSAssert(selector, @"selector cannot be null"); // because a nil would end the arguments array.
    if(!options){
        options = [NSDictionary dictionary];
    }
    
    MHMCursor* cursor = [[MHMCursor alloc] _initWithSelector:selector
                                                             options:options
                                                              container:self.container
                                                               value:[self invokeMethod:@"find" withArguments:@[selector,options]]];
    [_cursors addObject:cursor];
    return cursor;
}

-(NSDictionary*)findOneWithDocumentID:(NSString*)documentID options:(NSDictionary*)options{
    NSAssert(documentID, @"documentID cannot be nil");
    return [self _findOneWithSelector:documentID options:options];
}

-(NSDictionary*)findOneWithMongoSelector:(NSDictionary*)mongoSelector options:(NSDictionary*)options{
    if(!mongoSelector){
        mongoSelector = [NSDictionary dictionary];
    }
    return [self _findOneWithSelector:mongoSelector options:options];
}

// selector could either be a dictionary or a string
-(NSDictionary*)_findOneWithSelector:(id)selector options:(NSDictionary*)options{
    NSAssert(selector, @"selector cannot be null"); // because a nil would end the arguments array.
    if(!options){
        options = [NSDictionary dictionary];
    }
    JSValue* documentValue = [self invokeMethod:@"findOne" withArguments:@[selector, options]];
    return [documentValue toObjectOfClass:[NSDictionary class]];
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

-(void)removeDocumentWithID:(NSString*)documentID documentRemoved:(MHMCollectionDocumentRemoved)documentRemoved{
     NSAssert(documentID, @"documentID cannot be nil");
    [self invokeMethod:@"remove" withArguments:@[documentID]];
}

-(void)insertDocument:(NSDictionary*)document documentInserted:(MHMCollectionDocumentInserted)documentInserted{
    NSAssert(document, @"document cannot be nil");
    JSValue* value = [self invokeMethod:@"insert" withArguments:@[document]];
    NSLog(@"%@", value);
}



@end
