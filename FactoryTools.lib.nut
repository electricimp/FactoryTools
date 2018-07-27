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
* version 2.2.0
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
        local isFF = ("factoryfirmware" in imp.configparams && imp.configparams["factoryfirmware"]);
        if (callback) {
            if (_isAgent()) {
                callback(isFF);
            } else {
                imp.onidle(function() {
                    imp.onidle(null);
                    callback(isFF);
                }.bindenv(this));
            }
        } else {
            return isFF;
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
    static function isFactoryImp(callback = null) {
        local isFI;
        if (_isAgent()) {
            // Checks that Factory Fixture URL is not in imp.configparams
            isFI = isFactoryFirmware() && !isDeviceUnderTest();
            (callback) ? callback(isFI) : return ifFI;
        } else {
            // Checks if imp.configparams.factory_imp mac matches this imp's mac address
            isFI = (isFactoryFirmware() && "factory_imp" in imp.configparams && imp.configparams.factory_imp == _getMacAddr());
            if (callback) {
                imp.onidle(function() {
                    imp.onidle(null);
                    callback(isFI);
                }.bindenv(this));
            } else {
                return (isFI);
            }
        }
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
        local isDUT;
        if (_isAgent()) {
            // Checks that Factory Fixture URL is in imp.configparams
            isDUT = (isFactoryFirmware() && "factory_fixture_url" in imp.configparams);
            (callback) ? callback(isDUT) : return isDUT;
        } else {
            // Checks if that imp.configparams.factory_imp mac doesn't match this imp's mac address
            isDUT = isFactoryFirmware() && !isFactoryImp();
            if (callback) {
                imp.onidle(function() {
                    imp.onidle(null);
                    callback(isDUT);
                }.bindenv(this));
            } else {
                return (isDUT);
            }
        }
    }

    /**
    * Factory Device: @return {null}
    * Factory Agent: @return {null | string} - if in factory environment the Factory Fixture agent URL is returned, otherwise null
    */
    static function getFactoryFixtureURL() {
        if (_isAgent() && isFactoryFirmware()) {
            return ("factory_fixture_url" in imp.configparams) ? imp.configparams.factory_fixture_url : http.agenturl();
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
    * @return {string} - the mac address of the imp
    */
    function _getMacAddr() {
        // Note: Not all imps have a mac address. Use device Id to
        // get a mac address, unless on an imp001. For imp001 use the
        // imp.net.info table to look up the actual mac address.
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
