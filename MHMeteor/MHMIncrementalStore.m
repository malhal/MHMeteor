//
//  MHMeteorIncrementalStore.m
//  CoreMeteor
//
//  Created by Malcolm Hall on 26/07/2015.
//  Copyright (c) 2015 Malcolm Hall. All rights reserved.
//

#import "MHMIncrementalStore.h"
#import "MHMContainer.h"
#import "MongoDBPredicateAdaptor.h"
#import "MHMCursor.h"
#import "MHMCollection.h"

static NSString* const kMeteorDocumentIDKey = @"_id";
static NSString* const kCollectionNameUserInfoKey = @"collectionName";
NSString* const MHMIncrementalStoreContainerKey = @"container";

@interface MHMIncrementalStore()
@property (retain) NSMutableArray* liveQueryHandles;
@property (retain) MHMCursor* cursor;
@end

@implementation MHMIncrementalStore{
    MHMContainer* _container;
    NSMutableDictionary* _changedUserInfo;
}

+(void)initialize{
    if(self == [MHMIncrementalStore class]){
        [NSPersistentStoreCoordinator registerStoreClass:self forStoreType:self.type];
    }
}

+(NSString*)type{
    return NSStringFromClass(self);
}

-(BOOL)loadMetadata:(NSError **)error{
    NSLog(@"options %@", self.options);
    _container = self.options[MHMIncrementalStoreContainerKey];
    NSAssert(_container, @"container must be in the options dictionary");
    self.liveQueryHandles = [NSMutableArray array];
    _changedUserInfo = [NSMutableDictionary dictionary];
    return YES;
}

