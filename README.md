# CoreMeteor
CoreMeteor combines the Meteor javascript client with the best of Core Data to create a truly magical native iOS experience.

[Meteor](http://www.meteor.com) is a fantastic project, in my eyes one of the most exciting things to happen to the web. I thought the real-time sharing feature was mind-blowing and desperately wanted to bring it to my native iOS apps. To get the full experience of latency compensation, and off-line support I knew I needed more than just DDP, I needed the full javascript client stack inside my iOS application. Luckily it was around the same time Apple had released JavaScriptCore for iOS so implementing the required callbacks should be a breeze, however I hit a road block, the web thread was crashing with a CFRunLoopTimer release crash and no-one in the entire Internet had a solution. So month after month I kept re-visiting the issue in the hope of a solution and last week [I finally found it](http://stackoverflow.com/questions/23168779/ios-cfrunlooptimer-release-message-sent-to-deallocated-instance-error-debug/31673605#31673605). During this time I also learned NSIncrementalStore which let me throw away my managed object context clone and I could insert Meteor at exactly the right place, allowing the seemless use of the XCode model editor and one of the best classes in CoreData - NSFetchedResultsController. It also supports hot code and server restarts. I'm so excited about this project I knew I had to put it up on Github for others to see, so here it is. 

##Demo Video
I've uploaded a video to demonstrate the capabilities. You'll see a simulator on the left, a web page in the middle and an iPhone on the right, it's connected via Quicktime's iPhone capture using the lightning cable. You will see records being added, modified and being deleted, and also what happens when the iPhone goes in airplane mode and comes back online.

[![CoreMeteor — Demo Video](http://img.youtube.com/vi/hPbU_gfHXu8/0.jpg)](https://www.youtube.com/watch?v=hPbU_gfHXu8) 

##Demo Application
I've included a demo application which is basically Apple's Master-Detail template with CoreData checked, and a few modifications to make it use CoreMeteor. In the AppDelegate Meteor is started up and the rootViewController is added afterwards, and the MHMeteorIncrementalStore is created. Then there are a few modifications to the MasterViewController noted at the top. Also the model was changed to add the Task fields, and the detail segue was unhooked in the storyboard.

##How to Use
All you need to do is startup meteor and create the incremental store, and then everything the same as a normal CoreData application.

###Starting up Meteor
This is how to startup CoreMeteor - it will keep trying to connect until it succeeds. If the javascript on the server changes then the block will be called again with the isRestart flag true.
```objc
[MHMeteor startupMeteorWithURL:[NSURL URLWithString:url] startedUpHandler:^(MHMeteor *meteor, BOOL isRestart) {
}];
```

###Creating the Incremental Store
Once Meteor has started and you have the instance, then you can create add the MHMeteorIncrementalStore persistent stor as follows:
```objc
NSError* error;
[_persistentStoreCoordinator addPersistentStoreWithType:[MHMeteorIncrementalStore type] configuration:nil URL:nil options:@{@"meteor" : _meteor} error:&error];
```

###Other Meteor API
Many other methods in the Meteor API have been implemented, such as collections, cursors and live query handles, feel free to explore and let me know if anything is missing that you would like to see.

## Credits
CoreMeteor was created by [Malcolm Hall](http://www.malcolmhall.com)

## Contact 
Follow Malcolm Hall on [Twitter](http://twitter.com/malhal) and [GitHub](http://github.com/malhal)

## License
CoreMeteor is available under the MIT license.
It uses [NSPredicate-MongoDB-Adaptor](https://github.com/tjboneman/NSPredicate-MongoDB-Adaptor) created by Tim Bansemer under the Apache license.
See the LICENSE file and LICENSES folder for more info.
