//
//  MongoDBPredicateAdaptor.h
//
//  Created by Tim Bansemer on 6/09/13.
//  Copyright (c) 2013 Tim Bansemer. All rights reserved.

#import "MongoDBPredicateAdaptor.h"
#import <MapKit/MapKit.h>


//logical
NSString *const notOperator = @"$not";
NSString *const andOperator = @"$and";
NSString *const orOperator = @"$or";

//comparison
NSString *const lessThanOperator = @"$lt";
NSString *const lessThanOrEqualsOperator = @"$lte";
NSString *const greaterThanOperator = @"$gt";
NSString *const greaterThanOrEqualsOperator = @"$gte";
NSString *const notEqualsOperator = @"$ne";
NSString *const matchesOperator = @"$regex";

//not directly used
NSString *const equalsOperator = @"eq";

//array
NSString *const inOperator = @"$in";
NSString *const geoInOperator = @"$geoWithin";

//javascript comparison operators
NSString *const jsLessThanOperator = @"<";
NSString *const jsLessThanOrEqualsOperator = @"<=";
NSString *const jsGreaterThanOperator = @">";
NSString *const jsGreaterThanOrEqualsOperator = @"$>=";
NSString *const jsNotEqualsOperator = @"$!==";
NSString *const jsEqualsOperator = @"===";



@implementation MongoDBPredicateAdaptor


#pragma mark - public methods
+(NSDictionary *) queryDictFromPredicate:(NSPredicate *)predicate
                               orError:(NSError **)error
{
    NSDictionary *result = [MongoDBPredicateAdaptor tranformPredicate:predicate];
    
    if (!result && error) {
        NSString *description = NSLocalizedString(@"The predicate is not supported.", nil);
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey :description };
        *error = [NSError errorWithDomain:@"com..predicatetranslate"
                                       code:-666
                                   userInfo:userInfo];
    }

    return result;
}


#pragma mark - private methods
+(NSDictionary *) tranformPredicate:(NSPredicate *)predicate
{
    NSDictionary *result = nil;
    
    if ([predicate isKindOfClass:[NSComparisonPredicate class]]) {
        result = [MongoDBPredicateAdaptor transformComparisonPredicate:
                  (NSComparisonPredicate *)predicate];
    }
    else if ([predicate isKindOfClass:[NSCompoundPredicate class]]){
        result = [MongoDBPredicateAdaptor transformCompoundPredicate:
                  (NSCompoundPredicate *)predicate];
    }
    
    return result;
}


+(NSDictionary *) transformComparisonPredicate:(NSComparisonPredicate *)predicate
{
    NSDictionary *result = nil;

    if (predicate.leftExpression.expressionType==NSFunctionExpressionType||
        predicate.rightExpression.expressionType==NSFunctionExpressionType) {
        result = [MongoDBPredicateAdaptor transformFunctionBasedPredicate:predicate];
    }
    else{
        NSPredicate *replacementPredicate = nil;
        NSString *operator = nil;
        
        operator = [MongoDBPredicateAdaptor operatorStringForPredicate:predicate];
        if (!operator) {
            replacementPredicate = [MongoDBPredicateAdaptor replacementPredicateForPredicate:predicate];
        }
        if (replacementPredicate) {
            result = [MongoDBPredicateAdaptor tranformPredicate:replacementPredicate];
        }
        if (operator) {
            NSArray *expressions = nil;
            expressions = [NSArray arrayWithObjects:
                           predicate.leftExpression,
                           predicate.rightExpression, nil];
            
            result = [MongoDBPredicateAdaptor transformExpressions:expressions
                                                  withOperator:operator];
        }
        
    }
    return result;    
}

+(NSDictionary *) tranformPredicates:(NSArray *)predicates
                        withOperator:(NSString *)operator{
    
    NSMutableArray *subPredicates = [NSMutableArray new];
    
    for (NSPredicate *predicate in predicates) {
        NSDictionary *subResult = [MongoDBPredicateAdaptor tranformPredicate:predicate];
        if (!subResult) {
            break;
        }
        else {
            [subPredicates addObject:subResult];
        }
    }
    
    return @{operator:subPredicates};
}

