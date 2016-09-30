# Factory Tools Library

These utilities are provided to simplify building and maintaining factory firmware.

## Usage

Simply `#require` this library on either your device or agent side code in order to gain access to the methods listed below. Methods are namespaced to "FactoryTools".

```Squirrel
#require "FactoryTools.class.nut:2.0.1"
```

**Note** FactoryTools currently sets the imp’s [timeout policy](https://electricimp.com/docs/api/server/setsendtimeoutpolicy/) to *SUSPEND_ON_ERROR*. If your application requires the *RETURN_ON_ERROR*, you must set this in your code **after** the first call to a FactoryTools method.

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
