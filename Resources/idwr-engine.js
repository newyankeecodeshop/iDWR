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
/*
 * idwr-engine.js
 *
 * This file contains the additions to the DWR engine.js for iDWR.
 */

dwr.ios = {};

dwr.ios.replies = [];

/*
 * The callback for all DWR calls. It will store the JSON encoding of the data, and callback into Obj-C
 * using the UIWebViewDelegate.
 */
dwr.ios.callback = function (data) { 
	
	var index = dwr.ios.replies.push('data:' + JSON.stringify(data));
	
	location.replace('dwr-ios:/replies?' + index); 
};

/*
 * Method to pop a reply off the array and return to iOS code.
 */
dwr.ios.grabReply = function (index) {
	
	var data = dwr.ios.replies[index];
	dwr.ios.replies.splice(index, 1);
	return data;
};

/*
 * Set an error handler that will tell us what went wrong.
 */
dwr.ios.errorHandler = function (message, ex) {
	
	var index = dwr.ios.replies.push('error:' + JSON.stringify(ex));
	
	location.replace('dwr-ios:/replies?' + index); 
};

dwr.engine.setErrorHandler(dwr.ios.errorHandler);

