//
//  NSManagedObject+Properties.h
//  ignite
//
//  Created by Paul Crawford on 9/5/12.
//  Copyright (c) 2012 Paul Crawford. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSManagedObject(Properties)

+ (NSDictionary *)propertyNamesAndTypesWithContext:(NSManagedObjectContext *)context;
+ (NSString *)className;
+ (id) parsePropertyType:(NSString *)properyType value:(id)val;
+ (NSDate *) parseDate:(NSString *)val;

@end
