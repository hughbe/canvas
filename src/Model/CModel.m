//
//  CModel.m
//  canvas
//
//  Created by Hugh Bellamy on 09/12/2013.
//  Copyright (c) 2013 Hugh Bellamy. All rights reserved.
//

#import "CModel.h"

#import "CDrawingView.h"
#import <CoreData/CoreData.h>

#define DRAWING_COLOR_KEY @"DCK"
#define DRAWING_LINE_WIDTH_KEY @"DLWK"
#define DRAWING_OPACITY_KEY @"DOK"

#define DRAWING_LINE_CAP_KEY @"DLCK"
#define DRAWING_BRUSH_PATTERN_KEY @"DBPK"
#define DRAWING_BRUSH_BLEND_MODE_KEY @"DBBMK"

#define DRAWING_BACKGROUND_COLOR_KEY @"DBCK"
#define DRAWING_DEFAULT_BACKGROUND_COLOR_KEY @"DDBCK"

#define DRAWING_SIZE_WIDTH_KEY @"DSWK"
#define DRAWING_SIZE_HEIGHT_KEY @"DSHK"

#define APP_INITIALISED_KEY @"AIP"
#define CAN_USE_MORE_BRUSHES @"CUMB"

#define DRAWING_ENTITY_NAME @"Drawing"

UIColor *UIColorFromNSString(NSString *string) {
    //Creates a color with RGB values of the string
    NSString *componentsString = [[string stringByReplacingOccurrencesOfString:@"[" withString:@""] stringByReplacingOccurrencesOfString:@"]" withString:@""];
    NSArray *components = [componentsString componentsSeparatedByString:@", "];
    return [UIColor colorWithRed:[(NSString*)components[0] floatValue]
                           green:[(NSString*)components[1] floatValue]
                            blue:[(NSString*)components[2] floatValue]
                           alpha:[(NSString*)components[3] floatValue]];
}

NSString *NSStringFromUIColor(UIColor *color) {
    if(!color) {
        return nil;
    }
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    return [NSString stringWithFormat:@"[%f, %f, %f, %f]",
            components[0],
            components[1],
            components[2],
            components[3]];
}

@implementation NSArray (CModelSerialisation)

- (NSData*)serialize {
    NSMutableArray *array = [NSMutableArray new];
    
    for(UIBezierPath *aPath in [self copy]) {
        NSMutableDictionary *aCoder = [NSMutableDictionary new];
        UIColor *color = aPath.color;
        CGFloat opacity = aPath.opacity;
        
        CBrushType type = aPath.type;
        CShape shape = aPath.shape;
        
        CGBlendMode blendMode = aPath.blendMode;
        
        CHiddenInfo hiddenInfo = aPath.hiddenInfo;
        BOOL hidden = aPath.isHiddenNow;
        
        [aCoder setObject:color forKey:@"color"];
        [aCoder setObject:@(opacity) forKey:@"opacity"];
        
        [aCoder setObject:@(type) forKey:@"type"];
        [aCoder setObject:[NSData dataWithBytes:&shape length:sizeof(CShape)] forKey:@"shape"];
        
        [aCoder setObject:@(blendMode) forKey:@"blendMode"];
        
        [aCoder setObject:[NSData dataWithBytes:&hiddenInfo length:sizeof(CHiddenInfo)] forKey:@"hiddenInfo"];
        [aCoder setObject:@(hidden) forKey:@"hidden"];
        
        [aCoder setObject:aPath forKey:@"path"];
        
        [array addObject:aCoder];
    }
    
    return [NSKeyedArchiver archivedDataWithRootObject:array];
}

- (NSArray *)deserialize {
    NSMutableArray *array = [NSMutableArray new];
    for(NSMutableDictionary *aDecoder in [self copy]) {
        UIBezierPath *aPath = [aDecoder objectForKey:@"path"];
        aPath.color = [aDecoder objectForKey:@"color"];
        aPath.opacity = [[aDecoder objectForKey:@"opacity"] floatValue];
        
        aPath.type = [[aDecoder objectForKey:@"type"] integerValue];
        
        CShape shape;
        [[aDecoder objectForKey:@"shape"]getBytes:&shape length:sizeof(CShape)];
        aPath.shape = shape;
        
        aPath.blendMode = (CGBlendMode)[[aDecoder objectForKey:@"blendMode"]integerValue];
        
        CHiddenInfo hiddenInfo;
        [[aDecoder objectForKey:@"hiddenInfo"]getBytes:&hiddenInfo length:sizeof(CHiddenInfo)];
        aPath.hiddenInfo = hiddenInfo;
        aPath.hidden = [[aDecoder objectForKey:@"hidden"] boolValue];
        [array addObject:aPath];
    }
    
    return array;
}
@end

