// Copyright (C) 2015 Electric Imp, Inc
 
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files 
// (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge,
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
 
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
// FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#require "FactoryTools:1.0.0"

// CONSTS AND GLOBALS ---------------------------------------------------------

const SSID = "";
const PASSWORD = "";

// FACTORY FIXTURE FUNCTIONS AND CLASSES --------------------------------------

function sendFactoryBlinkUp() {
    // Use the BLINKUP_ACTIVEHIGH flag if the LED turns on when the LED pin is driven high
    // Otherwise, Active-Low is assumed (LED on when LED pin is driven low)
	server.factoryblinkup(SSID, PASSWORD, led, BLINKUP_ACTIVEHIGH);
}

function configureFactoryFixture() {
    // You can create global variables for hardware objects using getroottable
    // This example assumes the basic Electric Imp Factory Fixture design
	local globalscope = getroottable();
	globalscope.btn <- hardware.pin8;
	globalscope.led <- hardware.pin9;

	btn.configure(DIGITAL_IN_PULLUP, sendFactoryBlinkUp);
	led.configure(DIGITAL_OUT, 0);
}

// DEVICE UNDER TEST FUNCTIONS AND CLASSES ------------------------------------

function blessDeviceUnderTest() {
    // attempt to bless this device, and send the result to the Factory Test Results Webhook
    server.bless(true, function(bless_success) {
        // if blessing succeeds, clear the configuration so the device will be unconfigured on power cycle
        if (bless_success) imp.clearconfiguration();
        // log results (only works in developer environment; no logs for devices on the factory line)
        // this is useful only for developing this factory firmware
        server.log("Blessing " + (bless_success ? "PASSED" : "FAILED")); 
        // send results to the Factory Test Result webhook
        agent.send("testresult", {device_id = deviceid, mac = mac, success = bless_success});
    }); 
}

function runManufacturingTests() {
    // Add your device test code here
    
    // Example: light the LED, then wait for the user to press the button to verify
    userLed.write(1);
    // set a state-change callback to execute when the button is pressed or released
    userButton.configure(DIGITAL_IN, function() {
        // if the button is pressed
        if (userButton.read()) {
            // turn out the LED
            userLed.write(0);
            // bless this device
            blessDeviceUnderTest();
        }
    });
}

function configureDeviceUnderTest() {
    // configure your device under test here
    
    // Example: you can create global variables for hardware objects using getroottable
    local globalscope = getroottable();
    
    // In this example, the device under test has a button on pinA and an LED on PinB
    globalscope.userButton <- hardware.pinA;
    globalscope.userLed <- hardware.pinB;
    
    userButton.configure(DIGITAL_IN);
    userLed.configure(DIGITAL_OUT, 0);
    
    // When everything is configured, you can run your tests
    runManufacturingTests();
}

// RUNTIME --------------------------------------------------------------------

if (FactoryTools.isFactoryFixture()) {
 	configureFactoryFixture();
} else if (FactoryTools.isDeviceUnderTest()) {
	configureDeviceUnderTest();
} else {
    server.log("This firmware is not running in the factory environment");
}
