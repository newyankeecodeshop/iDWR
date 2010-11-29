/*
 Copyright (c) 2010 Andrew Goodale. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are
 permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this list of
 conditions and the following disclaimer.
 
 2. Redistributions in binary form must reproduce the above copyright notice, this list
 of conditions and the following disclaimer in the documentation and/or other materials
 provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY ANDREW GOODALE "AS IS" AND ANY EXPRESS OR IMPLIED
 WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 The views and conclusions contained in the software and documentation are those of the
 authors and should not be interpreted as representing official policies, either expressed
 or implied, of Andrew Goodale.
*/ 

#import "DWREngine.h"
#import "NSString+DWR.h"

#define kTopMargin				20.0

NSString* const kDWRErrorDomain = @"dwr.engine.error";
NSInteger const kDWRErrorNoEngine	   = 100;
NSInteger const kDWRErrorCallException = 101;

#pragma mark -

@interface DWREngine ()

- (void)serializeArg:(id)arg inString:(NSMutableString *)invoke;

@end

// -----------------------------------------------------------------------------------------
#pragma mark -

/*
 * An object that stores a record of an invocation that uses a callback.
 * Invocations without a callback don't need an instance of this class.
 */
@interface DWREngineCall : NSObject
{
	id	m_caller;
	SEL	m_callback;
}

@property (nonatomic, assign) id	caller;
@property (nonatomic, assign) SEL	callback;

@end


// -----------------------------------------------------------------------------------------
#pragma mark -

@implementation DWREngine

@synthesize serviceUrl = m_serviceUrl;
@synthesize headers = m_headers;
@synthesize delegate = m_delegate;

/* A shared instance of the first loaded engine. Services will generally use this instance. */
static DWREngine* s_engine = nil;

+ (DWREngine *)mainEngine
{	
	return s_engine;
}

- (id)initWithURL:(NSURL *)siteUrl
{
	if ((self = [super init]))
	{
		m_serviceUrl = siteUrl;
		[m_serviceUrl retain];
		
		m_callers = [[NSMutableArray alloc] initWithCapacity:4];
	}
		
	return self;
}

- (void)dealloc 
{
	[m_headers release];
	[m_callers release];
	[m_serviceUrl release];
	[m_webView release];
	
    [super dealloc];
}

- (void)loadEngine:(UIView *)parentView
{
	// Load the HTML page that defines the DWR service and engine
	//	
	NSURLRequest* request = [NSURLRequest requestWithURL:m_serviceUrl 
											 cachePolicy:NSURLRequestReturnCacheDataElseLoad
										 timeoutInterval:10.0];
	
	CGRect webFrame = [[UIScreen mainScreen] applicationFrame];
	webFrame.origin.y += kTopMargin + 5.0;	// leave from the URL input field and its label
	webFrame.size.height -= 40.0;
		
	m_webView = [[UIWebView alloc] initWithFrame:webFrame];
	m_webView.delegate = self;
	m_webView.hidden = YES;
	m_webView.dataDetectorTypes = UIDataDetectorTypeNone;
	[parentView addSubview:m_webView];
	
	NSLog(@"DWR loadEngine: %@", m_serviceUrl);
	[m_webView loadRequest:request];

	if (s_engine == nil)
		s_engine = self;	// Note the reference count is weak.
}

- (void)loadEngine:(UIView *)parentView htmlFile:(NSString *)filePath
{
	NSError* myErr = nil;
	NSString* htmlString = [[NSString alloc] initWithContentsOfFile:filePath 
														   encoding:NSUTF8StringEncoding
															  error:&myErr];
	if (myErr != nil)
	{
		[htmlString release];
		[m_delegate dwrEngineFailed:self withError:myErr];
		return;
	}
	
	NSString* htmlFull = [NSString stringWithFormat:htmlString, m_serviceUrl];
	[htmlString release];
	
	CGRect webFrame = [[UIScreen mainScreen] applicationFrame];
	webFrame.origin.y += kTopMargin + 5.0;	// leave from the URL input field and its label
	webFrame.size.height -= 40.0;
		
	m_webView = [[UIWebView alloc] initWithFrame:webFrame];
	m_webView.delegate = self;
	m_webView.hidden = YES;
	m_webView.dataDetectorTypes = UIDataDetectorTypeNone;
	[parentView addSubview:m_webView];
	
	NSLog(@"DWR loadEngine: %@", m_serviceUrl);
	[m_webView loadHTMLString:htmlFull baseURL:m_serviceUrl];
	
	if (s_engine == nil)
		s_engine = self;	// Note the reference count is weak.
}

