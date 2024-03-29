#import "CloudDBManager.h"
#import "SystemException.h"
#import "ManagedObjectModelFactory.h"

static CloudDBManager *singleton = nil;


@implementation CloudDBManager

@synthesize coordinator;
@synthesize mainContext;

+(CloudDBManager *) getInstance
{
	if(singleton)
	{
		return singleton;
	}
	
	@synchronized([CloudDBManager class])
	{
		if(singleton == nil)
		{
			singleton = [[CloudDBManager alloc] init];
		}
	}
	
	return singleton;
}

+(void)stop
{
	@synchronized([CloudDBManager class])
	{
		if(singleton != nil)
		{
			[self release];
			singleton = nil;
		}
	}
}

-(void) dealloc
{
    [self.coordinator release];
    if(self.mainContext != nil)
    {
        [self.mainContext release];
    }
	[super dealloc];
}

-init
{
	if(self == [super init])
	{
        @try
        {
            self.coordinator = [self persistentStoreCoordinator];
        }
        @catch(SystemException *se)
        {
            //Establishing peristent storage crashed. The App must not be allowed
            //to keep going
            NSLog(@"%@",[se getMessage]);
            
            //TODO: may be show some error message..Find the best way to exit the App
            exit(-1);
        }  
    }
	
	return self;
}


-(NSManagedObjectContext *) storageContext
{
    NSThread *currentThread = [NSThread currentThread];
    NSManagedObjectContext *context = [currentThread.threadDictionary objectForKey:@"context"];
    if(context != nil)
    {
        [context processPendingChanges];
        return context;
    }
	
	context = [[[NSManagedObjectContext alloc] init] autorelease];
	[context setPersistentStoreCoordinator: self.coordinator];
    [context processPendingChanges];
    [currentThread.threadDictionary setObject:context forKey:@"context"];
    [context setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    
    if([NSThread isMainThread])
    {
        NSLog(@"Running on Main Thread!!!!!!");
        self.mainContext = context;
    }
    /*else
    {
        //Add the Observer
        NSNotificationCenter *defaultCenter = (NSNotificationCenter *)[NSNotificationCenter defaultCenter];
        [defaultCenter addObserver:self selector:@selector(contextDidSave:) name:NSManagedObjectContextDidSaveNotification object:context];
    }*/
    else
    {
        NSLog(@"*NOT* Running on Main Thread!!!!!!");
    }
	
	return context;
}

-(void) contextDidSave:(NSNotification *)saveNotification
{
    /*NSLog(@"Merge Notification on the Main Thread received!!!!!");
    [self.mainContext performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:)
                          withObject:saveNotification
                       waitUntilDone:YES];
    
    [self.mainContext mergeChangesFromContextDidSaveNotification:saveNotification];*/
}

//For the classes internal-use only
-(NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
	NSString *appDir = [self applicationDocumentsDirectory];
    NSString *storePath = [appDir stringByAppendingPathComponent: @"cloudb.sqlite"];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:appDir]) 
	{
        //Recursively create the app dir
		[fileManager createDirectoryAtPath:appDir withIntermediateDirectories:YES attributes:nil error:NULL];
    }
	if(![fileManager fileExistsAtPath:storePath])
	{
		[fileManager createFileAtPath:storePath contents:nil attributes:nil];
	}
	
    NSURL *storeUrl = [NSURL fileURLWithPath:storePath];
	
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil]; 
	NSManagedObjectModel *myModel = [self managedModel];
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:myModel];
	persistentStoreCoordinator = [persistentStoreCoordinator autorelease];
	
    NSError *error;
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error]) 
	{
        NSLog(@"Core Data: %@",[error userInfo]);
		//Handle the error by throwing a SystemException
		NSString *errorInfo = [error localizedDescription];
		NSMutableArray *info = [NSMutableArray arrayWithObjects:errorInfo, nil];
		SystemException *exception = [SystemException withContext:@"common/CloudDBManager" method:@"persistentStoreCoordinator" parameters:info];
		@throw exception;
	}    
    
    return persistentStoreCoordinator;
}


-(NSManagedObjectModel *)managedModel
{
	NSArray *allBundles = [NSBundle allBundles];
	NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:allBundles];
	
	/*ManagedObjectModelFactory *factory = [ManagedObjectModelFactory withInit];
	NSManagedObjectModel *confModel = [factory buildConfigurationModel];
	NSManagedObjectModel *mobileObjectModel = [factory buildMobileObjectModel];
	NSManagedObjectModel *anchorModel = [factory buildAnchorModel];
	NSManagedObjectModel *changelogModel = [factory buildChangeLogModel];
	NSManagedObjectModel *syncErrorModel = [factory buildSyncErrorModel];
	NSArray *models = [NSArray arrayWithObjects:confModel,
					   mobileObjectModel,
					   anchorModel,
					   changelogModel,
					   syncErrorModel,
					   nil];
	
	NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel modelByMergingModels:models];*/
	
    return managedObjectModel;
}

-(NSString *)applicationDocumentsDirectory
{
	//Finds the Document directory for the installed App
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
	
    return basePath;
}
@end
