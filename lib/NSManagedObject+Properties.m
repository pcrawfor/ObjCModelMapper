//
//  NSManagedObject+Properties.m
//  ignite
//
//  Created by Paul Crawford on 9/5/12.
//  Copyright (c) 2012 Paul Crawford. All rights reserved.
//

#import "NSManagedObject+Properties.h"
#import "NSDate-UTC.h"

static NSString *dateTimeFormatString = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
static NSString *dateTimeZoneFormatString = @"yyyy-MM-dd'T'HH:mm:ssz";
static NSString *dateFormatString = @"yyyy-MM-dd";

@implementation NSManagedObject(Properties)

+ (NSDictionary *)propertyNamesAndTypesWithContext:(NSManagedObjectContext *)context {
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
      
  NSEntityDescription *desc = [NSEntityDescription entityForName:[self className] inManagedObjectContext:context];
  for(NSString *name in [desc propertiesByName]) {
    id d = [[desc propertiesByName] objectForKey:name];
    if( [d isKindOfClass:[NSAttributeDescription class]] ) {
      [dict setObject:[(NSAttributeDescription *)d attributeValueClassName] forKey:name];
    } else if( [d isKindOfClass:[NSRelationshipDescription class]] ) {
      NSRelationshipDescription *rd = (NSRelationshipDescription *)d;
      [dict setObject:[[rd destinationEntity] managedObjectClassName] forKey:name];
    }
  }

  return dict;
}

+ (NSString *)className {
	return NSStringFromClass([self class]);
}

// parse the value based on the property type
+ (id) parsePropertyType:(NSString *)properyType value:(id)val {
  if(NSClassFromString(properyType) == [NSString class] || NSClassFromString(properyType) == [NSNumber class]) {
        
    return val;
    
  } else if(NSClassFromString(properyType) == [NSDate class]) {
            
    if([val isKindOfClass:[NSDate class]]) {
      return [val convertToUTC];
    } else if([NSNull null] == val) {
      return nil;
    } else {
      return [self parseDate:val];
    }
    
  } else if(NSClassFromString(properyType) == [NSDictionary class]) {
    
    DLog(@"Parse NSDictionary Property");
    
  } else if(NSClassFromString(properyType) == [NSData class]) {
    
    DLog(@"Parse NSData Property");
    
  }
  
  return nil;
}

/*
 Parse NSDate from date string via several commmon date format string alternatives
 */
+ (NSDate *) parseDate:(NSString *)val {
  NSDate *returnDate;
  
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  NSString *format = ([val hasSuffix:@"Z"]) ? dateTimeFormatString : dateTimeZoneFormatString;
  [formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
  
  [formatter setDateFormat:format];
  returnDate = [formatter dateFromString:val];
  
  if(nil == returnDate) {
    [formatter setDateFormat:dateFormatString];
    returnDate = [formatter dateFromString:val];
  }
  
  return returnDate;
}

@end