@interface CModel ()

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end

@implementation CModel

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

+ (NSArray *)tips {
    static NSArray *tips;
    @synchronized(self) {
        if(!tips) {
            tips = @[@"Did you know that you can add shapes and straight lines to your pictures? Just tap on the two icons at the bottom of the interface", @"Did you know that you can draw on an image or video? Just tap Background", @"Canvas supports blend modes! Tap the Brush icon then Blend Mode to find loads of blend modes to create an awesome mixing of colors", @"Thinking of showing your image off to the world? Go to your Home Screen then tap the share icon on your drawing", @"Want to change the color of a line or shape? Click on the fill icon and select a color from brush options and the thing your want to change!", @"Want to change your drawing after saving? Click the edit icon on your drawing!", @"Got too many drawings and want to find one quickly? Simply swipe down anywhere in the home screen to search for your drawing", @"Did you know that you can save copies of your image to your camera roll? Just press the download button", @"Bored of the background color? You can change it by pressing the top right button twice!", @"I have no clue what to say here", @"I'm too obsessed with Game of Thrones to think of something to write...", @"Got a cracking idea about Canvas, or have you found a not-so-cracking bug? Tell us by clicking the question mark on your home screen!", @"Thanks for using Canvas!", @"Did you like using Canvas? We would love to hear your opinion, good or bad. Press the question mark in the home screen to get started", @"Share Canvas on Facebook, Twitter or rate on the App Store to unlock BONUS brush textures, colors, shapes and blend modes!"];
        }
        return tips;
    }
}

+ (NSArray *)shapeTitles {
    static NSArray *shapeTitles;
    @synchronized(self) {
        if(!shapeTitles) {
            shapeTitles = @[@"Circle", @"Triangle", @"Square", @"Rectangle", @"Rhombus", @"Kite", @"Pentagon", @"Hexagon", @"Heptagon", @"Parallel Lines", @"Happy Smiley ", @"Disturbed Smiley", @"Neutral Smiley", @"Awkward Smiley", @"Sad Smiley", @"Happy Smiley 2", @"Neutral Smiley 2", @"Awkward Smiley 2", @"Sad Smiley 2", @"A Shape", @"B Shape", @"C Shape", @"D Shape", @"E Shape", @"F Shape", @"G Shape", @"H Shape", @"I Shape", @"J Shape", @"K Shape", @"L Shape",  @"M Shape", @"N Shape", @"O Shape", @"P Shape", @"Q Shape", @"R Shape", @"S Shape", @"T Shape", @"U Shape", @"V Shape", @"W Shape", @"X Shape", @"Y Shape", @"Z Shape"];
        }
        return shapeTitles;
    }
}

+ (NSArray *)brushPatternTitles {
    static NSArray *brushPatternTitles;
    @synchronized(self) {
        if(!brushPatternTitles) {
            brushPatternTitles = @[@"Normal", @"Dashed 1", @"Dashed 2", @"Dashed 3", @"Dashed 4", @"Wood (Mahogany)", @"Wood (Normal)", @"Wood (Ebony)", @"Wood (Cartoon)", @"Asphalt", @"Concrete 1", @"Concrete 2", @"Leather 1", @"Leather 2", @"Leather 3", @"Fur", @"Carpet 1", @"Carpet 2", @"Bricks (Red)", @"Bricks (Tan)", @"Bricks (Gray)", @"Path 1", @"Path 2", @"Roof (Red Tiles)", @"Roof (Gray Tiles)", @"Roof (Tan Tiles)", @"Stone 1", @"Stone 2 (Granite)", @"Stone 3", @"Rock 1", @"Rock 2", @"Marble (White)", @"Marble (Black)", @"Metal 1", @"Metal 2", @"Metal 3 (Path)", @"Grass 1", @"Grass 2", @"Hay", @"Mud 1", @"Mud 2", @"Mud 3", @"Sand 1", @"Sand 2", @"Sky 1", @"Sky 2", @"Sky 3 (Night's Sky)", @"Water 1", @"Water 2", @"Water 3", @"Snow", @"Ice", @"Lava", @"Paper", @"Cardboard"];
        }
        return brushPatternTitles;
    }
}

