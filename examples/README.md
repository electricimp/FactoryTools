#Factory Fixture with Factory Agent Example

##This Example shows how to
* Use the Factory Tools library to determine if we are running in a factory environment.

* Use the Factory fixture ir output to bless devices.

* Run a test before blessing.

* Use factory agents to deliver device information from the Device Under Test to an external webhook and also back to the Factory Fixture to display on the Fixture's LCD.

* Use the "exit" button to reset the LCD display to welcome message.

##Hardware Used
* Blinkup Fixture:
[Electric Imp's Factory BlinUp Box](https://electricimp.com/docs/manufacturing/factoryblinkupbox/)

* Device Under Test:
[Developer Kit](http://www.amazon.com/WiFi-Environmental-Sensor-LED-kit/dp/B00ZQ4D1TM/)
  * Imp001 & April breakout board
  * [RGB LED Tail](https://electricimp.com/docs/tails/ws2812/)