//
//  TestProjectTests.m
//  TestProjectTests
//
//  Created by Ray Hilton on 10/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TestProjectTests.h"

@implementation TestProjectTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testNilShouldAlwaysBeNil
{
    STAssertNil(nil, @"This should definitely be nil");
}

- (void)testShouldFail
{
    STAssertEquals(1+1, 3, @"Something is broken");
}


@end
