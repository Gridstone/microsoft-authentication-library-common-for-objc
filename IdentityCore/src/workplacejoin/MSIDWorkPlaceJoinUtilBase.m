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

#import "MSIDKeychainUtil.h"
#import "MSIDWorkPlaceJoinUtil.h"
#import "MSIDWorkPlaceJoinUtilBase.h"
#import "MSIDWorkPlaceJoinUtilBase+Internal.h"
#import "MSIDWorkPlaceJoinConstants.h"
#import "MSIDWPJKeyPairWithCert.h"

NSString *const MSID_DEVICE_INFORMATION_UPN_ID_KEY        = @"userPrincipalName";
NSString *const MSID_DEVICE_INFORMATION_AAD_DEVICE_ID_KEY = @"aadDeviceIdentifier";
NSString *const MSID_DEVICE_INFORMATION_AAD_TENANT_ID_KEY = @"aadTenantIdentifier";

@implementation MSIDWorkPlaceJoinUtilBase

+ (NSString *_Nullable)getWPJStringDataForIdentifier:(nonnull NSString *)identifier
                                         accessGroup:(nullable NSString *)accessGroup
                                             context:(id<MSIDRequestContext>_Nullable)context
                                               error:(NSError*__nullable*__nullable)error
{
    // Building dictionary to retrieve given identifier from the keychain
    NSMutableDictionary *query = [[NSMutableDictionary alloc] init];
    [query setObject:(__bridge id)(kSecClassGenericPassword) forKey:(__bridge id<NSCopying>)(kSecClass)];
    [query setObject:identifier forKey:(__bridge id<NSCopying>)(kSecAttrAccount)];
    [query setObject:(id)kCFBooleanTrue forKey:(__bridge id<NSCopying>)(kSecReturnAttributes)];
    if (accessGroup)
    {
        [query setObject:accessGroup forKey:(__bridge id)kSecAttrAccessGroup];
    }

    CFDictionaryRef result = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
    if (status != errSecSuccess)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"String Data not found with error code:%d", (int)status);

        return nil;
    }

    NSString *stringData = [(__bridge NSDictionary *)result objectForKey:(__bridge id)(kSecAttrService)];

    if (result)
    {
        CFRelease(result);
    }

    if (!stringData || stringData.msidTrimmedString.length == 0)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDKeychainErrorDomain, status, @"Found empty keychain item.", nil, nil, nil, context.correlationId, nil, NO);
        }
    }

    return stringData;
}

+ (nullable NSDictionary *)getRegisteredDeviceMetadataInformation:(nullable id<MSIDRequestContext>)context
{
    MSIDWPJKeyPairWithCert *wpjCerts = [MSIDWorkPlaceJoinUtil getWPJKeysWithTenantId:nil context:context];

    if (wpjCerts)
    {
        NSString *userPrincipalName = [MSIDWorkPlaceJoinUtil getWPJStringDataForIdentifier:kMSIDUPNKeyIdentifier context:context error:nil];
        NSString *tenantId = [MSIDWorkPlaceJoinUtil getWPJStringDataForIdentifier:kMSIDTenantKeyIdentifier context:context error:nil];
        NSMutableDictionary *registrationInfoMetadata = [NSMutableDictionary new];

        // Certificate subject is nothing but the AAD deviceID
        [registrationInfoMetadata setValue:wpjCerts.certificateSubject forKey:MSID_DEVICE_INFORMATION_AAD_DEVICE_ID_KEY];
        [registrationInfoMetadata setValue:userPrincipalName forKey:MSID_DEVICE_INFORMATION_UPN_ID_KEY];
        [registrationInfoMetadata setValue:tenantId forKey:MSID_DEVICE_INFORMATION_AAD_TENANT_ID_KEY];
        return registrationInfoMetadata;
    }

    return nil;
}