+(NSString*)operatorStringForPredicate:(NSComparisonPredicate*)predicate{
    NSString *operator = nil;
    
    switch (predicate.predicateOperatorType) {
        case NSLessThanPredicateOperatorType:
            operator = lessThanOperator;
            break;
        case NSLessThanOrEqualToPredicateOperatorType:
            operator = lessThanOrEqualsOperator;
            break;
        case NSGreaterThanPredicateOperatorType:
            operator = greaterThanOperator;
            break;
        case NSGreaterThanOrEqualToPredicateOperatorType:
            operator = greaterThanOrEqualsOperator;
            break;
        case NSEqualToPredicateOperatorType:
            operator = equalsOperator;
            break;
        case NSNotEqualToPredicateOperatorType:
            operator = notEqualsOperator;
            break;
        case NSInPredicateOperatorType:
            operator = inOperator;
            break;
        case NSBetweenPredicateOperatorType:
            //handled by replacing the predicate
            break;
        case NSMatchesPredicateOperatorType:
            operator = matchesOperator;
            break;
            
            //handled by replacing the predicate
        case NSLikePredicateOperatorType:
        case NSBeginsWithPredicateOperatorType:
        case NSEndsWithPredicateOperatorType:
        case NSContainsPredicateOperatorType:
            
            //not Supported
        case NSCustomSelectorPredicateOperatorType:
        default:
            // Not supported, so operator remains nil
            break;
    }
    return operator;
}

+(NSString*)javascriptOperatorStringForPredicate:(NSComparisonPredicate*)predicate{
    NSString *operator = nil;
    switch (predicate.predicateOperatorType) {
        case NSLessThanPredicateOperatorType:
            operator = jsLessThanOperator;
            break;
        case NSLessThanOrEqualToPredicateOperatorType:
            operator = jsLessThanOrEqualsOperator;
            break;
        case NSGreaterThanPredicateOperatorType:
            operator = jsGreaterThanOperator;
            break;
        case NSGreaterThanOrEqualToPredicateOperatorType:
            operator = jsGreaterThanOrEqualsOperator;
            break;
        case NSEqualToPredicateOperatorType:
            operator = jsEqualsOperator;
            break;
        case NSNotEqualToPredicateOperatorType:
            operator = jsNotEqualsOperator;
            break;
        default:
            break;
    }
    
    return operator;
}

+(NSPredicate*)replacementPredicateForPredicate:(NSComparisonPredicate*)predicate{
    NSPredicate *replacementPredicate = nil;
    
    if (predicate.predicateOperatorType==NSBetweenPredicateOperatorType) {
        replacementPredicate =
        [MongoDBPredicateAdaptor replacementPredicateForBetweenPredicate:predicate];
    }
    else if (predicate.predicateOperatorType==NSBeginsWithPredicateOperatorType){
        replacementPredicate = [MongoDBPredicateAdaptor replacementPredicateBeginsWithPredicate:predicate];

    }
    else if (predicate.predicateOperatorType==NSContainsPredicateOperatorType) {
        replacementPredicate = [MongoDBPredicateAdaptor replacementPredicateContainsPredicate:predicate];

    }
    else if (predicate.predicateOperatorType == NSEndsWithPredicateOperatorType) {
        replacementPredicate = [MongoDBPredicateAdaptor replacementPredicateEndsWithPredicate:predicate];

    }
    else if (predicate.predicateOperatorType == NSLikePredicateOperatorType){
        replacementPredicate = [MongoDBPredicateAdaptor replacementPredicateLikePredicate:predicate];
    }
    
    return replacementPredicate;
}

