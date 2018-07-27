// Factory Fixture Display Driver
#require "CFAx33KL.class.nut:1.0.1"
// Factory Tools Utility Library
#require "FactoryTools.lib.nut:2.2.0"
// LED Driver
#require "HTS221.device.lib.nut:2.0.1"



// SHARED DEVICE SETUP
// ---------------------------------------

// Factory WiFi Network Info
const SSID = "<FACTORY NETWORK NAME>";
const PASSWORD = "<FACTORY NETWORK PASSWORD>";

// DEVICE CLASSES
// ---------------------------------------

// FACTORY FIXTURE CLASS
// Hardware: Electric Imp's Factory BlinUp Box (https://electricimp.com/docs/manufacturing/factoryblinkupbox/)
class BootFactoryFixture {
    // Note: All global variables are shared between
    // DUT and the Fixture, so all hardware configuration
    // must happen in the class.

    //max length of 16 char
    static FIXTURE_BANNER = "FactoryExample";

    // How long to wait (seconds) after triggering BlinkUp before allowing another
    static BLINKUP_TIME = 10;

    // Class variables
    fixture = null;
    lcd = null;

    // Flag used to prevent new BlinkUp triggers while BlinkUp is running
    sendingBlinkUp = null;


    constructor() {
        imp.enableblinkup(true);

        // Factory Fixture 005 HAL
        fixture = {
            "LED_RED"          : hardware.pinF,
            "LED_GREEN"        : hardware.pinE,
            "BLINKUP_PIN"      : hardware.pinM,
            "GREEN_BTN"        : hardware.pinC,
            "FOOTSWITCH"       : hardware.pinH,
            "LCD_DISPLAY_UART" : hardware.uart2,
            "USB_PWR_EN"       : hardware.pinR,
            "USB_FAULT_L"      : hardware.pinW,
            "RS232_UART"       : hardware.uart0,
            "FTDI_UART"        : hardware.uart1,
        }

        // Initialize front panel LEDs to Off
        configureLEDs();

        // Intiate factory BlinkUp on either a front-panel button press or footswitch press
        configureBlinkUpTrigger(fixture.GREEN_BTN);
        configureBlinkUpTrigger(fixture.FOOTSWITCH);

        // Configure display
        configureDisplay();

        // agent handler for displaying DUT info
        agent.on("DutDevInfo", displayDutInfo.bindenv(this));
    }

    function configureDisplay() {
        lcd = CFAx33KL(fixture.LCD_DISPLAY_UART);
        setDefaultDisplay();

        lcd.setBrightness(100);
        lcd.storeCurrentStateAsBootState();
        configureLCDResetKey();
    }

    function configureLCDResetKey() {
        lcd.onKeyEvent(function(event) {
            if (event == lcd.KEY_EXIT_PRESS) {
                setDefaultDisplay();
            }
        }.bindenv(this));
    }

    function configureLEDs() {
        // Initialize front panel LEDs to Off
        fixture.LED_RED.configure(DIGITAL_OUT, 0);
        fixture.LED_GREEN.configure(DIGITAL_OUT, 0);
    }

    function configureBlinkUpTrigger(pin) {
        pin.configure(DIGITAL_IN, createBlinkUpTriggerCB(pin));
    }

    // Return a Blinkup callback for pin
    function createBlinkUpTriggerCB(pin) {
        return function() {
            local status = pin.read();

            // Toggle green LED with button press
            if(status) {
                STATUS_GRN_PIN.write(0);
                return;
            }

            // Send BlinkUp
            if (status && !sendingBlinkUp) {
                STATUS_GRN_PIN.write(1);
                sendBlinkUp();
            }
        }.bindenv(this);
    }

