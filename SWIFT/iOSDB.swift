//
//  iOSDB.swift
//  iOSDB
//
//  Created by Suleyman Calik on 13.06.2014.
//  Copyright (c) 2014 Suleyman Calik. All rights reserved.
//

import Foundation

class iOSDB
{
    var dbPointer:COpaquePointer =  nil;
    
    func setup(fileName:String, version:String)
        -> Bool
    {
    
            return false
    }
    
    @required init(fileName:String, version:String)
    {
        let documentsPath = documentsDirectory()
        var cstr = fileName.bridgeToObjectiveC().UTF8String
        sqlite3_open(cstr,&dbPointer)
    }
}

func documentsDirectory()->String
{
    let filemanager = NSFileManager.defaultManager()
    let documetsPath : AnyObject = NSSearchPathForDirectoriesInDomains(.DocumentDirectory,.UserDomainMask,true)[0]
    return documetsPath.string
}

func resourcesDirectory()->String
{
    return NSBundle.mainBundle().resourcePath
}




/*
+(void)setupWithFileName:(NSString *)name
extension:(NSString *)extension
    version:(NSString *)version;

/**
Supports simple select queries like:
SELECT a , b FROM todos WHERE a = 1 AND b = 2

If elements argument is nil or empty array:
SELECT * FROM todos WHERE a = 1 AND b = 2
*/
+(NSArray *)selectFromTable:(NSString *)table
elements:(NSArray *)elements
keys:(NSDictionary *)keys;


+(BOOL)insertToTable:(NSString *)tableName
elements:(NSDictionary *)elements;


+(BOOL)updateTable:(NSString *)tableName
withControlKey:(NSDictionary *)controlKey
andElements:(NSDictionary *)elements;


+(BOOL)deleteFromTable:(NSString *)table
withControlKey:(NSString *)key
andValue:(NSString *)value;

+(void)clearTable:(NSString *)table;

+(void)clearTables:(NSArray *)tables;

+(void)clearAllTables;

*/