+(NSDictionary *) transformCompoundPredicate:(NSCompoundPredicate *)predicate
{
    NSDictionary *result = nil;
    NSString *operator = nil;
    
    switch (predicate.compoundPredicateType) {
        case NSNotPredicateType:
            operator = notOperator;
            break;
        case NSAndPredicateType:
            operator = andOperator;
            break;
        case NSOrPredicateType:
            operator = orOperator;
            break;
        default:
            // do nothing if unknown
            break;
    }
    
    if (operator) {
        result = [MongoDBPredicateAdaptor tranformPredicates:predicate.subpredicates
                                           withOperator:operator];
    }
    
    return result;
}


+(NSPredicate *) replacementPredicateBeginsWithPredicate:(NSComparisonPredicate *)predicate{
    NSPredicate *newPredicate = nil;
    id constant = predicate.rightExpression.constantValue;
    if (constant) {
        NSString *beginsWithRegex = [NSString stringWithFormat:@"/^%@/",predicate.rightExpression.constantValue];
        newPredicate = [MongoDBPredicateAdaptor replacementPredicateForPredicate:predicate withRegexString:beginsWithRegex];
    }
    return newPredicate;
}

+(NSPredicate *) replacementPredicateEndsWithPredicate:(NSComparisonPredicate *)predicate{
    NSPredicate *newPredicate = nil;
    id constant = predicate.rightExpression.constantValue;
    if (constant) {
        NSString *endsWithRegex = [NSString stringWithFormat:@"/.*%@/",predicate.rightExpression.constantValue];
        newPredicate = [MongoDBPredicateAdaptor replacementPredicateForPredicate:predicate withRegexString:endsWithRegex];
    }
    return newPredicate;
}

+(NSPredicate *) replacementPredicateContainsPredicate:(NSComparisonPredicate *)predicate{
    NSPredicate *newPredicate = nil;
    id constant = predicate.rightExpression.constantValue;
    if (constant) {
        NSString *containsRegex = [NSString stringWithFormat:@"/.*%@.*/",predicate.rightExpression.constantValue];
        newPredicate = [MongoDBPredicateAdaptor replacementPredicateForPredicate:predicate withRegexString:containsRegex];
    }
    return newPredicate;
}

+(NSPredicate *) replacementPredicateLikePredicate:(NSComparisonPredicate *)predicate{
    NSPredicate *newPredicate = nil;
    id constant = predicate.rightExpression.constantValue;
    if (constant) {
        NSString *likeRegex = [NSString stringWithFormat:@"/(%@)/",predicate.rightExpression.constantValue];
        newPredicate = [MongoDBPredicateAdaptor replacementPredicateForPredicate:predicate withRegexString:likeRegex];
    }
    return newPredicate;
}

+(NSPredicate *) replacementPredicateForPredicate:(NSComparisonPredicate*)predicate withRegexString:(NSString*)regex{
    NSExpression *newRightExpression = [NSExpression expressionForConstantValue:regex];
    NSPredicate *newPredicate = [NSComparisonPredicate predicateWithLeftExpression:predicate.leftExpression rightExpression:newRightExpression modifier:predicate.comparisonPredicateModifier type:NSMatchesPredicateOperatorType options:predicate.options];
    return newPredicate;
}


+(NSPredicate *) replacementPredicateForBetweenPredicate:(NSComparisonPredicate *)predicate
{
    NSMutableArray *subPredicates = [NSMutableArray array];
    
    NSExpression *rightExpression = predicate.rightExpression;
    NSExpression *leftExpression = predicate.leftExpression;
    
    NSArray *bounds = rightExpression.constantValue;
    id lowerBound = [bounds objectAtIndex:0];
    id upperBound = [bounds objectAtIndex:1];
    
    NSExpression *lowerBoundExpression = [MongoDBPredicateAdaptor ensureExpression:lowerBound];
    NSExpression *upperBoundExpression = [MongoDBPredicateAdaptor ensureExpression:upperBound];
    
    NSPredicate *lowerSubPredicate =
    [NSComparisonPredicate predicateWithLeftExpression:leftExpression
                                       rightExpression:lowerBoundExpression
                                              modifier:predicate.comparisonPredicateModifier
                                                  type:NSGreaterThanOrEqualToPredicateOperatorType
                                               options:predicate.options];
    [subPredicates addObject:lowerSubPredicate];
    
    NSPredicate *upperSubPredicate =
    [NSComparisonPredicate predicateWithLeftExpression:leftExpression
                                       rightExpression:upperBoundExpression
                                              modifier:predicate.comparisonPredicateModifier
                                                  type:NSLessThanOrEqualToPredicateOperatorType
                                               options:predicate.options];
    [subPredicates addObject:upperSubPredicate];
    
    return [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];
}


