// MIT License

// Copyright 2015 Electric Imp

// SPDX-License-Identifier: MIT

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

class FactoryTools {

    static VERSION = "3.0.0";

    /**
    * @return {bool} - 'true' or 'false'
    */
    static function isFactoryFirmware() {
        // If not connected force connection with server.log so imp.configparams is populated when we run the check
        if (!_isAgent() && !server.isconnected()) server.log("Connecting to server...");
        return ("factoryfirmware" in imp.configparams && imp.configparams["factoryfirmware"]);
    }

    /**
    * @return {bool}
    */
    static function isFactoryImp() {
        if (_isAgent()) {
            return (isFactoryFirmware() && !isDeviceUnderTest());
        } else {
            // If not connected force connection with server.log so imp.configparams is populated when we run the check
            if (!server.isconnected()) server.log("Connecting to server...");
            return (isFactoryFirmware() && "factory_imp" in imp.configparams && imp.configparams.factory_imp == imp.getmacaddress());
        }
    }

    /**
    * @return {bool}
    */
    static function isDeviceUnderTest() {
        if (_isAgent()) {
            return (isFactoryFirmware() && "factory_fixture_url" in imp.configparams);
        } else {
            // If not connected force connection with server.log so imp.configparams is populated when we run the check
            if (!server.isconnected()) server.log("Connecting to server...");
            return (isFactoryFirmware() && !isFactoryImp());
        }
    }

    /**
    * Factory Device: @return {null}
    * Factory Agent: @return {null | string} - if in factory environment the Factory Fixture agent URL is returned, otherwise null
    */
    static function getFactoryFixtureURL() {
        if (isAgent() && isFactoryFirmware()) {
            return ("factory_fixture_url" in imp.configparams) ? imp.configparams.factory_fixture_url : http.agenturl();
        }
        return null;
    }

    /**
    * @return {bool}
    */
    function _isAgent() {
        return (imp.environment() == ENVIRONMENT_AGENT);
    }
}
