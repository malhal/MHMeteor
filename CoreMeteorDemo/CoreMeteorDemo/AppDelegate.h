//
//  AppDelegate.h
//  CoreMeteorDemo
//
//  Created by Malcolm Hall on 29/07/2015.
//  Copyright (c) 2015 Malcolm Hall. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "CoreMeteor.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) MHMeteor *meteor;
- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;


@end