+(NSExpression *) ensureExpression:(id) item
{
    NSExpression *expression;
    
    if ([item isKindOfClass:[NSExpression class]]) {
        expression = item;
    }
    else {
        expression = [NSExpression expressionForConstantValue:item];
    }
    
    return expression;
}


+(NSDictionary*)transformFunctionBasedPredicate:(NSComparisonPredicate*)predicate{
    NSDictionary *result = nil;
    
    predicate = [MongoDBPredicateAdaptor predicateWithJSThisToKeyPathsInPredicate:predicate];
    NSString *operator = [MongoDBPredicateAdaptor javascriptOperatorStringForPredicate:predicate];
    if (operator) {
        NSString *functionString = [NSString stringWithFormat:@"%@ %@ %@",predicate.leftExpression.description, operator, predicate.rightExpression.description];
        
        result =  @{@"$where":functionString};
    }
    return result;
}

+(NSComparisonPredicate*)predicateWithJSThisToKeyPathsInPredicate:(NSComparisonPredicate*)predicate{
    NSExpression *leftExpression = [MongoDBPredicateAdaptor ensureKeyPathExpressionsContainJSThisInExpression:predicate.leftExpression];
    NSExpression *rightExpression = [MongoDBPredicateAdaptor ensureKeyPathExpressionsContainJSThisInExpression:predicate.rightExpression];
    NSComparisonPredicate *newPredicate = (NSComparisonPredicate*)[NSComparisonPredicate predicateWithLeftExpression:leftExpression rightExpression:rightExpression modifier:predicate.comparisonPredicateModifier type:predicate.predicateOperatorType options:predicate.options];
    
    return newPredicate;
}


#pragma mark - expression transformation
+(id) transformExpression:(NSExpression *)expression modifyingOperator:(NSString**)operator
{
    id result = nil;
    
    switch (expression.expressionType)
    {
        case NSConstantValueExpressionType:
            result = [MongoDBPredicateAdaptor transformConstant:expression.constantValue modifyingOperator:operator];
            break;
        case NSKeyPathExpressionType:
            result = expression.keyPath;
            break;
        case NSFunctionExpressionType:
            //functions handled by function adaptor
            break;
        case NSEvaluatedObjectExpressionType:
        case NSVariableExpressionType:
        case NSAggregateExpressionType:
        case NSSubqueryExpressionType:
        case NSUnionSetExpressionType:
        case NSIntersectSetExpressionType:
        case NSMinusSetExpressionType:
        case NSBlockExpressionType:
        default:
            // do nothing
            break;
    }
    return result;
}

+(NSDictionary *) transformExpressions:(NSArray *)expressions
                 withOperator:(NSString *)operator
{
    NSDictionary *result = [NSMutableDictionary new];
    
    id field = [MongoDBPredicateAdaptor transformExpression:expressions[0] modifyingOperator:&operator];
    id param = [MongoDBPredicateAdaptor transformExpression:expressions[1] modifyingOperator:&operator];
    
    if ([operator isEqualToString:@"eq"]) {
        [result setValue:param forKey:field];
    }
    else{
        NSDictionary *query = @{operator:param};
        result = @{field:query};
    }
    
    return result;
}