+ (NSString*)fileNameForBrushPatternType:(CBrushPatternType)type {
    NSString *toReturn;
    switch (type) {
        case CBrushPatternWood1:
            toReturn = @"wood1.png";
            break;
        case CBrushPatternWood2:
            toReturn = @"wood2.png";
            break;
        case CBrushPatternWood3:
            toReturn = @"wood3.png";
            break;
        case CBrushPatternWood4:
            toReturn = @"wood4.png";
            break;
        case CBrushPatternAsphalt:
            toReturn = @"asphalt.png";
            break;
        case CBrushPatternConcrete1:
            toReturn = @"concrete1.png";
            break;
        case CBrushPatternConcrete2:
            toReturn = @"concrete2.png";
            break;
        case CBrushPatternLeather1:
            toReturn = @"leather1.png";
            break;
        case CBrushPatternLeather2:
            toReturn = @"leather2.png";
            break;
        case CBrushPatternLeather3:
            toReturn = @"leather3.png";
            break;
        case CBrushPatternFur:
            toReturn = @"fur.png";
            break;
        case CBrushPatternCarpet1:
            toReturn = @"carpet1.png";
            break;
        case CBrushPatternCarpet2:
            toReturn = @"carpet2.png";
            break;
        case CBrushPatternBrick1:
            toReturn = @"brick1.png";
            break;
        case CBrushPatternBrick2:
            toReturn = @"brick2.png";
            break;
        case CBrushPatternBrick3:
            toReturn = @"brick3.png";
            break;
        case CBrushPatternPath1:
            toReturn = @"path1.png";
            break;
        case CBrushPatternPath2:
            toReturn = @"path2.png";
            break;
        case CBrushPatternRoof1:
            toReturn = @"roof1.png";
            break;
        case CBrushPatternRoof2:
            toReturn = @"roof2.png";
            break;
        case CBrushPatternRoof3:
            toReturn = @"roof3.png";
            break;
        case CBrushPatternStone1:
            toReturn = @"stone1.png";
            break;
        case CBrushPatternStone2:
            toReturn = @"stone2.png";
            break;
        case CBrushPatternStone3:
            toReturn = @"stone3.png";
            break;
        case CBrushPatternRock1:
            toReturn = @"rock1.png";
            break;
        case CBrushPatternRock2:
            toReturn = @"rock2.png";
            break;
        case CBrushPatternMarble1:
            toReturn = @"marble1.png";
            break;
        case CBrushPatternMarble2:
            toReturn = @"marble2.png";
            break;
        case CBrushPatternMetal1:
            toReturn = @"metal1.png";
            break;
        case CBrushPatternMetal2:
            toReturn = @"metal2.png";
            break;
        case CBrushPatternMetal3:
            toReturn = @"metal3.png";
            break;
        case CBrushPatternGrass1:
            toReturn = @"grass1.png";
            break;
        case CBrushPatternGrass2:
            toReturn = @"grass2.png";
            break;
        case CBrushPatternHay:
            toReturn = @"hay.png";
            break;
        case CBrushPatternMud1:
            toReturn = @"mud1.png";
            break;
        case CBrushPatternMud2:
            toReturn = @"mud2.png";
            break;
        case CBrushPatternMud3:
            toReturn = @"mud3.png";
            break;
        case CBrushPatternSand1:
            toReturn = @"sand1.png";
            break;
        case CBrushPatternSand2:
            toReturn = @"sand2.png";
            break;
        case CBrushPatternSky1:
            toReturn = @"sky1.png";
            break;
        case CBrushPatternSky2:
            toReturn = @"sky2.png";
            break;
        case CBrushPatternSky3:
            toReturn = @"sky3.png";
            break;
        case CBrushPatternWater1:
            toReturn = @"water1.png";
            break;
        case CBrushPatternWater2:
            toReturn = @"water2.png";
            break;
        case CBrushPatternWater3:
            toReturn = @"water3.png";
            break;
        case CBrushPatternSnow:
            toReturn = @"snow.png";
            break;
        case CBrushPatternIce:
            toReturn = @"ice.png";
            break;
        case CBrushPatternLava:
            toReturn = @"lava.png";
            break;
        case CBrushPatternPaper:
            toReturn = @"paper.png";
            break;
        case CBrushPatternCardboard:
            toReturn = @"cardboard.png";
            break;
        default:
            break;
    }
    return toReturn;
}

