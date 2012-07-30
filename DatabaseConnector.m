//
//  DatabaseConnector.m
//  Database
//
//  Created by Süleyman Çalık on 12/29/10.
//  Copyright 2010 www.suleymancalik.com All rights reserved.
//

#import "DatabaseConnector.h"


@implementation DatabaseConnector

@synthesize databasePath;
@synthesize isDatabaseOpen;

-(id)initWithDatabase:(NSString *)name;
{
    self = [super init];
	if (self)
	{
		
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];	
		NSString * localDatabase = [documentsDirectory stringByAppendingPathComponent:name];
        
        
        NSString *appDir = [[NSBundle mainBundle] resourcePath];			
        NSString *projectDatabase = [appDir stringByAppendingPathComponent:name];
        
		
		if (![[NSFileManager defaultManager] fileExistsAtPath:localDatabase])
			[[NSFileManager defaultManager] copyItemAtPath: projectDatabase toPath: localDatabase error: NULL];
        /*
        else
        {
            NSDictionary * localDict = [[NSFileManager defaultManager] attributesOfItemAtPath:localDatabase error:NULL];
            NSDictionary * projectDict = [[NSFileManager defaultManager] attributesOfItemAtPath:projectDatabase error:NULL];
            if(localDict != nil && projectDict != nil)
            {
                if([localDict fileSize] != [projectDict fileSize])
                {
                    [[NSFileManager defaultManager] removeItemAtPath:localDatabase error:NULL];
                    [[NSFileManager defaultManager] copyItemAtPath: projectDatabase toPath: localDatabase error: NULL];
                }
            }
        }
		*/
		databasePath = localDatabase;
		
		int result = sqlite3_open([databasePath UTF8String], &database);
		
		if (result != SQLITE_OK) 
		{
			sqlite3_close(database);
		}
		else
		{
			isDatabaseOpen = YES;
		}

	}
	
	return self;
}


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
                    
                    [dict setObject:contentString forKey:nameString];
                }
                else
                {
                    [dict setObject:@"" forKey:nameString];
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
		
		[query appendString:[NSString stringWithFormat:@"%@ = '%@'" , keyString , [elements objectForKey:keyString]]];
		
		keyCount++;
	}
	
    keyCount = 0;
    if(controlKey.count > 0)
    {
        [query appendString:@" WHERE "];
        
        for (NSObject * keyObject in controlKey.allKeys)
        {
            if(keyCount != 0)
                [query appendString:@" AND "];

            
            NSString * key = [NSString stringWithFormat:@"%@" ,keyObject];
            
            [query appendFormat:@"%@ = %@" , key , [controlKey objectForKey:key]];

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

-(void)clearDatabase
{
    NSArray * tables = [[NSArray alloc] initWithObjects:
                        @"Favorites", 
                        nil];
    
    for (NSString * table in tables)
    {
        NSString * query = [NSString stringWithFormat:@"DELETE FROM %@" , table];
        char *err;
        int result = sqlite3_exec(database, [query UTF8String],NULL, NULL, &err);
        NSLog(@"%@ %d" , table , result);
    }
}

@end
