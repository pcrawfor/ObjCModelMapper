//
//  NSObject+RemoteHelpers.h
//  DailyBurn
//
//  Created by Paul Crawford on 10-03-04.
//  Copyright 2010 Daily Burn, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSObject(RemoteHelpers)

+ (NSString *) remoteElementName;
+ (NSString *) remoteCollectionName;
+ (NSString *) remoteProtocolExtension;
+ (NSString *) remoteIdName;
+ (id) propertyClass:(NSString *)className;
+ (NSString *) entityIdName;
+ (NSString *) entityName;
+ (NSString *) idFieldName;

@end