+ (NSArray *)blendModeTitles {
    static NSArray *blendModeTitles;
    @synchronized(self) {
        if(!blendModeTitles) {
            blendModeTitles = @[@"Normal", @"Multiply", @"Screen", @"Overlay", @"Color Dodge", @"Color Burn", @"Soft Light", @"Hard Light", @"Difference", @"Hue", @"Saturation", @"Color"];
        }
        return blendModeTitles;
    }
}

+ (CGBlendMode)blendModeForTitle:(NSString*)title {
    CGBlendMode blendMode = kCGBlendModeNormal;
    if([title isEqualToString:@"Normal"]) {
        blendMode = kCGBlendModeNormal;
    }
    else if([title isEqualToString:@"Multiply"]) {
        blendMode = kCGBlendModeMultiply;
    }
    else if([title isEqualToString:@"Screen"]) {
        blendMode = kCGBlendModeScreen;
    }
    else if([title isEqualToString:@"Overlay"]) {
        blendMode = kCGBlendModeOverlay;
    }
    else if([title isEqualToString:@"Color Dodge"]) {
        blendMode = kCGBlendModeColorDodge;
    }
    else if([title isEqualToString:@"Color Burn"]) {
        blendMode = kCGBlendModeColorBurn;
    }
    else if([title isEqualToString:@"Soft Light"]) {
        blendMode = kCGBlendModeSoftLight;
    }
    else if([title isEqualToString:@"Hard Light"]) {
        blendMode = kCGBlendModeHardLight;
    }
    else if([title isEqualToString:@"Difference"]) {
        blendMode = kCGBlendModeDifference;
    }
    else if([title isEqualToString:@"Hue"]) {
        blendMode = kCGBlendModeHue;
    }
    else if([title isEqualToString:@"Saturation"]) {
        blendMode = kCGBlendModeSaturation;
    }
    else if([title isEqualToString:@"Color"]) {
        blendMode = kCGBlendModeColor;
    }
    
    return blendMode;
}

- (id)init {
    self = [super init];
    if(self) {
        [self loadSource];
    }
    return self;
}

- (NSNumber*)getNewID {
    NSError *objectError;
    NSArray *fetchedObjectArray = [self getEntryObjectForName:@"IDS" error:&objectError predicate:nil];
    if(objectError) {
        NSLog(@"%@", objectError);
    }
    
    NSNumber *ID = @(0);
    NSManagedObject *idEntry;
    if([fetchedObjectArray count] == 0) {
        idEntry = [NSEntityDescription insertNewObjectForEntityForName:@"IDS" inManagedObjectContext:self.managedObjectContext];
    }
    else {
        idEntry = fetchedObjectArray[0];
        ID = @([[idEntry valueForKey:@"id"]integerValue]);
    }
    
    NSInteger IDInteger = [ID integerValue];
    IDInteger++;
    ID = @(IDInteger);
    
    [idEntry setValue:[ID stringValue] forKey:@"id"];
    
    NSError *saveError;
    [self saveContext];
    if(saveError) {
        NSLog(@"%@", saveError);
    }
    return ID;
}

