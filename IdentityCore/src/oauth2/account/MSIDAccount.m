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

#import "MSIDAccount.h"
#import "MSIDClientInfo.h"
#import "MSIDAADTokenResponse.h"
#import "MSIDIdTokenClaims.h"
#import "MSIDAccountCacheItem.h"
#import "MSIDConfiguration.h"
#import "MSIDTokenResponse.h"
#import "MSIDClientInfo.h"
#import "MSIDClientInfo.h"
#import "MSIDClientInfo.h"

@implementation MSIDAccount

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    MSIDAccount *item = [[self.class allocWithZone:zone] init];
    item->_uniqueUserId = [_uniqueUserId copyWithZone:zone];
    item->_legacyUserId = [_legacyUserId copyWithZone:zone];
    item->_accountType = _accountType;
    item->_authority = [_authority copyWithZone:zone];
    item->_username = [_username copyWithZone:zone];
    item->_givenName = [_givenName copyWithZone:zone];
    item->_middleName = [_middleName copyWithZone:zone];
    item->_familyName = [_familyName copyWithZone:zone];
    item->_name = [_name copyWithZone:zone];
    item->_clientInfo = [_clientInfo copyWithZone:zone];
    item->_alternativeAccountId = [_alternativeAccountId copyWithZone:zone];
    return item;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object
{
    if (self == object)
    {
        return YES;
    }
    
    if (![object isKindOfClass:MSIDAccount.class])
    {
        return NO;
    }
    
    return [self isEqualToItem:(MSIDAccount *)object];
}

- (NSUInteger)hash
{
    NSUInteger hash = 0;
    hash = hash * 31 + self.uniqueUserId.hash;
    hash = hash * 31 + self.legacyUserId.hash;
    hash = hash * 31 + self.accountType;
    hash = hash * 31 + self.authority.hash;
    hash = hash * 31 + self.alternativeAccountId.hash;
    return hash;
}

- (BOOL)isEqualToItem:(MSIDAccount *)account
{
    if (!account)
    {
        return NO;
    }
    
    BOOL result = YES;
    result &= (!self.uniqueUserId && !account.uniqueUserId) || [self.uniqueUserId isEqualToString:account.uniqueUserId];
    result &= (!self.legacyUserId && !account.legacyUserId) || [self.legacyUserId isEqualToString:account.legacyUserId];
    result &= self.accountType == account.accountType;
    result &= (!self.alternativeAccountId && !account.alternativeAccountId) || [self.alternativeAccountId isEqualToString:account.alternativeAccountId];
    result &= (!self.authority && !account.authority) || [self.authority isEqual:account.authority];
    return result;
}

#pragma mark - Init

- (instancetype)initWithLegacyUserId:(NSString *)legacyUserId
                          clientInfo:(MSIDClientInfo *)clientInfo
{
    self = [self initWithLegacyUserId:legacyUserId
                         uniqueUserId:clientInfo.userIdentifier];
    
    if (self)
    {
        _clientInfo = clientInfo;
    }
    
    return self;
}

- (instancetype)initWithLegacyUserId:(NSString *)legacyUserId
                        uniqueUserId:(NSString *)userIdentifier
{
    if (!(self = [self init]))
    {
        return nil;
    }
    
    _legacyUserId = legacyUserId;
    _uniqueUserId = userIdentifier;
    
    return self;
}

#pragma mark - Cache

- (instancetype)initWithAccountCacheItem:(MSIDAccountCacheItem *)cacheItem
{
    self = [super init];
    
    if (self)
    {
        if (!cacheItem)
        {
            return nil;
        }
        
        _legacyUserId = cacheItem.legacyUserId;
        _accountType = cacheItem.accountType;
        _givenName = cacheItem.givenName;
        _familyName = cacheItem.familyName;
        _middleName = cacheItem.middleName;
        _name = cacheItem.name;
        _username = cacheItem.username;
        _uniqueUserId = cacheItem.uniqueUserId;
        _clientInfo = cacheItem.clientInfo;
        _alternativeAccountId = cacheItem.alternativeAccountId;

        NSString *environment = cacheItem.environment;
        NSString *tenant = cacheItem.realm;

        _authority = [NSURL msidURLWithEnvironment:environment tenant:tenant];
    }
    
    return self;
}

- (MSIDAccountCacheItem *)accountCacheItem
{
    MSIDAccountCacheItem *cacheItem = [[MSIDAccountCacheItem alloc] init];

    if (self.storageAuthority)
    {
        cacheItem.environment = self.storageAuthority.msidHostWithPortIfNecessary;
    }
    else
    {
        cacheItem.environment = self.authority.msidHostWithPortIfNecessary;
    }

    cacheItem.realm = self.authority.msidTenant;
    cacheItem.username = self.username;
    cacheItem.uniqueUserId = self.uniqueUserId;
    cacheItem.legacyUserId = self.legacyUserId;
    cacheItem.accountType = self.accountType;
    cacheItem.givenName = self.givenName;
    cacheItem.middleName = self.middleName;
    cacheItem.name = self.name;
    cacheItem.familyName = self.familyName;
    cacheItem.clientInfo = self.clientInfo;
    
    return cacheItem;
}

#pragma mark - Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"(authority=%@ username=%@ uniqueUserId=%@ clientInfo=%@ accountType=%@ legacyUserId=%@)",
            _authority, _username, _uniqueUserId, _clientInfo, [MSIDAccountTypeHelpers accountTypeAsString:_accountType], _legacyUserId];
}

@end
