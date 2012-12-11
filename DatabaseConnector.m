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



+(DatabaseConnector *)initializeDatabaseWithName:(NSString *)name andExtension:(NSString *)extension
{
    return [[DatabaseConnector alloc] initWithName:name andExtension:extension];
}



-(id)initWithName:(NSString *)name andExtension:(NSString *)extension
{
    self = [super init];
	if (self)
	{
        NSString * dbName;
        if (extension.length > 0)
        {
            dbName = [NSString stringWithFormat:@"%@.%@" , name , extension];
        }
        else
        {
            dbName = [NSString stringWithString:name];
        }

		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];	
		NSString * localDatabase = [documentsDirectory stringByAppendingPathComponent:dbName];
        
        
        NSString *appDir = [[NSBundle mainBundle] resourcePath];			
        NSString *projectDatabase = [appDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",dbName]];
        // TripinIPad/Resources/databases/
        
		
        NSLog(@"DB FOUND: %d" , [[NSFileManager defaultManager] fileExistsAtPath:projectDatabase]);
		if (![[NSFileManager defaultManager] fileExistsAtPath:localDatabase])
        {
			BOOL copySuccess = [[NSFileManager defaultManager] copyItemAtPath:projectDatabase toPath:localDatabase error:NULL];
            NSLog(@"DB COPY SUCCESS: %d" , copySuccess);
        }
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
        
        NSString * valueString;
        NSObject * keyValue = [elements objectForKey:keyString];
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
            NSObject * keyValue = [controlKey objectForKey:key];
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


-(BOOL)deleteFromTable:(NSString *)table withControlDict:(NSDictionary *)controlDict
{
    NSMutableString * query = [[NSMutableString alloc] initWithFormat:@"DELETE FROM %@ WHERE" , table];
    
    int keyCount = 0;
    for (NSString * key in controlDict.allKeys)
    {
        [query appendFormat:@"%@%@ = %@ " , keyCount ? @" AND " : @" " , key , [controlDict valueForKey:key]];
        ++keyCount;
    }

    char *err;
	int sonuc = sqlite3_exec(database, [query UTF8String],NULL, NULL, &err);
	
	if (sonuc == SQLITE_OK)
		return YES;
	else 
		return NO;	

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



@end
