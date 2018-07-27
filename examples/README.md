# Factory Code Example

## This Example shows how to

* Use the Factory Tools library to determine if we are running in a factory environment.
* Use the Factory Fixture (Purple Box) IR output to bless devices.
* Run a test before blessing.
* Use factory agents to deliver device information from the Device Under Test to an external webhook and also back to the Factory Fixture (Purple Box) to display on the Fixture's LCD display.
* Use the "exit" button to reset the LCD display to welcome message.

## Hardware Used

* Blinkup Fixture:
[Electric Imp's Factory BlinkUp Box](https://store.electricimp.com/collections/featured-products/products/impfactory?variant=31163225426)
* Device Under Test:
[Explorer Kit](https://store.electricimp.com/collections/featured-products/products/impexplorer-developer-kit?variant=31118866130)
  * Imp001 & impExplorer Developer Kit

## SetUp Instructions

These instructions will not go into detail on the Imp manufacturing process. Please look at the documentation on the [Dev Center](https://developer.electricimp.com/manufacturing/factoryguide) for details on manufacturing.

Select your device code: asynchronous or synchronous (synchronous is fine if your factory has a stable wifi connection, otherwise use the asynchronous code). The agent code will work with either device file. Copy and paste the agent and device code into your factory device group.

Enter your WEBHOOK_URL into the constant in the agent code, and enter your WiFi network's SSID and PASSWORD into constants in the device code. For webhook setup see this [example](https://developer.electricimp.com/manufacturing/webhooksexample).