- (void)freeEngine
{
	[m_webView removeFromSuperview];
	m_webView.delegate = nil;
	[m_webView release], m_webView = nil;
	
	if (s_engine == self)
		s_engine = nil;
}

- (void)execute:(NSString *)serviceName method:(NSString *)methodName withArguments:(NSArray *)args 
	andCallback:(SEL)callback withObject:(id)caller
{
	NSMutableString* invoke = [[NSMutableString alloc] initWithCapacity:64];
	[invoke appendFormat:@"%@.%@(", serviceName, methodName];
	
	for (id arg in args)
	{
		[self serializeArg:arg inString:invoke];
	}
	
	// If we have a valid callback, add our JS callback function to the end of the argument list.
	// Also, we save the call delegate in our array of callers in the same order.
	if (caller && callback)
	{
		[invoke appendString:@"dwr.ios.callback)"];
		
		DWREngineCall* callDelegate = [[DWREngineCall alloc] init];
		callDelegate.caller = caller;
		callDelegate.callback = callback;
		
		// Push the callers on the list in order.
		[m_callers addObject:callDelegate];
		[callDelegate release];		
	}
	else if ([args count] > 0) 
	{
		// Remove the trailing ", " before closing the function call
		//
		NSRange range = NSMakeRange([invoke length] - 2, 2);
		[invoke replaceCharactersInRange:range withString:@")"];
	}
	
//	NSLog(@"DWREngine execute: %@", invoke);
	[m_webView stringByEvaluatingJavaScriptFromString:invoke];
	[invoke release];
}

- (void)beginBatch
{
	[m_webView stringByEvaluatingJavaScriptFromString:@"dwr.engine.beginBatch()"];
}

- (void)endBatch
{
	[m_webView stringByEvaluatingJavaScriptFromString:@"dwr.engine.endBatch()"];
}

- (void)serializeArg:(id)arg inString:(NSMutableString *)invoke
{
	if (arg == [NSNull null])
	{
		[invoke appendString:@"null, "];
	}
	else if ([arg isKindOfClass:[NSNumber class]])
	{
		const char* numberType = [arg objCType];
		
		// If the number contains BOOL, its objC type will be "c"
		if (*numberType == 'c')
			[invoke appendString:([arg boolValue] ? @"true, " : @"false, ")];
		else 
			[invoke appendFormat:@"%@, ", arg];
	}
	else if ([arg isKindOfClass:[NSString class]])
	{
		// Need to encode quotes
		[invoke appendFormat:@"%@, ", [arg stringByEscapingForJavaScript]];
	}
	else if ([arg isKindOfClass:[NSDate class]])
	{
		[invoke appendFormat:@"new Date(%.0f), ", [arg timeIntervalSince1970]];
	}
	else // if array or dictionary
	{
		NSString* jsonArg = [m_delegate dwrEngine:self needsJsonForObject:arg];
		[invoke appendFormat:@"%@, ", jsonArg];			
	}	
}

- (void)setHeaders:(NSDictionary *)newHeaders
{
	// Cookies need to be set on the document specifically, otherwise they won't take.
	if ([newHeaders objectForKey:@"Cookie"] != nil)
	{
		NSString* cookie = [newHeaders objectForKey:@"Cookie"];
		NSString* script = [NSString stringWithFormat:@"document.cookie='%@'", cookie];
		[m_webView stringByEvaluatingJavaScriptFromString:script];
	}
	
	NSString* json = [m_delegate dwrEngine:self needsJsonForObject:newHeaders];
	NSString* script = [NSString stringWithFormat:@"dwr.engine.setHeaders(%@)", json];
	[m_webView stringByEvaluatingJavaScriptFromString:script];
}

