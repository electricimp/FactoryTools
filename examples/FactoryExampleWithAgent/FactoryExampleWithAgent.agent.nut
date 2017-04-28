// MIT License

// Copyright 2017 Electric Imp

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

#require "FactoryTools.device.lib.nut:3.0.0"

// FACTORY FIXTURE FUNCTIONS

function fixture() {
    server.log("Running Factory Fixture flow");

    // Open HTTP listener for messages from the Device Under Test
    http.onrequest(function(request, response) {
        try {
            // Look for a POST request from a device
            if (request.method == "POST") {
                if (request.body) {
                    // Make sure the request has a non-null body
                    try {
                        local data = http.jsondecode(request.body);

                        server.log("Transmitting DUT device data to Factory Fixture");
                        // Send the device’s data to the BlinkUp fixture
                        device.send("DUT_data", data);

                        // Confirm successful receipt
                        response.send(200, "OK");
                    } catch (error) {
                        response.send(400, "Could not process JSON");
                    }
                }
            }
        } catch (error) {
            response.send(500, "Transmission failed - please try again");
        }
    });

}

// PRODUCTION DEVICE FUNCTIONS

function sendDUTFlowCompleteToFactoryFixture(result) {
    // Get the URL of the BlinkUp fixture that configured the unit under test
    local fixtureAgentURL = imp.configparams.factory_fixture_url;

    if (fixtureAgentURL != null) {
        // Relay complete message to he factory BlinkUp fixture via HTTP
        local success = ("test_result" in result) ? false : result.bless_success;
        local header = { "content-type" : "application/json" };
        local body = {"device_id" : result.device_id, "mac" : result.mac, "success" : success};
        local request = http.post(fixtureAgentURL, header, http.jsonecode(body));

        // Wait for a response before proceeding, ie. pause operation until
        // fixture confirms receipt. We need label printing and UUT’s position
        // on the assembly line to stay in sync
        local response = request.sendsync();

        if (response.statuscode != 200) {
            // Issue a simple error here; real firmware would need a more advanced solution
            server.error("Problem contacting fixture");
        }
    } else {
        server.error("Factory Fixture URL not found");
    }
}

function pdevice() {
    server.log("Running Device Under Test flow");

    // Open listeners for messages from device
    device.on("testresult", function(result) {
        // Log test result
        "Received test result from device %s: %s", result.device_id, result.msg);
        // Send result to Factory Fixture if tests failed
        if (!result.test_result) sendDUTFlowCompleteToFactoryFixture(result);
        // Add code here to pass test results on to a webservice
    });

    deivce.on("blessingresult", function(result) {
        // Log blessing result
        "Received blessing result from device %s: %s", result.device_id, result.msg);
        // Send result to Factory Fixture
        sendDUTFlowCompleteToFactoryFixture(result);
        // Add code here to pass test results on to a webservice
    });
}


// START

// Don't run the factory code if not factory firmware
if (FactoryTools.isFactoryFirmware()) {
    // Select the appropriate code path
    if (FactoryTools.isFactoryImp()) fixture();
    if (FactoryTools.isDeviceUnderTest()) pdevice();
} else {
    server.log("Not running in Factory Environment");
}
