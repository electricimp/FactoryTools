#require "FactoryTools.device.nut:2.1.0"
#require "Button.class.nut:1.2.0"

// Set up WiFi disconnection response policy right at the start
server.setsendtimeoutpolicy(RETURN_ON_ERROR, WAIT_TIL_SENT, 10);

// CONSTANTS

const SSID = "<YOUR_FACTORY_WIFI_SSID>";
const PASSWORD = "<YOUR_FACTORY_WIFI_PASSWORD>";
const BLINKUP_INTERVAL_SECONDS = 10;

// GLOBALS

local blinkupLED = null;
local blinkupButton = null;

// FACTORY FIXTURE FUNCTIONS

function fixture() {
    server.log("Configuring Fixture");
    blinkupLED = hardware.pin9;
    blinkupLED.configure(DIGITAL_OUT, 0);
    blinkupButton = Button(hardware.pin8, DIGITAL_IN_PULLUP, 1, null, sendFactoryBlinkUp);
}

function sendFactoryBlinkUp() {
    server.log("Transmitting Factory BlinkUp");
    server.factoryblinkup(SSID, PASSWORD, blinkupLED, BLINKUP_ACTIVEHIGH);
}

// PRODUCTION DEVICE FUNCTIONS

function pdevice() {
    // About to bless a device
    local devId = hardware.getdeviceid();
    local devMac = imp.getmacaddress();
    local message = format("Blessing device %s", devId);
    agent.send("testresult", {"device_id" : devId, "mac" : devMac, "msg" : message});

    // Initiate bless
    server.bless(true, function(blessSuccess) {
        if (blessSuccess) {
            imp.clearconfiguration();
            message = format("Device %s blessed successfully", devId);
        } else {
            message = format("Device %s blessing failed", devId);
        }
        server.log("Blessing " + (blessSuccess ? "PASSED" : "FAILED"));
        agent.send("testresult", {"device_id" : devId, "mac" : devMac, "msg" : message});
    });
}

// START

// Don't run the factory code if not in the factory
if (imp.getssid() != SSID) {
    server.log("Not running in Factory Environment");
    return;
}

// Select the appropriate code path

FactoryTools.onFactoryImp(function(isBlinkUpBox) {
    if (isBlinkUpBox) {
        fixture();
    } else {
        FactoryTools.onDeviceUnderTest(function(isDUT) {
            if (isDUT) {
                pdevice();
            } else {
                server.log("Not running in Factory Environment");
            }
        });
    }
});