- (void)addDrawing:(UIImage *)drawing withTitle:(NSString *)title background:(id)background size:(CGSize)size pathArray:(NSArray *)pathArray videoPath:(NSString*)videoPath completion:(void(^)())completion {
    //Creates an entity for our new drawing entry
    NSManagedObject *drawingEntry = [NSEntityDescription insertNewObjectForEntityForName:DRAWING_ENTITY_NAME inManagedObjectContext:self.managedObjectContext];
    
    //Saves our drawing to a unique fileName / ID
    NSData *data = UIImagePNGRepresentation(drawing);
    NSString *ID = [[self getNewID] stringValue];
    NSString *filePath = [CModel documentPathForPNGFileName:ID];
    [data writeToFile:filePath atomically:YES];
    
    //Sets the creation date, title, location and ID
    [drawingEntry setValue:[NSDate date] forKey:@"date"];
    [drawingEntry setValue:title forKey:@"title"];
    [drawingEntry setValue:ID forKey:@"fileID"];
    [drawingEntry setValue:NSStringFromCGSize(size) forKey:@"size"];
    
    if(!videoPath.length) {
        videoPath = @"nil";
    }
    [drawingEntry setValue:videoPath forKey:@"videoPath"];
    
    if([background isKindOfClass:[UIColor class]]) {
        //Color background
        [drawingEntry setValue:[@"c" stringByAppendingString:NSStringFromUIColor(background)] forKey:@"background"];
    }
    else if([background isKindOfClass:[UIImage class]]){
        //Image / Video Background
        NSString *fileNameBackground = [@"i" stringByAppendingString:ID];
        NSString *filePathBackground = [CModel documentPathForPNGFileName:fileNameBackground];
        NSData *backgroundData = UIImagePNGRepresentation(background);
        [backgroundData writeToFile:filePathBackground atomically:YES];
        
        [drawingEntry setValue:fileNameBackground forKey:@"background"];
    }
    
    NSError *JSONError;
    [drawingEntry setValue:[pathArray serialize] forKey:@"pathArray"];
    
    
    if(JSONError) {
        NSLog(@"%@", JSONError);
    }
    
    //Saves the changes
    NSError *saveError;
    [self.managedObjectContext save:&saveError];
    if(saveError) {
        NSLog(@"%@", saveError);
    }
    completion();
}

- (void)updateDrawing:(NSString *)ID drawing:(UIImage *)drawing title:(NSString *)title background:(id)background size:(CGSize)size pathArray:(NSArray *)pathArray videoPath:videoPath completion:(void(^)())completion {
    NSError *objectError;
    NSMutableArray *fetchedObjectArray = [[self getEntryObjectForName:DRAWING_ENTITY_NAME error:&objectError predicate:[NSPredicate predicateWithFormat:@"fileID == %@", ID]]mutableCopy];
    if(objectError) {
        NSLog(@"%@", objectError);
    }
    
    NSManagedObjectContext *context = [fetchedObjectArray firstObject];
    if(context) {
        //Saves our new image
        NSData *data = UIImagePNGRepresentation(drawing);
        NSString *filePath = [CModel documentPathForPNGFileName:ID];
        [data writeToFile:filePath atomically:YES];
        
        //Saves our title and date
        [context setValue:title forKey:@"title"];
        [context setValue:[NSDate date] forKey:@"date"];
        [context setValue:NSStringFromCGSize(size) forKey:@"size"];
        
        if(!videoPath) {
            videoPath = @"nil";
        }
        [context setValue:videoPath forKey:@"videoPath"];
        
        //Saves our background
        if([background isKindOfClass:[UIColor class]]) {
            //Color background
            NSString *previousBackground = [context valueForKey:@"background"];
            if([[previousBackground substringToIndex:1] isEqualToString:@"i"]) {
                //Deletes our previous image background
                NSError *deleteError;
                [[NSFileManager defaultManager]removeItemAtPath:[CModel documentPathForPNGFileName:previousBackground] error:&deleteError];
                if(deleteError) {
                    NSLog(@"%@", deleteError);
                }
            }
            
            [context setValue:[@"c" stringByAppendingString:NSStringFromUIColor(background)] forKey:@"background"];
        }
        else if([background isKindOfClass:[UIImage class]]){
            //Image / Video Background
            NSString *fileNameBackground = [@"i" stringByAppendingString:ID];
            NSString *filePathBackground = [CModel documentPathForPNGFileName:fileNameBackground];
            NSData *backgroundData = UIImagePNGRepresentation(background);
            [backgroundData writeToFile:filePathBackground atomically:YES];
            
            [context setValue:fileNameBackground forKey:@"background"];
        }
        
        //Saves our pathArray
        [context setValue:[pathArray serialize] forKey:@"pathArray"];
    }
    
    NSError *error;
    [self.managedObjectContext save:&error];
    if(error) {
        NSLog(@"%@", error);
    }
    completion();
}