+(NSExpression*)ensureKeyPathExpressionsContainJSThisInExpression:(NSExpression*)expression{
    NSExpression *newExpression = expression;
    switch (expression.expressionType) {
        case NSKeyPathExpressionType:
            newExpression = [NSExpression expressionForKeyPath:[NSString stringWithFormat:@"this.%@",expression.keyPath]];
            break;
        case NSFunctionExpressionType:{
            NSMutableArray *newArguments = [NSMutableArray new];
            for (NSExpression *argument in expression.arguments) {
                NSExpression *newArgument = [MongoDBPredicateAdaptor ensureKeyPathExpressionsContainJSThisInExpression:argument];
                [newArguments addObject:newArgument];
            }
            newExpression = [NSExpression expressionForFunction:expression.function arguments:newArguments];
        }
            break;
        default:
            break;
    }
    return newExpression;
}

#pragma mark - Constant Transformation
+(id) transformConstant:(id)constant modifyingOperator:(NSString**)operator
{
    id result = nil;
    
    if (constant == nil || constant == [NSNull null]) {
        result = [NSNull null];
    }
    else if ([constant isKindOfClass:[NSString class]]) {
        if ([*operator isEqualToString:inOperator]) {
            result = [MongoDBPredicateAdaptor transformArrayConstant:@[constant]];
        }
        else{
            result = [MongoDBPredicateAdaptor transformStringConstant:constant];
        }
    }
    else if ([constant isKindOfClass:[NSDate class]]) {
        result = [MongoDBPredicateAdaptor transformDateConstant:constant];
    }
    else if ([constant isKindOfClass:[NSDecimalNumber class]]) {
        result = [MongoDBPredicateAdaptor transformDecimalNumberConstant:constant];
    }
    else if ([constant isKindOfClass:[NSNumber class]]) {
        result = [MongoDBPredicateAdaptor transformNumberConstant:constant];
    }
    else if ([constant isKindOfClass:[NSArray class]]) {
        result = [MongoDBPredicateAdaptor transformArrayConstant:constant];
    }
    else if ([constant isKindOfClass:[NSSet class]]){
        result = [MongoDBPredicateAdaptor transformSetConstant:constant];
    }
    else if ([constant isKindOfClass:[MKShape class]]){
        result = [MongoDBPredicateAdaptor transformGeoShapeConstant:constant];
        *operator = geoInOperator;
    }
    
    return result;
}

+(NSString *) transformStringConstant:(NSString *)string
{
    return string;
}

+(NSNumber *) transformDateConstant:(NSDate *)date
{
    return @([date timeIntervalSince1970]);
}

+(NSNumber *) transformNumberConstant:(NSNumber *)number
{
    return number;
}

+(NSDecimalNumber *)transformDecimalNumberConstant:(NSDecimalNumber*)number{
    return number;
}

+(NSArray *) transformArrayConstant:(NSArray *)array
{
    return array;
}

+(NSArray *) transformSetConstant:(NSSet *)set{
    return [set allObjects];
}
              
+(NSDictionary*)transformGeoShapeConstant:(MKShape*)constant{
    NSDictionary *result = nil;
    if ([constant isKindOfClass:[MKCircle class]]) {
        MKCircle *circle = (MKCircle*)constant;
        result = @{@"$centerSphere":@[@[@(circle.coordinate.longitude),@(circle.coordinate.latitude)],@(circle.radius/6371000.0f)]};
    }
    else if ([constant isKindOfClass:[MKPolygon class]]){
        
        MKPolygon *polygon = (MKPolygon*)constant;
        CLLocationCoordinate2D *coords = malloc(sizeof(CLLocationCoordinate2D) * polygon.pointCount);
        [polygon getCoordinates:coords range:NSMakeRange(0,polygon.pointCount)];
        NSMutableArray *coordArray = [[NSMutableArray alloc]initWithCapacity:polygon.pointCount];
        for (int i = 0; i < polygon.pointCount; i++) {
            CLLocationCoordinate2D coord = coords[0];
            coordArray[i] = @[@(coord.longitude),@(coord.latitude)];
        }
        result = @{@"$geometry":@{@"type":@"Polygon", @"coordinates":coordArray}};        
    }
    return result;
}


@end
