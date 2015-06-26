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

// Sample application: Factory blinkup fixture
// This example code is for blessing devices in a factory using a factory blinkup fixture.
// For this example:
// - Every 10 seconds the factory blinkup fixture will start the blinkup procedure automatically.
// - The target device will automatically and immediately be blessed as soon as it runs this code
// - The status LED on the target device (not the factory BlinkUp fixure) will turn solid green 
//   indicating pass/bless or turn solid red indicating fail/no blessing
// - Any configured webhooks will then be notified of the blessing event and take further actions

#require "FactoryTools.device.nut:1.0.0"

// CONSTS AND GLOBALS ---------------------------------------------------------

const SSID = "YOUR_FACTORY_SSID";
const PASSWORD = "YOUR_FACTORY_WIFI_PASSWORD";
const BLINKUP_INTERVAL_SECONDS = 10;

// FACTORY FIXTURE FUNCTIONS AND CLASSES --------------------------------------

function sendFactoryBlinkUp() {
    imp.wakeup(BLINKUP_INTERVAL_SECONDS, sendFactoryBlinkUp);
    // Use the BLINKUP_ACTIVEHIGH flag if the LED turns on when the LED pin is driven high
    // Otherwise, Active-Low is assumed (LED on when LED pin is driven low)
    server.factoryblinkup(SSID, PASSWORD, led, 0);
}

function configureFactoryFixture() {
    // You can create global variables for hardware objects using getroottable
    // This example assumes the basic Electric Imp Factory Fixture design
    local globalscope = getroottable();
    globalscope.btn <- hardware.pin8;
    globalscope.led <- hardware.pin9;

    led.configure(DIGITAL_OUT, 0);
    sendFactoryBlinkUp();
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

// RUNTIME --------------------------------------------------------------------

if (FactoryTools.isFactoryImp()) {
    configureFactoryFixture();
} else if (FactoryTools.isDeviceUnderTest()) {
    blessDeviceUnderTest();
} else {
    server.log("This firmware is not running in the factory environment");
}