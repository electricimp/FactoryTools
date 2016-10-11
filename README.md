# Factory Tools Library

These utilities are provided to simplify building and maintaining factory firmware.

## Usage

Simply `#require` this library on either your device or agent side code in order to gain access to the methods listed below. Methods are namespaced to "FactoryTools".

```Squirrel
#require "FactoryTools.class.nut:2.1.0"
```

### Waking Devices Under Test From Deep Sleep

If your factory firmware puts production devices under test into deep sleep, when the devices awake (ie. perform a warm start) they will immediately begin re-running the factory firmware. This is standard imp wake-from-sleep behavior. Unfortunately, this also means that you factory firmware may call the Factory Tools methods before the device has received the information from the server it needs to be able to return valid data via the Factory Tools methods. The factory firmware will erroneously believe that it is not running in a factory environment.

To avoid this issue, you should make use of Factory Tools 2.1.0’s new asynchronous methods: *onFactoryImp()* and *onDeviceUnderTest()*. These register a callback function with a single parameter, *result*, into which the answer to question posed by the synchronous version of the method is placed. For example, the callback registered with *onFactoryImp()* will receive `true` if the device is a factory imp, or `false` if it is a device under test.

In each case, embed your factor imp set-up flow and DUT test flow within the callbacks to ensure these flows are actioned correctly. An example is given in the method descriptions below. It also demonstrated in the accompanying example, `Async.factory.device.nut`.

**Important Note** Factory devices may warm-start outside of factory firmware control as outlined above. If fresh factory firmware is deployed during production, devices will receive the new code and automatically restart to run the new code. We strongly recommend all users of Factory Tools take advantage of the asynchronous methods to manage this situation.

## Methods

### isFactoryFirmware()

Supported on the device and agent.

Returns `true` if firmware is running in the factory environment, `false` otherwise. Please note both factory BlinkUp fixtures and devices under test (configured via factory BlinkUp from a factory BlinkUp fixture) will return `true`.

```Squirrel
if (FactoryTools.isFactoryFirmware()) {
    // Running in the Factory Environment
} else {
    server.log("This firmware is not running in the Factory Environment");
}
```

### isFactoryImp()

Supported on the device and agent.

Returns `true` if the imp is designated as a factory BlinkUp fixture, `false` otherwise. This method is intended to make it easy to determine whether to follow the *factory fixture flow* or *device under test flow* in your factory firmware.

### onFactoryImp(*callback*)

This method registers a function which will be called when the device has received the required status information and is able to verify the host device’s type. The callback takes a single parameter, *result*, which will be `true` if the device is a factory imp, otherwise `false`.

This method can also be used in your factory agent; the callback will simply be invoked immediately.

```squirrel
FactoryTools.onFactoryImp(function(isBlinkUpBox) {
    if (isBlinkUpBox) {
        // Device is a factory imp
        configureFactoryImp();
    } else {
        FactoryTools.onDeviceUnderTest(function(isDUT) {
            if (isDUT) {
                // Device is a production unit - test it
                testDeviceUnderTest();
            } else {
                server.log("Not running in Factory Environment");
            }
        });
    }
});
```

### isDeviceUnderTest()

Supported on the device and agent.

Returns `true` if the imp is not configured as the factory BlinkUp fixture, `false` otherwise. This method is intended to make it easy to determine whether to follow the *factory fixture flow* or *device under test flow* in your factory firmware.

```Squirrel
if (FactoryTools.isFactoryImp()) {
  configureFactoryImp();
} else if (FactoryTools.isDeviceUnderTest()) {
  configureDeviceUnderTest();
} else {
  server.log("Not running in Factory Environment");
}
```

### onDeviceUnderTest(*callback*)

This method registers a function which will be called when the device has received the required status information and is able to verify the host device’s type. The callback takes a single parameter, *result*, which will be `true` if the unit is a device under test, otherwise `false`.

This method can also be used in your factory agent; the callback will simply be invoked immediately.

```squirrel
FactoryTools.onFactoryImp(function(isBlinkUpBox) {
    if (isBlinkUpBox) {
        // Device is a factory imp - configure it
        configureFactoryImp();
    } else {
        FactoryTools.onDeviceUnderTest(function(isDUT) {
            if (isDUT) {
                // Device is a production unit - test it
                testDeviceUnderTest();
            } else {
                server.log("Not running in Factory Environment");
            }
        });
    }
});
```

### getFactoryFixtureURL()

Supported on the agent *only*. If called on the device this method will return `null`.

If the firmware is running as within the factory environment as an agent, this method returns the factory BlinkUp fixture’s agent URL. It returns `null` otherwise. You can use this agent URL to send information about the device under test to the factory BlinkUp fixture using an HTTP request.

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

## License

The Factory Tools library is licensed under the [MIT License](./LICENSE).
