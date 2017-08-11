# MHMeteor
MHMeteor combines the Meteor javascript client with the best of Core Data to create a truly magical native iOS experience.

## Background
[Meteor](http://www.meteor.com) is a fantastic project, in my eyes one of the most exciting things to happen to the web. I thought the real-time sharing feature was mind-blowing and desperately wanted to bring it to my native iOS apps. To get the full experience of latency compensation, and off-line support I knew I needed more than just DDP, I needed the full javascript client stack inside my iOS application. Luckily it was around the same time Apple had released JavaScriptCore for iOS so implementing the required callbacks should be a breeze, however I hit a road block, the web thread was crashing with a CFRunLoopTimer release crash and no-one in the entire Internet had a solution. So month after month I kept re-visiting the issue in the hope of a solution and last week [I finally found it](http://stackoverflow.com/questions/23168779/ios-cfrunlooptimer-release-message-sent-to-deallocated-instance-error-debug/31673605#31673605). During this time I also learned NSIncrementalStore which let me throw away my managed object context clone and I could insert Meteor at exactly the right place, allowing the seamless use of the XCode model editor and one of the best classes in CoreData - NSFetchedResultsController. It also supports hot code and server restarts. I'm so excited about this project I knew I had to put it up on Github for others to see, so here it is. 

## How it Works
Its using the Meteor javascript client via a UIWebView and uses JavascriptCore to allow Objective C to call into javascript and receive callbacks. Using this technique an ObjC wrapper around the Meteor javascript API was created.

When using Core Data and an SQLite store normally data is queried and saved and there are no external changes made to the SQLite file. However with Meteor changes are pushed down to clients in realtime. This required a special kind of store that was able to observe these changes and notify the managed object context that changes were made. When the fetch request is exectute these observers are setup and the context will be notified in a way that makes any NSFetchedResultsControllers automatically update with the changes.

Thus Core Meteor is a combination of a Javascript wrapper and an NSIncrementalStore that receives external updates and updates the managed object context. 

## Limitations
Currently it is only advisable to create a single Managed Object Context on the main thread.
Relations are not supported yet.
Only create NSFetchedRequests to be used with NSFetchedResultsController.
The entity name has to match the collection name, and to match Meteor's style it is currently plural. E.g. in the demo app the entity is Tasks, where as normally with CoreData it would be the singular Task.

## Future Work
I'm hoping to enable fetch requests to work out side of the fetched results controller. Currently because of the reactive nature of Meteor, the initial fetch initially is always empty, with the results arriving later during the observeAdded call. However it might be useful to do fetches after some data has arrived so for that reason I'll likely implement a way to make a standard fetch along side the currently reactive fetch.
I've done some initial testing of using MHMeteor with the [appcache](https://github.com/meteor/meteor/wiki/AppCache) and [GroundDB](https://github.com/GroundMeteor/db) packages. These allow the app to launch and display data that was previously download on the last launch when a connection to the server was available. The behavior of GroundDB is not very well documented so I'm still learning its behavior and how best to configure it for use inside MHMeteor.
I plan on adding a User Info key to the Entity model to allow the entity name to be different from the Meteor collection name so it doesn't need to be a plural.

## Demo Video
I've uploaded a video to demonstrate the capabilities. You'll see a simulator on the left, a web page in the middle and an iPhone on the right, it's connected via Quicktime's iPhone capture using the lightning cable. You will see records being added, modified and being deleted, and also what happens when the iPhone goes in airplane mode and comes back online.

[![MHMeteor — Demo Video](http://img.youtube.com/vi/hPbU_gfHXu8/0.jpg)](https://www.youtube.com/watch?v=hPbU_gfHXu8) 

## Demo Application
I've included a demo application which is basically Apple's Master-Detail template with CoreData checked, and a few modifications to make it use MHMeteor. In the AppDelegate Meteor is started up and the rootViewController is added afterwards, and the MHMIncrementalStore is created. Then there are a few modifications to the MasterViewController noted at the top. Also the model was changed to add the Task fields, and the detail segue was unhooked in the storyboard.

## How to Use
All you need to do is startup meteor and create the incremental store, and then everything the same as a normal CoreData application.

### Starting up Meteor
This is how to startup MHMeteor - it will keep trying to connect until it succeeds. If the javascript on the server changes then the block will be called again with the isRestart flag true.
```objc
[MHMContainer startupMeteorWithURL:[NSURL URLWithString:url] startedUpHandler:^(MHMContainer *container, BOOL isRestart) {
}];
```

### Creating the Incremental Store
Once Meteor has started and you have the instance, then you can create add the MHMeteorIncrementalStore persistent stor as follows:
```objc
NSError* error;
[_persistentStoreCoordinator addPersistentStoreWithType:[MHMIncrementalStore type] configuration:nil URL:nil options:@{@"meteor" : _meteor} error:&error];
```

### Creating the NSFetchedResultsController
Create it as normal and it will update automatically as changes to the collection are received from the server.

### Other Meteor API
Many other methods in the Meteor API have been implemented, such as collections, cursors and live query handles, feel free to explore and let me know if anything is missing that you would like to see.

## Credits
MHMeteor was created by [Malcolm Hall](http://www.malcolmhall.com)

## Contact 
Follow Malcolm Hall on [Twitter](http://twitter.com/malhal) and [GitHub](http://github.com/malhal)

## License
MHMeteor is available under the MIT license.
It uses [NSPredicate-MongoDB-Adaptor](https://github.com/tjboneman/NSPredicate-MongoDB-Adaptor) created by Tim Bansemer under the Apache license.
See the LICENSE file for more info.
