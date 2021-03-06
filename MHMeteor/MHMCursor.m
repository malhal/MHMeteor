//
//  MHMCursor.m
//  CoreMeteor
//
//  Created by Malcolm Hall on 12/05/2014.
//  Copyright (c) 2014 Malcolm Hall. All rights reserved.
//

#import "MHMCursor.h"
#import "MHMContainer.h"
#import "MHMLiveQueryHandle.h"

@interface MHMLiveQueryHandle(Private)
- (instancetype)_initWithType:(NSString*)type block:(id)block container:(MHMContainer*)container value:(JSValue*)value;
@end

@implementation MHMCursor{
    
    NSMutableArray* _observeQueryHandles;
    NSMutableArray* _observeChangesQueryHandles;
    
}

- (instancetype)_initWithSelector:(id)selector options:(id)options container:(MHMContainer*)container value:(JSValue*)value{
    self = [super initWithContainer:container value:value];
    if(self) {
        _selector = selector;
        _options = options;
        _observeQueryHandles = [NSMutableArray array];
        _observeChangesQueryHandles = [NSMutableArray array];
    }
    return self;
}

-(NSArray*)fetch{
    JSValue* documents = [self invokeMethod:@"fetch" withArguments:nil];
    return [documents toObjectOfClass:[NSArray class]];
}

-(void)setValue:(JSValue *)value{
    [super setValue:value];
    // observe
    for(MHMLiveQueryHandle* observeQueryHandle in _observeQueryHandles){
        JSValue* callbacks = [JSValue valueWithNewObjectInContext:self.value.context];
        callbacks[observeQueryHandle.type] = observeQueryHandle.block;
        observeQueryHandle.value = [self invokeMethod:@"observe" withArguments:@[callbacks]];
    }
    // observe changes
    for(MHMLiveQueryHandle* observeChangesQueryHandle in _observeChangesQueryHandles){
        JSValue* callbacks = [JSValue valueWithNewObjectInContext:self.value.context];
        callbacks[observeChangesQueryHandle.type] = observeChangesQueryHandle.block;
        observeChangesQueryHandle.value = [self invokeMethod:@"observeChanges" withArguments:@[callbacks]];
    }
}

#pragma mark Observe

-(MHMLiveQueryHandle*)_observe:(NSString*)type block:(id)block{
    JSValue* v = [self invokeMethod:@"observe" withArguments:@[@{type : block}]];
    MHMLiveQueryHandle* liveQueryHandle = [[MHMLiveQueryHandle alloc] _initWithType:type block:block container:self.container value:v];
    [_observeQueryHandles addObject:liveQueryHandle];
    return liveQueryHandle;
}

-(MHMLiveQueryHandle*)observeDocumentAdded:(MHMCursorDocument)documentAdded{
    id addedBlock = ^(JSValue *documentValue) {
        //NSLog(@"addedBlock");
        NSDictionary* document = [documentValue toObjectOfClass:[NSDictionary class]];
        // push to next event loop
      //  dispatch_async(dispatch_get_main_queue(),^{
            documentAdded(document);
     //   });
    };
    return [self _observe:@"added" block:addedBlock];
}

-(MHMLiveQueryHandle*)observeDocumentAddedAt:(MHMCursorDocumentAddedAt)documentAddedAt{
    id addedAtBlock = ^(JSValue *newDocument, JSValue* atIndex, JSValue* before) {
        //NSLog(@"addedAtBlock");
        NSDictionary* newDict = [newDocument toObjectOfClass:[NSDictionary class]];
        NSNumber* at = [atIndex toObject];
        NSDictionary* beforeDict = [before toObjectOfClass:[NSDictionary class]];
        // push to next event loop
        //dispatch_async(dispatch_get_main_queue(),^{
            documentAddedAt(newDict, at, beforeDict);
     //   });
    };
    return [self _observe:@"addedAt" block:addedAtBlock];
}

-(MHMLiveQueryHandle*)observeDocumentChanged:(MHMCursorDocumentChanged)documentChanged{
    id changedBlock = ^(JSValue *newDocument, JSValue* oldDocument) {
        //NSLog(@"changedBlock");
        NSDictionary* newDict = [newDocument toObjectOfClass:[NSDictionary class]];
        NSDictionary* oldDict = [oldDocument toObjectOfClass:[NSDictionary class]];
    //    dispatch_async(dispatch_get_main_queue(),^{
            documentChanged(newDict,oldDict);
    //    });
    };
    return [self _observe:@"changed" block:changedBlock];
}