+ (nullable MSIDWPJKeyPairWithCert *)findWPJRegistrationInfoWithAdditionalPrivateKeyAttributes:(nonnull NSDictionary *)queryAttributes
                                                                                certAttributes:(nullable NSDictionary *)certAttributes
                                                                                       context:(nullable id<MSIDRequestContext>)context
{
    OSStatus status = noErr;
    CFTypeRef privateKeyCFDict = NULL;
    
    // Set the private key query dictionary.
    NSMutableDictionary *queryPrivateKey = [NSMutableDictionary new];
    queryPrivateKey[(__bridge id)kSecClass] = (__bridge id)kSecClassKey;
    queryPrivateKey[(__bridge id)kSecReturnAttributes] = @YES;
    queryPrivateKey[(__bridge id)kSecReturnRef] = @YES;
    
    if (queryAttributes)
    {
        [queryPrivateKey addEntriesFromDictionary:queryAttributes];
    }
    
    status = SecItemCopyMatching((__bridge CFDictionaryRef)queryPrivateKey, (CFTypeRef*)&privateKeyCFDict); // +1 privateKeyCFDict
    if (status != errSecSuccess)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Failed to find workplace join private key with status %ld", (long)status);
        return nil;
    }
        
    NSDictionary *privateKeyDict = CFBridgingRelease(privateKeyCFDict); // -1 privateKeyCFDict
    
    /*
     kSecAttrApplicationLabel
     For asymmetric keys this holds the public key hash which allows digital identity formation (to form a digital identity, this value must match the kSecAttrPublicKeyHash ('pkhh') attribute of the certificate)
     */
    NSData *applicationLabel = privateKeyDict[(__bridge id)kSecAttrApplicationLabel];

    if (!applicationLabel)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Unexpected key found without application label. Aborting lookup");
        return nil;
    }
    
    SecKeyRef privateKeyRef = (__bridge SecKeyRef)privateKeyDict[(__bridge id)kSecValueRef];
    
    if (!privateKeyRef)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"No private key ref found. Aborting lookup.");
        return nil;
    }
        
    NSDictionary *certQuery = @{(__bridge id)kSecClass : (__bridge id)kSecClassCertificate,
                                (__bridge id)kSecAttrPublicKeyHash: applicationLabel,
                                (__bridge id)kSecReturnRef : @YES
    };
    
    NSMutableDictionary *mutableCertQuery = [certQuery mutableCopy];
    
    if (certAttributes)
    {
        [mutableCertQuery addEntriesFromDictionary:certAttributes];
    }
    
    SecCertificateRef certRef;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)mutableCertQuery, (CFTypeRef*)&certRef); // +1 certRef
    
    if (status != errSecSuccess || !certRef)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Failed to find certificate for public key hash with status %ld", (long)status);
        return nil;
    }
    
    // Get the public key
    MSID_LOG_WITH_CTX(MSIDLogLevelVerbose, context, @"Retrieving WPJ public key reference.");
    SecKeyRef publicKeyRef = nil;
    NSString *issuer = nil;
    
    if (@available(iOS 12.0, macos 10.14, *))
    {
        publicKeyRef = SecCertificateCopyKey(certRef); // +1 publicKeyRef
    }
    else
    {
#if TARGET_OS_IPHONE
        publicKeyRef = SecCertificateCopyPublicKey(certRef); // +1 publicKeyRef
#else
        status = SecCertificateCopyPublicKey(certRef, &publicKeyRef); // +1 publicKeyRef
        MSID_LOG_WITH_CTX(MSIDLogLevelVerbose, context, @"WPJ public key reference retrieved with result %ld", (long)status);
#endif
    }
            
    if (!publicKeyRef)
    {
        CFReleaseNull(certRef);
        MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"No public key ref found. Aborting lookup.");
        return nil;
    }
    
    MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Public key ref successfully retrieved");
        
    NSData *issuerData = nil;
    
    if (@available(iOS 11.0, macOS 10.12.4, *))
    {
        issuerData = CFBridgingRelease(SecCertificateCopyNormalizedIssuerSequence(certRef));
    }
#if !TARGET_OS_IPHONE
    else
    {
        issuerData = CFBridgingRelease(SecCertificateCopyNormalizedIssuerContent(certRef, NULL));
    }
#endif
        
    if (issuerData)
    {
        issuer = [[NSString alloc] initWithData:issuerData encoding:NSASCIIStringEncoding];
    }
    
    MSID_LOG_WITH_CTX_PII(MSIDLogLevelVerbose, context, @"Retrieved WPJ issuer %@", MSID_PII_LOG_MASKABLE(issuer));
    
    MSIDWPJKeyPairWithCert *keyPair = [[MSIDWPJKeyPairWithCert alloc] initWithPrivateKey:privateKeyRef
                                                                               publicKey:publicKeyRef
                                                                             certificate:certRef
                                                                       certificateIssuer:issuer
                                                                          privateKeyDict:privateKeyDict];
    CFReleaseNull(certRef);
    CFReleaseNull(publicKeyRef);
    return keyPair;
}

@end
