// MIT License

// Copyright 2016 Electric Imp

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

// Factory Tools Utility Library
#require "FactoryTools.device.lib.nut:3.0.0"


// SHARED SETUP
// ---------------------------------------
const webhookURL = "<YOUR WEBHOOK's BASEURL>";


// AGENT CLASSES
// ---------------------------------------

// FACTORY FIXTURE CLASS
class BootFactoryFixtureAgent {

    constructor() {
        device.on("testresult", sendTestResultToDB);
        handleDUTPostReq();
    }

    function sendTestResultToDB(result) {
        // send result to webhook backend
        local url = webhookURL + "/testresult.json";
        local headers = { "Content-Type":"application/json" };
        local body = http.jsonencode(result);
        local deviceid = imp.configparams.deviceid;

        server.log(format("posting testresults for device %s:%s", deviceid, body));

        http.post(url, headers, body).sendasync(function (response) {
            if (response.statuscode >= 300) {
                server.error(format(
                    "failed posting testresults for device %s with status code %d:%s",
                    deviceid, response.statuscode, response.body));
            }
        });
    }

    function handleDUTPostReq() {
        http.onrequest(function(req, res) {
            try {
                if(req.method == "POST" && req.body) {
                    local data = http.jsondecode(req.body);
                    device.send("DUT_devInfo", data);
                    res.send(200, "OK");
                }
            } catch (err) {
                res.send(500, "Transmission Failed - Please try again.");
            }
        })
    }

}

// DEVICE UNDER TEST CLASS
class BootDeviceUnderTestAgent {

    constructor() {
        device.on("testresult", function(result) {
            sendTestResultToDB(result);
            sendDeviceInfoToFactoryFixture(result);
        }.bindenv(this));
    }

    function sendTestResultToDB(result) {
        // send result to webhook backend
        local url = webhookURL + "/testresult.json";
        local headers = { "Content-Type":"application/json" };
        local body = http.jsonencode(result);
        local deviceid = imp.configparams.deviceid;

        server.log(format("posting testresults for device %s:%s", deviceid, body));

        http.post(url, headers, body).sendasync(function (response) {
            if (response.statuscode >= 300) {
                server.error(format(
                    "failed posting testresults for device %s with status code %d:%s",
                    deviceid, response.statuscode, response.body));
            }
        });
    }

    function sendDeviceInfoToFactoryFixture(result) {
        local fixtureAgentURL = FactoryTools.getFactoryFixtureURL();
        local headers = { "Content-Type":"application/json" };
        local body;

        if(fixtureAgentURL == null) {
            server.error("Factory Fixture URL Not Available.");
            return;
        }

        if(result.success) {
            body = http.jsonencode(result.deviceInfo);
        } else {
            body = http.jsonencode({"success": result.success});
        }

        local request = http.post(fixtureAgentURL, headers, body);
        local response = request.sendsync();

        if(response.statuscode != 200) {
            server.error("Problem contacting fixture");
        } else {
            server.log("Factory fixture confirmed receipt of DUT info.");
        }
    }
}


// RUNTIME CODE
// ---------------------------------------
server.log("AGENT RUNNING");

// Check that we are in the factory
if (FactoryTools.isFactoryFirmware()) {
    server.log("This agent is running factory firmware");

    // Run Class Code for Specified Device
    if (FactoryTools.isFactoryImp()) {
        server.log("Its device is a BlinkUp fixture");
        BootFactoryFixtureAgent();
    }

    if (FactoryTools.isDeviceUnderTest()) {
        server.log("Its device is a production unit");
        BootDeviceUnderTestAgent();
    }

} else {
    server.log("This agent is not running in the Factory Environment");
}