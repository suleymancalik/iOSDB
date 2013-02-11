//
//  DatabaseConnector.m
//  Database
//
//  Created by Süleyman Çalık on 12/29/10.
//  Copyright 2010 www.suleymancalik.com All rights reserved.
//

#import "DatabaseConnector.h"


@implementation DatabaseConnector

@synthesize isDatabaseOpen;


/*
static DatabaseConnector * _sharedHelper = nil;

+ (DatabaseConnector *)sharedHelper
{
    if(_sharedHelper == nil)
    {
        _sharedHelper = [[DatabaseConnector alloc] init];
    }
    return _sharedHelper;
}
*/

+(DatabaseConnector *)initDatabaseNamed:(NSString *)name
                                version:(NSString *)version
                              extension:(NSString *)extension
{
    return [[DatabaseConnector alloc] initWithName:name versio:version andExtension:extension];
}



-(id)initWithName:(NSString *)name
           versio:(NSString *)version
     andExtension:(NSString *)extension
{
    self = [super init];
	if (self)
	{
        NSString * dbName;
        if (extension.length > 0)
        {
            dbName = [NSString stringWithFormat:@"%@.%@" , name , extension];
//            dbName = [NSString stringWithFormat:@"%@" , name];
        }
        else
        {
            dbName = [NSString stringWithString:name];
        }

		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = paths[0];	
		NSString * localDatabasePath = [documentsDirectory stringByAppendingPathComponent:dbName];


        NSString *appDir = [[NSBundle mainBundle] resourcePath];
        NSString *projectDatabase = [appDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",dbName]];
        
		BOOL willOpenDatabase = YES;
        
		if (![[NSFileManager defaultManager] fileExistsAtPath:localDatabasePath])
        {
            NSError * err = nil;
			BOOL copySuccess = [[NSFileManager defaultManager] copyItemAtPath:projectDatabase toPath:localDatabasePath error:&err];
            if(copySuccess)
            {
                [self saveVersion:version ofDatabase:name];
            }
            else
            {
                NSLog(@"NEW DB NOT COPIED!!!  %@", err);
            }
        }
        else
        {
            NSString * existingVersion = [self savedVersionOfDatabase:name];
            if(!existingVersion || (![existingVersion isEqualToString:version]))
            {
                if(!existingVersion)
                    existingVersion = @"";
                
                
                if(extension.length > 0)
                    dbName = [dbName stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@".%@" , extension] withString:[NSString stringWithFormat:@"_%@.%@" ,existingVersion , extension]];
                
                NSString * oldDBPath = [documentsDirectory stringByAppendingPathComponent:dbName];
                
                NSError * err = nil;
                if ([[NSFileManager defaultManager] fileExistsAtPath:oldDBPath])
                {
                    BOOL removed = [[NSFileManager defaultManager] removeItemAtPath:oldDBPath error:&err];
                    if(!removed)
                    {
                        NSLog(@"OLD DB NOT REMOVED!!! %@", err);
                        err = nil;
                    }
                }
                BOOL moved = [[NSFileManager defaultManager] moveItemAtPath:localDatabasePath toPath:oldDBPath error:&err];
                if(!moved)
                {
                    NSLog(@"OLD DB NOT MOVED!!! %@", err);
                    err = nil;
                }

                BOOL copySuccess = [[NSFileManager defaultManager] copyItemAtPath:projectDatabase toPath:localDatabasePath error:&err];
                if(copySuccess)
                {
                    [self copyDataFromDB:oldDBPath toDB:localDatabasePath];
                    [self saveVersion:version ofDatabase:name];
                    willOpenDatabase = NO;
                }
                else
                {
                    NSLog(@"NEW DB NOT COPIED!!!  %@", err);
                }
            }
        }

        [self openDatabaseAtPath:localDatabasePath];

	}
	
	return self;
}