-(MHMLiveQueryHandle*)observeDocumentRemoved:(MHMCursorDocument)removedDocument{
    id removedBlock = ^(JSValue* documentValue) {
        //NSLog(@"removedBlock");
        NSDictionary* document = [documentValue toObjectOfClass:[NSDictionary class]];
     //   dispatch_async(dispatch_get_main_queue(),^{
            removedDocument(document);
     //   });
    };
    return [self _observe:@"removed" block:removedBlock];
}

-(MHMLiveQueryHandle*)observeDocumentMoved:(MHMCursorDocumentMoved)movedDocument{
    id movedBlock = ^(JSValue *document, JSValue* fromIndex,JSValue* toIndex, JSValue* before) {
        NSDictionary* dict = [document toObjectOfClass:[NSDictionary class]];
        NSNumber* from = [fromIndex toObject];
        NSNumber* to = [toIndex toObject];
      //  dispatch_async(dispatch_get_main_queue(),^{
            movedDocument(dict,from,to,[before toObject]);
     //   });
    };
    return [self _observe:@"moved" block:movedBlock];
};


#pragma mark Observe Changes

-(MHMLiveQueryHandle*)_observeChanges:(NSString*)type block:(id)block{
    JSValue* v = [self invokeMethod:@"observeChanges" withArguments:@[@{type : block}]];
    MHMLiveQueryHandle* liveQueryHandle = [[MHMLiveQueryHandle alloc] _initWithType:type block:block container:self.container value:v];
    [_observeChangesQueryHandles addObject:liveQueryHandle];
    return liveQueryHandle;
}

-(MHMLiveQueryHandle*)observeChangesDocumentIDChanged:(MHMCursorDocumentIDAndFields)documentIDChanged{
    id changedBlock = ^(JSValue *documentIDValue, JSValue* fieldsValue) {
        NSString* documentID = [documentIDValue toString];
        NSDictionary* fields = [fieldsValue toObjectOfClass:[NSDictionary class]];
     //   dispatch_async(dispatch_get_main_queue(),^{
            documentIDChanged(documentID, fields);
     //   });
    };
    return [self _observeChanges:@"changed" block:changedBlock];
}

-(MHMLiveQueryHandle*)observeChangesDocumentIDAdded:(MHMCursorDocumentIDAndFields)documentIDAdded{
    id addedBlock = ^(JSValue *documentIDValue, JSValue* fieldsValue) {
        NSString* documentID = [documentIDValue toString];
        NSDictionary* fields = [fieldsValue toObjectOfClass:[NSDictionary class]];
      //  dispatch_async(dispatch_get_main_queue(),^{
            documentIDAdded(documentID, fields);
      //  });
    };
    return [self _observeChanges:@"added" block:addedBlock];
}

-(MHMLiveQueryHandle*)observeChangesDocumentIDAddedBefore:(MHMCursorDocumentIDAddedBefore)documentIDAddedBefore{
    id addedBeforeBlock = ^(JSValue *documentIDValue, JSValue* fieldsValue, JSValue* beforeDocumentIDValue) {
        NSString* documentID = [documentIDValue toString];
        NSDictionary* fields = [fieldsValue toObjectOfClass:[NSDictionary class]];
        NSString* beforeDocumentID = [beforeDocumentIDValue toString];
       // dispatch_async(dispatch_get_main_queue(),^{
            documentIDAddedBefore(documentID, fields, beforeDocumentID);
      //  });
    };
    return [self _observeChanges:@"addedBefore" block:addedBeforeBlock];
}

-(MHMLiveQueryHandle*)observeChangesDocumentIDMovedBefore:(MHMCursorDocumentIDMovedBefore)documentIDMovedBefore{
    id movedBeforeBlock = ^(JSValue *documentIDValue, JSValue* beforeDocumentIDValue) {
        NSString* documentID = [documentIDValue toString];
        NSString* beforeDocumentID = [beforeDocumentIDValue toString];
     //   dispatch_async(dispatch_get_main_queue(),^{
            documentIDMovedBefore(documentID, beforeDocumentID);
     //   });
    };
    return [self _observeChanges:@"movedBefore" block:movedBeforeBlock];
}

-(MHMLiveQueryHandle*)observeChangesDocumentIDRemoved:(MHMCursorDocumentID)documentIDRemoved{
    id removedBlock = ^(JSValue *documentIDValue) {
        NSString* documentID = [documentIDValue toString];
        //dispatch_async(dispatch_get_main_queue(),^{
            documentIDRemoved(documentID);
       // });
    };
    return [self _observeChanges:@"removed" block:removedBlock];
}

@end
