//
//  DatabaseConnector.h
//  Database
//
//  Created by Süleyman Çalık on 12/29/10.
//  Copyright 2010 www.suleymancalik.com All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "sqlite3.h"


@interface DatabaseConnector : NSObject 
{
	sqlite3 * database;
	BOOL isDatabaseOpen;
}
@property BOOL isDatabaseOpen;

+(DatabaseConnector *)initDatabaseNamed:(NSString *)name
                                version:(NSString *)version
                              extension:(NSString *)extension;

-(id)initWithName:(NSString *)name
           versio:(NSString *)version
     andExtension:(NSString *)extension;

-(NSMutableArray *) selectWithQuery:(NSString *)query;
-(BOOL)insertToTable:(NSString *)tableName elements:(NSDictionary *)elements;
-(BOOL)updateTable:(NSString *)tableName withControlKey:(NSDictionary *)controlKey andElements:(NSDictionary *)elements;
-(BOOL)deleteFromTable:(NSString *)table withControlKey:(NSString *)key andValue:(NSString *)value;

-(void)clearTable:(NSString *)table;
-(void)clearTables:(NSArray *)tables;
-(void)clearAllTables;

@end
