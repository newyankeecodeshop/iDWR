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

#import "DemoViewController.h"
#import "DWREngine.h"
#import "NSObject+SBJSON.h"
#import "NSString+SBJSON.h"

@implementation DemoViewController



/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

- (void)dealloc 
{
	[m_dwr release];
	
    [super dealloc];
}

- (IBAction)sayHello:(id)sender
{
	[nameField resignFirstResponder];
	
	NSArray* args = [NSArray arrayWithObject:nameField.text];
	[m_dwr execute:@"Demo" method:@"sayHello" withArguments:args andCallback:@selector(updateResponse:) withObject:self];	
}

- (void)updateResponse:(id)data
{
    replyField.text = (NSString*)data;	
}

#pragma mark UIViewController

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];
	
	NSURL* index = [NSURL URLWithString:@"http://localhost:8080/dwr/simpletext/index.html"];
	m_dwr = [[DWREngine alloc] initWithURL:index];
	m_dwr.delegate = self;
	
	[m_dwr loadEngine:self.view];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning 
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload 
{
	[m_dwr freeEngine];
	
	[nameField release];
	nameField = nil;
}

#pragma mark DWREngineDelegate

- (void)dwrEngineDidLoad:(DWREngine *)dwrEngine
{
	
}

- (void)dwrEngineFailed:(DWREngine *)dwrEngine withError:(NSError *)error
{
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"DWR Error" 
													message:[error localizedDescription] 
												   delegate:nil 
										  cancelButtonTitle:@"Bummer!" 
										  otherButtonTitles:nil];
	[alert show];
	[alert release];
}

- (NSString *)dwrEngine:(DWREngine *)dwrEngine needsJsonForObject:(id)object
{
	return [object JSONRepresentation];
}

- (id)dwrEngine:(DWREngine *)dwrEngine needsObjectForJson:(NSString *)json
{
	return [json JSONValue];
}

@end
