# Overview

Welcome to "iDWR", a native iOS wrapper for the DWR client engine. This library allows Objective-C classes to invoke DWR-based services using an embedded UIWebView that hosts the DWR engine. The DWR engine is handling the network operations, just as in a standard browser. The library code is coordinating the callbacks and handling marshaling to/from Objective-C types.

# Requirements

This code is compiled against the iOS 4.1 SDK, and should run fine on iOS 3.1 or later.

## JSON

Service call parameters and response data is marshaled into and out of the UIWebView using JSON. You will need to use a JSON library such as SBJson or TouchJSON in your project to help iDWR with that.

# Usage

You can use iDWR by directly including the Classes and Resources into your project, or by building and linking with the shared library. Note that you need to include idwr-engine.js as a bundle resource either way. This file is used by the engine to implement some enhancements to the DWR engine that facilitate the call bridging.

Make sure you implement the DWREngineDelegate. It has important methods for dealing with errors and hooking in a JSON library (see above).

## Initializing the engine

The first thing your app needs to do is setup the DWR engine. There are two ways you can do it. You can give iDWR the URL to an HTML file that includes DWR's "engine.js" and the generated service proxy JS files. The other way is to write your own HTML page that includes these files, and place that HTML file in your bundle. If your web application's main HTML page that includes DWR is simple, use that. If not, using a bundle HTML file will reduce the memory consumption and improve startup time, since the UIWebView won't have to load a lot of other JS/CSS/HTML that is used in the web app's main UI.

Here's an example:

	NSURL* index = [NSURL URLWithString:@"http://localhost:8080/dwr/simpletext/index.html"];
	DWREngine* dwr = [[DWREngine alloc] initWithURL:index];
	
	dwr.delegate = self;
	[dwr loadEngine:self.view];

## Calling a service

Once the DWR engine is loaded, you can start making calls. As in the JavaScript API, the method you want to invoke is .

For example, assuming you want to call the "Demo.sayHello()" method in the dwr.war tutorial, you would write:

	NSArray* args = [NSArray arrayWithObject:@"Andrew"];
	[dwr execute:@"Demo" method:@"sayHello" withArguments:args andCallback:@selector(updateResponse:) withObject:self];	

Like the JavaScript API, iDWR is asynchronous; if you want the return value of the service invocation, you need to pass an object and selector to invoke. The selector will be called with the unmarshaled data. If you don't care about the return value, you can pass nil for either the selector or the object.

# License

iDWR is licensed using the BSD license.

# Upcoming Work

I'm not thrilled with the way the response values are queued in JavaScript, so I will be doing some work there. I think the current implementation has issues with simultaneous calls that come back in different order.

## Missing DWR Features

I don't have an application that uses Reverse Ajax, so there's work to do to support that.

