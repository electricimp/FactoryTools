/**
* Copyright (C) 2015-2018 Electric Imp, Inc
* Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files
* (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge,
* publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do
* so, subject to the following conditions:
* The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
* FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
* WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/**
* FACTORY TOOLS LIBRARY utility for simplifying factory firmware flow.
* @author cat-haines
* @author ersatzavian
* @author Tony Smith <tony@electricimp.com>
* @author Elizabeth Rhodes <betsy@electricimp.com>
*
*/

class FactoryTools {

    static VERSION = "2.2.0";

    /**
    * Checks imp.configparams table for factory firmware flag
    * Params:
    *   callback (optional) : Function with one param - boolean flag if imp is running factory firmware.
    *                         On device called after imp has a chance populate imp.configparams table.
    *                         On Agent called immediately.
    * Returns:
    *   bool (if no callback provided) or null (if callback is provided - bool is passed to callback)
    */
    static function isFactoryFirmware(callback = null) {
        if (callback) {
            if (_isAgent()) {
                callback(_isFFirm());
            } else {
                // Wait for imp.configparams table to populate before checking
                imp.onidle(function() {
                    callback(_isFFirm());
                }.bindenv(this));
            }
        } else {
            return _isFFirm();
        }
    }

    /**
    * Checks that imp is running factory firmware and if the imp is a factory fixture (ie the Purple box)
    * Params:
    *   callback (optional) : Function with one param - boolean flag if imp the Factory Fixture
    *                         On device called after imp has a chance populate imp.configparams table.
    *                         On Agent called immediately.
    * Returns:
    *   bool (if no callback provided) or null (if callback is provided - bool is passed to callback)
    */
    static function isFactoryFixture(callback = null) {
        if (_isAgent()) {
            // Checks that Factory Fixture URL is not in imp.configparams
            local isFixture = (_isFFirm() && !_isDUT());
            if (callback) {
                callback(isFixture);
            } else {
                return isFixture;
            }
        } else {
            // Checks if imp.configparams.factory_imp mac matches this imp's mac address
            if (callback) {
                // Wait for imp.configparams table to populate before checking
                imp.onidle(function() {
                    callback(_isFFirm() && _isFFix());
                }.bindenv(this));
            } else {
                return (_isFFirm() && _isFFix());
            }
        }
    }

    /**
    * Compatibility call. Factory imps are not used in impCentral, so we have deprecated isFactioryImp(),
      but the method is retained for backwards compatibility
    */
    static function isFactoryImp(callback = null) {
        return isFactoryFixture(callback);
    }

    /**
    * Checks that imp is running factory firmware and if the imp is the device under test (ie the product imp)
    * Params:
    *   callback (optional) : Function with one param - boolean flag if imp the Device Under Test
    *                         On device called after imp has a chance populate imp.configparams table.
    *                         On Agent called immediately.
    * Returns:
    *   bool (if no callback provided) or null (if callback is provided - bool is passed to callback)
    */
    static function isDeviceUnderTest(callback = null) {
        if (_isAgent()) {
            // Checks that Factory Fixture URL is in imp.configparams
            local isDUT = (_isFFirm() && _isDUT());
            if (callback) {
                callback(isDUT);
            } else {
                return isDUT;
            }
        } else {
            // Checks if that imp.configparams.factory_imp mac doesn't match this imp's mac address
            if (callback) {
                // Wait for imp.configparams table to populate before checking
                imp.onidle(function() {
                    callback(_isFFirm() && !_isFFix());
                }.bindenv(this));
            } else {
                return (_isFFirm() && !_isFFix());
            }
        }
    }

    /**
    * Factory Device: @return {null}
    * Factory Agent: @return {null | string} - null if not in factory environment, otherwise the Factory Fixture agent URL
    */
    static function getFactoryFixtureURL() {
        if (_isAgent() && isFactoryFirmware()) {
            return (_isDUT()) ? imp.configparams.factory_fixture_url : http.agenturl();
        }

        return null;
    }

    /**
    * Private method
    * @return {bool} - if this is the agent
    */
    function _isAgent() {
        return (imp.environment() == ENVIRONMENT_AGENT);
    }

    /**
    * Private method
    * @return {bool} - if imp.configparams factoryfirmware is true
    */
    function _isFFirm() {
        return ("factoryfirmware" in imp.configparams && imp.configparams["factoryfirmware"]);
    }

    /**
    * Private method - Device only
    * @return {bool} - if imp.configparams factory_imp mac matches device mac
    */
    function _isFFix() {
        return ("factory_imp" in imp.configparams && imp.configparams.factory_imp == _getMacAddr());
    }

    /**
    * Private method - Agent only
    * @return {bool} - if factory_fixture_url is in imp.configparams
    */
    function _isDUT() {
        return ("factory_fixture_url" in imp.configparams);
    }

    /**
    * Private method - Device only
    * @return {string} - the mac address of the imp
    */
    function _getMacAddr() {
        // NOTE: The mac address used to identify the Factory Fixture
        // is the WiFi mac address for that imp. For all WiFi imps
        // except the imp001 the device address is based off the mac
        // address. For compatibility with cellular and ethernet this
        // method will use the Device ID to infer the mac address. For
        // imp001 the mac address in the imp.net.info will be returned.
        if (imp.info().type != "imp001") {
            local devID = hardware.getdeviceid();
            return devID.slice(4);
        } else {
            local interfaces = imp.net.info().interface;
            foreach (interface in interfaces) {
                if (interface.type == "wifi") {
                    return interface.macaddress;
                }
            }
        }
    }
}