    function sendBlinkUp() {
        // Limit time between blinkup triggers
        sendingBlinkUp = true;
        // Reset Blinkup flag after timeout
        imp.wakeup(BLINKUP_TIME, function() {
            sendingBlinkUp = false;
        }.bindenv(this));

        // Update display
        server.log("Sending BlinkUp");
        setDisplay("Sending BlinkUp");

        // Create a testResult report
        local testResult = {
            "deviceInfo" : {
                "deviceId" : hardware.getdeviceid(),
            },
            "ts"  : time(),
            "msg" : "Starting factory blinkup."
        };

        // Send factory BlinkUp
        server.factoryblinkup(SSID, PASSWORD, fixture.BLINKUP_PIN, BLINKUP_FAST | BLINKUP_ACTIVEHIGH);
        agent.send("testresult", testResult);
    }

    function setDefaultDisplay() {
        setDisplay(FIXTURE_BANNER);
    }

    function setDisplay(line2) {
        lcd.clearAll();
        lcd.setLine1("Electric Imp");
        lcd.setLine2(line2);
    }

    function displayDutInfo(results) {
        lcd.clearAll();
        if ("deviceInfo" in results && "deviceId" in results.deviceInfo) {
            lcd.setLine1(results.deviceInfo.deviceId);
        }
        if ("success" in results) {
            lcd.setLine2("Passed = " + results.success);
        } else {
            lcd.setLine2("No results");
            server.log("No test results in data.");
        }
        server.log("Device Blessing Complete");
    }

}

// DEVICE UNDER TEST CLASS
// Hardware: Explorer Kit
class BootDeviceUnderTest {
    // Note: All global variables are shared between
    // DUT and the Fixture, so all hardware configuration
    // must happen in the class.

    exKit = null;

    tempHumid  = null;
    testsPassing = null;

    constructor() {
        testsPassing = false;

        // ExplorerKit_001 HAL
        exKit = {
            "LED_SPI" : hardware.spi257,
            "SENSOR_AND_GROVE_I2C" : hardware.i2c89,
            "TEMP_HUMID_I2C_ADDR" : 0xBE,
            "ACCEL_I2C_ADDR" : 0x32,
            "PRESSURE_I2C_ADDR" : 0xB8,
            "POWER_GATE_AND_WAKE_PIN" : hardware.pin1,
            "AD_GROVE1_DATA1" : hardware.pin2,
            "AD_GROVE2_DATA1" : hardware.pin5
        }

        configureSensor();
        runTests();
        blessDeviceUnderTest();
    }

    function configureSensor() {
        exKit.SENSOR_AND_GROVE_I2C.configure(CLOCK_SPEED_400_KHZ);

        tempHumid = HTS221(exKit.SENSOR_AND_GROVE_I2C, exKit.TEMP_HUMID_I2C_ADDR);
        tempHumid.setMode(HTS221_MODE.ONE_SHOT);
    }

    function runTests() {
        // Run tests and set testPassing flag with results
        testsPassing = (test1() && test2());
    }

    function test1() {
        // Test that sensor has expected id
        // Return true if test passes, false if it doesn't
        return (tempHumid.getDeviceID() == 0xBC);
    }

    function test2() {
        // Test that temp is in range
        local low  = 15;
        local high = 40;
        local temp = tempHumid.read().temperature;
        // Return true if temp is in range, false if not in range
        return (temp > low && temp < high);
    }

    function blessDeviceUnderTest() {
        // Attempt to bless this device, and send the result to the Factory Test Results Webhook
        server.bless(testsPassing, function(blessSuccess) {

            if (blessSuccess) {
              imp.clearconfiguration();
            }

            local testResult = {
                "deviceInfo" : {
                    "device_id" : hardware.getdeviceid()
                },
                "ts" : time(),
                "success" : blessSuccess
            };

            server.log("Blessing " + (blessSuccess ? "PASSED" : "FAILED") + " for device " + deviceInfo.device_id);
            agent.send("testresult", testResult);
        });
    }
}



// RUNTIME CODE
// ---------------------------------------
// Force a connction to the server with a log message.
// This will ensure the imp.configparams table is populated, so we
// can use the Factory Tools library synchronously.
server.log("DEVICE STARTED...");

// Check that we are in the factory
if (FactoryTools.isFactoryFirmware()) {
    server.log("This device is running factory firmware");

    // Run Class Code for Specified Device
    if (FactoryTools.isFactoryFixture()) {
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