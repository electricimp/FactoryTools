# Factory Tools Library

These utilities are provided to simplify building and maintaining factory firmware.

## Usage

Simply require this library on both your device and agent side code in order to gain access to the methods listed below. Methods are namespaced to "FactoryTools".

```Squirrel
#require "FactoryTools.device.nut:1.1.1"
```

## Methods

#### isFactoryFirmware()
Supported on the Device *only*.  If called on the Agent this method will return `null`.

On the Device this method returns `true` if firmware is running in the factory environment, `false` otherwise. Please note both Factory fixtures and Devices Under Test (configured via Factory BlinkUp from a Factory Fixture) will return `true`.

```Squirrel
if (FactoryTools.isFactoryFirmware()) {
    // Running in the Factory Environment
} else {
    server.log("This firmware is not running in the Factory Environment");
}
```

#### isFactoryImp()
Supported on *both* Device and Agent.

Returns `true` if imp is designated as a Factory fixture, `false` otherwise. This method is intended to make it easy to determine whether to follow the *Factory Fixture flow* or *Device Under Test flow* in your Factory Firmware.

#### isDeviceUnderTest()
Supported on *both* Device and Agent.

Returns `true` if imp is not configured as the Factory fixture, `false` otherwise.  This method is intended to make it easy to determine whether to follow the *Factory Fixture flow* or *Device Under Test flow* in your Factory Firmware.

```Squirrel
if (FactoryTools.isFactoryImp()) {
  configureFactoryImp();
} else if (FactoryTools.isDeviceUnderTest()) {
  configureDeviceUnderTest();
} else {
  server.log("Not running in Factory Environment");
}
```

#### getFactoryFixtureURL()
Supported on the Agent *only*.  If called on the Device this method will return `null`.

On the Agent of the *Device Under Test* this method returns the Factory Fixture's agent URL.  Returns `null` otherwise.  You can use the Factory Fixture's agent URL to send information about the Device Under Test to the Factory Fixture using an HTTP request.

```Squirrel
device.on("testresult", function(result) {
    local fixtureAgentURL = FactoryTools.getFactoryFixtureURL();

    if (fixtureAgentURL == null) {
        server.error("Factory Fixture URL not available.");
    } else {
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
