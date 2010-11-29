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

#import "PeopleEditController.h"
#import "PeopleTableController.h"
#import "DWREngine.h"

@implementation PeopleEditController

@synthesize nameField = m_nameField, salaryField = m_salaryField;
@synthesize addressField = m_addressField, idLabel = m_idLabel;
@synthesize person = m_person;

- (void)dealloc 
{
	[m_person release];
	
    [super dealloc];
}

- (IBAction)writePerson:(id)sender
{
	NSDictionary* person = [NSDictionary dictionaryWithObjectsAndKeys:
							[m_person objectForKey:@"id"], @"id",
							m_nameField.text, @"name",
							m_addressField.text, @"address",
							m_salaryField.text, @"salary",
							nil];
	PeopleTableController* tableController = [[[self navigationController] viewControllers] objectAtIndex:0];

	DWREngine* dwr = tableController.dwr;
	
	[dwr beginBatch];
	[dwr execute:@"People" method:@"setPerson" withArguments:[NSArray arrayWithObject:person] 
					  andCallback:nil withObject:self];		
	[dwr execute:@"People" method:@"getAllPeople" withArguments:nil 
					  andCallback:@selector(gotAllPeople:) withObject:tableController];		
	[dwr endBatch];
}

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

#pragma mark UIViewController

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];
	
	NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
	
	m_nameField.text = [m_person objectForKey:@"name"];
	m_salaryField.text = [formatter stringFromNumber:[m_person objectForKey:@"salary"]];
	m_addressField.text = [m_person objectForKey:@"address"];
	m_idLabel.text = [formatter stringFromNumber:[m_person objectForKey:@"id"]];
	
	[formatter release];
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
    [super viewDidUnload];
    
	// Release any retained subviews of the main view.
    self.nameField = nil;
	self.salaryField = nil;
	self.addressField = nil;
	self.idLabel = nil;
}



@end
