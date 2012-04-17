//
//  AnotherTest.m
//  TestProject
//
//  Created by Ray Hilton on 1/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AnotherTest.h"

@implementation AnotherTest

// All code under test must be linked into the Unit Test bundle
- (void)testMath
{
    STAssertTrue((1 + 1) == 2, @"Compiler isn't feeling well today :-(");
}

@end