-(void)openDatabaseAtPath:(NSString *)dbPath
{
    int result = sqlite3_open([dbPath UTF8String], &database);
    
    if (result != SQLITE_OK)
    {
        sqlite3_close(database);
    }
    else
    {
        isDatabaseOpen = YES;
    }
}


-(void)closeCurrentDatabase
{
    sqlite3_close(database);
}

-(NSString *)savedVersionOfDatabase:(NSString *)databaseName
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:databaseName];
}

-(void)saveVersion:(NSString *)version ofDatabase:(NSString *)databaseName
{
    [[NSUserDefaults standardUserDefaults] setObject:version forKey:databaseName];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(void)copyDataFromDB:(NSString *)oldDBPath toDB:(NSString *)newDBPath
{
    [self openDatabaseAtPath:oldDBPath];
    
    NSMutableDictionary * allOldDict = [NSMutableDictionary dictionary];
    
    NSArray * allTables = [self selectWithQuery:@"SELECT name FROM sqlite_master WHERE type = 'table'"];
    for (NSDictionary * tableDict in allTables)
    {
        NSString * table = tableDict[@"name"];
        if(![table isEqualToString:@"sqlite_sequence"])
        {
            NSArray * tableData = [self selectWithQuery:[NSString stringWithFormat:@"SELECT * FROM %@" , table]];
            [allOldDict setObject:tableData forKey:table];
        }
    }
    
    [self closeCurrentDatabase];
    [self openDatabaseAtPath:newDBPath];
    
    for (NSDictionary * tableDict in allTables)
    {
        NSString * table = tableDict[@"name"];

        NSArray * oldDataArr = [allOldDict objectForKey:table];
        for (NSDictionary * oldData in oldDataArr)
        {
            [self insertToTable:table elements:oldData];
        }
    }
}


- (BOOL)checkForColumn:(NSString *)desiredColumn inTable:(NSString *)tableName
{
    const char *sql = [[NSString stringWithFormat:@"PRAGMA table_info(%@)", tableName] cStringUsingEncoding:NSUTF8StringEncoding];
    sqlite3_stmt *stmt;
    
    if (sqlite3_prepare_v2(database, sql, -1, &stmt, NULL) != SQLITE_OK)
    {
        return NO;
    }
    
    while(sqlite3_step(stmt) == SQLITE_ROW)
    {
        
        NSString *fieldName = @((char *)sqlite3_column_text(stmt, 1));
        if([desiredColumn isEqualToString:fieldName])
            return YES;
    }
    
    return NO;
}

#pragma mark - Query Methods


-(NSMutableArray *) selectWithQuery:(NSString *)query
{
	sqlite3_stmt * statement;

	sqlite3_prepare_v2(database, [query UTF8String],-1, &statement, nil);
    int columnCount = sqlite3_column_count(statement);
    
    NSMutableArray * result = [[NSMutableArray alloc] init];
    
    
    while(sqlite3_step(statement) == SQLITE_ROW)
    {
        NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
        for (int column = 0; column < columnCount; ++column)
        {
            char * nameData = (char *)sqlite3_column_name(statement, column);
            if(nameData != nil)
            {
                NSString * nameString = [[NSString alloc] initWithUTF8String:nameData];
                
                char * contentData = (char *)sqlite3_column_text(statement,column);
                if(contentData != nil)
                {
                    NSString * contentString = [[NSString alloc] initWithUTF8String:contentData];
                    
                    dict[nameString] = contentString;
                }
                else
                {
                    dict[nameString] = @"";
                }
            }
            
        }
    
        [result addObject:dict];

    }
    
	return result;
}

-(BOOL)insertToTable:(NSString *)tableName elements:(NSDictionary *)elements
{
	NSMutableString * query = [[NSMutableString alloc] initWithFormat:@"INSERT INTO %@ ( " , tableName];
	
	int keyCount = 0;
	for (NSObject * key in [elements allKeys])
	{
        NSString * keyString = [NSString stringWithFormat:@"%@" ,key];
        
		if(keyCount != 0)
			[query appendString:@" , "];
		
		[query appendString:keyString];
		
		keyCount++;
	}
	
	[query appendString:@" ) VALUES ( '"];
	
	int valueCount = 0;
	for (NSObject * value in [elements allValues])
	{
        NSString * valueString = [NSString stringWithFormat:@"%@" ,value];
        
		if(valueCount != 0)
			[query appendString:@"' , '"];
		
		[query appendString:[valueString stringByReplacingOccurrencesOfString:@"'" withString:@""]];
		valueCount++;
	}
	
	[query appendString:@"' )"];
	
	char *err;
	int sonuc = sqlite3_exec(database, [query UTF8String],NULL, NULL, &err);
	
	if (sonuc == SQLITE_OK)
		return YES;
	else 
		return NO;	
}

-(BOOL)updateTable:(NSString *)tableName withControlKey:(NSDictionary *)controlKey andElements:(NSDictionary *)elements
{
    NSMutableString * query = [[NSMutableString alloc] initWithFormat:@"UPDATE %@ SET " , tableName];

    int keyCount = 0;
	for (NSObject * key in [elements allKeys])
	{
        NSString * keyString = [NSString stringWithFormat:@"%@" ,key];
        
		if(keyCount != 0)
			[query appendString:@" , "];
        
        NSString * valueString;
        NSObject * keyValue = elements[keyString];
        if ([keyValue isKindOfClass:[NSNumber class]])
        {
            valueString = [NSString stringWithFormat:@"%@" , keyValue];
        }
        else
        {
            valueString = [NSString stringWithFormat:@"'%@'" , keyValue];
        }
        
		
		[query appendString:[NSString stringWithFormat:@"%@ = %@" , keyString , valueString]];
		
		keyCount++;
	}
	
    keyCount = 0;
    if(controlKey.count > 0)
    {
        [query appendString:@" WHERE "];
        
        for (NSObject * key in controlKey.allKeys)
        {
            if(keyCount != 0)
                [query appendString:@" AND "];

            NSString * valueString;
            NSObject * keyValue = controlKey[key];
            if ([keyValue isKindOfClass:[NSNumber class]])
            {
                valueString = [NSString stringWithFormat:@"%@" , keyValue];
            }
            else
            {
                valueString = [NSString stringWithFormat:@"'%@'" , keyValue];
            }

            
            NSString * keyString = [NSString stringWithFormat:@"%@" ,key];
            
            [query appendFormat:@"%@ = %@" , keyString , valueString];

        }
    }
    
    char *err;
	int sonuc = sqlite3_exec(database, [query UTF8String],NULL, NULL, &err);
	
	if (sonuc == SQLITE_OK)
		return YES;
	else 
		return NO;	

}


-(BOOL)deleteFromTable:(NSString *)table withControlKey:(NSString *)key andValue:(NSString *)value
{
    NSMutableString * query = [[NSMutableString alloc] initWithFormat:@"DELETE FROM %@ WHERE %@ = %@ " , table , key ,value];

    char *err;
	int sonuc = sqlite3_exec(database, [query UTF8String],NULL, NULL, &err);
	
	if (sonuc == SQLITE_OK)
		return YES;
	else 
		return NO;
}


-(void)clearTable:(NSString *)table
{
    NSString * query = [NSString stringWithFormat:@"DELETE FROM %@" , table];
    char *err;
    sqlite3_exec(database, [query UTF8String],NULL, NULL, &err);
}

-(void)clearTables:(NSArray *)tables
{
    for (NSString * table in tables)
    {
        NSString * query = [NSString stringWithFormat:@"DELETE FROM %@" , table];
        char *err;
        sqlite3_exec(database, [query UTF8String],NULL, NULL, &err);
    }
}

-(void)clearAllTables
{
    NSArray * tables = [self selectWithQuery:@"SELECT name FROM sqlite_master WHERE type = 'table'"];
    [self clearTables:tables];
}


@end
