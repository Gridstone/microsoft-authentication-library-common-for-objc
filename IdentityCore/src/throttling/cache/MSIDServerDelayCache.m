//
// Copyright (c) Microsoft Corporation.
// All rights reserved.
//
// This code is licensed under the MIT License.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.  


#import <Foundation/Foundation.h>
#import "MSIDServerDelayCache.h"
#import "MSIDThrottlingCacheRecord.h"
#import "MSIDThrottlingCacheNode.h"
#import "MSIDCache.h"

@interface MSIDServerDelayCache ()

@property (nonatomic) NSUInteger cacheSizeInt;

@end

@implementation MSIDServerDelayCache

- (instancetype)initWithCacheSize:(NSUInteger)cacheSize
{
    self = [super init];
    if (self)
    {
        _cacheSizeInt = cacheSize;
    }
    return self;
}

- (NSUInteger)cacheSize
{
    return self.cacheSizeInt;
}

- (void)addToFront:(NSString *)thumbprintKey
     errorResponse:(NSError *)errorResponse
{
    //TODO: Implement this
    return;
}

- (MSIDThrottlingCacheRecord *)getCachedResponse:(NSString *)thumbprintKey
{
    //TODO: Implement this
    return nil;
}

- (void)removeNode:(NSString *)thumbprintKey
{
    //TODO: implement this
    return;
}

- (MSIDCache *)internalCache
{
    static MSIDCache *m_cache;
    static dispatch_once_t once_token;
    dispatch_once(&once_token, ^{
        m_cache = [MSIDCache new];
    });
    
    return m_cache;
}



@end
