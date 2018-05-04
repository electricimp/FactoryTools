# Factory Tools Library #

These utilities are provided to simplify building and maintaining factory firmware.

## Usage ##

Simply `#require` this library on either your device or agent side code in order to gain access to the methods listed below. Methods are namespaced to "FactoryTools".

```Squirrel
#require "FactoryTools.class.nut:2.1.1"
```

### Waking Devices Under Test From Deep Sleep ###

If your factory firmware puts production devices under test (DUT) into deep sleep, when the devices awake (ie. perform a warm start) they will immediately begin re-running the factory firmware. This is standard imp wake-from-sleep behavior. Unfortunately, this also means that you factory firmware may call the Factory Tools methods before the device has received the information from the server it needs to be able to return valid data via the Factory Tools methods. The factory firmware will erroneously believe that it is not running in a factory environment.

To avoid this issue, you should make use of Factory Tools 2.1.1’s new support for asynchronous operation. The methods *isFactoryFirmware()*, *isFactoryImp()* and *isDeviceUnderTest()* can now take an optional callback function with a single parameter, *result*, into which the boolean answer is placed. For example, a callback registered with *isFactoryImp()* will receive `true` if the device is a factory imp, or `false` if it is a device under test.

In each case, embed your factory imp set-up flow and DUT test flow within the callbacks to ensure these flows are actioned correctly. An example is given in the method descriptions below. It also demonstrated in the accompanying example, `Async.factory.device.nut`.

You only need employ asynchronous operation on **the first call** to one of Factory Tools’ methods. Once the first callback has been executed, you can be sure the status information is present, and all other calls can be made synchronously without penalty.

**Important Note** Factory devices may warm-start outside of factory firmware control as outlined above. If fresh factory firmware is deployed during production, devices will receive the new code and automatically restart to run the new code. We strongly recommend all users of Factory Tools take advantage of the asynchronous methods to manage this situation.

Asynchronous functionality does not impact synchronous operation, so existing code can continue to make use of the library without requiring updates.

## Release Notes ##

- 2.1.1
    - Switch to non-deprecated imp API methods (imp.net.info())

## Methods ##

### isFactoryFirmware(*[callback]*) ###

Supported on the device and agent.

If no callback is provided, the method returns `true` if firmware is running in the factory environment, `false` otherwise. Both factory BlinkUp&trade; fixtures and production devices under test (configured via factory BlinkUp from a factory BlinkUp fixture) will return `true`.

```Squirrel
if (FactoryTools.isFactoryFirmware()) {
    // Running in the Factory Environment
} else {
    server.log("This firmware is not running in the Factory Environment");
}
```

If a callback is provided, the function will be called when the device has received the required status information. The callback takes a single parameter, *result*, which will be `true` if firmware is running in the factory environment, otherwise `false`.

The callback can also be used in your factory agent; it will simply be invoked immediately.

### isFactoryImp(*[callback]*) ###

Supported on the device and agent. This method is intended to make it easy to determine whether to follow the *factory fixture flow* or *device under test flow* in your factory firmware.

If no callback is provided, this method returns `true` if the imp is designated as a factory BlinkUp fixture, `false` otherwise.

If a callback is provided, the function will be called when the device has received the required status information and is able to verify the host device’s type. The callback takes a single parameter, *result*, which will be `true` if the device is a factory imp, otherwise `false`.

The callback can also be used in your factory agent; it will simply be invoked immediately.

```squirrel
FactoryTools.isFactoryImp(function(isBlinkUpBox) {
    if (isBlinkUpBox) {
        // Device is a factory imp
        configureFactoryImp();
    } else {
        // The next call need not be asynchronous since we can be sure
        // at this point (we're executing in a callback) that the status
        // data has been acquired
        if (FactoryTools.isDeviceUnderTest()) {
            // Device is a production unit - test it
            testDeviceUnderTest();
        } else {
            server.log("Not running in Factory Environment");
        }
    }
});
```

### isDeviceUnderTest(*[callback]*) ###

Supported on the device and agent. This method is intended to make it easy to determine whether to follow the *factory fixture flow* or *device under test flow* in your factory firmware.

If no callback is provided, this method returns `true` if the imp is not configured as the factory BlinkUp fixture, `false` otherwise.

If a callback is provided, the function will be called when the device has received the required status information and is able to verify the host device’s type. The callback takes a single parameter, *result*, which will be `true` if the unit is a device under test, otherwise `false`.

The callback can also be used in your factory agent; it will simply be invoked immediately.

```squirrel
FactoryTools.isFactoryImp(function(isBlinkUpBox) {
    if (isBlinkUpBox) {
        // Device is a factory imp - configure it
        configureFactoryImp();
    } else {
        if (FactoryTools.isDeviceUnderTest()) {
            // Device is a production unit - test it
            testDeviceUnderTest();
        } else {
            server.log("Not running in Factory Environment");
        }
    }
});
```

### getFactoryFixtureURL() ###

Supported on the agent *only*. If called on the device this method will return `null`.

If the firmware is running as within the factory environment as an agent, this method returns the factory BlinkUp fixture’s agent URL. It returns `null` otherwise. You can use this agent URL to send information about the device under test to the factory BlinkUp fixture using an HTTP request. There is no asynchronous operation option.

```Squirrel
device.on("testresult", function(result) {
    local fixtureAgentURL = FactoryTools.getFactoryFixtureURL();

    if (FactoryTools.isDeviceUnderTest() && fixtureAgentURL) {
        local headers = {"Content-Type" : "application/json"};
        local body = http.jsonencode(result.deviceInfo);
        local request = http.post(fixtureAgentURL, headers, body);
        local response = request.sendsync();

        if (response.statuscode != 200) {
            server.error("Problem contacting Factory Fixture.");
        } else {
            server.log("Factory Fixture confirmed receipt of device info.");
        }
    }
});
```

## License ##

The Factory Tools library is licensed under the [MIT License](./LICENSE).
