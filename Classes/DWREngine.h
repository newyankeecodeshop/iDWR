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

#import <UIKit/UIKit.h>

/* The error domain for all DWR NSErrors */
extern NSString* const kDWRErrorDomain;

extern NSInteger const kDWRErrorNoEngine;
extern NSInteger const kDWRErrorCallException;

@protocol DWREngineDelegate;

// ----------------------------------------------------------------------------------------
#pragma mark -

@interface DWREngine : NSObject 
	<UIWebViewDelegate>
{
	NSURL*			m_serviceUrl;
	NSDictionary*	m_headers;
	
	UIWebView*		m_webView;
	
	id<DWREngineDelegate> m_delegate;
	
	NSMutableArray*	m_callers;
}

@property (nonatomic, readonly) NSURL*			serviceUrl;
@property (nonatomic, retain)	NSDictionary*	headers;

@property (nonatomic, assign)	id<DWREngineDelegate> delegate;

/*
 * Access the primary instance of the engine, shared across multiple services.
 */
+ (DWREngine *)mainEngine;

/*
 * Create an instance of the engine bound to a web application at the given URL.
 * The URL should point to an HTML page that loads the DWR service proxy and the engine.
 */
- (id)initWithURL:(NSURL *)siteUrl;

/*
 * Load the engine with the URL provided above. The parent view will host the hidden UIWebView.
 */
- (void)loadEngine:(UIView *)parentView;

/*
 * Load the engine with the HTML container provided, instead of the file from the site URL.
 */
- (void)loadEngine:(UIView *)parentView htmlFile:(NSString *)filePath;

/*
 * Release resources allocated by the engine, such as the UIWebView.
 */
- (void)freeEngine;

/*
 * Execute a method on the service.
 */
- (void)execute:(NSString *)serviceName method:(NSString *)methodName withArguments:(NSArray *)args 
	andCallback:(SEL)callback withObject:(id)caller;

@end

/*
 * This category defines the additional interfaces for creating batches.
 * http://directwebremoting.org/dwr/documentation/browser/engine/batch.html
 */
@interface DWREngine (Batching)

/*
 * Starts a new batch. Calls will be queued for sending until endBatch is invoked.
 */
- (void)beginBatch;

/*
 * Execute the calls made since beginBatch was invoked.
 */
- (void)endBatch;

@end

// -----------------------------------------------------------------------------------
#pragma mark -

/*
 * Protocol to implement for clients of the DWREngine.
 */
@protocol DWREngineDelegate

/*
 * This selector is called when the JavaScript engine has been loaded, either via HTTP or local HTML.
 * At this point, service calls can now be made.
 */
- (void)dwrEngineDidLoad:(DWREngine *)dwrEngine;

/*
 * This selector is called at two times:
 * 1) The engine cannot be loaded, perhaps because the DWR server is not available.
 * 2) A service invocation fails. The NSError will have details about what call failed.
 */
- (void)dwrEngineFailed:(DWREngine *)dwrEngine withError:(NSError *)error;

/*
 * This selector must be implemented to support serializing Arrays and Dictionaries to JSON.
 * The delegate can use whatever JSON library is preferred.
 */
- (NSString *)dwrEngine:(DWREngine *)dwrEngine needsJsonForObject:(id)object;

/*
 * This selector must be implemented to support serializing the return value of calls back
 * into native Foundation objects, such as NSDictionary and NSString.
 */
- (id)dwrEngine:(DWREngine *)dwrEngine needsObjectForJson:(NSString *)json;

@end

