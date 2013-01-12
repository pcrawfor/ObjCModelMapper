//
//  ModelMapper.m
//  ignite
//
//  Created by Paul on 12-09-06.
//  Copyright (c) 2012 Paul Crawford. All rights reserved.
//
//  Based on several iterations of work originally inspired by http://henrik.nyh.se/2007/01/importing-legacy-data-into-core-data-with-the-find-or-create-or-delete-pattern/
//

#import "ModelMapper.h"
#import "NSManagedObject+Properties.h"
#import "NSObject+RemoteHelpers.h"
#import "NSString+InflectionSupport.h"

@implementation ModelMapper

/*
 Map the array of server dictionaries to the local core data objects for the given entityName
 
 Server dictionaries are compared with any existing local objects based on the remote id field
 
 Attributes:
 entityName => the name of the model class that is being mapped
 eg. entityName = "MealLog"
 
 filterPredicate => An NSPredicate that can be used to filter the set of objects that are being compared to the serverArray
 This can be useful for things like updating a data set for a given date where you may want to delete entries specific to that date,
 but not anything else in the overall dataset
 
 deleteMissingLocal => BOOL flag if this is YES then any local object that is not found in the server array will be deleted from the core data db
 
 Deletion is handled in two ways:
 1) delete all local objects that are not in the server set and which match the filter predicate
    a nil filter predicate will result in all local objects of the class being matched
 2) do not delete any of the local objects
 
 context => the NSManagedObjectContext to perform the core data operations on
 
 */

+ (NSArray *) mapServerArray:(NSArray *)serverArray
               forEntityName:(NSString *)entityName
             filterPredicate:(NSPredicate *)filterPredicate
          deleteMissingLocal:(BOOL)deleteMissingLocal
                     context:(NSManagedObjectContext *)context
{
  if (!serverArray) return nil;
  if (!context) return nil;
  
  DLog(@"array = %@", serverArray);
  
  __block NSMutableArray *results = [NSMutableArray array];
  
  [context performBlockAndWait:^{
    
    NSError *error, *saveErr;
    Class entityClass = NSClassFromString(entityName);
    NSDictionary *propertyNamesAndTypes = [entityClass propertyNamesAndTypesWithContext:context];
    NSString *idFieldName = [entityClass idFieldName];
    
    NSArray *sortDescriptors = nil;
    
    NSSortDescriptor *idSortDescriptor = [[NSSortDescriptor alloc] initWithKey:idFieldName ascending:YES];
    sortDescriptors = @[idSortDescriptor];
    
    // sort the server objects by the id attribute
    // =================================================
    id serverData;
    if([[serverArray objectAtIndex:0] objectForKey:[entityClass remoteElementName]]) {
      serverData = [serverArray valueForKey:[entityClass remoteElementName]];
    } else {
      serverData = serverArray;
    }
    
    NSArray *serverObjects = nil;
    if( [serverData isKindOfClass:[NSArray class]] ) serverObjects = [serverData sortedArrayUsingDescriptors:sortDescriptors];
    else serverObjects = @[serverData];
    
    
    // load the local set of objects for the entity sorted by the main id
    // =================================================
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:context]];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    if(nil != filterPredicate) {
        [fetchRequest setPredicate:filterPredicate];
    }
    
    NSArray *localObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    // create iterators for server set and local set
    // =================================================
    NSEnumerator* serverIterator = [serverObjects objectEnumerator];
    NSEnumerator* localIterator = [localObjects objectEnumerator];
    NSDictionary *serverObject = [serverIterator nextObject];
    NSManagedObject *localObject = [localIterator nextObject];
    
    
    // Loop through both lists, comparing identifiers, until both are empty
    // =================================================
    NSComparisonResult comparison;
    while (serverObject || localObject) {
      // Compare id's of the server and local objects
      if (!serverObject) {
        // If the server list has run out, the server id sorts last (i.e. remove remaining objects)
        comparison = NSOrderedDescending;
      } else if (!localObject) {
        // If local list has run out, the server id sorts first (i.e. add remaining objects)
        comparison = NSOrderedAscending;
      } else if( [serverObject valueForKey:@"id"] != nil &&
                [serverObject valueForKey:@"id"] != [NSNull null] &&
                [localObject valueForKey:idFieldName] != nil) {
        // If neither list has run out, compare with the object
        comparison = [[serverObject valueForKey:@"id"] compare:[localObject valueForKey:idFieldName]];
      } else {
        comparison = NSOrderedAscending;
      }
      
      if (comparison == NSOrderedSame) {  // Identifiers match
                                        // replace local with server
        DLog(@"replace local object");
        
        localObject = [self replaceObject:localObject withDict:serverObject entityClass:entityClass propertyInfo:propertyNamesAndTypes];
        DLog(@"replaced: %@", localObject);
        
        if(localObject) {
          [results addObject:localObject];
        }
        
        // Move ahead in both lists
        localObject = [localIterator nextObject];
        serverObject = [serverIterator nextObject];                
      } else if(comparison == NSOrderedAscending) {
        // create local
        DLog(@"create local object");
        
        NSManagedObject *newObject = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:context];
        newObject = [self replaceObject:newObject withDict:serverObject entityClass:entityClass propertyInfo:propertyNamesAndTypes];
        DLog(@"created: %@", newObject);
        
        serverObject = [serverIterator nextObject];
        
        if(newObject) {
          [results addObject:newObject];
        }      
      } else {
        // optionally delete local object
        if(deleteMissingLocal) {
          DLog(@"delete local object");
          [context deleteObject:localObject];
        }
        
        localObject = [localIterator nextObject];        
      }
    }
    
    if([context save:&saveErr]) {
      DLog(@"saved changes");
    }
    else {
      DLog(@"failed to save with error %@, \n conflicts: %@ \n recovery options:%@ \n recovery suggestion: %@\n userInfo:%@", [saveErr localizedDescription], [saveErr localizedFailureReason], [saveErr localizedRecoveryOptions], [saveErr localizedRecoverySuggestion], [saveErr userInfo]);
      results = nil;
    }
  }];
  
  return [NSArray arrayWithArray:results];
}

// overwrites the values of the obj keys with the values contained in the dictionary based on the propertyNamesAndTypes data
+ (id) replaceObject:(NSManagedObject *)obj
            withDict:(NSDictionary *)dict
         entityClass:(Class)entityClass
        propertyInfo:(NSDictionary *)propertyInfo
{
  for(NSString *key in [dict allKeys]) {
      
    NSString *camelKey = [key camelize];
    
    if([key isEqualToString:@"id"]) {
      if ([dict valueForKey:key] != [NSNull null])
        [obj setValue:[dict valueForKey:key] forKey:[entityClass idFieldName]];
    } else if([[propertyInfo allKeys] containsObject:camelKey]) {
      NSString *propertyType = [propertyInfo objectForKey:camelKey];
      
      id value = [dict valueForKey:key];
      if([value isKindOfClass:NSClassFromString(propertyType)] ||
         ([value isKindOfClass:[NSArray class]] && [propertyType isKindOfClass:[NSString class]] )  ) {
        id val = [entityClass parsePropertyType:propertyType value:[dict valueForKey:key]];
        
        if (val == [NSNull null]) {
          val = nil;
        }
        
        [obj setValue:val forKey:camelKey];
      }      
    }
  }
    
  return obj;
}

@end
