# ObjCModelMapper

A simple library for converting JSON data into core data NSManagedObjectModel objects.

The library uses NSEntityDescription for the core data model to automatically map the properties of an NSDictionary into an instance of a NSManagedObjectModel.

The advantage of using the NSEntityDescription is that you can ignore all non-data related properties on NSObject, which tend to differ on different iOS/OSX versions.

This approach to converting JSON data into core data model data was written and is designed for use with a Ruby on Rails API and the type of JSON objects that rails returns.

## Using with your project:

For now the only way to use the library is to include the source code directly in your project.  Cocoapods support is in the works.

## Usage

The key function exposed by the ModelMapper class is:

    + (NSArray *) mapServerArray:(NSArray *)serverArray
                   forEntityName:(NSString *)entityName
                 filterPredicate:(NSPredicate *)filterPredicate
              deleteMissingLocal:(BOOL)deleteMissingLocal
                         context:(NSManagedObjectContext *)context;

It expects to be passed an array of NSDictionary objects representing the parsed JSON data from the server along with the following additional parameters:

* entityName: Name of the core data model class
* filterPredicate: Optional predicate to filter the set that will be replaced by the given array
* deleteMissingLocal: boolean flag telling the mapper whether to remove objects in the local set that are not in the server set
* context: NSManagedObjectContext to operate on

## How it works:

The basic algorithm used by the mapper is a comparison of the two sets of objects: 

1) Those currently store in core data which map any predicate passed in: the local objects

2) Those contained in the array of dictionaries from the server: the remote objects

The local objects are loaded based on the filterPredicate and compared to the remote objects.

If deleteMissingLocal is true then any object that is not in the remote set is deleted from the local set, this can be used to maintain a 'synced' set of objects from your server in your cocoa app.

If deleteMissingLocal is false then objects will only be added or replaced(updated)

## Handling remote object id fields:

Remote server objects that are stored in relational databases often have an id field which represents the unique key for the record.  Since id is a reserved word in objective-c ObjCModelMapper maps the id attribute in JSON data to a field of the form:

    modelnameId

So for a Todo model the id field is expected to be todoId.  You must define this field on your core data model for the mapping to work correctly. 

## Using with AFNetworking:

If you have a core data model named Todo:

eg. Sample interface:

    #import "Todo.h"

    @interface Todo : NSManagedObject

    @property (strong, nonatomic) NSNumber  * todoId;
    @property (strong, nonatomic) NSString  * title;
    @property (strong, nonatomic) NSString  * desc;

    @end

You can load the todos from an API available at /todos.json by doing:

    // MyApiClient is a subclass of AFHTTPClient, which defines the base URL and default HTTP headers for NSURLRequests it creates
    + (void)loadTodosFromServer {
      MyApiClient *client = [MyApiClient sharedInstance];      
      [client getPath:@"/todos.json"
           parameters:nil
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];                
                
                [ModelMapper mapServerArray:responseObject 
                              forEntityName:@"Todo" 
                            filterPredicate:nil 
                         deleteMissingLocal:NO 
                                    context:context];                                
              }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"error: %@", [error localizedDescription]);                                
              }];
    }

All that is required to use the model mapper is a valid core data model and a valid response JSON data set.

In this case the data set would look like:

    [
        {
            "todo": {
                "created_at": "2011-12-22T02:24:51Z",
                "title": "Pick up groceries",
                "id": 27,
                "desc": "Pick up groceries from the super market."                
            }
        },
        {
            "todo": {
                "created_at": "2011-12-22T02:24:51Z",
                "title": "Take the kids to music lessons",
                "id": 27,
                "desc": "Take the kids to their music lessions at the conservatory."
            }
        }
    ]

_The id field in the todo json data will be mapped to the todoId field on the core data model objects_

# Credit

This mapper is based on several iterations of this syncing approach developed over the last few years on a number of heavily used production iOS applications.  It is also based on discussion with Apple engineers on good ways to tackle the data synchronization problems when working with web services and core data.

Inspired by http://henrik.nyh.se/2007/01/importing-legacy-data-into-core-data-with-the-find-or-create-or-delete-pattern/