- (id)executeRequest:(NSPersistentStoreRequest *)persistentStoreRequest withContext:(NSManagedObjectContext*)context error:(NSError **)error{
    if(persistentStoreRequest.requestType == NSFetchRequestType)
    {
        NSFetchRequest* fetchRequest = (NSFetchRequest*)persistentStoreRequest;
        
        MHMCollection* collection = [_container collectionNamed:fetchRequest.entity.userInfo[kCollectionNameUserInfoKey]];
        if(!collection){
#warning - todo read the collection name out of a custom entity property created in the model editor.
            collection = [_container collectionNamed:[fetchRequest.entityName lowercaseString]];
            // at this point we don't know if there was a server collection with same name so we can't error.
        }
        NSDictionary* mongoSelector = nil;
        if(fetchRequest.predicate){
            mongoSelector = [MongoDBPredicateAdaptor queryDictFromPredicate:fetchRequest.predicate orError:error];
            if(!mongoSelector){
                if(error){
                    if (error) {
                        *error = [[NSError alloc] initWithDomain:MHMeteorErrorDomain code:0 userInfo:@{NSLocalizedFailureReasonErrorKey:@"The NSPredicate could not be converted to a Mongo selector"}];
                    }
                    return nil;
                }
            }
        }
        NSMutableDictionary* options = [NSMutableDictionary dictionary];
        
        // we can't only request the id because then observe changes doesn't work.
        //options[@"fields"] =  @{@"_id" : @1};
        
        if(fetchRequest.sortDescriptors.count){
            //todo: make real
            NSMutableArray* fixed = [NSMutableArray array];
            for(NSSortDescriptor* s in fetchRequest.sortDescriptors){
                [fixed addObject:@[s.key , s.ascending ? @"asc" : @"desc"]];
            }
            options[@"sort"] = fixed;
        }
        //testingb
        if(fetchRequest.fetchOffset > 0){
            options[MHMCollectionSkipOption] = @(fetchRequest.fetchOffset);
        }
        
        self.cursor = [collection findWithMongoSelector:mongoSelector options:options];
        
        //observe changes before fetching so we don't miss any.
        MHMLiveQueryHandle* changedHandle = [_cursor observeChangesDocumentIDChanged:^(NSString *documentID, NSDictionary *fields) {
            NSLog(@"observeChangesDocumentIDChanged %@", documentID);
            NSManagedObjectID* objectID = [self newObjectIDForEntity:fetchRequest.entity referenceObject:documentID];
            NSManagedObject* obj = [context objectRegisteredForID:objectID];
            // obj might have been deleted
            if(obj){
                [context refreshObject:obj mergeChanges: YES];
                [self _object:obj didChange:NSUpdatedObjectsKey context:context];
            }
        }];
        [_liveQueryHandles addObject:changedHandle];

        MHMLiveQueryHandle* addedHandle = [_cursor observeChangesDocumentIDAdded:^(NSString *documentID, NSDictionary *fields) {
            NSLog(@"observeChangesDocumentIDAdded %@", documentID);
            NSManagedObjectID* objectID = [self newObjectIDForEntity:fetchRequest.entity referenceObject:documentID];
            NSManagedObject* obj = [context objectWithID:objectID];
            
           //[obj willAccessValueForKey: nil];
           [context refreshObject:obj mergeChanges: NO];
           [self _object:obj didChange:NSInsertedObjectsKey context:context];
        }];
        [_liveQueryHandles addObject:addedHandle];
        
        MHMLiveQueryHandle* removedHandle = [_cursor observeChangesDocumentIDRemoved:^(NSString *documentID) {
            NSLog(@"observeChangesDocumentIDRemoved %@", documentID);
            NSManagedObjectID* objectID = [self newObjectIDForEntity:fetchRequest.entity referenceObject:documentID];
            NSManagedObject* obj = [context objectRegisteredForID:objectID];
            
            // the object will be nil if we were the one that deleted it and this is just the notification coming back in.
            // if we do have the object then we need to fake delete it from the context.
            if(obj){
                [self _object:obj didChange:NSDeletedObjectsKey context:context];
            }
        }];
        [_liveQueryHandles addObject:removedHandle];
    
        // fetch the records, if the subscription isn't ready there won't be any and they will arrive in the added handler instead.
        NSArray* documents = [_cursor fetch];
        NSMutableArray* result = [NSMutableArray array];
        //convert to Meteor objects
        for(NSDictionary* document in documents){
            NSManagedObjectID* objectID = [self newObjectIDForEntity:fetchRequest.entity referenceObject:document[@"_id"]];
            NSManagedObject* obj = [context objectWithID:objectID];
            [result addObject:obj];
        }
        return result;
    }
    else if(persistentStoreRequest.requestType == NSSaveRequestType){
        NSSaveChangesRequest* request = (NSSaveChangesRequest*)persistentStoreRequest;
        for (NSManagedObject* object in request.updatedObjects) {
            MHMCollection* collection = [_container collectionNamed:object.entity.userInfo[kCollectionNameUserInfoKey]];
            NSString* documentID = (NSString*)[self referenceObjectForObjectID:object.objectID];
            NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary:object.changedValues];
            [self _convertBooleansInDictionary:dict];
            [collection updateDocumentWithID:documentID setFields:dict];
        }
        for(NSManagedObject* object in request.insertedObjects){
            MHMCollection* collection = [_container collectionNamed:object.entity.userInfo[kCollectionNameUserInfoKey]];
            NSString* documentID = (NSString*)[self referenceObjectForObjectID:object.objectID];
            NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary:object.changedValues];
            [self _convertBooleansInDictionary:dict];
            dict[kMeteorDocumentIDKey] = documentID;
            [collection insertDocument:dict documentInserted:nil];
        }
        for(NSManagedObject* object in request.deletedObjects){
            MHMCollection* collection = [_container collectionNamed:object.entity.userInfo[kCollectionNameUserInfoKey]];
            NSString* documentID = (NSString*)[self referenceObjectForObjectID:object.objectID];
            [collection removeDocumentWithID:documentID documentRemoved:nil];
        }
        return @[];
    }
    return nil;
}

// Coelesce the notifications for effiency.
// when using GroundDB objects are deleted and inserted at the same time.
-(void)_object:(NSManagedObject*)object didChange:(NSString*)changeType context:(NSManagedObjectContext*)context{
    NSLog(@"didChange %@", changeType);
    NSMutableSet* set = _changedUserInfo[changeType];
    if(!set){
        set = [NSMutableSet set];
        _changedUserInfo[changeType] = set;
    }
    [set addObject:object];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_delayedObjectsDidChange:) object:context];
    [self performSelector:@selector(_delayedObjectsDidChange:) withObject:context afterDelay:0];
}