- (void)removeDrawingWithID:(NSString *)ID completion:(void(^)())completion {
    NSManagedObject *managedObject;
    //Gets the managed object for the ID specified
    for (NSManagedObject *object in self.source) {
        if([[object valueForKey:@"fileID"] isEqualToString:ID]) {
            managedObject = object;
            break;
        }
    }
    
    if(managedObject) {
        //Removes the drawing and updates our database
        [self.source removeObject:managedObject];
        [self.managedObjectContext deleteObject:managedObject];
        
        NSError *error;
        [self.managedObjectContext save:&error];
        if(error) {
            NSLog(@"%@", error);
        }
        if(completion) {
            completion();
        }
        
        //Delete the drawing png file
        NSString *filePath = [CModel documentPathForPNGFileName:ID];
        NSError *deleteError;
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&deleteError];
        if (deleteError) {
            NSLog(@"%@", deleteError);
        }
        
        NSString *videoPath = [managedObject valueForKey:@"videoPath"];
        if(videoPath.length) {
            NSError *deleteVideoError;
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:&deleteVideoError];
            if(deleteVideoError) {
                NSLog(@"%@", deleteVideoError);
            }
        }
        
        //Deletes the drawing background file (if any)
        NSString *background = [managedObject valueForKey:@"background"];
        if([[background substringToIndex:1] isEqualToString:@"b"]) {
            NSError *deleteBackgroundError;
            [[NSFileManager defaultManager]removeItemAtPath:[CModel documentPathForPNGFileName:background] error:&deleteBackgroundError];
            if(deleteBackgroundError) {
                NSLog(@"%@", deleteBackgroundError);
            }
        }
    }
    else {
        NSLog(@"%@", @"Invalid ID");
    }
}

- (NSArray*)getEntryObjectForName:(NSString*)name error:(__autoreleasing NSError**)error predicate:(NSPredicate*)predicate {
    //Creates a fetch request for our entry
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:name inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    //Filters the results by the predicate
    if(predicate) {
    [fetchRequest setPredicate:predicate];
    }
    
    NSError *fetchError;
    //Get's the list of objects that match our request
    NSArray *object = [self.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    *error = fetchError;
    //Get's the list of objects that match our request
    return object;
}

- (void)loadSource {
    //Loads our list of drawings
    NSError *error;
    self.source = [[self getEntryObjectForName:DRAWING_ENTITY_NAME error:&error predicate:nil] mutableCopy];
    if(error) {
        NSLog(@"%@", error);
    }
}

- (void)saveContext {
    //Saves our context
    NSError *error;
    if (self.managedObjectContext != nil) {
        if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext {
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Canvas" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Data.sqlite"];
    //[[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
    
    NSError *error;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
-  (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

+ (NSString*)documentPathForFileName:(NSString*)fileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = paths[0];
    return [documentsPath stringByAppendingPathComponent:fileName];
}

+ (NSString*)documentPathForPNGFileName:(NSString*)fileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = paths[0];
    fileName = [fileName stringByAppendingString:@".png"];
    return [documentsPath stringByAppendingPathComponent:fileName];
}

+ (void)setupFirstUse:(UIColor*)backgroundColor {
    //Loads defaults and makes sure we have never loaded this app before
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if([defaults boolForKey:APP_INITIALISED_KEY]) {
        return;
    }
    
    //Loads and saves the default values
    [defaults setObject:NSStringFromUIColor([UIColor brownColor]) forKey:DRAWING_COLOR_KEY];
    [defaults setFloat:1.0f forKey:DRAWING_OPACITY_KEY];
    [defaults setFloat:30.0f forKey:DRAWING_LINE_WIDTH_KEY];
    
    [defaults setInteger:kCGLineCapRound forKey:DRAWING_LINE_CAP_KEY];
    [defaults setInteger:CBrushPatternNormal forKey:DRAWING_BRUSH_PATTERN_KEY];
    [defaults setObject:@"Normal" forKey:DRAWING_BRUSH_BLEND_MODE_KEY];
    
    [defaults setObject:NSStringFromUIColor(backgroundColor) forKey:DRAWING_BACKGROUND_COLOR_KEY];
    [defaults setObject:NSStringFromUIColor(backgroundColor) forKey:DRAWING_DEFAULT_BACKGROUND_COLOR_KEY];
    
    [defaults setBool:NO forKey:CAN_USE_MORE_BRUSHES];
    [defaults setBool:YES forKey:APP_INITIALISED_KEY];
    [defaults synchronize];
}

+ (void)writeStrokeColor:(UIColor*)color {
    //Updates our strokeColor
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:NSStringFromUIColor(color) forKey:DRAWING_COLOR_KEY];
    [defaults synchronize];
}

+ (UIColor*)strokeColor {
    //Gets our strokeColor
    return UIColorFromNSString([[NSUserDefaults standardUserDefaults]objectForKey:DRAWING_COLOR_KEY]);
}

+ (void)writeLineWidth:(float)lineWidth {
    //Updates our lineWidth
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setFloat:lineWidth forKey:DRAWING_LINE_WIDTH_KEY];
    [defaults synchronize];
}

