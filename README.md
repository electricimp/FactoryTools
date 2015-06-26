# Factory Tools Library

These utilities are provided to simplify building and maintaining factory firmware. 

## Usage

Simple require this library in order to gain access to the methods listed below. Methods are namespaced to "FactoryTools".

```Squirrel
#require "FactoryTools.device.nut:1.0.0"
```

## Methods

#### *bool* isFactoryFirmware(*none*)
Returns true if this firmware is running in the factory environment, false otherwise. Factory fixtures and Devices Under Test (configured via Factory BlinkUp from a Factory Fixture) will both receive "true" from this method.

```Squirrel
if (FactoryTools.isFactoryFirmware()) {
    // Running in the Factory Environment
} else {
    server.log("This firmware is not running in the Factory Environment");
}
```

#### *bool* isFactoryImp(*none*)
Returns true if this device is designated as a Factory Imp, false otherwise. This method is intended to make it easy to determine whether to follow the Factory Fixture flow or Device Under Test flow in your Factory Firmware.

```Squirrel
if (FactoryTools.isFactoryImp()) {
	configureFactoryImp();
} else if (FactoryTools.isDeviceUnderTest()) { 
	configureDeviceUnderTest();
} else {
	server.log("Not running in Factory Environment");
}
```

#### *bool* isDeviceUnderTest(*none*) 
Returns true if this device is running Factory Firmware, but is not configured as the Factory Imp. Returns false otherwise. 

## License

The Factory Tools library is licensed under the [MIT License](./LICENSE).
