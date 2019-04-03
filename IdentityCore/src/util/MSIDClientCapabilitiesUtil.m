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

#import "MSIDClientCapabilitiesUtil.h"
#import "NSDictionary+MSIDExtensions.h"
#import "MSIDClaimsRequest.h"
#import "MSIDIndividualClaimRequest.h"
#import "MSIDIndividualClaimRequestAdditionalInfo.h"

static NSString *kCapabilitiesClaims = @"xms_cc";

@implementation MSIDClientCapabilitiesUtil

+ (MSIDClaimsRequest *)msidClaimsRequestFromCapabilities:(NSArray<NSString *> *)capabilities
                                           claimsRequest:(MSIDClaimsRequest *)claimsRequest
{
    if (![capabilities count]) return [claimsRequest copy];
    
    MSIDClaimsRequest *result = claimsRequest ? [claimsRequest copy] : [MSIDClaimsRequest new];
    MSIDIndividualClaimRequest *claimRequest = [MSIDIndividualClaimRequest new];
    claimRequest.name = kCapabilitiesClaims;
    claimRequest.additionalInfo = [MSIDIndividualClaimRequestAdditionalInfo new];
    claimRequest.additionalInfo.values = [[NSSet alloc] initWithArray:capabilities];
    
    [result requestClaim:claimRequest forTarget:MSIDClaimsRequestTargetAccessToken];
    
    return result;
}

+ (NSString *)jsonFromClaimsRequest:(MSIDClaimsRequest *)claimsRequest
{
    NSDictionary *claims = [claimsRequest jsonDictionary];
    if (!claims)
    {
        return nil;
    }

    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:claims options:0 error:&error];

    if (!jsonData)
    {
        MSID_LOG_NO_PII(MSIDLogLevelError, nil, nil, @"Failed to convert capabilities into JSON");
        MSID_LOG_PII(MSIDLogLevelError, nil, nil, @"Failed to convert capabilities into JSON with error %@", error.description);
        
        return nil;
    }

    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

@end
