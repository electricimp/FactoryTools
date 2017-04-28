// MIT License

// Copyright 2016 Electric Imp

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

// Factory Fixture Display Driver
#require "CFAx33KL.class.nut:1.0.1"
// Factory Tools Utility Library
#require "FactoryTools.device.lib.nut:3.0.0"
// LED Driver
#require "WS2812.class.nut:2.0.1"



// SHARED DEVICE SETUP
// ---------------------------------------

// Factory WiFi Network Info
const SSID = "<FACTORY NETWORK NAME>";
const PASSWORD = "<FACTORY NETWORK PASSWORD>";
const MODEL = "FactoryExample" //max length of 16 char



// DEVICE CLASSES
// ---------------------------------------

// FACTORY FIXTURE CLASS

// Hardware: Electric Imp's impFactory BlinkUp Box (https://electricimp.com/docs/manufacturing/impfactory/)
class BootFactoryFixture {
    // class variables (share a global name space with DUT so all values set within class)
    STATUS_RED_PIN = null;
    STATUS_GRN_PIN = null;
    BLINKUP_PIN = null;
    BLINKUP_BTN_PIN = null;
    FOOTSWITCH_PIN = null;
    LCD = null;
    THROTTLE_TIME = null;

    buttonPressed = null;
    throttle_protection = null;

    constructor() {
        THROTTLE_TIME = 10;
        buttonPressed = false;

        configureLCD();
        configureLEDs();
        configureBlinkupPins();

        configureBlinkUpTrigger(BLINKUP_BTN_PIN);

        // agent handler for displaying DUT info
        agent.on("DUT_devInfo", displayDUTInfo.bindenv(this));
    }

    function configureLCD() {
        LCD = CFAx33KL(hardware.uart2);
        showDefaultLCD();
        LCD.storeCurrentStateAsBootState();
        LCD.setBrightness(100);
        configureLCDResetKey();
    }

    function configureLCDResetKey() {
        LCD.onKeyEvent(function(event) {
            if (event == LCD.KEY_EXIT_PRESS) {
                showDefaultLCD();
            }
        }.bindenv(this));
    }

    function showDefaultLCD() {
        LCD.clearAll();
        LCD.setLine1("Electric Imp");
        LCD.setLine2("BlinkUp Fixture");
    }

    function configureLEDs() {
        STATUS_RED_PIN = hardware.pinF;
        STATUS_GRN_PIN = hardware.pinE;
        BLINKUP_PIN = hardware.pinM;

        STATUS_RED_PIN.configure(DIGITAL_OUT);
        STATUS_RED_PIN.write(0);

        STATUS_GRN_PIN.configure(DIGITAL_OUT);
        STATUS_GRN_PIN.write(1);

        BLINKUP_PIN.configure(DIGITAL_OUT);
        BLINKUP_PIN.write(1);
    }

    function configureBlinkupPins() {
        BLINKUP_BTN_PIN = hardware.pinC;
        FOOTSWITCH_PIN = hardware.pinH;
    }

    function configureBlinkUpTrigger(pin) {
        pin.configure(DIGITAL_IN, function() {
            blinkupCallback(pin);
        }.bindenv(this));
    }

    function blinkupCallback(pin) {
        local status = pin.read();
        // button released
        if(status) {
            STATUS_GRN_PIN.write(0);
            buttonPressed = true;
            return;
        }
        // button pressed
        if(!status && buttonPressed) {
            buttonPressed == false;
            sendBlinkUp();
            STATUS_GRN_PIN.write(1);
        }
    }

    function sendBlinkUp() {
      // make sure we only send blinkup once per unit
      if(throttle_protection) { return; }
      throttle_protection = true;

      // reset rate limit after receiving communicaiton back from agent??
      imp.wakeup(THROTTLE_TIME, (function() { throttle_protection = false; }).bindenv(this));

      server.log("Sending BlinkUp");
      LCD.setLine1("Sending BlinkUp");
      LCD.setLine2(MODEL);

      local deviceInfo = {"device_id" : hardware.getdeviceid(), "mac" : imp.getmacaddress()};

      imp.wakeup(0.5, function() {
        server.factoryblinkup(SSID, PASSWORD, BLINKUP_PIN, BLINKUP_FAST);
        agent.send("testresult", {"deviceInfo" : deviceInfo, "ts": time(), "msg" : "Starting factory blinkup."});
      }.bindenv(this))
    }

    function displayDUTInfo(deviceInfo) {
        LCD.clearAll();
        if ("success" in deviceInfo) {
            LCD.setLine1("Blessing Result:");
            LCD.setLine2("Passed = " + deviceInfo.success);
        } else if ("device_id" in deviceInfo && "mac" in deviceInfo) {
            LCD.setLine1(deviceInfo.device_id);
            LCD.setLine2("Mac " + deviceInfo.mac);
        } else {
            LCD.setLine1("Device Blessed");
        }
        server.log("Device Blessing Complete");
    }

}

// DEVICE UNDER TEST CLASS
// Hardware: LED Tail
class BootDeviceUnderTest {
    // class variables (share a global name space with Factory Fixture so all values set within class)
    leds = null;
    tests_pass = null;

    constructor() {
        tests_pass = false;
        configureLEDs();
        testLEDs();
        blessDeviceUnderTest();
    }

    function configureLEDs() {
        hardware.spi257.configure(MSB_FIRST, 7500);
        leds = WS2812(hardware.spi257, 5);
    }

    function testLEDs() {
        blink(); // Run actual test here
        tests_pass = true;
    }

    function blink() {
        local red = [25, 0, 0];
        local off = [0, 0, 0]

        leds.fill(red).draw();
        imp.sleep(1);
        leds.fill(off).draw();
        imp.sleep(0.5);
        leds.fill(red).draw();
        imp.sleep(1);
        leds.fill(off).draw();
        imp.sleep(0.5);
        leds.fill(red).draw();
        imp.sleep(1);
        leds.fill(off).draw();
    }

    function blessDeviceUnderTest() {
        // attempt to bless this device, and send the result to the Factory Test Results Webhook
        server.bless(tests_pass, function(bless_success) {

            if (bless_success) {
              imp.clearconfiguration();
            }

            local deviceInfo = {"device_id" : hardware.getdeviceid(), "mac" : imp.getmacaddress()};

            server.log("Blessing " + (bless_success ? "PASSED" : "FAILED") + " for device " + deviceInfo.device_id + " and mac " + deviceInfo.mac);
            agent.send("testresult", {"deviceInfo" : deviceInfo, "ts": time(), "success" : bless_success});
        });
    }
}



// RUNTIME CODE
// ---------------------------------------
server.log("DEVICE STARTED");

// Check that we are in the factory
if (FactoryTools.isFactoryFirmware()) {
    server.log("This device is running factory firmware");

    // Run Class Code for Specified Device
    if (FactoryTools.isFactoryImp()) {
        server.log("This device is a BlinkUp fixture");
        BootFactoryFixture();
    }

    if (FactoryTools.isDeviceUnderTest()) {
        server.log("This device is a production unit");
        BootDeviceUnderTest();
    }

} else {
    server.log("This firmware is not running in the Factory Environment");
}