// -----------------------------------------------------------------------------------------

#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request 
 navigationType:(UIWebViewNavigationType)navigationType
{
//	NSLog(@"DWREngine webView:shouldStartLoad %@", [request URL]);
	
	if (![[[request URL] scheme] isEqualToString:@"dwr-ios"])
		return YES;

	NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
	NSNumber* replyCount = [formatter numberFromString:[[request URL] query]];
		
	for (NSInteger reply = 0; reply < [replyCount unsignedIntValue]; ++reply)
	{
		DWREngineCall* callDelegate = [m_callers objectAtIndex:reply];
		NSString* grabReply = [NSString stringWithFormat:@"dwr.ios.grabReply(%d)", reply];
		NSString* replyData = [webView stringByEvaluatingJavaScriptFromString:grabReply];	
//		NSLog(@"DWREngine: %@", replyData);
		
		// Reply will be of the form "[data|error]:JSON"
		if ([replyData rangeOfString:@"data:"].location == 0)
		{
			id callData = nil;
			NSString* json = [replyData substringFromIndex:5];
			
			// If the result is a String, not an Object, we should remove the quotes.
			if ([json length] > 0 && [json characterAtIndex:0] == '"')
			{
				callData = [json substringWithRange:NSMakeRange(1, [json length] - 2)];
			}
			else	// Must be an object or array
			{
				callData = [m_delegate dwrEngine:self needsObjectForJson:json];					
			}
			
			// We can invoke the callback synchronously because this method is called on a RunLoop 
			// source perform callback.
			[callDelegate.caller performSelector:callDelegate.callback withObject:callData];
		}
		else if ([replyData rangeOfString:@"error:"].location == 0)
		{
			NSString* json = [replyData substringFromIndex:6];
			NSDictionary* exception = [m_delegate dwrEngine:self needsObjectForJson:json];
			
			// Convert into an NSError
			NSError* err = [NSError errorWithDomain:kDWRErrorDomain 
											   code:kDWRErrorCallException 
										   userInfo:exception];
			[m_delegate dwrEngineFailed:self withError:err];
		}
		
		[m_callers removeObjectAtIndex:reply];
	}
	
	[formatter release];
	return NO;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	//Make sure that DWR's engine.js is actually loaded.
	NSString* typeofEngine = [webView stringByEvaluatingJavaScriptFromString:@"typeof(dwr)"];
	
	if ([typeofEngine isEqualToString:@"undefined"])
	{
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:@"The DWR engine.js file was not loaded." 
															 forKey:NSLocalizedDescriptionKey];
		NSError* httpError = [NSError errorWithDomain:kDWRErrorDomain 
												 code:kDWRErrorNoEngine 
											 userInfo:userInfo];		
		[self.delegate dwrEngineFailed:self withError:httpError];
		return;
	}
	
	NSString* scriptFile = [[NSBundle mainBundle] pathForResource:@"idwr-engine" ofType:@"js"];
	NSString* scriptData = [NSString stringWithContentsOfFile:scriptFile encoding:NSUTF8StringEncoding error:nil];

	[webView stringByEvaluatingJavaScriptFromString:scriptData];
	NSLog(@"DWREngine loaded");
	
	[self.delegate dwrEngineDidLoad:self];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	NSLog(@"DWREngine load failed: %@", error);
	
	// Create our own NSError that wraps the load failure
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							  error, NSUnderlyingErrorKey,
							  [error localizedDescription], NSLocalizedDescriptionKey,
							  nil];
	NSError* httpError = [NSError errorWithDomain:kDWRErrorDomain 
											 code:kDWRErrorNoEngine 
										 userInfo:userInfo];
	
	[self.delegate dwrEngineFailed:self withError:httpError];
}

@end

#pragma mark -

@implementation DWREngineCall

@synthesize caller = m_caller;
@synthesize callback = m_callback;

@end
