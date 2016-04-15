/**
* Copyright (C) 2015-2016 Electric Imp, Inc
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
* version 1.1.1
*/

class FactoryTools {

    static version = [1,1,1];

    /**
    * @return {bool} - 'true' or 'false'
    */
    static function isFactoryFirmware() {
        return ("factoryfirmware" in imp.configparams && imp.configparams["factoryfirmware"]);
    }

    /**
    * @return {bool}
    */
    static function isFactoryImp() {
        if ( _isAgent() ) {
            return ( isFactoryFirmware() && !getFactoryFixtureURL() );
        } else {
            return ( isFactoryFirmware() && "factory_imp" in imp.configparams && imp.configparams.factory_imp == imp.getmacaddress() );
        }
    }

    /**
    * @return {bool}
    */
    static function isDeviceUnderTest() {
        if ( _isAgent() ) {
            return (isFactoryFirmware() && typeof getFactoryFixtureURL() == "string");
        } else {
            return (isFactoryFirmware() && !isFactoryImp());
        }
    }

    /**
    * Factory Device: @return {null}
    * Factory Agent: @return {null | string} - if in Device Under Test agent the Factory Fixture agent URL is returned, otherwise null
    */
    static function getFactoryFixtureURL() {
        return ("factory_fixture_url" in imp.configparams) ? imp.configparams.factory_fixture_url : null;
    }

    /**
    * @return {bool}
    */
    function _isAgent() {
        return (imp.environment() == ENVIRONMENT_AGENT);
    }
}