+ (float)lineWidth {
    //Gets our lineWidth
    return [[NSUserDefaults standardUserDefaults]floatForKey:DRAWING_LINE_WIDTH_KEY];
}

+ (void)writeOpacity:(float)opacity {
    //Updates our opacity
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setFloat:opacity forKey:DRAWING_OPACITY_KEY];
    [defaults synchronize];
}

+ (float)opacity {
    //Gets our opacity
    return [[NSUserDefaults standardUserDefaults]floatForKey:DRAWING_OPACITY_KEY];
}

+ (void)writeLineCapStyle:(CGLineCap)lineCap {
    //Updates our lineCapStyle
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:lineCap forKey:DRAWING_LINE_CAP_KEY];
    [defaults synchronize];
}

+ (CGLineCap)lineCapStyle {
    //Gets our lineCapStyle
    return (CGLineCap)[[NSUserDefaults standardUserDefaults]integerForKey:DRAWING_LINE_CAP_KEY];
}

+ (void)writeBrushPatternType:(CBrushPatternType)brushPatternType {
    //Updates our lineCapStyle
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:brushPatternType forKey:DRAWING_BRUSH_PATTERN_KEY];
    [defaults synchronize];
}

+ (CBrushPatternType)brushPatternType {
    //Gets our brushPattern
    return [[NSUserDefaults standardUserDefaults]integerForKey:DRAWING_BRUSH_PATTERN_KEY];
}

+ (void)writeBrushBlendMode:(NSString *)brushBlendMode {
    //Updates our blendMode
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:brushBlendMode forKey:DRAWING_BRUSH_BLEND_MODE_KEY];
    [defaults synchronize];
}

+ (NSString*)brushBlendMode {
    //Gets our blendMode
    return [[NSUserDefaults standardUserDefaults]objectForKey:DRAWING_BRUSH_BLEND_MODE_KEY];
}

+ (void)writeBackgroundColor:(UIColor*)color {
    //Updates our backgroundColor
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:NSStringFromUIColor(color) forKey:DRAWING_BACKGROUND_COLOR_KEY];
    [defaults synchronize];
}

+ (UIColor*)backgroundColor {
    //Gets our backgroundColor
    return UIColorFromNSString([[NSUserDefaults standardUserDefaults]objectForKey:DRAWING_BACKGROUND_COLOR_KEY]);
}

+ (UIColor*)defaultBackgroundColor {
    //Gets our default backgroundColor
    return UIColorFromNSString([[NSUserDefaults standardUserDefaults]objectForKey:DRAWING_DEFAULT_BACKGROUND_COLOR_KEY]);
}

+ (void)writeSizeWidth:(float)width {
    //Updates our default width
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setFloat:width forKey:DRAWING_SIZE_WIDTH_KEY];
    [defaults synchronize];
}

+ (float)sizeWidth {
    //Gets our default width
    return [[NSUserDefaults standardUserDefaults]floatForKey:DRAWING_SIZE_WIDTH_KEY];
}

+ (void)writeSizeHeight:(float)height {
    //Updates our default height
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setFloat:height forKey:DRAWING_SIZE_HEIGHT_KEY];
    [defaults synchronize];
}

+ (float)sizeHeight {
    //Gets our default height
    return [[NSUserDefaults standardUserDefaults]floatForKey:DRAWING_SIZE_HEIGHT_KEY];
}

+ (void)writeCanUseMoreBrushes:(BOOL)canUseMoreBrushes {
    //Updates our canUseMoreBrushes
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:canUseMoreBrushes forKey:CAN_USE_MORE_BRUSHES];
    [defaults synchronize];
}
+ (BOOL)canUseMoreBrushes {
    //Gets our canUseMoreBrushes
    return [[NSUserDefaults standardUserDefaults]boolForKey:CAN_USE_MORE_BRUSHES];
}
@end
