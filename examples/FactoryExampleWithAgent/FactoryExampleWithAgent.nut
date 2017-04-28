// MIT License

// Copyright 2017 Electric Imp

// SPDX-License-Identifier: MIT

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

#require "FactoryTools.device.lib.nut:3.0.0"
#require "Button.class.nut:1.2.0"

// HARDWARE
// Factory Fixture: Imp 002 with IR tail
// DUT: Hardware not specific, any imp will work

// CONSTANTS

const SSID = "<YOUR_FACTORY_WIFI_SSID>";
const PASSWORD = "<YOUR_FACTORY_WIFI_PASSWORD>";
const BLINKUP_INTERVAL_SECONDS = 10;

// GLOBALS

local blinkupLED = null;
local blueLED = null;
local blinkupButton = null;

// FACTORY FIXTURE FUNCTIONS

function sendFactoryBlinkUp() {
    server.log("Transmitting Factory BlinkUp");
    server.factoryblinkup(SSID, PASSWORD, blinkupLED, BLINKUP_ACTIVEHIGH);
    blueLED.write(1);
}

function done(deviceData) {
    blueLED.write(0);
    // If a printer is attached add code here
    // to print labels for successful devices
}

function fixture() {
    server.log("Configuring Fixture");
    blinkupLED = hardware.pin8;
    blinkupLED.configure(DIGITAL_OUT, 0);
    blinkupButton = Button(hardware.pin1, DIGITAL_IN_PULLUP, 1, null, sendFactoryBlinkUp);
    blueLED.configure(DIGITAL_OUT, 0);

    // Open listener for messages from agent
    agent.on("DUT_data", done);
}

// PRODUCTION DEVICE FUNCTIONS

function test() {
    // Add tests for production devices here
    local testResults = true;
    // Return test results, so only devices
    // that pass tesing are blessed
    return testResults;
}

function pdevice() {
    server.log("Configuring Device Under Test");
    local testResults = test();
    local devId = hardware.getdeviceid();
    local devMac = imp.getmacaddress();

    server.log("Testing " + (testResults ? "PASSED" : "FAILED"));
    local message = testResults ? format("Device %s passed tests. Blessing device.", devId) : message = format("Device %s failed tests.", devId);

    agent.send("testresult", {"device_id" : devId, "mac" : devMac, "test_result" : testResult, "msg" : message});
    server.bless(testResults, function(blessSuccess) {
        if (blessSuccess) {
            imp.clearconfiguration();
            message = format("Device %s blessed successfully", devId);
        } else {
            message = format("Device %s blessing failed", devId);
        }
        server.log("Blessing " + (blessSuccess ? "PASSED" : "FAILED"));
        agent.send("blessingresult", {"device_id" : devId, "mac" : devMac, "bless_success" : blessSuccess, "msg" : message});
    });
}

// START

// Don't run the factory code if not in the factory
if (FactoryTools.isFactoryFirmware() && imp.getssid() == SSID) {
    // Select the appropriate code path
    if (FactoryTools.isFactoryImp()) fixture();
    if (FactoryTools.isDeviceUnderTest()) pdevice();
} else {
    server.log("Not running in Factory Environment");
}