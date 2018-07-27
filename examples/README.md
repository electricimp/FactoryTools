# Factory Code Example ##

## This Example shows how to ##

* Use the Factory Tools library to determine if we are running in a factory environment.
* Use the BlinkUp fixture (impFactory™) IR output to configure device under test (DUT).
* Run a test on DUT before blessing.
* Use agent to deliver device information from the DUT to an external webhook and also back to the BlinkUp fixture to display on the fixture's LCD display.
* Use the **Exit** button to reset the LCD display to welcome message.

## Hardware Used ##

* Blinkup Fixture:
[Electric Imp's impFactory](https://store.electricimp.com/collections/featured-products/products/impfactory?variant=31163225426)
* Device Under Test:
[Explorer Kit](https://store.electricimp.com/collections/featured-products/products/impexplorer-developer-kit?variant=31118866130)
  * imp001 & impExplorer™ Developer Kit

## Setup Instructions ##

These instructions will not go into detail on the Electric Imp Connected Factory Process. Please look at the documentation on the [Dev Center](https://developer.electricimp.com/manufacturing/factoryguide) for details on manufacturing.

Select your device code: asynchronous or synchronous (synchronous is fine if your factory has a stable WiFi connection, otherwise use the asynchronous code. The agent code will work with either device file. Copy and paste the agent and device code into your Factory Test Device Group.

Enter your webhook URL into the constant provided in the agent code, and enter your WiFi network's SSID and password into the constants provided in the device code. For webhook setup see this [example](https://developer.electricimp.com/manufacturing/webhooksexample).