-(void)_delayedObjectsDidChange:(NSManagedObjectContext*)context{
    NSLog(@"_delayedObjectsDidChange");
    _changedUserInfo[@"managedObjectContext"] = context;
    // Post the private notification for NSFetchedResultsController
    [[NSNotificationCenter defaultCenter] postNotificationName:@"_NSObjectsChangedInManagingContextPrivateNotification" object:context userInfo:_changedUserInfo];
    // Post the public notification
    [[NSNotificationCenter defaultCenter] postNotificationName:NSManagedObjectContextObjectsDidChangeNotification object:context userInfo:_changedUserInfo];
    // reset the user info for next time
    [_changedUserInfo removeAllObjects];
}

// fix issue with boolean NSNumbers coming out of NSManagedObjects ending up in javascript as integers.
-(void)_convertBooleansInDictionary:(NSMutableDictionary*)dict{
    for(NSString* key in dict.allKeys){
        id obj = dict[key];
        if([obj isKindOfClass:[NSMutableDictionary class]]){
            [self _convertBooleansInDictionary:obj];
        }
        else if([obj isKindOfClass:[NSNumber class]]){
            NSNumber* num = (NSNumber*)obj;
            if(strcmp([num objCType], "c") == 0) {
                dict[key] = [NSNumber numberWithBool:num.boolValue];
            }
        }
    }
}

- (NSIncrementalStoreNode *)newValuesForObjectWithID:(NSManagedObjectID*)objectID withContext:(NSManagedObjectContext*)context error:(NSError**)error{
    NSLog(@"newValuesForObjectWithID");
    NSString* documentID = (NSString*)[self referenceObjectForObjectID:objectID];

    MHMCollection* collection = [_container collectionNamed:objectID.entity.userInfo[kCollectionNameUserInfoKey]];
    NSDictionary* options = @{@"fields" : @{@"_id" : @0}};
    NSDictionary* doc = [collection findOneWithDocumentID:documentID options:options];
    
    NSIncrementalStoreNode* node =
    [[NSIncrementalStoreNode alloc] initWithObjectID:objectID
                                          withValues:doc
                                             version:1];
    
    return node;
}

- (id)newValueForRelationship:(NSRelationshipDescription*)relationship forObjectWithID:(NSManagedObjectID*)objectID withContext:(NSManagedObjectContext *)context error:(NSError **)error{
    //return [_destinationPersistentStore newValueForRelationship:relationship forObjectWithID:objectID withContext:context error:error];
    return nil;
}

- (NSArray*)obtainPermanentIDsForObjects:(NSArray*)array error:(NSError **)error{
    NSMutableArray *permanentIDs = [NSMutableArray arrayWithCapacity:array.count];
    [array enumerateObjectsUsingBlock:^(NSManagedObject* obj, NSUInteger idx, BOOL *stop) {
        NSString* documentID = _container.newObjectID;
        NSManagedObjectID* objectID = [self newObjectIDForEntity:obj.entity referenceObject:documentID];
        [permanentIDs addObject:objectID];
    }];
    return permanentIDs;
}

// increment that its being used
/*
- (void)managedObjectContextDidRegisterObjectsWithIDs:(NSArray*)objectIDs{
    NSLog(@"Registered objects");
    //[_destinationPersistentStore managedObjectContextDidRegisterObjectsWithIDs:objectIDs];
}
*/
// decrement that its being used
/*
- (void)managedObjectContextDidUnregisterObjectsWithIDs:(NSArray*)objectIDs{
    NSLog(@"Unregistered objects");
#warning - todo improve this to work with multiple contexts.
    for(NSManagedObjectID* objectID in objectIDs){
        NSString* documentID = (NSString*)[self referenceObjectForObjectID:objectID];
    }
}
*/

@end
