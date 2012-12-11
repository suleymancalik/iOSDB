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
	
	NSString * databasePath;
	BOOL isDatabaseOpen;
}
@property(nonatomic , retain) NSString * databasePath;
@property BOOL isDatabaseOpen;

+(DatabaseConnector *)initializeDatabaseWithName:(NSString *)name andExtension:(NSString *)extension;
-(id)initWithName:(NSString *)name andExtension:(NSString *)extension;
-(NSMutableArray *) selectWithQuery:(NSString *)query;
-(BOOL)insertToTable:(NSString *)tableName elements:(NSDictionary *)elements;
-(BOOL)updateTable:(NSString *)tableName withControlKey:(NSDictionary *)controlKey andElements:(NSDictionary *)elements;
-(BOOL)deleteFromTable:(NSString *)table withControlDict:(NSDictionary *)controlDict;
-(void)clearTables:(NSArray *)tables;

@end
