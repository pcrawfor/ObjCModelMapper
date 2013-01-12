//
//  ModelMapper.h
//  ignite
//
//  Created by Paul on 12-09-06.
//  Copyright (c) 2012 Paul Crawford. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ModelMapper : NSObject

+ (NSArray *) mapServerArray:(NSArray *)serverArray
               forEntityName:(NSString *)entityName
             filterPredicate:(NSPredicate *)filterPredicate
          deleteMissingLocal:(BOOL)deleteMissingLocal
                     context:(NSManagedObjectContext *)context;

+ (id) replaceObject:(NSManagedObject *)obj
            withDict:(NSDictionary *)dict
         entityClass:(Class)entityClass
        propertyInfo:(NSDictionary *)propertyInfo;

@end
