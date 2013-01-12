//
//  NSObject+RemoteHelpers.m
//  DailyBurn
//
//  Created by Paul Crawford on 10-03-04.
//  Copyright 2010 Daily Burn, Inc.. All rights reserved.
//

#import "NSObject+RemoteHelpers.h"
#import "NSString+InflectionSupport.h"
#import "NSObject+PropertySupport.h"
#import "NSString-UppercaseFirst.h"

@implementation NSObject(RemoteHelpers)

#pragma mark -
#pragma mark Remote Path Helpers

+ (NSString *) remoteElementName {
	return [[NSStringFromClass([self class]) stringByReplacingCharactersInRange:NSMakeRange(0, 1) 
                                                                   withString:[[NSStringFromClass([self class]) substringWithRange:NSMakeRange(0,1)] lowercaseString]] underscore];
}

+ (NSString *) remoteCollectionName {
	return [[self remoteElementName] stringByAppendingString:@"s"];
}

+ (NSString *) remoteProtocolExtension {
  return @".json";
}

+ (NSString *) remoteIdName {
  return [NSString stringWithFormat:@"%@_id",[self remoteElementName]];
}                               

+ (id) propertyClass:(NSString *)className {
	return NSClassFromString([className toClassName]);
}

+ (NSString *) entityIdName {
  return [[NSString stringWithFormat:@"%@Id", [self className]] stringByLowercasingFirstLetter];
}

+ (NSString *) entityName {
  return [[self className] stringByLowercasingFirstLetter];
}

+ (NSString *) idFieldName {
  return [NSString stringWithFormat:@"%@Id", [[self remoteElementName] camelize]];
}


@end
