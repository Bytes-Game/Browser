        ��  ��                  z>      �� ���    0 	        <!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8" />
    <title>Binary vs String Transfer Benchmark</title>
    <script src="https://cdn.plot.ly/plotly-2.34.0.min.js"></script>
    <style>
      body {
        font-family: Tahoma, Serif;
        font-size: 10pt;
        background-color: white;
      }
      .info {
        font-size: 12pt;
      }
      .left {
        text-align: left;
      }
      .right {
        text-align: right;
      }
      .positive {
        color: green;
        font-weight: bold;
      }
      .negative {
        color: red;
        font-weight: bold;
      }
      .center {
        text-align: center;
      }
      table.resultTable {
        border: 1px solid black;
        border-collapse: collapse;
        empty-cells: show;
        width: 100%;
      }
      table.resultTable td {
        padding: 2px 4px;
        border: 1px solid black;
      }
      table.resultTable > thead > tr {
        font-weight: bold;
        background: lightblue;
      }
      table.resultTable > tbody > tr:nth-child(odd) {
        background: white;
      }
      table.resultTable > tbody > tr:nth-child(even) {
        background: lightgray;
      }
      .hide {
        display: none;
      }
    </style>
  </head>

  <body background-color="white">
    <h1>Binary vs String Transfer Benchmark</h1>

    <table>
      <tr>
        <td>
          <p class="info">
            This benchmark evaluates the message transfer speed between the
            renderer process and the browser process. <br />It compares the
            performance of binary and string message transfer.
          </p>
          <p class="info">
            <b>Note:</b> There is no progress indication of the tests because it
            significantly influences measurements. <br />It usually takes 30
            seconds (for 300 samples) to complete the tests.
          </p>
        </td>
      </tr>
      <tr>
        <td>
          Samples:
          <input
            id="sSamples"
            type="text"
            value="300"
            required
            pattern="[0-9]+"
          />
          <button id="sRun" autofocus onclick="runTestSuite()">Run</button>
        </td>
      </tr>
    </table>

    <div style="padding-top: 10px; padding-bottom: 10px">
      <table id="resultTable" class="resultTable">
        <thead>
          <tr>
            <td class="center" style="width: 8%">Message Size</td>
            <td class="center" style="width: 8%">
              String Round Trip Avg,&nbsp;ms
            </td>
            <td class="center" style="width: 8%">
              Binary Round Trip Avg,&nbsp;ms
            </td>
            <td class="center" style="width: 10%">Relative Trip Difference</td>
            <td class="center" style="width: 8%">String Speed,&nbsp;MB/s</td>
            <td class="center" style="width: 8%">Binary Speed,&nbsp;MB/s</td>
            <td class="center" style="width: 10%">Relative Speed Difference</td>
            <td class="center" style="width: 8%">String Standard Deviation</td>
            <td class="center" style="width: 8%">Binary Standard Deviation</td>
          </tr>
        </thead>
        <tbody>
          <!-- result rows here -->
        </tbody>
      </table>
    </div>

    <div id="round_trip_avg_chart">
      <!-- Average round trip linear chart will be drawn inside this DIV -->
    </div>
    <div id="round_trip_chart">
      <!-- Round trip linear chart will be drawn inside this DIV -->
    </div>
    <div id="box_plot_chart">
      <!-- Box plot of round trip time will be drawn inside this DIV -->
    </div>

    <script type="text/javascript">
      let tests = [];
      let box_plot_test_data = [];
      let round_trip_avg_plot_data = [];
      let round_trip_plot_data = [];

      function nextTestSuite(testIndex) {
        const nextTestIndex = testIndex + 1;
        setTimeout(execTestSuite, 0, nextTestIndex);
      }

      function generateString(size) {
        // Symbols that will be encoded as two bytes in UTF-8
        // so we compare transfer of the same amount of bytes
        const characters =
          "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя";
        let randomString = "";
        for (let i = 0; i < size; i++) {
          const randomIndex = Math.floor(Math.random() * characters.length);
          randomString += characters.charAt(randomIndex);
        }
        return randomString;
      }

      function generateArrayBuffer(size) {
        const buffer = new ArrayBuffer(size);
        const uint8Array = new Uint8Array(buffer);
        for (let i = 0; i < uint8Array.length; i++) {
          uint8Array[i] = Math.floor(Math.random() * 256);
        }
        return buffer;
      }

      function reportError(errorCode, errorMessage) {
        console.error(`ErrorCode:${errorCode} Message:${errorMessage}`);
      }

      function sendString(request, testIndex) {
        const startTime = performance.now();
        const onSuccess = (response) => {
          const roundTrip = performance.now() - startTime;
          const test = tests[testIndex];
          test.totalRoundTrip += roundTrip;
          test.sample++;
          box_plot_test_data[testIndex].x.push(roundTrip);
          round_trip_plot_data[testIndex].x.push(test.sample);
          round_trip_plot_data[testIndex].y.push(roundTrip);
          setTimeout(execTest, 0, testIndex);
        };

        window.cefQuery({
          request: request,
          onSuccess: onSuccess,
          onFailure: reportError,
        });
      }

      function sendArrayBuffer(request, testIndex) {
        const startTime = performance.now();
        const onSuccess = (response) => {
          const roundTrip = performance.now() - startTime;
          const test = tests[testIndex];
          test.totalRoundTrip += roundTrip;
          test.sample++;
          box_plot_test_data[testIndex].x.push(roundTrip);
          round_trip_plot_data[testIndex].x.push(test.sample);
          round_trip_plot_data[testIndex].y.push(roundTrip);
          setTimeout(execTest, 0, testIndex);
        };

        window.cefQuery({
          request: request,
          onSuccess: onSuccess,
          onFailure: reportError,
        });
      }

      function getStandardDeviation(array, mean) {
        const n = array.length;
        if (n < 5) return null;
        return Math.sqrt(
          array.map((x) => Math.pow(x - mean, 2)).reduce((a, b) => a + b) /
            (n - 1)
        );
      }

      function execTest(testIndex) {
        const test = tests[testIndex];
        if (test.sample >= test.totalSamples) {
          return nextTestSuite(testIndex);
        }
        test.func(test.request, test.index);
      }

      function column(prepared, value) {
        return (
          "<td class='right'>" + (!prepared ? "-" : value.toFixed(3)) + "</td>"
        );
      }

      function relativeDiffColumn(prepared, value, isBiggerBetter) {
        if (!prepared) return "<td class='right'>-</td>";

        const isPositive = value >= 0 == isBiggerBetter;
        return [
          "<td class='right ",
          isPositive ? "positive" : "negative",
          "'>",
          value > 0 ? "+" : "",
          value.toFixed(2),
          "%</td>",
        ].join("");
      }

      function displayResult(test) {
        const id = "testResultRow_" + test.index;

        const markup = [
          "<tr id='",
          id,
          "'>",
          "<td class='left'>",
          test.name,
          "</td>",
          column(test.prepared, test.avgRoundTrip),
          column(test.prepared, test.avgRoundTripBin),
          relativeDiffColumn(test.prepared, test.relativeTripDiff, false),
          column(test.prepared, test.speed),
          column(test.prepared, test.speedBinary),
          relativeDiffColumn(test.prepared, test.relativeSpeedDiff, true),
          "<td class='right'>",
          !test.prepared || test.stdDeviation == null
            ? "-"
            : test.stdDeviation.toFixed(3),
          "</td>",
          "<td class='right'>",
          !test.prepared || test.stdDeviationBinary == null
            ? "-"
            : test.stdDeviationBinary.toFixed(3),
          "</td>",
          "</tr>",
        ].join("");

        const row = document.getElementById(id);
        if (row) {
          row.outerHTML = markup;
        } else {
          const tbody = document.getElementById("resultTable").tBodies[0];
          tbody.insertAdjacentHTML("beforeEnd", markup);
        }
      }
      function relativeDiff(left, right) {
        if (right != 0) {
          return ((left - right) / right) * 100;
        }
        return 0;
      }

      function buildTestResults(tests) {
        testResults = [];

        let stringRoundTrip = {
          x: [],
          y: [],
          type: "scatter",
          name: "String",
        };

        let binaryRoundTrip = {
          x: [],
          y: [],
          type: "scatter",
          name: "Binary",
        };

        for (let i = 0; i < tests.length / 2; i++) {
          const index = testResults.length;

          // Tests are in pairs - String and Binary
          const test = tests[i * 2];
          const testBin = tests[i * 2 + 1];

          const avgRoundTrip = test.totalRoundTrip / test.totalSamples;
          const avgRoundTripBin = testBin.totalRoundTrip / testBin.totalSamples;
          const relativeTripDiff = relativeDiff(avgRoundTripBin, avgRoundTrip);

          // In MB/s
          const speed = test.byteSize / (avgRoundTrip * 1000);
          const speedBinary = testBin.byteSize / (avgRoundTripBin * 1000);
          const relativeSpeedDiff = relativeDiff(speedBinary, speed);

          const stdDeviation = getStandardDeviation(
            box_plot_test_data[test.index].x,
            avgRoundTrip
          );
          const stdDeviationBinary = getStandardDeviation(
            box_plot_test_data[testBin.index].x,
            avgRoundTripBin
          );

          testResults.push({
            name: humanFileSize(test.byteSize),
            index: index,
            prepared: true,
            avgRoundTrip: avgRoundTrip,
            avgRoundTripBin: avgRoundTripBin,
            relativeTripDiff: relativeTripDiff,
            speed: speed,
            speedBinary: speedBinary,
            relativeSpeedDiff: relativeSpeedDiff,
            stdDeviation: stdDeviation,
            stdDeviationBinary: stdDeviationBinary,
          });

          stringRoundTrip.x.push(test.byteSize);
          binaryRoundTrip.x.push(test.byteSize);
          stringRoundTrip.y.push(avgRoundTrip);
          binaryRoundTrip.y.push(avgRoundTripBin);
        }

        round_trip_avg_plot_data = [stringRoundTrip, binaryRoundTrip];
        return testResults;
      }

      function buildEmptyTestResults(tests) {
        testResults = [];
        for (let i = 0; i < tests.length / 2; i++) {
          const index = testResults.length;
          const test = tests[i * 2];

          testResults.push({
            name: humanFileSize(test.byteSize),
            index: index,
            prepared: false,
          });
        }
        return testResults;
      }

      function resetTestsResults(totalSamples) {
        if (totalSamples <= 0) totalSamples = 1;

        // Reset tests results
        tests.forEach((test) => {
          test.sample = 0;
          test.totalRoundTrip = 0;
          test.totalSamples = totalSamples;
        });

        testResults = buildEmptyTestResults(tests);
        testResults.forEach((result) => displayResult(result));

        round_trip_avg_plot_data = [];
        box_plot_test_data.forEach((data) => {
          data.x = [];
        });
        round_trip_plot_data.forEach((data) => {
          data.x = [];
          data.y = [];
        });
      }

      function queueTest(name, byteSize, request, testFunc) {
        const testIndex = tests.length;
        test = {
          name: name,
          byteSize: byteSize,
          index: testIndex,
          sample: 0,
          totalRoundTrip: 0,
          request: request,
          func: testFunc,
        };
        tests.push(test);

        box_plot_test_data.push({
          x: [],
          type: "box",
          boxpoints: "all",
          name: name,
          jitter: 0.3,
          pointpos: -1.8,
        });

        round_trip_plot_data.push({
          x: [],
          y: [],
          type: "scatter",
          name: name,
        });
      }

      function execTestSuite(testIndex) {
        if (testIndex < tests.length) {
          setTimeout(execTest, 0, testIndex);
        } else {
          testsRunFinished();
        }
      }

      function startTests() {
        // Let the updated table render before starting the tests
        setTimeout(execTestSuite, 200, 0);
      }

      function execQueuedTests(totalSamples) {
        resetTestsResults(totalSamples);
        startTests();
      }

      function setSettingsState(disabled) {
        document.getElementById("sSamples").disabled = disabled;
        document.getElementById("sRun").disabled = disabled;
      }

      function testsRunFinished() {
        testResults = buildTestResults(tests);
        testResults.forEach((result) => displayResult(result));

        Plotly.newPlot("round_trip_avg_chart", round_trip_avg_plot_data, {
          title: "Average round trip, μs (Smaller Better)",
        });
        Plotly.newPlot("round_trip_chart", round_trip_plot_data, {
          title: "Linear: Round Trip Time, μs",
        });
        Plotly.newPlot("box_plot_chart", box_plot_test_data, {
          title: "Box plot: Round Trip Time, μs",
        });

        setSettingsState(false);
      }

      function humanFileSize(bytes) {
        const step = 1024;
        const originalBytes = bytes;

        if (Math.abs(bytes) < step) {
          return bytes + " B";
        }

        const units = [" KB", " MB", " GB"];
        let u = -1;
        let count = 0;

        do {
          bytes /= step;
          u += 1;
          count += 1;
        } while (Math.abs(bytes) >= step && u < units.length - 1);

        return bytes.toString() + units[u];
      }

      window.runTestSuite = () => {
        Plotly.purge("round_trip_avg_chart");
        Plotly.purge("box_plot_chart");
        Plotly.purge("round_trip_chart");
        setSettingsState(true);
        const totalSamples = parseInt(
          document.getElementById("sSamples").value
        );
        execQueuedTests(totalSamples);
      };

      const totalSamples = parseInt(document.getElementById("sSamples").value);

      queueTest("Empty String", 0, generateString(0), sendString);
      queueTest("Empty Binary", 0, generateArrayBuffer(0), sendArrayBuffer);
      for (let byteSize = 8; byteSize <= 512 * 1024; byteSize *= 4) {
        // Byte size of a string is twice its length because of UTF-16 encoding
        const stringLen = byteSize / 2;
        queueTest(
          humanFileSize(byteSize) + " String",
          byteSize,
          generateString(stringLen),
          sendString
        );
        queueTest(
          humanFileSize(byteSize) + " Binary",
          byteSize,
          generateArrayBuffer(byteSize),
          sendArrayBuffer
        );
      }
      resetTestsResults(totalSamples);
    </script>
  </body>
</html>
  �      �� ���    0 	        <html>
<head>
<title>Binding Test</title>
<script language="JavaScript">

function setup() {
  if (location.hostname == 'tests' || location.hostname == 'localhost')
    return;

  alert('This page can only be run from tests or localhost.');

  // Disable all elements.
  var elements = document.getElementById("form").elements;
  for (var i = 0, element; element = elements[i++]; ) {
    element.disabled = true;
  }
}

// Send a query to the browser process.
function sendMessage() {
  // Results in a call to the OnQuery method in binding_test.cc
  window.cefQuery({
    request: 'BindingTest:' + document.getElementById("message").value,
    onSuccess: function(response) {
      document.getElementById('result').value = 'Response: '+response;
    },
    onFailure: function(error_code, error_message) {}
  });
}
</script>

</head>
<body bgcolor="white" onload="setup()">
<form id="form">
Message: <input type="text" id="message" value="My Message">
<br/><input type="button" onclick="sendMessage();" value="Send Message">
<br/>You should see the reverse of your message below:
<br/><textarea rows="10" cols="40" id="result"></textarea>
</form>
</body>
</html>
  �a      �� ���    0 	        <!DOCTYPE HTML>
<html>
<head>
  <title>Configuration Test</title>
  <meta http-equiv="Content-Type" content="text/html;charset=utf-8">

  <style>
    body {
      font-family: Verdana, Arial;
      font-size: 12px;
    }
    #message {
      color: red;
      font-weight: bold;
      font-size: 14px;
    }
    .desc {
      font-size: 14px;
    }
    .foot {
      font-size: 11px;
    }
    .mono {
      font-family: monospace;
    }
    .cat_header_0 {
      font-weight: bold;
      font-size: 14px;
    }
    .cat_header_1 {
      font-weight: bold;
    }
    .cat_header_2 {
      font-family: Verdana, Arial;
    }
    .cat_body {
      font-family: monospace;
      white-space: pre;
      margin-left: 10px;
    }
    #temp-message {
      display: none;
      background-color: #f0f0f0;
      border: 1px solid #ccc;
      padding: 10px;
      position: fixed;
      bottom: 20px;
      left: 50%;
      transform: translateX(-50%);
    }
    .hr-container {
      display: flex;
      align-items: center;
      text-align: center;
    }
    .hr-line {
      border-top: 1px solid black;
      width: 100%;
      margin: 0 3px;
    }
    .hr-text {
      padding: 0;
      white-space: nowrap;
    }
  </style>

  <script>
    function onLoad() {
      if (location.hostname != 'tests') {
        onCefError(0, 'This page can only be run from tests.');

        // Disable all form elements.
        var elements = document.getElementById("form").elements;
        for (var i = 0, element; element = elements[i++]; ) {
          element.disabled = true;
        }

        return;
      }

      getGlobalConfig();
      updateFilter();
      startSubscription();
    }

    function onUnload() {
      stopSubscription();
    }

    function onCefError(code, message) {
      val = 'ERROR: ' + message;
      if (code !== 0) {
        val += ' (' + code + ')';
      }
      document.getElementById('message').innerHTML = val + '<br/><br/>';
    }

    function sendCefQuery(payload, onSuccess, onFailure=onCefError, persistent=false) {
      // Results in a call to the OnQuery method in config_test.cc
      return window.cefQuery({
        request: JSON.stringify(payload),
        onSuccess: onSuccess,
        onFailure: onFailure,
        persistent: persistent
      });
    }

    // Request the global configuration.
    function getGlobalConfig() {
      sendCefQuery(
        {name: 'global_config'},
        (message) => onGlobalConfigMessage(JSON.parse(message)),
      );
    }

    // Display the global configuration response.
    function onGlobalConfigMessage(message) {
      document.getElementById('global_switches').innerHTML =
          message.switches !== null ? message.switches.join('<br/>') : '(none)';
      if (message.strings !== null) {
        document.getElementById('global_strings').innerHTML = message.strings.join('<br/>');
        document.getElementById('global_strings_ct').textContent = message.strings.length;
      }
    }

    var currentSubscriptionId = null;

    // Subscribe to ongoing message notifications from the native code.
    function startSubscription() {
      currentSubscriptionId = sendCefQuery(
        {name: 'subscribe'},
        (message) => onSubscriptionMessage(JSON.parse(message)),
        (code, message) => {
          onCefError(code, message);
          currentSubscriptionId = null;
        },
        true
      );
    }

    // Unsubscribe from message notifications.
    function stopSubscription() {
      if (currentSubscriptionId !== null) {
        // Results in a call to the OnQueryCanceled method in config_test.cc
        window.cefQueryCancel(currentSubscriptionId);
      }
    }
 
    // Returns a nice timestamp for display purposes.
    function getNiceTimestamp() {
      const now = new Date();

      const year = now.getFullYear();
      const month = String(now.getMonth() + 1).padStart(2, '0'); // Months are 0-indexed
      const day = String(now.getDate()).padStart(2, '0');
      const hours = String(now.getHours()).padStart(2, '0');
      const minutes = String(now.getMinutes()).padStart(2, '0');
      const seconds = String(now.getSeconds()).padStart(2, '0');

      return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
    }

    var paused = false;
    var paused_messages = [];
    var first_after_pause = false;

    // Toggle whether messages are displayed or queued.
    function togglePause() {
      paused = !paused;
      document.getElementById("pause_button").value = paused ? "Resume" : "Pause";

      if (!paused) {
        first_after_pause = true;
        while (paused_messages.length > 0) {
          onSubscriptionMessage(paused_messages.shift());
        }
      }
    }

    function doPause() {
      if (!paused) {
        togglePause();
        showTempMessage('Event processing is paused. Click Resume to continue.');
      }
    }

    var filter = {}
    var filtered_ct = 0;
    var filter_updating = false;

    // Populate |filter| based on form control state.
    function updateFilter() {
      if (filter_updating) {
        // Ignore changes triggered from individual elements while we're updating multiple.
        return;
      }

      filter.text = document.getElementById("filter_text").value.trim().toLowerCase();
      filter.global_prefs = document.getElementById("filter_global_prefs").checked;
      filter.context_prefs = document.getElementById("filter_context_prefs").checked;
      filter.context_settings = document.getElementById("filter_context_settings").checked;
    }

    function doFilter(type, text, global=false) {
      filter_updating = true;

      document.getElementById("filter_text").value = text;

      var checked = '';
      if (type === 'preference') {
        checked = global ? 'filter_global_prefs' : 'filter_context_prefs';
      } else if (type === 'setting') {
        checked = 'filter_context_settings';
      }

      ['filter_global_prefs', 'filter_context_prefs', 'filter_context_settings'].forEach(function(id) {
        document.getElementById(id).checked = id === checked;
      });

      filter_updating = false;
      updateFilter();
    }

    function doFilterReset() {
      filter_updating = true;
      document.getElementById("filtered_ct").textContent = 0;
      document.getElementById("filter_text").value = '';
      document.getElementById("filter_global_prefs").checked = true;
      document.getElementById("filter_context_prefs").checked = true;
      document.getElementById("filter_context_settings").checked = true;
      filter_updating = false;
      updateFilter();
    }

    // Returns true if the message should be displayed based on the current filter settings.
    function passesFilter(message) {
      if (message.type === 'preference') {
        if (message.global) {
          if (!filter.global_prefs) {
            return false;
          }
        } else if (!filter.context_prefs) {
          return false;
        }
      } else if (message.type === 'setting' && !filter.context_settings) {
        return false;
      }

      if (filter.text.length > 0) {
        var check_text = JSON.stringify(message).toLowerCase();
        if (message.type === 'setting') {
          check_text += ' ' + getSettingTypeLabel(message.content_type).toLowerCase();
        }
        if (check_text.indexOf(filter.text) < 0) {
          return false;
        }
      }

      return true;
    }

    // Match the cef_value_type_t values from include/internal/cef_types.h
    const value_types = [
      'INVALID',
      'NULL',
      'BOOL',
      'INT',
      'DOUBLE',
      'STRING',
      'BINARY',
      'DICTIONARY',
      'LIST',
    ]

    function getValueType(index) {
      if (index < 0 || index >= value_types.length) {
        return 'UNKNOWN';
      }
      return value_types[index];
    }

    // Match the cef_content_setting_types_t values from include/internal/cef_types_content_settings.h
    const setting_types = [
      "COOKIES",
      "IMAGES",
      "JAVASCRIPT",
      "POPUPS",
      "GEOLOCATION",
      "NOTIFICATIONS",
      "AUTO_SELECT_CERTIFICATE",
      "MIXEDSCRIPT",
      "MEDIASTREAM_MIC",
      "MEDIASTREAM_CAMERA",
      "PROTOCOL_HANDLERS",
      "DEPRECATED_PPAPI_BROKER",
      "AUTOMATIC_DOWNLOADS",
      "MIDI_SYSEX",
      "SSL_CERT_DECISIONS",
      "PROTECTED_MEDIA_IDENTIFIER",
      "APP_BANNER",
      "SITE_ENGAGEMENT",
      "DURABLE_STORAGE",
      "USB_CHOOSER_DATA",
      "BLUETOOTH_GUARD",
      "BACKGROUND_SYNC",
      "AUTOPLAY",
      "IMPORTANT_SITE_INFO",
      "PERMISSION_AUTOBLOCKER_DATA",
      "ADS",
      "ADS_DATA",
      "MIDI",
      "PASSWORD_PROTECTION",
      "MEDIA_ENGAGEMENT",
      "SOUND",
      "CLIENT_HINTS",
      "SENSORS",
      "DEPRECATED_ACCESSIBILITY_EVENTS",
      "PAYMENT_HANDLER",
      "USB_GUARD",
      "BACKGROUND_FETCH",
      "INTENT_PICKER_DISPLAY",
      "IDLE_DETECTION",
      "SERIAL_GUARD",
      "SERIAL_CHOOSER_DATA",
      "PERIODIC_BACKGROUND_SYNC",
      "BLUETOOTH_SCANNING",
      "HID_GUARD",
      "HID_CHOOSER_DATA",
      "WAKE_LOCK_SCREEN",
      "WAKE_LOCK_SYSTEM",
      "LEGACY_COOKIE_ACCESS",
      "FILE_SYSTEM_WRITE_GUARD",
      "NFC",
      "BLUETOOTH_CHOOSER_DATA",
      "CLIPBOARD_READ_WRITE",
      "CLIPBOARD_SANITIZED_WRITE",
      "SAFE_BROWSING_URL_CHECK_DATA",
      "VR",
      "AR",
      "FILE_SYSTEM_READ_GUARD",
      "STORAGE_ACCESS",
      "CAMERA_PAN_TILT_ZOOM",
      "WINDOW_MANAGEMENT",
      "INSECURE_PRIVATE_NETWORK",
      "LOCAL_FONTS",
      "PERMISSION_AUTOREVOCATION_DATA",
      "FILE_SYSTEM_LAST_PICKED_DIRECTORY",
      "DISPLAY_CAPTURE",
      "FILE_SYSTEM_ACCESS_CHOOSER_DATA",
      "FEDERATED_IDENTITY_SHARING",
      "JAVASCRIPT_JIT",
      "HTTP_ALLOWED",
      "FORMFILL_METADATA",
      "DEPRECATED_FEDERATED_IDENTITY_ACTIVE_SESSION",
      "AUTO_DARK_WEB_CONTENT",
      "REQUEST_DESKTOP_SITE",
      "FEDERATED_IDENTITY_API",
      "NOTIFICATION_INTERACTIONS",
      "REDUCED_ACCEPT_LANGUAGE",
      "NOTIFICATION_PERMISSION_REVIEW",
      "PRIVATE_NETWORK_GUARD",
      "PRIVATE_NETWORK_CHOOSER_DATA",
      "FEDERATED_IDENTITY_IDENTITY_PROVIDER_SIGNIN_STATUS",
      "REVOKED_UNUSED_SITE_PERMISSIONS",
      "TOP_LEVEL_STORAGE_ACCESS",
      "FEDERATED_IDENTITY_AUTO_REAUTHN_PERMISSION",
      "FEDERATED_IDENTITY_IDENTITY_PROVIDER_REGISTRATION",
      "ANTI_ABUSE",
      "THIRD_PARTY_STORAGE_PARTITIONING",
      "HTTPS_ENFORCED",
      "ALL_SCREEN_CAPTURE",
      "COOKIE_CONTROLS_METADATA",
      "TPCD_HEURISTICS_GRANTS",
      "TPCD_METADATA_GRANTS",
      "TPCD_TRIAL",
      "TOP_LEVEL_TPCD_TRIAL",
      "TOP_LEVEL_TPCD_ORIGIN_TRIAL",
      "AUTO_PICTURE_IN_PICTURE",
      "FILE_SYSTEM_ACCESS_EXTENDED_PERMISSION",
      "FILE_SYSTEM_ACCESS_RESTORE_PERMISSION",
      "CAPTURED_SURFACE_CONTROL",
      "SMART_CARD_GUARD",
      "SMART_CARD_DATA",
      "WEB_PRINTING",
      "AUTOMATIC_FULLSCREEN",
      "SUB_APP_INSTALLATION_PROMPTS",
      "SPEAKER_SELECTION",
      "DIRECT_SOCKETS",
      "KEYBOARD_LOCK",
      "POINTER_LOCK",
      "REVOKED_ABUSIVE_NOTIFICATION_PERMISSIONS",
      "TRACKING_PROTECTION",
      "DISPLAY_MEDIA_SYSTEM_AUDIO",
      "JAVASCRIPT_OPTIMIZER",
      "STORAGE_ACCESS_HEADER_ORIGIN_TRIAL",
      "HAND_TRACKING",
      "WEB_APP_INSTALLATION",
      "DIRECT_SOCKETS_PRIVATE_NETWORK_ACCESS",
      "LEGACY_COOKIE_SCOPE",
      "ARE_SUSPICIOUS_NOTIFICATIONS_ALLOWLISTED_BY_USER",
      "CONTROLLED_FRAME",
    ];

    function getSettingType(index) {
      if (index < 0 || index >= setting_types.length) {
        return 'UNKNOWN';
      }
      return setting_types[index];
    }

    function getSettingTypeLabel(type) {
      return getSettingType(type) + ' (' + type + ')'
    }

    function makeDetails(summaryHTML, summaryClass, contentHTML, contentClass, contentId=null, open=false) {
      const newDetails = document.createElement('details');
      if (open) {
        newDetails.open = true;
      }

      const newSummary = document.createElement('summary');
      newSummary.innerHTML = summaryHTML;
      if (summaryClass !== null) {
        newSummary.className = summaryClass;
      }
      newDetails.append(newSummary);

      const newContent = document.createElement('p');
      newContent.innerHTML = contentHTML
      if (contentClass !== null) {
        newContent.className = contentClass;
      }
      if (contentId !== null) {
        newContent.id = contentId;
      }
      newDetails.append(newContent);

      const newP = document.createElement('p');
      newP.append(newDetails);

      return newP;
    }

    function makeValueExample(value, value_type) {
      code = '\n// Create a CefValue object programmatically:\n' +
             'auto value = CefValue::Create();\n';
      if (value === null || getValueType(value_type) == 'NULL') {
        code += 'value->SetNull();\n';
      } else if (typeof value === 'boolean' || getValueType(value_type) == 'BOOL') {
        code += 'value->SetBool(' + (value ? 'true' : 'false') + ');\n';
      } else if (Number.isInteger(value) || getValueType(value_type) == 'INT') {
        code += 'value->SetInt(' + value + ');\n';
      } else if (typeof value === 'number' || getValueType(value_type) == 'DOUBLE') {
        code += 'value->SetDouble(' + value + ');\n';
      } else if (typeof value === 'string' || getValueType(value_type) == 'STRING') {
        code += 'value->SetString("' + value + '");\n';
      } else if (Array.isArray(value) || getValueType(value_type) == 'LIST') {
        code += 'auto listValue = CefListValue::Create();\n';
        if (value.length > 0) {
          code += '\n// TODO: Populate |listValue| using CefListValue::Set* methods.\n\n';
        }
        code += 'value->SetList(listValue);\n';
        if (value.length > 0) {
          code += '\n// ALTERNATELY: Create a CefValue object by parsing a JSON string:\n' +
                  'auto value = CefParseJSON("[ ... ]", JSON_PARSER_RFC);\n';
        }
      } else if (typeof value === 'object' || getValueType(value_type) == 'DICTIONARY') {
        code += 'auto dictValue = CefDictionaryValue::Create();\n';
        const has_value = Object.keys(value).length > 0;
        if (has_value) {
          code += '\n// TODO: Populate |dictValue| using CefDictionaryValue::Set* methods.\n\n';
        }
        code += 'value->SetDictionary(dictValue);\n';
        if (has_value) {
          code += '\n// ALTERNATELY: Create a CefValue object by parsing a JSON string:\n' +
                  'auto value = CefParseJSON("{ ... }", JSON_PARSER_RFC);\n';
        }
      } else {
        code += '\n//TODO: Populate |value|.\n\n';
      }
      return code;
    }

    function makeCopyLink(elem_id) {
      return '<a href="#" onMouseDown="copyToClipboard(\'' + elem_id + '\')" onClick="return false">[copy to clipboard]</a>';
    }

    function makeContent(elem_id, content) {
      const content_id = 'cn-' + elem_id;
      return makeDetails('Content ' + makeCopyLink(content_id), 'cat_header_2', content, 'cat_body', content_id, true);
    }

    function makeHR(label) {
       const container = document.createElement('div');
      container.className = 'hr-container';
      const line1 = document.createElement('div');
      line1.className = 'hr-line';
      container.append(line1);
      const text = document.createElement('span');
      text.className = 'hr-text';
      text.innerHTML = label;
      container.append(text);
      const line2 = document.createElement('div');
      line2.className = 'hr-line';
      container.append(line2);
      return container;
    }

    function makeCodeExample(elem_id, message) {
      const example_id = 'ex-' + elem_id;
      var code = '// Code must be executed on the browser process UI thread.\n\n';

      if (message.type === "preference") {
        if (message.global) {
          code += 'auto pref_manager = CefPreferenceManager::GetGlobalPreferenceManager();\n';
        } else {
          code += '// |browser| is an existing CefBrowser instance.\n' +
                  'auto pref_manager = browser->GetHost()->GetRequestContext();\n';
        }
        code += makeValueExample(message.value, message.value_type) + '\n' +
                'CefString error;\n' +
                'bool success = pref_manager->SetPreference("' + message.name + '", value, error);\n' +
                'if (!success) {\n' +
                '  // TODO: Use |error| to diagnose the failure.\n' +
                '}\n';
      } else if (message.type === "setting") {
        const type = getSettingType(message.content_type);
        const content_type = type !== 'UNKNOWN' ? 'CEF_CONTENT_SETTING_TYPE_' + type : message.content_type;

        code += '// |browser| is an existing CefBrowser instance.\n' +
                'auto context = browser->GetHost()->GetRequestContext();\n' +
                makeValueExample(message.value, message.value_type) + '\n' +
                'context->SetWebsiteSetting("' + message.requesting_url + '", "' + message.top_level_url +
                '", '+ content_type +', value);\n';
      }

      return makeDetails('C++ Code Example ' + makeCopyLink(example_id), 'cat_header_2', code, 'cat_body', example_id, false);
    }

    var message_ct = 0;

    // A new message has arrived. It may be queued, filtered out or displayed.
    function onSubscriptionMessage(message) {
      if (paused) {
        // Queue the message until the user clicks Resume.
        message.timestamp = getNiceTimestamp();
        paused_messages.push(message);
        document.getElementById("pause_button").value = 'Resume (' + paused_messages.length + ')';
        return;
      }

      if (!passesFilter(message)) {
        // Filter out the message.
        filtered_ct++;
        document.getElementById("filtered_ct").innerHTML = filtered_ct;
        return;
      }

      // Use the arrival timestamp for queued messages.
      var timestamp;
      if (message.timestamp) {
        timestamp = message.timestamp;
        delete message.timestamp;
      } else {
        timestamp = getNiceTimestamp();
      }

      // Display the message.
      var label = timestamp + ': ';
      var content = 'value_type=' + getValueType(message.value_type);
      var search = '';
      var filter = '';

      if (message.type === "preference") {
        label += 'Preference (' + (message.global ? 'Global' : 'Profile') +
                 ') <span class="mono">' + message.name + '</span>';
        search = '%5C%22' + message.name + '%5C%22';
        filter = "'preference', '" + message.name + "', " + (message.global ? 'true' : 'false');
      } else if (message.type === "setting") {
        label += 'Setting <span class="mono">' + getSettingTypeLabel(message.content_type) + '</span>';
        const setting_type = getSettingType(message.content_type);
        search = 'ContentSettingsType::' + setting_type;
        filter = "'setting', '" + setting_type + "'";
        content = 'requesting_url=' + message.requesting_url +
                  '\ntop_level_url=' + message.top_level_url +
                  '\n' + content;
      }
      content += '\nvalue=' + JSON.stringify(message.value, null, 1);
      label += ' <a href="#" onMouseDown="doFilter(' + filter + ')" onClick="return false">[filter]</a>' +
               ' <a href="https://source.chromium.org/search?q=' + search + '" target="_blank">[search &#x1F517]</a>';

      const messages = document.getElementById('messages');
      
      if (first_after_pause) {
        messages.prepend(makeHR('RESUMED'));
        first_after_pause = false;
      }

      const elem_id = message_ct++;
      const newDetails = makeDetails(label, null, makeContent(elem_id, content).outerHTML +
                                                  makeCodeExample(elem_id, message).outerHTML, 'cat_body');
      messages.prepend(newDetails);
    }

    // Clear filter count and displayed/pending messages.
    function doClear() {
      filtered_ct = 0;
      document.getElementById("filtered_ct").textContent = 0;
      document.getElementById('messages').innerHTML = '';
      if (paused) {
        paused_messages = [];
        document.getElementById("pause_button").value = 'Resume';
      }
      message_ct = 0;
    }

    function showTempMessage(msg) {
      const element = document.getElementById("temp-message");
      element.innerHTML = msg;
      element.style.display = "block";

      setTimeout(function() {
        element.style.display = "none";
      }, 3000);
    }

    function copyToClipboard(elementId) {
      const element = document.getElementById(elementId);
      if (!element) {
        return;
      }

      // Make all parent details nodes are open, otherwise nothing will be copied to the clipboard.
      var parent = element.parentNode;
      while (parent) {
        if (parent.nodeName === 'DETAILS') {
          if (!parent.open) {
            parent.open = true;
          }
        }
        parent = parent.parentNode;
      }

      navigator.clipboard.writeText(element.outerText)
        .then(() => {
          showTempMessage('Text copied to clipboard.');
        })
        .catch(err => {
          showTempMessage('Failed to copy text to clipboard!');
          console.error('Failed to copy text: ', err);
        });
    }
  </script>
</head>
<body bgcolor="white" onload="onLoad()" onunload="onUnload()">
  <div id="message"></div>
  <details open>
    <summary class="cat_header_0">Startup configuration</summary>
    <p class="desc">
       This section displays the global configuration (Chrome Variations) that was applied at startup.
       Chrome Variations can be configured via chrome://flags <sup>[*]</sup>, via the below command-line switches, or via field trials (disabled in Official builds).
       The Active Variations section below is the human-readable equivalent of the "Active Variations" section of chrome://version.
       See <a href="https://developer.chrome.com/docs/web-platform/chrome-variations" target="_blank">Chrome Variations docs</a> for background.
    </p>
    <p class="foot">
      * Flags are stored in the global <span class="mono">browser.enabled_labs_experiments</span> preference.
    </p>
    <p class="cat_header_1">Command-Line Switches:</p>
    <p class="cat_body" id="global_switches"></p>
    <details>
      <summary class="cat_header_1">Active Variations (<span id="global_strings_ct">0</span>)</summary>
      <p class="cat_body" id="global_strings"></p>
    </details>
  </details>
  <br/>
  <details open>
    <summary class="cat_header_0">Runtime configuration</summary>
    <p class="desc">
       This section displays preference and site settings changes that occur during runtime.
       Chromium stores both global and Profile-specific preferences.
       See <a href="https://www.chromium.org/developers/design-documents/preferences/" target="_blank">Preferences docs</a> for background.
       To view a snapshot of all preferences go <a href="https://tests/preferences#advanced">here</a> instead.
    </p>
    <p id="filter">
      <form id="form">
        Text Contains: <input type="text" id="filter_text"/> <input type="button" onclick="updateFilter();" value="Apply"/>
        <br/>Show: <input type="checkbox" id="filter_global_prefs" onChange="updateFilter()" checked /> Global preferences
        <input type="checkbox" id="filter_context_prefs" onChange="updateFilter()" checked /> Profile-specific preferences
        <input type="checkbox" id="filter_context_settings" onChange="updateFilter()" checked /> Site settings <sup>[*]</sup>
        <br/><input type="button" id="clear_button" onclick="doClear()" value="Clear"/>
        <input type="button" id="pause_button" onclick="togglePause()" value="Pause"/> <sup>[**]</sup> Filtered out: <span id="filtered_ct">0</span>
        <input type="button" id="reset_button" onclick="doFilterReset()" value="Reset"/>
        <p class="foot">
          * Site settings are stored in the Profile-specific <span class="mono">profile.content_settings</span> preference and can be modified via chrome://settings/content.
          <br/>** Events will not be displayed or filtered out while processing is paused.
        </p>
      </form>
    </p>
    <div id="messages" onMouseDown="doPause()"></div>
    <div id="temp-message"></div>
  </details>
</body>
</html>
 �      �� ���    0 	        <html>
<head>
<title>Dialog Test</title>
<style>
#loading {
  display: inline-block;
  width: 10px;
  height: 10px;
  border: 3px solid rgba(0,0,0,.3);
  border-radius: 50%;
  border-top-color: #000;
  animation: spin 1s ease-in-out infinite;
  -webkit-animation: spin 1s ease-in-out infinite;
}

@keyframes spin {
  to { -webkit-transform: rotate(360deg); }
}
@-webkit-keyframes spin {
  to { -webkit-transform: rotate(360deg); }
}
</style>
<script>
function show_alert() {
  alert("I am an alert box!");
}

function show_confirm() {
  var r = confirm("Press a button");
  var msg = r ? "You pressed OK!" : "You pressed Cancel!";
  document.getElementById('cm').innerText = msg;
}

function show_prompt() {
  var name = prompt("Please enter your name" ,"Harry Potter");
  if (name != null && name != "")
    document.getElementById('pm').innerText = "Hello " + name + "!";
}

window.onbeforeunload = function() {
  return 'This is an onbeforeunload message.';
}

function update_time() {
  document.getElementById('time').innerText = new Date().toLocaleString();
}

function setup() {
  update_time();
  setInterval(update_time, 1000);

  if (location.hostname != 'tests' && location.hostname != 'localhost') {
    alert('Parts of this page can only be run from tests or localhost.');
    return;
  }

  // Enable all elements.
  var elements = document.getElementById("form").elements;
  for (var i = 0, element; element = elements[i++]; ) {
    element.disabled = false;
  }
}

function show_file_dialog(element, test) {
  var message = 'DialogTest.' + test;
  var target = document.getElementById(element);

  // Results in a call to the OnQuery method in dialog_test.cpp
  window.cefQuery({
    request: message,
    onSuccess: function(response) {
      target.innerText = response;
    },
    onFailure: function(error_code, error_message) {}
  });
}

window.addEventListener('load', setup, false);
</script>
</head>
<body bgcolor="white">
<form id="form">
Click a button to show the associated dialog type.
<br/><input type="button" onclick="show_alert();" value="Show Alert">
<br/><input type="button" onclick="show_confirm();" value="Show Confirm"> <span id="cm"></span>
<br/><input type="button" onclick="show_prompt();" value="Show Prompt"> <span id="pm"></span>
<br/>input type="file" (.png): <input type="file" name="pic" accept=".png">
<br/>input type="file" (image/*): <input type="file" name="pic" accept="image/*">
<br/>input type="file" (multiple types): <input type="file" name="pic" accept="text/*,.js,.css,image/*">
<br/>input type="file" (directory): <input type="file" webkitdirectory  accept="text/*,.js,.css,image/*">
<br/><input type="button" onclick="show_file_dialog('fop', 'FileOpenPng');" value="Show File Open (.png)" disabled="true"> <span id="fop"></span>
<br/><input type="button" onclick="show_file_dialog('foi', 'FileOpenImage');" value="Show File Open (image/*)" disabled="true"> <span id="foi"></span>
<br/><input type="button" onclick="show_file_dialog('fom', 'FileOpenMultiple');" value="Show File Open (multiple types/files)" disabled="true"> <span id="fom"></span>
<br/><input type="button" onclick="show_file_dialog('fof', 'FileOpenFolder');" value="Show File Open Folder" disabled="true"> <span id="fof"></span>
<br/><input type="button" onclick="show_file_dialog('fs', 'FileSave');" value="Show File Save" disabled="true"> <span id="fs"></span>
</form>

Observe page responsiveness:
<br/><br/>
<table><tr>
<td valign="top">
CSS:<br/><div id="loading"></div>
</td>
<td>&nbsp;</td>
<td valign="top">
JavaScript:<br/><div id="time"></div>
</td>
</tr></table>
(JavaScript will stop updating while alert/confirm/prompt is displayed)
</body>
</html>
   �      �� ���    0 	        <html>
<head>
<title>Draggable Regions Test</title>
<style>
html, body {
  height: 100%;
  overflow: hidden;
}
.draggable-title {
  -webkit-app-region: drag;
  position: absolute;
  top: 0px;
  left: 0px;
  width: 100%;
  height: 34px;
  background-color: white;
  opacity: .5;
}
.content {
  margin-top: 34px;
  background-color: white;
}
.draggable {
  -webkit-app-region: drag;
  position: absolute;
  top: 125px;
  left: 50px;
  width: 200px;
  height: 200px;
  background-color: red;
}
.nondraggable {
  -webkit-app-region: no-drag;
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 50px;
  height: 50px;
  background-color: blue;
}
</style>
</head>
<body>
  <div class="draggable-title"></div>
  <div class="content">
  Draggable regions can be defined using the -webkit-app-region CSS property.
  <br/>In the below example the red region is draggable and the blue sub-region is non-draggable.
  <br/>Windows can be resized by default and closed using JavaScript <a href="#" onClick="window.close(); return false;">window.close()</a>.
  </div>
  <div class="draggable">
    <div class="nondraggable"></div>
  </div>
</body>
</html>   �      �� ���    0 	        <html>
<head>
<title>Render Process Hang Test</title>
<style>
#loading {
  display: inline-block;
  width: 10px;
  height: 10px;
  border: 3px solid rgba(0,0,0,.3);
  border-radius: 50%;
  border-top-color: #000;
  animation: spin 1s ease-in-out infinite;
  -webkit-animation: spin 1s ease-in-out infinite;
}

@keyframes spin {
  to { -webkit-transform: rotate(360deg); }
}
@-webkit-keyframes spin {
  to { -webkit-transform: rotate(360deg); }
}

#hangtime {
  width: 40px;
}
</style>
<script language="JavaScript">

function setFormEnabled(enabled) {
  var elements = document.getElementById("form").elements;
  for (var i = 0, element; element = elements[i++]; ) {
    element.disabled = !enabled;
  }
}

function updateTime() {
  document.getElementById('time').innerText = new Date().toLocaleString();
}

function setupTest() {
  // Retrieve the currently configured command.
  // Results in a call to the OnQuery method in hang_test.cc
  window.cefQuery({
    request: 'HangTest:getcommand',
    onSuccess: function(response) {
      document.getElementById(response).checked = true;
      setFormEnabled(true);
    },
  });
}

function setup() {
  // Disable all elements.
  setFormEnabled(false);

  updateTime();
  setInterval(updateTime, 1000);

  if (location.hostname == 'tests' || location.hostname == 'localhost') {
    setupTest();
    return;
  }

  alert('This page can only be run from tests or localhost.');
}

// Send a query to the browser process.
function sendCommand(command) {
  // Set the configured command.
  // Results in a call to the OnQuery method in hang_test.cc
  window.cefQuery({
    request: 'HangTest:' + command
  });
}

// Hang the render process for the specified number of seconds.
function triggerHang() {
  const delayMs = parseInt(document.getElementById('hangtime').value) * 1000;
  const startTime = performance.now();
  while(performance.now() - startTime < delayMs) {}
}

</script>

</head>
<form id="form">
<body bgcolor="white" onload="setup()">
<div>Use the below controls to trigger a render process hang.</div>
<br/>
<div>Hang for <input type="number" id="hangtime" min="1" max="99" step="1" value="20"/> seconds.</div>
<br/>
<div>Action after hanging for at least 15 seconds:</div>
<br/>
<div><input type="radio" name="command" id="default" value="default" onclick="sendCommand('setdefault')"/>
<label for="default">Default behavior (Alloy style: Wait; Chrome style: show "Page unresponsive" dialog [1])</label></div>
<div><input type="radio" name="command" id="wait" value="wait" onclick="sendCommand('setwait')"/>
<label for="wait">Wait</label></div>
<div><input type="radio" name="command" id="terminate" value="terminate" onclick="sendCommand('setterminate')"/>
<label for="terminate">Terminate the render process [2]</label></div>
<br/>
<div>[1] The "Page unresponsive" dialog will be auto-dismissed when the hang ends.</div>
<div>[2] After termination the browser navigates to the startup URL or shows an error page.</div>
<br/>
<div><input type="button" value="Trigger Hang" onclick="triggerHang()"/></div>
</form>
Observe page responsiveness:
<br/><br/>
<table><tr>
<td valign="top">
CSS:<br/><div id="loading"></div>
</td>
<td>&nbsp;</td>
<td valign="top">
JavaScript:<br/><div id="time"></div>
</td>
</tr></table>
(JavaScript will stop updating during the hang)
</body>
</html>
   .1      �� ���    0 	        <!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8" />
    <title>IPC Performance Tests</title>
    <script src="https://cdn.plot.ly/plotly-2.26.0.min.js"></script>
    <style>
      body {
        font-family: Tahoma, Serif;
        font-size: 10pt;
        background-color: white;
      }

      .left {
        text-align: left;
      }

      .right {
        text-align: right;
      }

      .positive {
        color: green;
        font-weight: bold;
      }

      .negative {
        color: red;
        font-weight: bold;
      }

      .center {
        text-align: center;
      }

      table.resultTable {
        border: 1px solid black;
        border-collapse: collapse;
        empty-cells: show;
        width: 100%;
      }

      table.resultTable td {
        padding: 2px 4px;
        border: 1px solid black;
      }

      table.resultTable > thead > tr {
        font-weight: bold;
        background: lightblue;
      }

      table.resultTable > tbody > tr:nth-child(odd) {
        background: white;
      }

      table.resultTable > tbody > tr:nth-child(even) {
        background: lightgray;
      }

      .hide {
        display: none;
      }
    </style>
  </head>

  <body background-color="white">
    <h1>IPC Performance Tests</h1>

    <table>
      <tr>
        <td>
          <p>
            There is no progress indication of the tests because it
            significantly influences measurements. <br />It usually takes 15
            seconds (for 1000 samples) to complete the tests. <br /><b>AL</b> -
            ArgumentList-based process messages. <b>SM</b> -
            SharedMemoryRegion-based process messages.
          </p>
        </td>
      </tr>
      <tr>
        <td>
          Samples:
          <input
            id="sSamples"
            type="text"
            value="1000"
            required
            pattern="[0-9]+"
          />
          <button id="sRun" autofocus onclick="runTestSuite()">Run</button>
        </td>
      </tr>
    </table>

    <div style="padding-top: 10px; padding-bottom: 10px">
      <table id="resultTable" class="resultTable">
        <thead>
          <tr>
            <td class="center" style="width: 8%">Message Size</td>
            <td class="center" style="width: 8%">AL Round Trip Avg,&nbsp;μs</td>
            <td class="center" style="width: 8%">SM Round Trip Avg,&nbsp;μs</td>
            <td class="center" style="width: 10%">Relative Trip Difference</td>
            <td class="center" style="width: 8%">AL Speed,&nbsp;MB/s</td>
            <td class="center" style="width: 8%">SM Speed,&nbsp;MB/s</td>
            <td class="center" style="width: 10%">Relative Speed Difference</td>
            <td class="center" style="width: 8%">AL Standard Deviation</td>
            <td class="center" style="width: 8%">SM Standard Deviation</td>
          </tr>
        </thead>
        <tbody>
          <!-- result rows here -->
        </tbody>
      </table>
    </div>

    <div id="round_trip_avg_chart">
      <!-- Average round trip linear chart will be drawn inside this DIV -->
    </div>

    <div id="box_plot_chart">
      <!-- Box plot of round trip time will be drawn inside this DIV -->
    </div>

    <script type="text/javascript">
      let tests = [];
      let box_plot_test_data = [];
      let round_trip_avg_plot_data = [];

      function testSendProcessMessageResult(
        testIndex,
        fromRendererToBrowser,
        fromBrowserToRenderer
      ) {
        const test = tests[testIndex];
        const roundTrip = fromRendererToBrowser + fromBrowserToRenderer;
        test.totalRoundTrip += roundTrip;
        test.sample++;
        box_plot_test_data[testIndex].x.push(roundTrip);

        setTimeout(execTest, 0, testIndex);
      }

      function sendRequest(size, testIndex) {
        window.testSendProcessMessage({
          size: size,
          testId: testIndex,
        });
      }

      function sendSMRRequest(size, testIndex) {
        window.testSendSMRProcessMessage({
          size: size,
          testId: testIndex,
        });
      }

      function getStandardDeviation(array, mean) {
        const n = array.length;
        if (n < 5) return null;
        return Math.sqrt(
          array.map((x) => Math.pow(x - mean, 2)).reduce((a, b) => a + b) /
            (n - 1)
        );
      }

      function execTest(testIndex) {
        const test = tests[testIndex];

        if (test.sample >= test.totalSamples) {
          setTimeout(execNextTest, 0, testIndex);
        } else {
          test.func(test.messageSize, test.index);
        }
      }

      function column(prepared, value) {
        return (
          "<td class='right'>" + (!prepared ? "-" : value.toFixed(2)) + "</td>"
        );
      }

      function relativeDiffColumn(prepared, value, isBiggerBetter) {
        if (!prepared) return "<td class='right'>-</td>";

        const isPositive = value > 0 == isBiggerBetter;
        return [
          "<td class='right ",
          isPositive ? "positive" : "negative",
          "'>",
          value > 0 ? "+" : "",
          value.toFixed(2),
          "%</td>",
        ].join("");
      }

      function displayResult(test) {
        const id = "testResultRow_" + test.index;

        const markup = [
          "<tr id='",
          id,
          "'>",
          "<td class='left'>",
          test.name,
          "</td>",
          column(test.prepared, test.avgRoundTrip),
          column(test.prepared, test.avgRoundTripSMR),
          relativeDiffColumn(test.prepared, test.relativeTripDiff, false),
          column(test.prepared, test.speed),
          column(test.prepared, test.speedSMR),
          relativeDiffColumn(test.prepared, test.relativeSpeedDiff, true),
          "<td class='right'>",
          !test.prepared || test.stdDeviation == null
            ? "-"
            : test.stdDeviation.toFixed(2),
          "</td>",
          "<td class='right'>",
          !test.prepared || test.stdDeviationSMR == null
            ? "-"
            : test.stdDeviationSMR.toFixed(2),
          "</td>",
          "</tr>",
        ].join("");

        const row = document.getElementById(id);
        if (row) {
          row.outerHTML = markup;
        } else {
          const tbody = document.getElementById("resultTable").tBodies[0];
          tbody.insertAdjacentHTML("beforeEnd", markup);
        }
      }

      function buildTestResults(tests) {
        testResults = [];

        let oldRoundTrip = {
          x: [],
          y: [],
          type: "scatter",
          name: "ArgumentList",
        };

        let newRoundTrip = {
          x: [],
          y: [],
          type: "scatter",
          name: "SharedMemoryRegion",
        };

        for (let i = 0; i < tests.length / 2; i++) {
          const index = testResults.length;

          const test = tests[i * 2];
          const testSMR = tests[i * 2 + 1];

          const avgRoundTrip = test.totalRoundTrip / test.totalSamples;
          const avgRoundTripSMR = testSMR.totalRoundTrip / testSMR.totalSamples;
          const relativeTripDiff =
            ((avgRoundTripSMR - avgRoundTrip) / avgRoundTrip) * 100;

          // In MB/s
          const speed = test.messageSize / avgRoundTrip;
          const speedSMR = testSMR.messageSize / avgRoundTripSMR;
          const relativeSpeedDiff = ((speedSMR - speed) / speed) * 100;

          const stdDeviation = getStandardDeviation(
            box_plot_test_data[test.index].x,
            avgRoundTrip
          );
          const stdDeviationSMR = getStandardDeviation(
            box_plot_test_data[testSMR.index].x,
            avgRoundTripSMR
          );

          testResults.push({
            name: humanFileSize(test.messageSize),
            index: index,
            prepared: true,
            avgRoundTrip: avgRoundTrip,
            avgRoundTripSMR: avgRoundTripSMR,
            relativeTripDiff: relativeTripDiff,
            speed: speed,
            speedSMR: speedSMR,
            relativeSpeedDiff: relativeSpeedDiff,
            stdDeviation: stdDeviation,
            stdDeviationSMR: stdDeviationSMR,
          });

          oldRoundTrip.x.push(test.messageSize);
          newRoundTrip.x.push(test.messageSize);
          oldRoundTrip.y.push(avgRoundTrip);
          newRoundTrip.y.push(avgRoundTripSMR);
        }

        round_trip_avg_plot_data = [oldRoundTrip, newRoundTrip];
        return testResults;
      }

      function buildEmptyTestResults(tests) {
        testResults = [];
        for (let i = 0; i < tests.length / 2; i++) {
          const index = testResults.length;
          const test = tests[i * 2];

          testResults.push({
            name: humanFileSize(test.messageSize),
            index: index,
            prepared: false,
          });
        }
        return testResults;
      }

      function prepareQueuedTests(totalSamples) {
        if (totalSamples <= 0) totalSamples = 1;

        tests.forEach((test) => {
          test.sample = 0;
          test.totalRoundTrip = 0;
          test.totalSamples = totalSamples;
        });

        testResults = buildEmptyTestResults(tests);
        testResults.forEach((result) => displayResult(result));

        round_trip_avg_plot_data = [];
        box_plot_test_data.forEach((data) => {
          data.x = [];
        });
      }

      function queueTest(name, messageSize, testFunc) {
        const testIndex = tests.length;
        test = {
          name: name,
          messageSize: messageSize,
          index: testIndex,
          func: testFunc,
        };
        tests.push(test);

        box_plot_test_data.push({
          x: [],
          type: "box",
          boxpoints: "all",
          name: name,
          jitter: 0.3,
          pointpos: -1.8,
        });
      }

      function execNextTest(testIndex) {
        testIndex++;
        if (tests.length <= testIndex) {
          testSuiteFinished();
        } else {
          execTest(testIndex);
        }
      }

      function execQueuedTests(totalSamples) {
        prepareQueuedTests(totalSamples);
        // Let the updated table render before starting the tests
        setTimeout(execNextTest, 200, -1);
      }

      function setSettingsState(disabled) {
        document.getElementById("sSamples").disabled = disabled;
        document.getElementById("sRun").disabled = disabled;
      }

      function testSuiteFinished() {
        testResults = buildTestResults(tests);
        testResults.forEach((result) => displayResult(result));

        const round_trip_layout = {
          title: "Average round trip, ms (Smaller Better)",
        };
        Plotly.newPlot(
          "round_trip_avg_chart",
          round_trip_avg_plot_data,
          round_trip_layout
        );

        const box_plot_layout = {
          title: "Round Trip Time, ms",
        };
        Plotly.newPlot("box_plot_chart", box_plot_test_data, box_plot_layout);
        setSettingsState(false);
      }

      function humanFileSize(bytes) {
        const step = 1024;

        if (Math.abs(bytes) < step) {
          return bytes + " B";
        }

        const units = [" KB", " MB", " GB"];
        let u = -1;
        let count = 0;

        do {
          bytes /= step;
          u += 1;
          count += 1;
        } while (Math.abs(bytes) >= step && u < units.length - 1);

        return bytes.toString() + units[u];
      }

      window.runTestSuite = () => {
        Plotly.purge("round_trip_avg_chart");
        Plotly.purge("box_plot_chart");
        setSettingsState(true);
        const totalSamples = parseInt(
          document.getElementById("sSamples").value
        );
        execQueuedTests(totalSamples);
        return false;
      };

      for (let size = 512; size <= 512 * 1024; size = size * 2) {
        queueTest(humanFileSize(size) + " AL", size, sendRequest);
        queueTest(humanFileSize(size) + " SM", size, sendSMRRequest);
      }

      const totalSamples = parseInt(document.getElementById("sSamples").value);
      prepareQueuedTests(totalSamples);
    </script>
  </body>
</html>
  .      �� ���    0 	        <html>
<body bgcolor="white">
<script language="JavaScript">
var val = window.localStorage.getItem('val');
function addLine() {
  if(val == null)
    val = '<br/>One Line.';
  else
    val += '<br/>Another Line.';
  window.localStorage.setItem('val', val);
  document.getElementById('out').innerHTML = val;
}
</script>
Click the "Add Line" button to add a line or the "Clear" button to clear.<br/>
This data will persist across sessions if a cache path was specified.<br/>
<input type="button" value="Add Line" onClick="addLine();"/>
<input type="button" value="Clear" onClick="window.localStorage.removeItem('val'); window.location.reload();"/>
<div id="out"></div>
<script language="JavaScript">
if(val != null)
  document.getElementById('out').innerHTML = val;
</script>
</body>
</html>
  �]      �� ���    0 	        �PNG

   IHDR  y     ??�l   	pHYs     ��   tEXtSoftware Adobe ImageReadyq�e<  ]fIDATx��	x\�u�{
� �	��"�"@q_$�Z�͋;��N�����%3;_�e2����9��d�%yv&�8��3���L��s�ĖdG�%K"�R�bq��\� 	�]��v�۵�Z���@w�����uo���u��/�%@AAAA�t�Z�<T�|���������������� OAAAAA������ �SPPPP�)((((�y



�<A�����������@�Y�<��}����ɳCp��Š��;�'�%����yӌ��s�CǤ6�)y�� P>x�\	�g/o�_�������l'>W�W����+�N���ݝ0yb+,�7�: 

�<EtU���`��S�@m>����=c����9���I��A��uN����#�/.��93�i�SP�������OFꜱt
�� ��[0�s������[��=a���>�>Vtώ�~	��頠��;��OU�l�8qv^}���.��@����U�s��K�r�{�G���������Ņ�>A� �j�Go�W���,�e����L���{�g������7.����'�OA�����u�d�]E�g�`��w'�Y�N�Kyl�P�g}��O����u�|
�<�)���Y�����k��o�5`�`�s�m�Ϥ�S�$�߿�'�>Y:y���॑�b?�n?e�0�)oS��`wC�|�B��z�����k}7�y�|B�1��.,	ݵ��v��ʠ,3�g�=��Q(���ȇ`ø�X�����M=�I�S�)2��W�:��hwɎQ�n�� �K�W�I|ܫ�C@���Өy=�ʾxY���\
�<��m��m�W�cG8�W��,�
�i����n'h���z�m�S���X�=>|�"��ЁLA��P���<\T��%�A5����;�� ����6{��l�j�k=��i+`���t`S�	�%��]�k�*ˢ���w	�h��w����{A�V�Y�y���0���ݻ6/_@:A~��}�A��C>oϘG���;a�������g�������ơ ȏ������|w�� ��Uc<Bn��.,�_�A�y~j>O���l���;��Ϗ����C����eU�}��u�.�k�;P��I�kg�0���\HLܒ��d ��h���g���4���fk�,o��O����E������&����|3�3o�o?[I�d�J�9��*�|.V�mL�Y��;Tn�*�.17�*y�e���k��(��?񁍰y����6�������h2��C�FI��8<��6`Cu��g�[�?l��!V��ܷ^����,,
R�f��.�C�Pҙ^�3 S���C��`�z򕳂��䱿S����7��G�ZI?
R���v�Ի��^i���x����H�3�WL��w���4ʬڜ�Z��|_<ti���.�Z<v>��FX�5�~H���Q���W���%m��Sd�(�[�"�4J˗fi��f��;'��'�)y�lE{H,d"��oYF?*
R���޿��+��j`��4�G|�ʝ�6K���$"ң�f:��?�{r�*�U��Yڠ*���<���ľ��8����v��ӣ�{�x+e�P��k���Ƿ�3�	M����գ��]g=���,����Q��U��x��w|��	m�{�V/�IT��j5v�s~�?	Ok����Z���|?�x�_��Cu�4���Bki�V���@�[���מ�o>��~pd׌f�A2q��`��Rz"�͢AI��������n����){©J��o_ZO��[���!����?���f�X�D�Gɾ� �������/���,�F�����Rb@z�f���t�(�n�+C�e�D�H�!���8p����2�j]Wf�H�~����:ʾ� ��ƞ��"���%	X��^oނԬ��|X������J�_x��޻�N�r�WtϮܟ�=��"ܢ�\�Ol{��l�����I���^��������K�J���_�_}|;��?S�Vz�C���7
�m0�^@[ |ŵ����EU�ī��N`g��� �B�i&z�S��.�K/|��D&��b\z���Ƕ��opL.�~���~��UO�)�%��Led�P<z�{�uWp��ˬ�)T�hxϫ�q��\�P��j�ǘ3�#�ȥ�űs��,�(��Q�L�m��/�l��߿:&�OOAJ>�?��g#Uf�\���j۸��j}�}�ga�j���o\��]\˥�BX~�~z4�� ������aI�t����&�S����}E�?cLn�A��R��>�Y���&G@߲ftׁ�2Zq|`��>V��	��^��Jz� ���K��ܙT䌂 v�/|��hP�! �Sym��Y ���}(����r)���qv�Y�ӯ�.��1T��2�KgAm����ΟI�� ����ށ/��ˈP�C�a@�}6���E��e������~Q�/`�T�R��1S7eϓN�40����{�y,��Ԏ��BuPҩ�`��ng�}(�@_�1�nZ����<�Z���Y�`��;'$�C~����cb��)�j��#[#����H-Л�˜ ���P�߾�1x��-��JR����(
Q�x�Ⱒ�U�z�����E�� ȋ��"��|�RLZ��1�lӜA�S��?�(���f���,�9u����! ����?��.\�@��8�Z�O~�ݰt��bC�/~�����K������q���~�R;����"�}�-�P���we0�O~���C���������N�6v�Oo߄��b��h����;�c"ؿ���{�#��?����)����_,���������y��S�9�>���A�@��������a��'���Oˠ/>�q���_E?����!��𯾭���V����g�~o|;���7^?�~u�g.�K�}ŧ/�߈�R_�w�)43���!���z~X|�&YЧ�o2��j`
|�Y1�w����+��P��C����U�+B?Y��H}�m��^=EsB��ߌ/�|�A�Y�� �fc�����o~�F�3�|�F�p���n�������΅����@F4t�/?�2<����quG^.�D� |t奐J+&���$/^���\ɣ�*=&�T`�U��O�U_V[���KW1�퓷U�Gx@�2��q����7-'k��B��_y�:�u�"��?� {�����7��/}�����B��]������#EECQ�>���l2�$ن'y���B�N5O��� �%P�;��t�YK�"k�r����S9�2�M�t�x}��'�%�7x���/����W߻6�q��R�
��V�o�����ꝗ��4��P�\R�٦$�c�����j�W�D�+�ۥ�qǭ�Qu�T�R>��En��߹�����&��ݻ>t���7������!o���!���i���4��֐m�@��d�$+� �M���� _,��}�1+���?$�]2ozdψҵ�i����+�!(�}�/�����0��@���y�gg��Hp	�_���ӗ�q�S��z�U�=��}�_I�;��v4�g������ґNAA�����������#8�l-�,�ek&� 9 epTU/U����4�����:Խ�:�;&�Ep�k�b:�)(�����EVM"}�j:Q�RVMb��V�>=��c����[8���jPZ�ٽ��Y:bb��~�fX�5��p

�|�������!I�V��(�@���b� ���!�1GF6��r�woZ:�G�r��-�1��((( �Ͻy~v����P��_V߸O�cpU��<�[8�U�z9��y����ޡ�Eܹn1|���tTSPP4�=#l[p۠��iT�dh���昲wZ9	���a�|�Ε�(Â���A /Z�E&�/���ZP|�R�eU��V>sP�z����r��k[1��z��X)((	�_yt싦l�Eq��0UoS�ט���6��m�v���u����)((��v����+0abL�^<+� eϾ����R��3`/�{�,@�P�P�^�/�������}���x

����y)��<��.ä���^/��1��%�c3a��7<�>f唞I|�Xħ�N��R$)((����Nxy������%`-&�L	�#�ג)�J�@��M����S��$���)((�C�W��Ͻm<>x�bt=1C�j�he0kK��պÚ1_��{��4`� ��zݿ� OAAuUj����aڼE��ڊ�~d�J����.�Vn��P��}zs[�l�)V���砟˥��{�J�����K訥��h<�>}	���	hmk�%=K�m.��+W�f��2�c��a*���ux�w _�4�Z���>�� OAAѸ�d[_iپ�{�b�2u*
����
{p�޼pߦ��� �
�{��]+	�����������}���V@����֚pt �g
�+��N��^"E��YMG*EcB^�F*J9쬄y�5{̙;�
��sCP(�\���;�X3�¼`S�c�׿�%�f�o��Mt�RPPd�1Ϯ���F
�J��n._�N?�����B��Θ--,'ؗ�{h�����'OS��L�D�J�v��h�?���MyЉ�_�%4�fM�.�S���֒_Q�1�'O�=�z`ߞ}�z�(�պ8f��:��N#��,����5eb+��_�Ұku�����3�"s����f����V�.��ע�6�tE���u�G��� ��x(�7��[G��/:A?}��ܿ���ǳaU^~m��րW0�;�_��t�̆8����"��v�zCYB�{c_t;����<߳`f���`CoWM�/:�Ƕ�%zxBt�b��m���f�߹�f�n� ��o�<t��tD�ǀlk+*��{��7޴�� ��sC��ܤW�J]�s�Y>���s�Rx�ƥum��?����uH����Ɉ��/Q�4[�tG�y�>����Dq_��A�ةƝz3�H��w5��Ƣ�U`��څp��8}���D��Z��T�P��hc��,��D��_�̍u	v�x����Z��B��U��ń��i���(�/��)DS^��C~��s��o��♦����˖��K?��|��}E��fL��0h�P)YW������n�#|��ͤ�D'���x>ZRR����6Р.E]�X?���ps@��m���O�/K���9;R��~��E�2yT��d�l��pՆ)��3v**��߳��2�~�P��o?�3�@�͊�[�?�m_ԩ��)M�b�C$&����7�66��ħ�F�^���6V�]}}�pe�]��rQ���^���Y�
��5�;�΃�1�K�	����#�������7�𐏽x��p�����	mm���:xk��R��re-��[8� �P��}�;R	9�Ð���^�<Es��Q����C�3D���W�X���C�
��R����1���.|iܙ����,sП�Y>9���X�3�_)�^͏*���	
��]�K�^�s������^��z�느�s��H��^j[f(u�g|t}20$��O�-�I�Sԫ��3�f� ���	��^<(����9���ؓ'O}�Ѕ�pM�5�O_O���eT?O���82�
uf93v������S�v[+�\sȓOQ�!�����(SU<��5��M��m�+W��v��QM���7>�]�_��P[�[�u��m)?V�_�͒��v-��B/������ �3��]��#�$EAQ�!lTa�6���7�C�����h������fvD�٣�@���~����,@5�+���.�R�8@�$\�_�|��V�od�g���������|Jg�
���q�5]]��5�	JO�Z�����z�h�e{�������
\m`�!ۢ)�������jQ���L�E�����h�$%��}�Ri7���Y�;P��,�<�枼�QSR�ّ#Z��t&O�7��m�^O�鳦�Z�24DF��i9ȟ}��Q;�ă�ҵˏg҃6�9�j�Γ���,h��1/X�!ԜJ�1����`��Fe�ճK�T}�\cx��7����VN�b�L�j������\e�]�Ů�2����%�]{�쇁�s�A�w���毿���.?��3#kU�
���Rm�R��%�X�p.�t�3pdسr��j�$�z+Kl��p����VEC��<m>���9֡Z;U��5���&��B�������kj׈z�{���6LFD�3P�x�Ͽ�5��[\�8�եB��=5W������v9@���Ńy�oʺ�g�]`Ӵ0�@mv��^T|,r�J��Z��o�Jk�/�xIKŢ��QK��@ZFoLd,�����m��Y���V�iQ���^�ڞ�~T]�5�������
{�[Uj�̝�	v��#}�@?Z���*^ ����GHgII���v��u��)�Ԏ�V=?�UK��*{��˭O�<ˤ:�ڏW���ҙ<W��ފ�$������%Gng��W
c�rzk��;iG��5nԳU�~Ҟ�Ev܊��j-��A^�ݺ��y�uaȠ�_��q�Ƶp��I�Ե+�_˔��q�)C^��t�KQ; �u�:�]���SXŦQ�����b�'\8��R�+�D�|�V��O�6�nMH�Q�E˦�7b['z�1a��L�c���kcn{ܱb(Sơ�߇��k7T���5"m���U[�[��)v�稜z�vʔ�vX��'�w--:2X���*>�+�������,�-�͂�֑�Q�	 �zZ�L������9 �QO~,JW��m���'�Z0-M�d�����jQ۽ޕ{��l�R{u{L� �-�$K�E�iT�F��Z�k-����eS3%���Sv��W@�:���C��X����?��C���b�T�Z��T�_��A�-�R�ԡm��m��������'���Y�	�lˈ%e�%͚��7���v�:$�N�<�T�����+R޶���<c��+͸�9~�V^��T=�֘m	���q�p�'$�dr�ģ�V�U��t,s�}1e/�lD!�������&/��Y5��IL�����e�6ظqm��/:�w���jbV���`���A�tb�s��ߘ�� ��5	�E��ΖE����i��Ï��9�ev�ׂ(ui�U�HJ��]z�Ђ�!����lmNE����N(��� : sF�Y���Q˦����jp�������뮽v~4{��dU��Kы��Z����/�eͶ`��C���(rP1�����2�:gz;̝���̉�
,�=.n_W�����v�@"����̅h J\�=���*���qE?ZJ�f'1���|�$+|�L�66��{�ȍ��GL����0&��z7�����YkE�k-�"Wޙ��v�-q0SY_�ח�2e��򌥴j p��2����TT����SU+�<@_/ �ٯ?U����m�L����������"�K��"��+���k��������ㅻ���//S�N���3���}!�2��v�&~~�����*x<.=$%z�$3D��NV<�����<ϕ�"�f�v�C7f˲�;��m!D�%�,��'W�@nO�>3ڴ|��\~�CUulr��X�5�z�U���3��O�5k:,]���SЋI7�����o�8R�i�"��a��q�����{a����1�q�m���cbAd��w�|L��V�t�(M=����@p�d=��w�r�oX�x��i��!����U[5v���M��¡C�`d$�:���/g�E_/f��x�a�Lc
`��4dq�+ؼ|>��w���2n_smt�ă�"K��b{=����ک��^,��x�A�����)<c{��ֶ��&k�\!/f�>})�O�Z5�1����Q��6�֯�W^~�����EG�^�Q(ӿ��c�6��;�i`�U�;�@�Xs՞%�X���v����(׸VJ�d�1;aӏ�b�5=���uz{Wӑ6c��\!/&?��#�co�1��0c���K͕+{`��}�R*��H������7_(��v[@���g�{
����-�ls�b?�j.?�-�(e'L�_w���L�u<i�w����j��7 ���x�3�����O<W�ߖ�[�����x�!���q#k�����J��&3l���Vx�3J}�����!l�����\s8�m����U�T<�:6!t7�1?��������)�Y@_��/������S�-��Y�ni���m�~ᖆP��f����#��M�{T<2��O[7Y��6*�Sc�労2�+B�r	B\��o�rcn&@/c�*>g��	O��l�j���0����.�7������6�_���j��M��g��5�+��PJ��V	�zA��f��5��/��`�� v��Y�V���)SڣA�<A?2l/����+�c���nӎ	<C�t���=1"`I�t�ÏmI����2�\!˷o�Eo�t��a�t��ѕYҐ�#��]m��k�\ ��09s�e\Z]c�תqHvf�V�ꁶ	m���� ��`�R|���`��j�x�V�۲ý�٪%����J�7�]����'mLp7�|�vfH�[�L�5�U��E�w���0��2��p��e߈���7�ͭ�l���iՔT�O�ѧ1��7�z�.��X2o:��Gn&��RQ�N� Q��0�^=�L���w�̬	�.��u�mũL 3�@��̭�������3gM�)��jDu�D��vE�<ׂ&�E��O��w�5���ޙ��`.�,�����!��3�r���&k?ޝ:�ɪ��.sU�:�E��\���5������#g����ݏ�B�wB�w�V�����+�{]��vfh;�"���k��ؠ����7��IWn}
��!R*����o]�0��y�"�,>����'D�U��E��wy�b��¡S�Rǲ�`ԍ˾r�]�5б^��aꝅ�Œ]��� �� ��D�� ��"�U#?�~Ê\acЯY�_z�_y�i��������/}�(S��M=D�Y!3:`}?������!�K��;R�� CD����P8A>R�}C��bϏ���G�-u2�bw���vX�*�mZ�(���/�<���#Pq@�
x �R�����D� ����0���*K��7���Ξ�)C:a �E��`��+1t�j4�U:�tgX�������rutL�o���Sa�i9����Q���z��x0���߱��h'�^Ii��H`�/
l��Ac��o��b6�jQ�pgM�U��� �<��=��׺	��]ON��7ݜ� l^*>���o�:T�!� �Q��~�i2@�i���$�Y o��Ie.��K�8����^e�f0@M3���u����R'}V��i���0��3ȯ�g�UX5���1R� ˦A}x���H"��e�P��5j6�.���x�̊´�T�cZa��oX�x'�׹!�ǐ���@�נa��u�=�ʹ�|���]�o���E� �m�� X�M��3��t�R?�G�k�g.�7;t2��ё��l�S�Wڹ9GA�Q����CZvO,/Ycy�Y��Cϲ�R*��O�9A���Ǎ=pdldU��~��nR����o����~����2ww���l���N���O]Dm�4�eBmS�2��XE�O�"�ryw~��/�:�z�G�{�Ar�n�Hj����O��U��Hq��\w�1kb�g�|�U�������0��F��PG&��# ����U*�t�w�^�ʴy0&�@�^?��L���SdP��N��Dy�LS�AgJ!m��_�<��i�cX聋��U@<�3X��'*I�%D�d�v2�M�4�=���S��c��O�(�}*�Q� 
���L)��Y�2�R�W�jl����ܕm"Ђ�������W�-�,��D��RɇZ�������".Z�>n¾5��^�C��wQ�|�����tB��N�;�n���9�5��G�W�K���J�$�&�qŜ*�9�������?>��s�v\{�s�Y�>�6�>!���)��ه��:�}�o�$�L�3]/_��w�'��,9g߹���Tk�5��o<1�V������5ށ7��(�~��\<��]�Y�7�݋w[.������!�,6�=�H�hs�hW����s	��ܾV*>��w�q*H��+*>d�UW9�ж���-ڛEum���Ο��|>V���g��,��k����?+�I�Ws��s�ÍF���0d�2��C_�tPC�{ǐ�r�pV�tt��-C:��1�zTϢ�� ��gml)�q��P�c=D�����=��+�f�|��I��2!�5yz6��7l\{�:��#޷�kԅK��1`Հ��T|��Q9�|,�
���& S�ُ�'�d<�w�r�UD3`�-��d�:V�f�����FS�;��։>�������޽�:]j�q��c����.���|�$���Xb�^/�L�>�UC��5,�E]�[�f�Nm���!����A���j/�}�y_uN�bd�R��QoL���ѢgX�K����,��=�(/i���Љ2�J�ֶc�`s��L;�c9�m&��5kҌ��I� ˖wG�a�vM>�|�ϐ����������|�aaVR����w�ݫIc�Z���W�A���w�Ǫ	�h�8�ﵮ�f,�i)W���!5Et����"r��sͳa~�% }2�DO/�^x�m~5�W�dT���u�*�^��Y�����*��L�G#�W�.��Z����[7��m �fl�2��׷A;0��u�j�/���=��e~E\e;g��[�S��v]
#>sf����/��%����e�u\��ɪ�kGy̱�cخ�D�b���52���g�,��y],aŲm��D�e�]l�o�=e}��Z6�H[g��&m��a?�5�5�G��Q�yխ9>0h=AN�7���T�,�cŰ��V�YÖVl)Vg;��+u����,��dϩg����F��+�K�f����I� x����p�H��a���ʹ�|^K�v�uj��=�[<���ZL^�y-慩�c�꧀��B��{��:e����`8y�m��Ax�Z�����'=�/���k`,�����ت�=�Gy�+ԟ�:n|�R̺d a�iYY��.��	�2v�ط�oֱ��rvZ=`��7�G�ë��sZjq<�������e�P�R�R��0?�8]�LO�{��2��<��bdP��m�Ųi��fy�/{����������7&B��Yn��f�)R*Em9��:c��(�m�����b�g�G9���ݾV�&��Zs%_��G3��c��X]��5�Q~u�O���M��v��}��s2dŵT��r#�Oc�/��卹���h����`\�&���X|�־��(�o=wF�(C�V4+�|�P��,�=,���M������Pъ���j����y�>��/��o~�����%�-�� ���[�O�������8�a;�W�ΤnD��{:��$G��P����Q����,I�����-m�[�T�9�GAɋٮ͋�q��S*�S=�:�@#��	��� y֓6D9*��.\B����+�*!�^s���q0*Hb)G���Pi�ޞK���oIy�)�-��fp�Y��p���Iډ9�}e�Dxȃ\����\��<������ȎbP�J�H���ڗ�(��%U��y�ٮ"Z�'�-/��G.���e�-�*��G9I���S���xy�2X�ϵMKw����ݙ�Ę�w[5�N=99R���Xn��v�u�6�Q���S<� 4ژ�g6!ggAg���U׮h��j�#�w�u5�x^�?�`�Y�ߙ2T�������DG�`U���q{"�퀜���v[P�c�%�����ư	�����(��ʛ�͏'�g�=k�~�J~���F��V:Oɤ��Wh��}\xy��9��`�G@d8\g미ݿ{�sKG�)a[:)�(p�M�+m\�$��>�]�4v2���:��U�Eݞ�W�fv����� ��M�S�v�U>��X6�����i�ת��
P���X1�	���X���\_�0_F
"
,��Q���4:	�=���.��!��66,Q��6��*�d�æ��x'�j b%���ښ���� �xM���n�y�[��k�H�Ή�C��h�/x@�/z�[�9V�]y	/B~95�o/XNHs�	��ʌU��uq�#O���n)	�1i���5U�?�i ��W�X{�\�%G�T��hd�[P�M^�;O���yN�a��CR�1�f�&��6/�4���v�`���U�gR򳧶�����ۆȨ�C7t���>{	M�T��^��Ps�g�`��j� �V'ck�P��%m�T�zUٶ)�N
�G�d}j���L�ǚ��)���=e�U����=
iY$��.�[�h���-��j^�{��\4@�����Sk����<G���k�0�3
lm��m׌�ד���/�|5���b�U>��<�.���ս�d�d?n�i��U�,yꀜާB��2!��'N�����Sl��X��xrp$�Ϙ7s
�	qU������쯼u����3�e���R�<����1�?�!ϳ�[K�J3�7Tz������W
��1���wiԞ[�L���:��3/����F� U66 y�&p�����~1r���Q�`\C~YWG�}BO^��m�l�Cù}��3��G���1/5/��1�r�y��Y
zP��;S�=�66U}s5zKU-^���B����g������zѶɢ�-@y�G��")�.�|���8ML����ߙbc �l�J���k��Z���<ţ�9�3�8���P~VǺ���\^���`]0�2a�O���h 65�%%���}�~��J���W��y��l��*�C[6䯟�Q=�}�<cQU�L�׈�zb0�f��	�t�0`+�!>��K)(���Oqxp	�|t�h-�oM\�s��#�%w�5a�?�t�͊�*�<��	�N
(��N��R��\�žb55N5����^(yR��.��i)��e�%�����Xx�ڌ'O� �h�$��S,���œ�D�W�9�ʲ�ϲ�&EUM\�s����$�P����$��8��R'���ʐ{@h�HB���I�p��~F�W��	�����u:��T�o������{=/�F�m����Im�7ϵ�!�<*8`n��2�ߺ����6H�	{����O��6�a�hV��z/�)O^R�:d�Z+Ə�V�L��bj�x��q�E�y�|�P���<����gwS���J� �[ H��@��pͺ���M��d���	����p��4�t+���!�����W�ܥ�|�[W/2- i�s4ʚ"��^�X~#11���~��xH��� r�ޣ6)�N8��cN��i�fm�L�W&D9������ʰ�6s&�e�Q�y[6s�Z6�t<$���%�ljƀ=�}��'�Y<�����(�v�I�� _n�B�>�z�C5ۙ7�iS&�Ϟ�Yn�_	4�a�u�5x���|���\w�{7.�Իt
�9Z� ,ӹ�jp5#��g�8@t�B�k�W���j(�]�S8ծ1��m�������F����S'���Չ�.���)_3Aܣڱ�E]��!��w	� �4>��3~����J�N�~A��4��c-D֤����k�N�8��ۙ�����kY���|l٠���3W^r�g�d�tՖM`�4�<Kt͚R��2�S2� �n�z��& zO�,��k�w�J[�vV-2�<�S�N��$�\��V��c��I �3Y6i�<�@�o���W,��! �G����qU)��w�[ �=��
�͎V�oU��u�wf�ϊ|y�~7��:\�&B�6ˆg8���w�b�;g}ϼh��M ��OY}J�ep�Lዏ�
_z���:�`��Ȱ��Z{[N�"����67E�ͤ��o��<3�wd� ��5�_���`�F���j��J^į�w���6@�X7�SV�=�-��O���}�_��� A�`� }!���z�>���PvM0�����Nը<��5�5��ٓ�A��_��׬����m�3����'.�;1J�y19�#���J�l�R1�zQ����Ŭ���ʓ�gvt��Wӛ�=f�ysWD��������QI�@�7���J8q�`p�w�\�g�k�/�Ʋ��������$[ ���S� ����yj&C_L��ֳ�����x�����+�찧(����H�P�޼/�5o��dyA�����-�M���|�|�*<x���y<+Cd�D��1�g=H�0@�ZL�O��C�ٯ�>�g����w`��������#�kz��`,�N�sJ�є|��kW��LXo�fk��j^,gؔ�e��~L����1��x0���։��K~]�۶?�'.�D%�Mj�uG}莕������� � �a��6.o�K<HV�ʷ�WB������;��.�¹kC7ܽ~1̝�1�� ������F���k��]8�&�/u�Ҿ`L�Șt��,J���`@���<��c_��E�q�OZ���h�5[TE��]#��vS?�Fe������k�,��}L��ko���ܰpZ�;J,(��6��/� I��.��姘6��X�]������~	��c��·��]�tM�����%s�K�c{�����7��Ep??4��QD��̅�[71T�v��U�Ǐǟ�}ܢ�����������s�$��]9u�
�CM~������߰�fK��
��P�G�\R����NJ�q�(q�C��N8gP�ΞA�/,��!/b}OWQѯ(���51�L�L�[�c�O�Ym+`���w6�@y�v���"�gD�*Ό��j��30xq�E���u���]��q�����P���,�#���o��P��y:�<��s�:}���Ҽ��I�,2^�ĬB0���x��-�v6<���������+��5ᄨ�=�u������y( j�%�1�.�&����U���n��^���#Q�͜)r�a�xps�T�\ �U7KTC�:c�7�_5hx���q�D4H��vɼ��>�M���J�|��+t*�����-���L�.+Oy��Ǖ�x�s"~XBh����Rx2�e%���p5}�zT�Y:{��í���n6W�j���{pB9LQ��P�\����Ct�jO��ǃ��^���j y%��(�E�i�c��y���^S���`6S�q���XrX�bTf&�jU����u��q���Ǖ�~�[hqG�[2���W�Dع+�E4���JG
r��G�ܩ�m+v�Y9\�l��?(�B,�=yB�rp2�fɸ�@����h�}��ŕ��=��Ȳ鯝�+��Go�2���( �lSy�`IK3���?m���ܙ�>f˘P� G�-5�ͅ�l������,�������]���g�ߥ�e��۸�fo�C`mm���
JB�<�xż��i�fj
�-����b��c����qp���@�
�)跬�.���l�qx�?7d��W��܀�f� ����]=�����1P�xn<т(>��{>8�t �5J�R��n�T�tL �K`�SiK�S+h!�xE-�v�$���b�g��s�IA�
ާ؍�tgm��߿��Y���/���5�N����\A�J�gc`�s��YG������E��X)M[n|���\ʿPio��7���3
!gS 6���1�o��	�$s��WG5���AW5O���xu�`�<x�l@ls��������t{t-������O�Ó��p�A��+��pg߇/����\���WJ����~�s��FӮ��z#]��B���'f�I��	��,m�١PE��+m���bs��y�J��{*l?t�|`0O��k�UI!�`�61J{,s�M�<x/��kG�ý�g�t'
Ћvb�>#��� $��{*?���:)| ʀ�"���2=�D)+�����>�*�/���O����_o{}?��7�r�Ӵb�ʜ'�ͦ�[�z�uE��}y�c),9m,�)s����bﱣ��ȷ-�������{�� f�,v
�����;<��\���S�V󘍃�+��C۠�k0�m��.p�8i�P�ǂ�>��g��i���R�X�#7 :խ#b���!�G>\����O>���ɇ������y#C�;
DY�g
��`��>��Y��)�5k��xA{�5��ݲ�r'�&hƫòYW�l�5i���F�D�s+lfl%<�7�m�^u��Z�mv�]�[O�I�-5ߡ�kU����l-���v6���3��:*�ym��Xpf���1�6��ޣ��>�����$(��ᚲ��g蓒��ͽ3�-���S�v��L�=o�z�m��玣��U>jj^��7��_|�~�7�-�k�e�uu�[�E)���e��i��YA0���W%�V�`I�4����=�b|D��_�xLnk��>ˆ�s捎�+x���m�@洞���sp)ǅ�}!&L�����os������RPV��$}!_mo�D�ڴM�A>Dy�LH� �����T6Gf�rC��#�V sdu��j>�Y@������՝+l���ѿ�:ʵa �������������y��b�ٵac�U�<E�C��ز��շ��ZԼ��z<��\ ��^<pvT2m�ز���'�^=�
�x�Mn*<����%P2C�i�c��A�� �g�E�&�ၖ��,bل��``{ץ��2 �%tؿ���1�ѱ�����z���tnfp۪;��<V�z�c��6�((��"�^5+�e��'iV5_�mc���`/����w��7���?z{40��Ε>�����ݮ���f��)(F���,U�D�Xq�e�-��j�b�Tc�pOG�S��sO��Y�"GX8!���Ӑ�|d�P䫌{V�v�>xʑ�� 5o�`���4�?<pv��db���5׎��^�PP�:Zk��"g�{����Z4�$)e�G�=*�4�f�p��[��)�r�9P��ؤ�6g`Hga[���5���>*�Bmq
��m{ᱭ{�EÛ'�Yˇ�\un�*b��	Q��K{ j�'��[������\�)Ӧr���c�R�2��� �md�o[wS�H�|ᝳpO�̺: �fM����]�o-�/�Fmd�+�E&J3�����sJ�O�7����~�^JXR�~5����'xi� �#��u�ryʹ��:��'õ3'���!��[o�n�/`/�R�u=���zJg'���E�+����������ao�Pi�EVZӒ�a��.Ù��a�����+�l��2V�����^���
��)uWf�lڤk�W6͇Im-u���/�����~a��3�u�,]�SPP�"����_=���
����6 �5:�5x�'�ѧ|��y��ES�e3����e�y��r&�x�e����C���b �ɏQPP��]#bYW�v�Gj^7�Ѫ��Ugno^�g�=�1�9<�m�[/i��}�XN�A�~^�Mg��6i-��)(�#F�#x߆��j��j5��(�p��R�\������%��r�������,)�X<��\)�IAA�x��ռ�:�e8r��(u��	RrI��K�IR<d�(�/�;����t5=E�A^Q��Q5�1e�Lh���#葉	����7���h�2�3=t�ɋ�ʡstTRPP4䅚���٘�xXf�r�xW��A�t��՞w�u�a�Z�D�<�� ??LG&EcA^�ț�z�����[�nT�*��	s�JG� =��(Y��� ����7_�'����� /f��
�Y�<H�%�AXٶ� .���@,��>Gz�&` �}�r�
�@OAAA�P�/�����?��VLesc�ml���q �|��h�OՇf�p����������h0ȷO�&�m05��!���HV���k��m VV�ܥ֫ɪ�"v�W�@,EA^�(C�p�Dc�uQb���rn�6.�+�C�dh����So�O�R�s

������%3\ɂ���fƌö���۳jl�畎�W�#vOP����g(ㆂ��� /R*o��T�<�Mj߬V՟w���=���T��	yˆ�,�?��O����h��j^,��A��k͂᠂���r�m��T��g�I��7��y1���R!+-�ƚ.ծ�&�\}��p�z�Q�AV�_�'^)�~[��� ybl�v#c[Ǖ[j�p��=ʙ���M��y�ڀ�M�ۼ���<�Y7��'�SPP4�E��%��gd�&� �ܰ]裠7��Z6��̅Ƀdy�A���6��Ќj��(��	���9ҬV�$�'.����q���|ܑ�VA�~,0J��
~N�E�pq� �=~�� ?�qw9wްm4խ�<��Ʌn�Vb�W&L����;!pX5N��-�`��A�O���s{���eX<{5A~�#Ν�g�%
��I-���>q��G|zTՇ���R�����"�����((,1x�*���3C#0�D�x5
A~�#Ν�f�Zk�c��k�4I���m>=����<��)��º��^;	o���f�����008�@��vj��ت�$w^�m���sk|�����6�`/?�&�
�F�����4��v*jFQ���#y� ��1�9��N�@C����|�T��Y1`Z4>�����?h;��@/G���dÍ���ߛ�/��~����S��c��⾳	���d��)�0���u��`��SՎ� ���@�e�hg�}cx��ʗr�eb�p�ڌ]L�s�<)���K������𿊠�?K��1F�4��F`��`�DR���	�;?�����[��^����í� ��\K�T �����r'�Q�����3��� ��A�����)�]��#�
�����Q��˶��w]�*u ky��� 4��%�m�^_�
�kt��9�Jn?�� �_���������ͣ��,^No_�����ੋE���2ht�_�9�PFA��bѬI������{^�u�z�A�k_W�ܴ�\.w
���ߛk�^�捃����A���t�7�=�����ʁ�p�J쿗_ hma�q�Tj(�|}��$�����iAo*x��w�^�Łύ�]��b��9r����������G���g�o�8y~��y
���\z	�����A�v����B�E����|<���3cMޡ��Wg���נa�o��E�"8W&�	���ä�]�_-D�T�E�<��Uɞ�����VX9��� _��UnY��ZPЃ������ss��{@�q��7�l���j����C�NH�;6p���axj�i�4`+v�O;�Ǉ�`��^����;�� �!�y����\�מ�D��FU�׍�> >�Zy��Y5��c�ա*�S����?v �>AŪ!������g#�]�)�U�~�~є(C�b|+��?]��L�|�w��G����<+^�7���u�>c,ٶ�0��.oXy.~]�f�c��&�*�X�t��!�x���G�r�����n���}�;a&A�.���Ŏx��Q���\��z�Ì�~|p�j<
hm�/,b��[��-q�E=UV�r[�^�Cb�mt7~���'�������g	�c�F��%�L^�A�2��1�_����B'�m�zg�;�^(�d(:��m��<����!�������	�X�sI��]�`�4�
y��e!\,���y�	�_�!�J��`�/���U=��.�>�6V�	<�*�u��
��0���<�<���� wyE��������[��ճ`��3�2Fq��p�Cp�U�۔�M�M��S茌�A�8�?�W��G�\6���Va��"Y4�}�X0��7-�İa��"[9���
u��_�Ѿ�v�+漏k�lo������Р-���[��p�w	�<&��w�d��:g�f�|��V��1���eHKpfҋ��^z��Ą<"�MЫT��]��J��ጎVx�NX�h
�85���H��V����vݳ'�{WͦƤh��}rE����:-�S ߥ����-�R�p8j���;�1�`R[ܱ|ܹb&�>�8|��s�"]Izn0��h��_�	i�E�A�����Oݟ���Kի����m+�C�z���z� �v � �	wݮ@*v��lZ:��YQj+E��I��S ~�x���u��s�۳ڋ�_O��hb�G���Ţ�?���r�m��t�˰�l��x���;èmQ��zB�a����Q��Z�ū������{Vφ��Ӡ�
`9C,�~������vЛ�M|[d�|h�\�:�����!_�;p�z4>��Ga/�8�E�ٙ	��,y�@,�r��pw�w}��(�%�-�3`��iх��/]������0t��1xjS}޼ ��|��O1N ��<yN�(�F���z<��quo�ڙͻ�JxC��]=2�wL��Z�G��Z�O9��BُW�����؇v�G��,3Y���KϷ��x��y�`�85f���@N�ǀ�5.�� �F���]W���Իl�\�ZN�_�=�,���w4�o,���Е�"���+�3ɫ	���Tͦq�w�7/��n �S�ESy���o߿��ӗ*3^�3TK��$��,لn�y�5ԹQ�r[���O�����z��9��9.���,y���j��������å+���"�8�Llk<��\�e���_��X0
��T��m���|� OA����Bt�T�)R��	� [!53kx�/!���Ϻ��=���L��p��{|]��%��j��e(_�QN�����J\�E��z���<ʀ�|.a~���Ȏ�����-�1\�l|�o+���y�������K{*�@S���@�JYP�}l�h�4��~��/<���-tw*s�9������~�w�a�}Ƭ���*�Ը�:���"��5-,�zj���OĹ"�#�a.2�Ĳ�r҂V�� D���}��w��8����S���n�`��;O��Ԕ�L�W��!��(��KGi��CŻ_��HG�n��@��v���VX�^4�NnM�'��$�k_�Vtz�.:W.� �Ղ����P�+���G���^���rE�F��(�?��(���;
qIJ]�W(��^!����Z�W��C�����rf��/����w��Q�M��R��KW���:�2��������0�oQ����� ��Όfh��c����BRQ2.�X8P��u�'�]S�&����uo�G|{���K�p�;ĮI��o.��'^ǀ�B�v[�s(�S�ޑ+/����d0���wGϢY�#�~A���@[U[�ɹ�����azQ�'���뻂�Zpm�,m��
 �ըR~ʤk�w~�w�	��+���+��j�D�,�T�U./��\�d��B	�ɒ{Ѣ������r|�����]M���=����}�n�x��Yx
R�YBdz������/��K��EA��[0�><���6���R�ҩ�C��
\W�.�Y3��!�eŬ:U�`�����rW��`+��}@VĻV̄��6A��u�z��Ⱦyxk_��d�'7e�+�&�cPW�]y��ZTp�5c"̟96���ꚶ5|��T}�v��6���c�D�1�n��S)��� �[��Z˺��+���
PʪQ`Y��}�z�j<+豎�;
�����.M�4K�q��X����p�!�n�5�Ŏ�5�ɞ� ��"�.���ܑhv&��k�$j��i�[@�Bպ�I�Ў�츝���E4�i����d�c T股����D'|���m�H��Y3"���e��JA���}3��7�����oo��;�a����+��z�%��r�_���qlXR�����:�A̥����x��wۄ'����̻V̂�s&��� ?Zq˲����#R�{����#@K~5|e~�yTދ�A��x�n)TV��n����OY�: V���$�' VK&��)ɧ�<{9Ȟ� ȏa���z�:xr�I����#U��.��c&���d<TÇ]7j�p�jQy�o�S���kusd+,`�,^<�>�	�P��6�^�Y���bg��ک�C� ȏu�kugT��?*�z���7��4���	u�U�0l)@��l�Z�&�*��pV��
� ��'E�8>��9kVW�"=r�d��Q��J�������W�ұ���րo���z�������k-�����:@���p�6P*�;��;����3^9^q2�I�S� n]63R��/���
�y%�F������'�EΏ�S,e�,����Q����5��v��I1
Z-���]�u����b��z� �7@���ݹ(��?,��V���ٖFe�z��#Ŋǰf�����ٮ��^��U�X��������c ���u ����J��;e�P�0����都��cS��qRM&&�`�l�n�$E��\��k�_[^0�g�Ll{�7�L��)yW���Y�hj��N�3�&�p��y*���a�0=��k�9�'$zc�r�"p���Ԫ�Ժ1��=�T����Aقc�����{'k�� �d��o��O�����_?^b͵S�j��[W�e��{겍cS���L�{����2X���-�ө�E]+ğ.^��"�8u~x\�^dӬ�ꆹ]�]�C]����L\�j@K�D�)x�܅r_8s"����K��K18+�}��^�7����C���V���uه�f�X�ՄL�r�W�)H�S)�'w�*���׳o���т Ʋ���ZlIA4��:�*)qM�{��������b�Fp� �S1t�j4@+2rDI�F����{7�1�nU�6��6�E�j]V�o޴v��Ȗ��s2�R�]C�x�V\�_�3P*��`�|���V��t|R��j���)Cl��.� �r�TH
�<E����r��Exj�)x�ๆ�rfMi���UR&сW� =���ȼ��:@��(@|w�j'K�� O�K\;{r4H+B��7��-���_R����\��},�}�{��Z5�c)�.B���j� O��� OQSu/j��vN\6�BLz����P�8���	��IQ���`�]<+��N^;A�b�B�`���RO�_�`j���?����n��� dR6���X�P�v
�<E]����1�t��[[��x�2�}@D}up��E��<����xMVA������,�����`��SK�M���p5H��a�����</M�re��P@פ�)(��O�."D��}-�/ ���TI�5Ս&�Aݥ�c���x!�SP�2D�}��O_����,��F��I�[6!�� ��n������J�2�r���QP��s����"�|��.GЗo�bi�(<��oo\�U.ba�Zܟ���y�4��n�����bR���%�<)K�J�M�F9rSQ��s�qa�LhmI����I��q�,

�<E�CLʪt��SFAAAA������ �SPPPP�)((((�y




[�� �s0y$$    IEND�B`�   �>      �� ���    0 	        <html>
<head>
<style>
body {
  font-family: Verdana, Arial;
  font-size: 12px;
}

/* Give the same font styling to form elements. */
input, select, textarea, button {
  font-family: inherit;
  font-size: inherit;
}

.content {
  display: flex;
  flex-direction: column;
  width: 100%;
  height: 100%;
}

.description {
  padding-bottom: 5px;
}

.description .title {
  font-size: 120%;
  font-weight: bold;
}

.route_controls {
  flex: 0;
  align-self: center;
  text-align: right;
  padding-bottom: 5px;
}

.route_controls .label {
  display: inline-block;
  vertical-align: top;
  font-weight: bold;
}

.route_controls .control {
  width: 500px;
}

.messages {
  flex: 1;
  min-height: 100px;
  border: 1px solid gray;
  overflow: auto;
}

.messages .message {
  padding: 3px;
  border-bottom: 1px solid #cccbca;
}

.messages .message .timestamp {
  font-size: 90%;
  font-style: italic;
}

.messages .status {
  background-color: #d6d6d6;  /* light gray */
}

.messages .sent {
  background-color: #c5e8fc;  /* light blue */
}

.messages .recv {
  background-color: #fcf4e3;  /* light yellow */
}

.message_controls {
  flex: 0;
  text-align: right;
  padding-top: 5px;
}

.message_controls textarea {
  width: 100%;
  height: 10em;
}
</style>
<script language="JavaScript">
// Application state.
var demoMode = false;
var currentSubscriptionId = null;
var currentRouteId = null;

// List of currently supported source protocols.
var allowedSourceProtocols = ['cast', 'dial'];

// Values from cef_media_route_connection_state_t.
var CEF_MRCS_UNKNOWN = 0;
var CEF_MRCS_CONNECTING = 1;
var CEF_MRCS_CONNECTED = 2;
var CEF_MRCS_CLOSED = 3;
var CEF_MRCS_TERMINATED = 4;

function getStateLabel(state) {
  switch (state) {
    case CEF_MRCS_CONNECTING: return "CONNECTING";
    case CEF_MRCS_CONNECTED: return "CONNECTED";
    case CEF_MRCS_CLOSED: return "CLOSED";
    case CEF_MRCS_TERMINATED: return "TERMINATED";
    default: break;
  }
  return "UNKNOWN";
}

// Values from cef_media_sink_icon_type_t.
var CEF_MSIT_CAST = 0;
var CEF_MSIT_CAST_AUDIO_GROUP = 1;
var CEF_MSIT_CAST_AUDIO = 2;
var CEF_MSIT_MEETING = 3;
var CEF_MSIT_HANGOUT = 4;
var CEF_MSIT_EDUCATION = 5;
var CEF_MSIT_WIRED_DISPLAY = 6;
var CEF_MSIT_GENERIC = 7;

function getIconTypeLabel(type) {
  switch (type) {
    case CEF_MSIT_CAST: return "CAST";
    case CEF_MSIT_CAST_AUDIO_GROUP: return "CAST_AUDIO_GROUP";
    case CEF_MSIT_CAST_AUDIO: return "CAST_AUDIO";
    case CEF_MSIT_MEETING: return "MEETING";
    case CEF_MSIT_HANGOUT: return "HANGOUT";
    case CEF_MSIT_EDUCATION: return "EDUCATION";
    case CEF_MSIT_WIRED_DISPLAY: return "WIRED_DISPLAY";
    case CEF_MSIT_GENERIC: return "GENERIC";
    default: break;
  }
  return "UNKNOWN";
}


///
// Manage show/hide of default text for form elements.
///

// Default messages that are shown until the user focuses on the input field.
var defaultSourceText = 'Enter URN here and click "Create Route"';
var defaultMessageText = 'Enter message contents here and click "Send Message"';

function getDefaultText(control) {
  if (control === 'source')
    return defaultSourceText;
  if (control === 'message')
    return defaultMessageText;
  return null;
}

function hideDefaultText(control) {
  var element = document.getElementById(control);
  var defaultText = getDefaultText(control);
  if (element.value === defaultText)
    element.value = '';
}

function showDefaultText(control) {
  var element = document.getElementById(control);
  var defaultText = getDefaultText(control);
  if (element.value === '')
    element.value = defaultText;
}

function initDefaultText() {
  showDefaultText('source');
  showDefaultText('message');
}


///
// Retrieve current form values. Return null if validation fails.
///

function getCurrentSource() {
  var sourceInput = document.getElementById('source');
  var value = sourceInput.value;
  if (value === defaultSourceText || value.length === 0 || value.indexOf(':') < 0) {
    return null;
  }

  // Validate the URN value.
  try {
    var url = new URL(value);
    if ((url.hostname.length === 0 && url.pathname.length === 0) ||
        !allowedSourceProtocols.includes(url.protocol.slice(0, -1))) {
      return null;
    }
  } catch (e) {
    return null;
  }

  return value;
}

function getCurrentSink() {
  var sinksSelect = document.getElementById('sink');
  if (sinksSelect.options.length === 0)
    return null;
  return sinksSelect.value;
}

function getCurrentMessage() {
  var messageInput = document.getElementById('message');
  if (messageInput.value === defaultMessageText || messageInput.value.length === 0)
    return null;
  return messageInput.value;
}


///
// Set disabled state of form elements.
///

function updateControls() {
  document.getElementById('source').disabled = hasRoute();
  document.getElementById('sink').disabled = hasRoute();
  document.getElementById('create_route').disabled =
      hasRoute() || getCurrentSource() === null || getCurrentSink() === null;
  document.getElementById('terminate_route').disabled = !hasRoute();
  document.getElementById('message').disabled = !hasRoute();
  document.getElementById('send_message').disabled = !hasRoute() || getCurrentMessage() === null;
}


///
// Manage the media sinks list.
///

/*
Expected format for |sinks| is:
  [
    {
      name: string,
      type: string ('cast' or 'dial'),
      id: string,
      icon: int
    }, ...
  ]
*/
function updateSinks(sinks) {
  var sinksSelect = document.getElementById('sink');

  // Currently selected value.
  var selectedValue = sinksSelect.options.length === 0 ? null : sinksSelect.value;

  // Build a list of old (existing) values.
  var oldValues = [];
  for (var i = 0; i < sinksSelect.options.length; ++i) {
    oldValues.push(sinksSelect.options[i].value);
  }

  // Build a list of new (possibly new or existing) values.
  var newValues = [];
  for(var i = 0; i < sinks.length; i++) {
    newValues.push(sinks[i].id);
  }

  // Remove old values that no longer exist.
  for (var i = sinksSelect.options.length - 1; i >= 0; --i) {
    if (!newValues.includes(sinksSelect.options[i].value)) {
      sinksSelect.remove(i);
    }
  }

  // Add new values that don't already exist.
  for(var i = 0; i < sinks.length; i++) {
    var sink = sinks[i];
    if (oldValues.includes(sink.id))
      continue;
    var opt = document.createElement('option');
    opt.innerHTML = sink.name + ' (' + sink.model_name + ', ' + sink.type + ', ' +
                    getIconTypeLabel(sink.icon) + ', ' + sink.ip_address + ':' + sink.port + ')';
    opt.value = sink.id;
    sinksSelect.appendChild(opt);
  }

  if (sinksSelect.options.length === 0) {
    selectedValue = null;
  } else if (!newValues.includes(selectedValue)) {
    // The previously selected value no longer exists.
    // Select the first value in the new list.
    selectedValue = sinksSelect.options[0].value;
    sinksSelect.value = selectedValue;
  }

  updateControls();

  return selectedValue;
}


///
// Manage the current media route.
///

function hasRoute() {
  return currentRouteId !== null;
}

function createRoute() {
  console.assert(!hasRoute());
  var source = getCurrentSource();
  console.assert(source !== null);
  var sink = getCurrentSink();
  console.assert(sink !== null);

  if (demoMode) {
    onRouteCreated('demo-route-id');
    return;
  }

  sendCefQuery(
    {name: 'createRoute', source_urn: source, sink_id: sink},
    (message) => onRouteCreated(JSON.parse(message).route_id)
  );
}

function onRouteCreated(route_id) {
  currentRouteId = route_id;
  showStatusMessage('Route ' + route_id + '\ncreated');
  updateControls();
}

function terminateRoute() {
  console.assert(hasRoute());
  var source = getCurrentSource();
  console.assert(source !== null);
  var sink = getCurrentSink();
  console.assert(sink !== null);

  if (demoMode) {
    onRouteTerminated();
    return;
  }

  sendCefQuery(
    {name: 'terminateRoute', route_id: currentRouteId},
    (unused) => {}
  );
}

function onRouteTerminated() {
  showStatusMessage('Route ' + currentRouteId + '\nterminated');
  currentRouteId = null;
  updateControls();
}


///
// Manage messages.
///

function sendMessage() {
  console.assert(hasRoute());
  var message = getCurrentMessage();
  console.assert(message !== null);

  if (demoMode) {
    showSentMessage(message);
    setTimeout(function(){ if (hasRoute()) { recvMessage('Demo ACK for: ' + message); } }, 1000);
    return;
  }

  sendCefQuery(
    {name: 'sendMessage', route_id: currentRouteId, message: message},
    (unused) => showSentMessage(message)
  );
}

function recvMessage(message) {
  console.assert(hasRoute());
  console.assert(message !== undefined && message !== null && message.length > 0);
  showRecvMessage(message);
}

function showStatusMessage(message) {
  showMessage('status', message);
}

function showSentMessage(message) {
  showMessage('sent', message);
}

function showRecvMessage(message) {
  showMessage('recv', message);
}

function showMessage(type, message) {
  if (!['status', 'sent', 'recv'].includes(type)) {
    console.warn('Invalid message type: ' + type);
    return;
  }

  if (message[0] === '{') {
    try {
      // Pretty print JSON strings.
      message = JSON.stringify(JSON.parse(message), null, 2);
    } catch(e) {}
  }

  var messagesDiv = document.getElementById('messages');

  var newDiv = document.createElement("div");
  newDiv.innerHTML =
      '<span class="timestamp">' + (new Date().toLocaleString()) +
      ' (' + type.toUpperCase() + ')</span><br/>';
  // Escape any HTML tags or entities in |message|.
  var pre = document.createElement('pre');
  pre.appendChild(document.createTextNode(message));
  newDiv.appendChild(pre);
  newDiv.className = 'message ' + type;

  messagesDiv.appendChild(newDiv);

  // Always scroll to bottom.
  messagesDiv.scrollTop = messagesDiv.scrollHeight;
}


///
// Manage communication with native code in media_router_test.cc.
///

function onCefError(code, message) {
  showStatusMessage('ERROR: ' + message + ' (' + code + ')');
}

function sendCefQuery(payload, onSuccess, onFailure=onCefError, persistent=false) {
  // Results in a call to the OnQuery method in media_router_test.cc
  return window.cefQuery({
    request: JSON.stringify(payload),
    onSuccess: onSuccess,
    onFailure: onFailure,
    persistent: persistent
  });
}

/*
Expected format for |message| is:
  {
    name: string,
    payload: dictionary
  }
*/
function onCefSubscriptionMessage(message) {
  if (message.name === 'onSinks') {
    // List of sinks.
    updateSinks(message.payload.sinks_list);
  } else if (message.name === 'onRouteStateChanged') {
    // Route status changed.
    if (message.payload.route_id === currentRouteId) {
      var connection_state = message.payload.connection_state;
      showStatusMessage('Route ' + currentRouteId +
                        '\nconnection state ' + getStateLabel(connection_state) +
                        ' (' + connection_state + ')');
      if ([CEF_MRCS_CLOSED, CEF_MRCS_TERMINATED].includes(connection_state)) {
        onRouteTerminated();
      }
    }
  } else if (message.name === 'onRouteMessageReceived') {
    // Route message received.
    if (message.payload.route_id === currentRouteId) {
      recvMessage(message.payload.message);
    }
  }
}

// Subscribe to ongoing message notifications from the native code.
function startCefSubscription() {
  currentSubscriptionId = sendCefQuery(
    {name: 'subscribe'},
    (message) => onCefSubscriptionMessage(JSON.parse(message)),
    (code, message) => {
      onCefError(code, message);
      currentSubscriptionId = null;
    },
    true
  );
}

function stopCefSubscription() {
  if (currentSubscriptionId !== null) {
    // Results in a call to the OnQueryCanceled method in media_router_test.cc
    window.cefQueryCancel(currentSubscriptionId);
  }
}


///
// Example app load/unload.
///

function initDemoMode() {
  demoMode = true;

  var sinks = [
    {
      name: 'Sink 1',
      type: 'cast',
      id: 'sink1',
      icon: CEF_MSIT_CAST
    },
    {
      name: 'Sink 2',
      type: 'dial',
      id: 'sink2',
      icon: CEF_MSIT_GENERIC
    }
  ];
  updateSinks(sinks);

  showStatusMessage('Running in Demo mode.');
  showSentMessage('Demo sent message.');
  showRecvMessage('Demo recv message.');
}

function onLoad() {
  initDefaultText();

  if (window.cefQuery === undefined) {
    // Initialize demo mode when running outside of CEF.
    // This supports development and testing of the HTML/JS behavior outside
    // of a cefclient build.
    initDemoMode();
    return;
  }

  startCefSubscription()
}

function onUnload() {
  if (demoMode)
    return;

  if (hasRoute())
    terminateRoute();
  stopCefSubscription();
}
</script>
<title>Media Router Example</title>
</head>
<body bgcolor="white" onLoad="onLoad()" onUnload="onUnload()">
<div class="content">
  <div class="description">
    <span class="title">Media Router Example</span>
    <p>
      <b>Overview:</b>
      Chromium supports communication with devices on the local network via the
      <a href="https://blog.oakbits.com/google-cast-protocol-overview.html" target="_blank">Cast</a> and
      <a href="http://www.dial-multiscreen.org/" target="_blank">DIAL</a> protocols.
      CEF exposes this functionality via the CefMediaRouter interface which is demonstrated by this test.
      Test code is implemented in resources/media_router.html and browser/media_router_test.cc.
    </p>
    <p>
      <b>Usage:</b>
      Devices available on your local network will be discovered automatically and populated in the "Sink" list.
      Enter a URN for "Source", select an available device from the "Sink" list, and click the "Create Route" button.
      Cast URNs take the form "cast:<i>&lt;appId&gt;</i>?clientId=<i>&lt;clientId&gt;</i>" and DIAL URNs take the form "dial:<i>&lt;appId&gt;</i>",
      where <i>&lt;appId&gt;</i> is the <a href="https://developers.google.com/cast/docs/registration" target="_blank">registered application ID</a>
      and <i>&lt;clientId&gt;</i> is an arbitrary numeric identifier.
      Status information and messages will be displayed in the center of the screen.
      After creating a route you can send messages to the receiver app using the textarea at the bottom of the screen.
      Messages are usually in JSON format with a example of Cast communication to be found
      <a href="https://github.com/chromiumembedded/cef/issues/2900#issuecomment-1465022620" target="_blank">here</a>.
    </p>
  </div>
  <div class="route_controls">
    <span class="label">Source:</span>
    <input type="text" id="source" class="control" onInput="updateControls()" onFocus="hideDefaultText('source')" onBlur="showDefaultText('source')"/>
    <br/>
    <span class="label">Sink:</span>
    <select id="sink" size="3" class="control"></select>
    <br/>
    <input type="button" id="create_route" onclick="createRoute()" value="Create Route" disabled/>
    <input type="button" id="terminate_route" onclick="terminateRoute()" value="Terminate Route" disabled/>
  </div>
  <div id="messages" class="messages">
  </div>
  <div class="message_controls">
    <textarea id="message" onInput="updateControls()" onFocus="hideDefaultText('message')" onBlur="showDefaultText('message')" disabled></textarea>
    <br/><input type="button" id="send_message" onclick="sendMessage()" value="Send Message" disabled/>
  </div>
</div>
</body>
</html>
h      �� ���    0 	        �PNG

   IHDR         ���$   sBIT|d�   	pHYs   �   �F.   tEXtSoftware www.inkscape.org��<   tEXtTitle Hamburger (Menu) Icon�$��   tEXtAuthor Daniel Fowler'K�   �tEXtDescription A simple and basic hamburger (menu) icon. It originates from Xerox "Star" workstations of the 1980's but is now popular to hide/show menus on mobile devices.c_��   tEXtCreation Time 2015-06-29��nM   XtEXtCopyright CC0 Public Domain Dedication http://creativecommons.org/publicdomain/zero/1.0/���   aIDAT(����	�0E��`K��Y� ZL�]�"6���`�wfFLh���W��*t����9�$��doI\��4X3��KK����$����;�]9L    IEND�B`��      �� ���    0 	        �PNG

   IHDR          Ǎ�   sBIT|d�   	pHYs  n  n�P_$   tEXtSoftware www.inkscape.org��<   tEXtTitle Hamburger (Menu) Icon�$��   tEXtAuthor Daniel Fowler'K�   �tEXtDescription A simple and basic hamburger (menu) icon. It originates from Xerox "Star" workstations of the 1980's but is now popular to hide/show menus on mobile devices.c_��   tEXtCreation Time 2015-06-29��nM   XtEXtCopyright CC0 Public Domain Dedication http://creativecommons.org/publicdomain/zero/1.0/���   �IDATH���=
1@�oc'j#b���wX�����³XZZڈ���hᮨX��,胁���I�d.40BG6�cM,q���m�@^�8��V3ߣ]lů~�nVd����{�3�"��T��f]C+�w������Y�u��#�c0x���b�H��՝�T���]*�H�#
���j��i#8$��H<��0�dtp�����    IEND�B`� �      �� ���    0 	        <html>
  <head><title>OSR Test</title></head>
  <style>
  .red_hover:hover {color:red;}
  #li { width: 530px; }
  body {background:rgba(255, 0, 0, 0.5); }
  input {-webkit-appearance: none; }
  #LI11select {width: 75px;}
  #LI11select option { background-color: cyan; }
  .dropdiv {
    width:50px;
    height:50px;
    border:1px solid #aaaaaa;
    float: left;
  }
  #dragdiv {
    width: 30px;
    height: 30px;
    background-color: green;
    margin: 10px;
  }
  #draghere {
    position: relative;
    z-index: -1;
    top: 7px;
    left: 7px;
    opacity: 0.4;
  }
  #touchdiv, #pointerdiv {
    width: 100px;
    height: 50px;
    background-color: red;
    float: left;
    margin-left: 10px;
  }
  </style>
  <script>
  function getElement(id) { return document.getElementById(id); }
  function makeH1Red() { getElement('LI00').style.color='red'; }
  function makeH1Black() { getElement('LI00').style.color='black'; }
  function navigate() { location.href='?k='+getElement('editbox').value; }
  function load() {
    var elems = [];
    var param = { type: 'ElementBounds', elems: elems };

    elems.push(getElementBounds('LI00'));
    elems.push(getElementBounds('LI01'));
    elems.push(getElementBounds('LI02'));
    elems.push(getElementBounds('LI03'));
    elems.push(getElementBounds('LI04'));
    elems.push(getElementBounds('LI05'));
    elems.push(getElementBounds('LI06'));
    elems.push(getElementBounds('LI07'));
    elems.push(getElementBounds('LI08'));
    elems.push(getElementBounds('LI09'));
    elems.push(getElementBounds('LI10'));
    elems.push(getElementBounds('LI11'));
    elems.push(getElementBounds('LI11select'));
    elems.push(getElementBounds('email'));
    elems.push(getElementBounds('quickmenu'));
    elems.push(getElementBounds('editbox'));
    elems.push(getElementBounds('btnnavigate'));
    elems.push(getElementBounds('dropdiv'));
    elems.push(getElementBounds('dragdiv'));
    elems.push(getElementBounds('touchdiv'));
    elems.push(getElementBounds('pointerdiv'));

    if (window.testQuery)
      window.testQuery({request: JSON.stringify(param)});

    fillDropDown();
  }

  function fillDropDown() {
    var select = document.getElementById('LI11select');
    for (var i = 1; i < 21; i++)
      select.options.add(new Option('Option ' + i, i));
  }

  function getElementBounds(id) {
    var element = document.getElementById(id);
    var bounds = element.getBoundingClientRect();
    return {
      id: id,
      x: Math.floor(bounds.x),
      y: Math.floor(bounds.y),
      width: Math.floor(bounds.width),
      height: Math.floor(bounds.height)
    };
  }

  function onEventTest(event) {
    var param = 'osr' + event.type;

    if (event.type == "click")
      param += event.button;

    // Results in a call to the OnQuery method in os_rendering_unittest.cc.
    if (window.testQuery)
      window.testQuery({request: param});
  }

  function onFocusTest(ev) {
    if (window.testQuery)
      window.testQuery({request: "osrfocus" + ev.target.id});
  }

  function allowDrop(ev) {
    ev.preventDefault();
  }

  function drag(ev) {
    ev.dataTransfer.setData("Text",ev.target.id);
  }

  function drop(ev) {
    var data=ev.dataTransfer.getData("Text");
    ev.target.innerHTML = '';
    var dragged = document.getElementById(data);
    dragged.setAttribute('draggable', 'false');
    ev.target.appendChild(dragged);
    if (window.testQuery)
      window.testQuery({request: "osrdrop"});
  }

  function selectText(ev) {
    var element = ev.target;
    var selection = window.getSelection();
    var range = document.createRange();
    range.selectNodeContents(element);
    selection.removeAllRanges();
    selection.addRange(range);
  }

  function onTouchEvent(ev) {
    var param = 'osr' + ev.type;
    // For Touch start also include touch points.
    if (event.type == "touchstart")
      param += ev.touches.length;
    // For Touch Move include the touches that changed.
    if (event.type == "touchmove")
      param += ev.changedTouches.length;

    // Results in a call to the OnQuery method in os_rendering_unittest.cc.
    if (window.testQuery)
      window.testQuery({request: param});
  }

  function onPointerEvent(ev) {
    var param = 'osr' +  ev.type + ' ' + ev.pointerType;
    if (window.testQuery)
      window.testQuery({request: param});
  }

  </script>
  <body onfocus='onEventTest(event)' onblur='onEventTest(event)' onload='load();'>
  <h1 id='LI00' onclick="onEventTest(event)">
    OSR Testing h1 - Focus and blur
    <select id='LI11select'>
      <option value='0'>Default</option>
    </select>
    this page and will get this red black
  </h1>
  <ol>
  <li id='LI01'>OnPaint should be called each time a page loads</li>
  <li id='LI02' style='cursor:pointer;'><span>Move mouse
      to require an OnCursorChange call</span></li>
  <li id='LI03' onmousemove="onEventTest(event)"><span>Hover will color this with
      red. Will trigger OnPaint once on enter and once on leave</span></li>
  <li id='LI04'>Right clicking will show contextual menu and will request
      GetScreenPoint</li>
  <li id='LI05'>IsWindowRenderingDisabled should be true</li>
  <li id='LI06'>WasResized should trigger full repaint if size changes.
      </li>
  <li id='LI07'>Invalidate should trigger OnPaint once</li>
  <li id='LI08'>Click and write here with SendKeyEvent to trigger repaints:
      <input id='editbox' type='text' value='' size="5" onfocus="onFocusTest(event)"></li>
  <li id='LI09'>Click here with SendMouseClickEvent to navigate:
      <input id='btnnavigate' type='button' onclick='navigate()'
      value='Click here to navigate' /></li>
  <li id='LI10' title='EXPECTED_TOOLTIP'>Mouse over this element will
      trigger show a tooltip</li>
  <li id='LI11' onclick='selectText(event)'>SELECTED_TEXT_RANGE</li>
  <li><input id='email' type='text' size=10 inputmode='email'></li>
  <li id="quickmenu">Long touch press should trigger quick menu</li>
  </ol>

  <div class="dropdiv" id="dropdiv" ondrop="drop(event)" ondragover="allowDrop(event)">
    <span id="draghere">Drag here</span>
  </div>
  <div class="dropdiv">
    <div id="dragdiv" draggable="true" ondragstart="drag(event)"></div>
  </div>
  <div id="touchdiv" ontouchstart="onTouchEvent(event)" ontouchend="onTouchEvent(event)" ontouchmove="onTouchEvent(event)" ontouchcancel="onTouchEvent(event)">
  </div>
  <div id="pointerdiv" onpointerdown="onPointerEvent(event)" onpointerup="onPointerEvent(event)" onpointermove="onPointerEvent(event)" onpointercancel="onPointerEvent(event)">
  </div>
  <br />
  <br />
  <br />
  <br />
  <br />
  <br />
  </body>
</html>
  �      �� ���    0 	        <html>
<head>
<title>Other Tests</title>
</head>
<body bgcolor="white">
<h3>Various other internal and external tests.</h3>
<ul>
<li><a href="http://mudcu.be/labs/JS1k/BreathingGalaxies.html">Accelerated 2D Canvas</a></li>
<li><a href="http://webkit.org/blog-files/3d-transforms/poster-circle.html">Accelerated Layers</a></li>
<li><a href="https://jigsaw.w3.org/HTTP/Basic/">Authentication (Basic)</a> - credentials returned via GetAuthCredentials</li>
<li><a href="https://jigsaw.w3.org/HTTP/Digest/">Authentication (Digest)</a> - credentials returned via GetAuthCredentials</li>
<li><a href="binary_transfer">Binary vs String Transfer Benchmark</a></li>
<li><a href="config">Chrome Configuration</a></li>
<li><a href="http://html5advent2011.digitpaint.nl/3/index.html">Cursors</a></li>
<li><a href="dialogs">Dialogs</a></li>
<li><a href="http://html5demos.com/drag">Drag & Drop</a></li>
<li><a href="draggable">Draggable Regions</a></li>
<li>DRM (Clearkey, Widevine) <a href="https://shaka-player-demo.appspot.com/support.html">Codecs support</a>, <a href="https://shaka-player-demo.appspot.com/demo/">Video player demo</a></li>
<li><a href="http://www.html5test.com">HTML5 Feature Test</a></li>
<li><a href="http://html5-demos.appspot.com/static/filesystem/filer.js/demos/index.html">HTML5 Filesystem</a> - requires "cache-path" flag</li>
<li><a href="http://www.youtube.com/watch?v=siOHh0uzcuY&html5=True">HTML5 Video</a></li>
<li><a href="ipc_performance">IPC Performance Tests</a></li>
<li><a href="binding">JavaScript Binding</a></li>
<li><a href="performance">JavaScript Performance Tests</a></li>
<li><a href="performance2">JavaScript Performance (2) Tests</a></li>
<li><a href="window">JavaScript Window Manipulation</a></li>
<li><a href="localstorage">Local Storage</a></li>
<li><a href="media_router">Media Router (Cast/DIAL)</a></li>
<li><a href="pdf.pdf">PDF Viewer direct</a></li>
<li><a href="pdf">PDF Viewer iframe</a></li>
<li><a href="preferences">Preferences</a></li>
<li><a href="javascript:window.print();">Print this page with &quot;javascript:window.print();&quot;</a></li>
<li><a href="hang">Render process hang test</a></li>
<li><a href="http://mrdoob.com/lab/javascript/requestanimationframe/">requestAnimationFrame</a></li>
<li><a href="response_filter">Response Filtering</a></li>
<li><a href="client://tests/handler.html">Scheme Handler</a></li>
<li><a href="https://www.google.com/intl/en/chrome/demos/speech.html">Speech Input</a> - requires "enable-speech-input" flag</li>
<li><a href="task_manager">Task Manager</a></li>
<li><a href="https://patrickhlauke.github.io/touch">Touch Feature Tests</a> - requires "touch-events=enabled" flag (and CAPS LOCK on Mac for Trackpad simulation)</li>
<li><a href="transparency">Transparency</a></li>
<li><a href="http://webglsamples.org/field/field.html">WebGL</a></li>
<li><a href="http://apprtc.appspot.com/">WebRTC</a> - requires "enable-media-stream" flag</li>
<li><a href="server">HTTP/WebSocket Server</a></li>
<li><a href="websocket">WebSocket Client</a></li>
<li><a href="urlrequest">CefURLRequest</a></li>
<li><a href="xmlhttprequest">XMLHttpRequest</a></li>
</ul>
</body>
</html>
  �       �� ���    0 	        <html>
<head>
<title>PDF Test</title>
</head>
<body bgcolor="white">
<iframe src="pdf.pdf" width="500" height="500"></iframe>
<iframe src="pdf.pdf" width="500" height="500"></iframe>
</body>
</html>
�u      �� ���    0 	        %PDF-1.4
%äüöß
2 0 obj
<</Length 3 0 R/Filter/FlateDecode>>
stream
x���Mk1���>v*ɒ?`hڤ�۶=���$P��䒿_���n��,;c�,�yeK30�v���|*��ܗ+�ۡ������I���S�\�za����Wm)NŲ��԰q��e�W�Fh�@2Y���"L��d!�EB�YHlD��K2Y8��c1YX���L6e��f0YBN���c
�8^��"��د?��[I~��:.4A��\�q��=�N{��]�!�fYv�˷���Y���}]*dV�5+�-+:§nc��%���У z�_�s7֙x3��f�<O#��l�K�Nx��/C�����A][��Ǩ�h�٥����8DQ�AݺM"r �0&ZJ-��D�f��~HFES��;&Z�h�qL4'͒�D3�h8(Ӡh�=	`�G��u7H9�s��o[%=^#�p]��VEߟ]���Ef�m�:�[O���c#@�����_�/�Z���h�~���n����C��N�&{�� u��
endstream
endobj

3 0 obj
496
endobj

5 0 obj
<</Length 6 0 R/Filter/FlateDecode>>
stream
x�u�;1��������������+�b�,����Q��df��#AM�Pw��<1��0��n�W�0^�2+��#���0�	��|�'$ᄌ��F�^���Z��	�F�L�!o�&��d���}�q�]5���ɼ��p]3���2���٠)��byg�Nh$_���EA
endstream
endobj

6 0 obj
177
endobj

8 0 obj
<</Length 9 0 R/Filter/FlateDecode>>
stream
x�uP�
1��[w��@H��
������	����fs��H`23dvؠ&x�;`9�|`��j����E�.j�;�<�'X��u)qDƶF�E��r{��q;�!5T�wj���Sd��:m��,qͮ+�e:�75�F܈&[�Ig�a�in�-�aCٳ�\,��u��A�
endstream
endobj

9 0 obj
177
endobj

12 0 obj
<</Length 13 0 R/Filter/FlateDecode/Length1 31040>>
stream
x���{\T��8>3�잽���,����(
(�DaU�\D0RYa5����&�f�&MҾ�5ML�����&6m�X�&MߦibSs}c�ך&Q��̜s�%1}�������7{��gf��y�g��9�o	!B�o
����v)B�E���}�tǻ7��I������ߴ�g!�+EH������ZҮ)DH�&�_�;�եV�.�w(��	�'�Z@2:7^��dX�"ȷu�������!�=�l
^޷R�����!/�7���y�e�3j�z�F��6ͥ�}����g�@�!�P���Z�'��
:��h2[������@��|4Q�d�c(��"'B�S�=�NtEޣ�4% �ڍ��]�)t=��@�=� C�FT�~��D�C;�����Q=<(�N���|���C�8�DW��(;#�kЍ����FdF�P�C��6�,��Fo�ףb���><i���3��1:��:rQ2j��x�#ͿG^Gӡ�]�^�&�S��a�!��7ԏ��ZyY�(HGۀU���(�A�!�.v�+�r��G�p�`�P+�D���x6^B�5�#Ց�(Ƹz���������װIs&�H�JBy��3�~��r��XH\�A%PӋ~�~�^��ҫ1i
4~��WP<��V ��A�w��jx���G!��;����8��Z�DrH/���G:q<��}������DNp?��ЦN��X`E�����/�f*�|~����5��-�{���� ��[h�=�>�v</Ǘ�N|%މ������K�=RF�F�1��m�~�/�������ܢ}o�y����&>�Dv�� ��w��af�	�'x�Doa6b<N�+��߆ƻ��xFy	���ǟ��/�GKRH:�����m�{��</��g�������\)���U;�]�����'�'��@s���n͓�g4g�&�:ҽx�Gr/�1�&n��{btb,�W� k�\p�R�>�X�A�����	x��s��8�o�������}�ǌ������?⏁f3q1�g��d���[$D6�]�N2F^%�sg�\��-�Z�7�m����܋�_���s�yx"��w��x/���k�-�������՚4ok�M��q�
s�B��\h�����@:�E��ӱ{����>t;)��o�oA�נ�������&r#�˵��|\���^��s�r���qn@�,�7m<�$����4��[��r�	_M>֚�(F���%7��q/�׸7��?�����&�qu ?�h�Q:�C�Sn3�
�#�_�n9��O�^h��\q������m$��N�>�	}w�����_��E�®���hs�	�7��&qx�q�]	���&݀[����?�-�o@op?�O��r��M=�pځ6G�E�5����z��&�ɟ�v%W��Czh�ՠ����>z����'H�2���!���<HP���~�ƴ�d��X0h��&�Ѫȣ���z��M}�3r%�����@���F}(v�x�f19�Y�N�ɟH�{���3�} �O!�@s�Dha���@��A�ދ֢K�)��G0�R�(*��!#��\��M�<�Xč�3ҍj�a�cA����8���6
��� ��>�\���������_���q�ʦ�e��.)�?�dn��Y3�gL����dgy33<��%wZ�+%9��HL����D��l2�:A��9�Q^���M
{�¼׳t�t��� S���h�T����Ф��~�\�%L���bbQ*E���G
��H�x��f�o��H���f�.�NO�R��Y!�q�/��9h���F��rOy�0=�� 
;<}#ر 3�8�Fҙ��p��"N�TP
�\f ��[��HIOo����ힵa�Y��
*gÄ��a�#u�٠[����÷��hm������ns�:���V�W�rNf�s{y����n8��hvxx�~pyslm:�[Z�hK2�/��o&V5H0���9�o�!%::+y~!O���m��z�"O���6X���0�ߞ>���?9���pc�'=�0���p�ģ���{��R�Ԛ�y#�Mf�Ū &s,��1��S��>�YL)�T�@��v	(i�����(4��4��`h��
��ۆ�y���k2E�4�w�9��Ԓ�R����(H�$*jP��a�/��KED(�5����y[ǉ��'J� �P�6�2/؟�N��q?Z����f9/��)�ȟ�k	�6ZsT�IXAk�Ԛh�6H���:o��*&�:�q�?���U��嫚��p��۪�)9�~n�N��q��\
Q �±Z��Qd�i6��L��2��t ��K��b�R9n1������#gh+�L6S���M�ϟ��B�i���jV5�6L�Q��T�x�؜.���
ؙ��39:�����XVN@��"%;1E�[�C�sz�bPt�Ë=�����xdh�G=��3��@�*8㑃���������`S�hăoZ>��75�j> g3���Q�Iyۢ���k> �~g����B��hUa��(�1��~��X-�
X�}#V�S�0j'r�(�e���k�����C�N.���lԈ�� ہX���ʩ��9V��^�+}�&2\� �F+sS1�mƞ����#�g�ɳ=
=a	 ��%���a	���,Ǵ
繠����Z7���ɚ�)[��.����}[�F���:\�����a|��#d���a�^=�ʓz3���Y���� ��C)���!^4NCZ4F�)�0N���!�C�?�Q�N�9E�����09}���5�����h!��y�f�L���2!°��%��y�}�$�(=��_� �9t~���L��?�$��V0� ��؏��|'@#��
��d�Q��~����~K���������'{%��?��0��0�>�%�o<��(�d�Y��G>3��֘�̀�P����P z����r��>���YN��#������1�� {f�'��H�D*?<��1?�����?��gr#��?A�I��q|�M�>�s -���EB#w�d��Đl��*���z��^/��IlV�sc��Ω��\���cz}���������j�����SgX}X�s��gO����`/ɇ��dmt~rx��8?�;�����&�d��P�:�.����L.�̆�"�@fe�1p�
�59Ee�I*�@���#�E��c`W���cM�SaQ,��v���y>3k6W�*�*�e�wE���EX��2��8���	ep�
d��W�T��x/#�@�
xU ���S(��� \V�k��"3��Jj���6n0o���9��0_a�Jܒ1���6�l��&ޘq}�滭w'��h�V�OO��S��zo�"��l�fyQ��y����SHJf�yzZV&��$j�#g�&*������D-<���f/i��$��fw�䟖�����٨Iw����n�M�řӠD9ez��
��8�t"���$�i��%\^Rޅ�x����iR\ܢt` ��Ls�����21rv��-�>�ItQ����o�{Q��|0f��9t>F:XNrA�I�tu����t��oa�}<�!keWw	 ��[is{#�LI�����Z}
��i�4�5t��VS��i`�~���S4:K9esPΕ` [f�D��'5������4RX0g��"o�7#��]4gNaAb�C�z=Ӵ	�Dޑg*��3-û�i�__��DC����˻�_���~���A�S��*����<tŎ/��W�u/���s��E��G�W��P�/:�^��r���^V[X�1{���[N��q?����ȉZȶ1�T�U񗉗��FS��bA'UQHg����.�=fi����m�{u�"��((���X'��:�Nv*w�d)�O�Ӭ*7��\�r3���M^ud��_T�%�_=��A�)�ms++b�)kp�ۘoE���
i$!���� �Wɓ~?ɹ���Ζ�&~3q����[�ͺa�f�A�=�ӡ�~��[�Y}}�Y�fp֊R�t�]r�r��ML�"�c
71�t �d��nrx%=v����z���J�Y��NU��l>Ey/ +��N|���*�by��Pɶ�T�ì����s�A��it���&9��Dk4�f�MH�O�K�)�#�-9u�t�h��Þ ��k���DG�V�B<���s���?{r��-�5W|���#��;?���~w�S/j&�.[;q��c���3+����|��s��~#����?�Y�;5�`|(�HH�����~I('�"��Я�������e[������I�B��󞺰��\G �f��{�J6�D������"����7>��&�-���޹����HN�ϔ��9�d�ij��:�Y��5�E�f�f���$�Q�@�0��ա7���KP�q��X�TX����T����c����-1���!�qk���RP�ʇznSܶB[���3���/�|��%��A��M��\��kI�'�(�9UB���p��^;������^{�U�bT�8���=��_��҂�y��"���ðF���i�~��Kg元56)k,�Ш����U�"��|�:h�Vu�PP��ϣ̢�cM�I{�nC ��(�$���
��b��T�����6VSî�����$�Jՙ�*<�d��1�D�N�MR�d�3�(�oDg�O�#�:d(5~]pA˖�ņ��+c& xv��M2�G�,"�8�ϧ������I+h��j@�IK��d�4�6��@��l��}����W������|Çz&��(~��5��9r��2��6�NNK)8Ɏ<�
ب�һӋDWjV���vg�Z�>N��O�kx�k�z�EgQ/�t)�TK�ru>K�-��ͷTpK�~�ZWe,�.�]j��Zo�(t��۷k�u�����~��6ڲQ�9˒mͲ���E��m��{��û�n㣦}h��������?���߳�k?��\�2j)�&�,����b��%�,Vގl:A�)X3-�L�,gƦL�x�U1�f��s)��8>Nk0ڼ����7��uۮ��6�!L�C^�IVS���$�w6_v
�S���j�I��s�
�Fo0��PD��:�ګAvi<R�_g�Z�gm�Nlv�O#�k4��9�l�7�-:���3��9���czS�;���L3#�n6������[�g�?'�q���<d�@���Z�5\c �q�¯���^�56b�9���m�>͐t0~l>wn3[I�g[[�Z7�Or����D�rL�:���X��z�o�U�v�p~5��i�	��
�Pv7�Iy�_��y�,�$r8rl�I��/���V	<��x��i�
E��xiD��YyzCU�p���ʓ#�$Wڡ2-�z�o��ా4*̤Ì���<|t�hsGls[��^��K���I ������^�� ��+�I��Z~s�r(��
F
M�|_�Iǅq�9�qC�=\��&||!_���f_���ء�s��{/����y�s���u_�F��w��p!ډ�#e���H�ԋ�A{� �?�?t�E�����gva���Ǐ���E˹�(��w�mF�&>Ϙ�����S�R���<O�qN�����MB�������	�����Y˲v�=�'�I���0o�qqz �1�1�KhOo�i��{-��<g��ڄq22���8y�/Jh&jC}hE/!��������\&CbBaf���I�� ����Qş�d�t:_r`��w�9�|�d�"�y�;���aۨwh�ё�����7RA��4�3�z�D5���c� �c���V����U[��)�ŭ8�&w��	�ֈ�w[Zk��U=�ZE���dg���&S`�F���(EV�{ɔk�/o0���	�W��ySN��X�j�\�
N�������/���);m�㬃���ς#)�]d��cv��Q�q��t8���c,(��&�o��L��n;|ţ�??���}��+w?u�廛��gt�*߂K�rƷ�3t~�?N\�$����G^|��g��UD��@��(	��?�I�����Jmh�BI��.�LK�KuM��zm�NW$γ�K���U��Ās�f��^l��&�;7i6�;�M�M��m8A�՘/�5���L�\H2t�/؀��S�)>�~">*MbS|F
��?]������Q)=3F���jX�
@W��Z22�f
	� 	�pH�V�7	��L�)�-N��آ��E�,]��&��&�?��11��EIA�-[��i�b��;ꇡ�h!�ߤ��~顆]��Y�EŊ�u�}T���>8\�N��3�i�C��V���_ߠiЯլ��ʋ�A��|�b��⑛�g������͉�Fw��{��Q��n�:�����:���/����~���T�]Q1;��%��s:s:u?��Oo���8r!��H�Uu�9�l��u�mV৛4s(���x�|
*�-�3g��4����LpY5n��75|-Dg4������o \&��f=�ԟP8����� $�:<�xz�S��S��B<[w[�x��:���ܑ�z9�70��_Rsy�X����I�[_����c�EP��4ؽ	(�;�ȕ@Vp��V�
c�ۨ�Շ�����)��<寧P���Y�?i>�?��ϲ�K��*�W'����W'ջ��M�A����ΑsN%b���KlK�K�]�]�"E>�e�A���Q�v-i�31�wŹx#��9�5�0�K-���י�m�ϝZ
|�Xf���r��flNv������i�A�؝xH���M���N���y������[�
����}'�;��k���t=S,l.�:�JIJ��s��(�b8e�}�s�6R��:M�Ġ�ٍÅͥ��&߄Q/ds?v�=ilP[���H7'N��1Ӵܷ�}t����q���|�=����^x�,7�m����q��Gc؍9l��oL|&J{v�v�w>
��.�w�$����Q��Ae�^�QƩ����.��+����C��e���ؒ ��N���1㟬��)7����Q��f�L�/ћ��UW�h�kp�ŵ9~@~��g~D|$٤3'6�.n�f����p4��7�3�M;L#�e�k�����k��dw�oم�mz��jD�4���2C�q����6Y3���cʹ��4�(��2�>7�@�����ï�*�W�����A�"v�����R	��t\�JP�J�*�	�QIoJ�8!`*�D>�@`W��j4�+��XT��nfV"�UZ��W��.����g���g�bi+�[O��U�Ӣxƪ\2Od��
'W:���O_�������zݽ'�U7=��n�7:�>�S��'�\�硔��Ͼ��3�Ow"���z�K��Dq1�@�r�=	�b���Sb����芁Sb���sWl��-1�5��qy���bธ�rbl��m1�9r�iAz�� �x����FsQ&�?����mI��9�8t�G�L���Isi��*`�'9I4���we>�I2�dK�.��TMۜ�o���H7�-^��x��[�F��٘�b�R�ɦ^�+w!��{���p���)[n��ə�|'6RJt�6�?���H)<)��7�NЫH�Lt��mq
��B�:�G�;ŧ�o�d��[�Pߪ��N��"��D���D�����b�����H6ͲӖ��9�/ߛ�d��O��|�|J�)dN���&�xg3l���҅K����i�|n���|��b���ƛl)�nNH��I�U��W��H`�4J�ylE��d  �|���[��������Y���{c�ˮ��{�Y�������ȿu��w�#�OF/����\�=\
>�vi6*&o���f}n�997ǜ�[b��P�2/�2��ܚ��ܕ�6sؼ#��$?nNȦ���,*GIz4���I���%���}�_�u�8���(��L�i�����=e-���ӗ�[T�U�K�t-�u�.�V�N�oL��?�ي�,��3����59�9$ǕoYh���%b�<`�c���Y���鏧�s�rh�.� ��t�-&�2�.�ū��N&V���wq0/{�y�n�49��E+�wŻ\���.Θ�<�s1�?b,�����&��e�g�w�����U|s'3��F�5�� �O ^�߰ ���qr�ߒ�G^�+ygz�x5%����^��*�C��&�,Z�7S��h	y��г���-�j��ɑ霖�n�|�P�+��֔�qD{BK�څZ��W/���;o��MZe���Z�[i�>Բ�8Z�ݴ"��v���X�fg![7��i�tt���{��oSCv���H�\�1�7���%X��e�&8%�g�9�����b��.b������7ŉ	`�/�,D6{�ĕvذ�𒁥�7��n�f{j�����7=Q'���k���.�����7�������ښx�99#��3�����ͷT���θ��7^2�%�%fW�/m����m�|U
N��9����Ū�&��qq�>;f�1�#����9-^��T7EHK��i.Ԥ1�N'��&bp8$�h#DrS�r���Q>�/}����N����Mv;s����VQ�9�7��Ȋ�xZF�����.n>�[��EF/��GG;&{��5�4G���_�~�*M-�F�FS��
�q7���N~;�L����8�fuZ��d�{�:W2��.�ř��q���Z�n�ع�҉(a{11�|��0��J�Y07/���"|�\=���l��5��\Cxr�d 7�c�vew�4i�xv��,�αɷ�����>�U�1��g͔�.��)�KL�D���"'�R=z��n=[P+n�oi�LH��Q��2�d������đ���>�}﷯�!>��߽|n�c�<�:����Jۏ^}��u�������'?rSpHֺȻ����Q*����lH%XU���[k($�s;�у�C��]�>͓܏��1��/�S���j��Sm��\�6ۖ��K�M�+��:5S�m��~w��>�n��m��%ţd1^L��x���vH��KD+�|J\��KI����z)�J�X'���?�j���?}a��:�E,��i]RZ���W�	{�{�}�d!���Ud+�h��OO\�gZ�d�(,��6���r~�K&�}�����?�:Λ���>��՛��������=��9����|x����x�0��\������?N�i��nq\��n��\����y���]���/9O:#N^��[��.8n�f��b���z������w5Y2�~j:��J̘Mac<U�F���1#3&�i�}��r�Ȭ�?�].��#}��̲�_8�(b��c�q�K.�Sv�q�>�ΰ�wr�0!Q5��Z%�v"�ݦ�}����^�8�ri«_1�wz fUy����䜡_�V/aj��1_����-evb����2�]B��N�J��~%jmz�� 8��i-)�j�+n���f&��[�=��v>��/mՉ��܍K����.��� �ѳ���/j3"��\ͽȁKʤ)gc����X��~/}Kxԟ�PBMf�P���Y�Dp?��44�����5�dS<�ɞi�A�ڄ>aH�%�H����pTxI�
���.�@M�_�߽cg{�=(�	_^U�r�od׬Z�U�D�ȉ猬��U��S�i������J��Qxƶ�B�7�zDA�tP3�m��.��jxl�􂄈��J�v��p��}��|�i= .=L�o�B��m�^�nu^2�AS�>���*�͘�d�Nb��G����l5Y����4�����=f�8m���A�t^ݛ�;N��%R�l������%�1_���Ԙ��3���mM������[���w���oN�����-/`ScF��}�_�4�����y�<��H�_�i�<�}�m�����E���z%"�+|iH��H�i$�4����b�Q/�i{���q<w4�e|����x��Cߕ7��T��43���cQk���s�N��^�~�b"G5'�rl�� ��%�81zQ-O�Y+�ZD��D�i�}��k�<|U�x�q`|ǆ�[���?����o\�qݮ��^�E_�wg��+���\~U�u7� ����ю5?����ۏN���+b�W����?ye�����ͱ����;�{d˵^���ߛf�5�|�;�+�N-�C35M�a����Az��W�~(��#� ��Z��B���*�:�h'��B(�u���Hᐁ��p)'��3�F��懚3p����0-0/��%v�s�V���	�K��J'�K/��ڑ��Qx�G4"+�G~���iu2��X;�q��|$�P)P`p�*�9ɐk�PyT�uh&gP`=��)���厩��f��Hc�T�	l��C���Hc�T`2�sX���,�%
�CN{��Q��C�����_��1���7I�b0吘���ZV~�V���:��`=����S�)0�0�
<Ly]���.I����\�)��ֺ�x�U`��-�v3�@�̽��FJ[��6��2����)m��18`{�+�g8�08���	�i��08���Y�Bq|.�2�<�<�������g�t*��6
��
,���e��/g0����88h&��� jD�(i5�E=�v�viI9���qʻ��)C��H���C�A4�r!HC����	-��Z(�mPR�z�q�q�A�ۡ�-Џ��B�]��v����?:��~&*���<FCz�\	��8��v�Q��r�PJk� ��9Q>t�yt-=�/$��k���'��Q�W���F���l�4���m�Y���`���\]�J��r����a���ڇFm�1)�;X,)��+�ʿ��
N΃�]�r �P�0��Z����_��y1�җp%��]l���\sbZ4��D��#υ��Ĩ��ǎ�r4��C���͞���qz��J���-��7)�s`� 7�����KY��O��^]l�5��J(���ֱ��YM�kē�A90� �
�Q���3	�W|0*�����k4��������򲖵U%.�V����ȇZ��ֲFig=�s���jg{�b���.���n�G�����[�A��S�K�]�+��L�<s��͠lh�3e_|]=_��_�R�S׺��3u�Ti����ѿJ��Й�sd�r��v�vƽ^��N���������Z�W��Y�0�w}�֣�n�J��Ť�����XP��:&�݌^�_S�T�q��ʊ~U~Y�e3{@)��Y>�����ȴ]��O��\��Z�����K�5�Q��}l��<w����������R��>�Ԩ\n�2��������V�̤��3����[Au���` FS��%KLHo=��e��y�+J��TC��k�Jekߧ�6y�!e���� ���>�\�(��l6V�A+���%~�:HL�w+r�������4�_ V<'�Gt�e
����?���X;��*�K�J���[S���1v�*]�~��������1���FY͇b$�j!y��������^�h�1��S�����ʊ����A��Se�_����,c��T����6��M��uTu;�#{�L���H�-'��0�c,��?�ɲ�`3P�׼�h� ���4�Žs�;R��$�T�4ɧX�2�� ��z�U�~q+��U�r`�Ij�]�I�-����[)��uK�{��h1�V�U�J*��zv�P��
(���,�hP�؊�d6i)�`�N��ȷ0]�I,OsU�_}Ѷ���@o���]�� (x�E9���<��0m(�W���F�beJ�\��p*U�lD��j��C�K��2軒�G��/fpM���
�e�G�g�g��ֳ���^���Y����a1��s	0
��3���x�?MJ]#J�2x&gU�x��Q3ɿrH�r���md��ZV��60����.c��Y�+U�fC�JyPp5�%Q�ճX��>����[��'����)q9�\-�ɫQ�r�l�hm����l_u%�� �*c3n�J�b&�2��t�c��P"�G�6�U���G�^���J�/��e�'�����_��ǥ������ΐT���;��/$�������z{fHe��R}�����>4���!��KCk�CۤھPO#m�,��wˠ�ݻ��]j����O�H������&�yR}���SZ�i�m����v�HK�tБ;����~���K���vw��%eD��A���-��!H�n���-=�~i�Σ�QZ���͗B!)�im��#�!u˥RGh�����N���vu�(��
vׇ�o���ܘ�
%�Tʮ�j�北氊�P� �fΌ�Ŭ��Qn t���`GhS��Ի��y�u�2���ථ��R��u0i�T߻��G��j����Iu��������d��f��-h��"m
n����)����J��/Կ�kpزv;�[`Ų2��������>(��:a����v��wo��:��`դ`O���v�
�ΐ$u�ޞ��RvW���}���%I^9:��� �eK���<��|FAv�2�Dy���v�n����
DeRAb`��0�[�@�:B[){�3�����f]�u��ݽl5�ʓ���ޞ���98�7/??�3c[�Ʈ�PGWpFo��|���5����I����� �vs��u�]�{c�x��rC/N����x:u�Q~Mفtzut�L��1!h��?�ȓ���~Yn����YSV�l�H�ka�P������yP��� �T:z۷l�����ɦ=N��Ԡ(��sE!��䕸(���k���HU�"U�z����Q���/�Aa]q:�<iSoG�:��C����:�趀��n��Z��	�0&>�
=��V�tQRY:��7N3"�u�n�'s�Ҿ���Q�i/(KFˆP��*b��2�����<Ũk{��b�9�#�7Et7�MʊR5��y�M٢����SA����]*���y�-H��W����������"P!e�5@>+OZYٸ�vE��e5�-R�b���E����ȓ�u�����^���[V��ʚ�e+**k�H��]M-��J؏�ic�DT��4�Ϊ��K![��rYecK��������:-����+�A��Ku+��j0|t[SY��F	Tjg��P&� #5,-[��U���g���ֵ�W.Y�(-�]V��E��lѲ�<L�|YYeu�TQV]�$�Z�B/�M�n�� +���ৼ����N������y0���hӕ��<�����2dq}-tO�	-jY'Ю& �BY-MY@���IZ*eˠ��8yx$��d竵h;6�Ya�5�g���A9�t��Dw7���;� w�����4�9�75߼��?{S��{�o��|���4߼���=�7�i�yO��{�o��|���4߼���=�׾��rg2	���X�_��QK{���S���n�����4~_�/�/��d�=����R�V���:���Cb:���\V�G�P$��ȯ~�L��ˣ��R���q����Qm�{����u�_:�堓�3�Kuಸ���n�8��kO(��M��߉�g�q/�=�@�����R�k A���� h��4V+A�� ����K�\��[,�⒠-�v��s��!D p@�Fu�Zk ��Z�GKz!\��3���9F�,����d�����խ,�we��V/�ӊJm��6�H.��HN���ԞY0DS���hY"���_���cȊ1r���@8�R���{3��x�9�a w�(�GͶ�2������G�\CN��
(�����@8�#o��W�Wt9Iy�B@8���!h�Ixބ������|!��� �#>� ��@,�����YL�yb����g���5�^#�i/��`�/_ܙ
�HQ {b�8���g9 Q^Xi��C�4� r�F3g��9GK����o{%�������@��W`�W��B�>Z�^�U4a�!�!��A,B���^��*�	�����4
Ì���E�D�[�+� �'�f��9��@~���@�����47*3B=�6"�"��P�!�؛awG�l���q>��j!��p-9B��v����!���(z�����uȿ����� J4�λ ������{!K#��wD#��D#��D#o�V�h��� ���� D#om#@������r�n�R��l.m.m.mC<�F�Oi��hn.p�>�/'�=t�C�x�a<�CW�k�P)���!J�C~<t�Va�ؔl�߉���CO�<��C�x(I��?N�G+Y`��2�� �dh+I���̧�N8�	���4MFNJ�鴽����y��}�����2<�ބ��=b�,t�,t`�x!�5�B�B����w��
q>���@�������!ԫ���F��W����g��T.���SE���rw��5צE�H1JL�m��l�ؼ�S�?>5#}���N��R�;F?Ս��r�%��4$� /΄t.`��ȥ�ir�'!-u5A3�7�}[h����\����	����(��x��(yr���������wCrPb�\s�O=�P����F�W�d��*��F���������r/��*\k���s�{��[�Rk6m��=H��`.��b�z�X�+��q�?O�[hj�9B��'�n!UH�uv����L:�N���x�!]<�{���x�H-Oc��"�1�e�`A��pWE����vT�V
�k��c��Ua�g۫PU��\_ո����B�e�#���ar�8F���8B�nL���� ��v�m)4;��Lܺйо�V���"Q���֭s
�����9�DjK���Ԗ��w��:�?�g�Ҥ�� � ���܂����q�����@b�����8S<$��d��d�Lhx4<�e2�L�����d*F22�fg�!��<�	8��'q=�p�O�8����4C����P\8��4M��+(7GQnf#qx�%�O�8擀�u
�+��"���Ҿ����6O �-|��N'�O6�H{��ożmk�;i�[<��p��B���"իi�|O�ZhlY�U����x�-{��O���XEu鬎vVD�ZR|��bZ���UL�*�c-�/ac!&�u�#:���|���%F�k[JzˢD�o���ΫS�ǲ}-a�gQ��VM/�^F�`O�*�qJ�����)�n�J�b�g�n؂���
�g >P4��2\�}_���@��D�*��P^�|U� @i�Rx�Zf4�#G��P8�r\����2�^A���oQR�'q�����A4�Ӫ	��F�q������ ����l�O�҄�Y�[H�Š��-�ɀʒ�2��� 떱Ӈ�?�}I�
endstream
endobj

13 0 obj
15512
endobj

14 0 obj
<</Type/FontDescriptor/FontName/BAAAAA+ArialMT
/Flags 4
/FontBBox[-664 -324 2000 1040]/ItalicAngle 0
/Ascent 905
/Descent -211
/CapHeight 1039
/StemV 80
/FontFile2 12 0 R
>>
endobj

15 0 obj
<</Length 326/Filter/FlateDecode>>
stream
x�]��n�0E�|���"�FBH)	�>T� ��"c����I[�Йǵ�fVͱ1���I���~0��<ݜq��`=���_��B�m�y��1�TA��k��V�9��A��4��\��j}�ެ���"��,��ޟ��ٗn��T�F��[/�k8�DL�d+j�0�N����"�JQ�u���jqK�>;�[�o��]Zz���r��9%�#��3�'mΜ!?2����8ϑ���rE�Q��\#��I[3�71�7���#2��$2�Obd��R?���^��s�/���������~�"��9�z���`����ɢ��oZ���
endstream
endobj

16 0 obj
<</Type/Font/Subtype/TrueType/BaseFont/BAAAAA+ArialMT
/FirstChar 0
/LastChar 23
/Widths[750 610 666 666 277 666 722 610 277 556 722 277 556 556 222 556
500 833 556 556 722 556 277 556 ]
/FontDescriptor 14 0 R
/ToUnicode 15 0 R
>>
endobj

17 0 obj
<</Length 18 0 R/Filter/FlateDecode/Length1 21648>>
stream
x��|\Tי�s�3���ʇ�sagD��aA �
6`���f�j��I0�n�&M��ik�ִ �h��f��ݮ�6�H��fk�釭M������s��aL��������{��9�9����<�{�:���}�DH&W�.op�A���_�XJ�����?r�@d����������ȸ�o`_��ڷ>Mdq��}ޞ�V�!�_
������gB ���]�w0_��ѷ�����c�'��~8x�����W��|����wЇ=Ee�@(�C�Q"O��|�W�A�'�(�8����y_����c�J=YQ���B���(Q^���b�I���r*���";�OG)�.���,��������t���9��}��Q=Fvf%��)��Az�n�!z�.P>��K,r<�4Z�5�:�+z
\	TI_��l��P����|(z��)?���O��<��r��T�?i.-�����B;��+�4���Qv�5eS'TJ���NZO'�G��&�g�i�I��/�tv6z>�+����I��`����ɕ�c�R}����ы,�-�]�%ъ��>J�I�;�	v8��:�^z��1]�7X"[�>�N����᧰����f���#z���t�-g˥t)�J���!:���<�c��,��|�P<Y���U4JK��oB��<� ��ae�6��s<졇�y��x	q���zY���?�5�X��GVZC7�6
��K_��>Kߢ?���xp�S�m��p9�I�6�*`{#�[ � fi�&p�^�e*�X�X3�c���l���^��R��[����'�\Ye0D�AR-�^m�~��G�O���������X!<�1ƿ)���p}Q:'�$�!R�>>ya�oGGȄ,ۀ8�W�?�4�P�v��%,?,=)ϑ-�M^)��V�]�K�O�g�_�!��3C��k8a�NN� Z��]�����Ji5�ٴ�q�-t��'�/��ct~����G��f�X6l�C�.d���d��o�o�����M~I9��UR�T)UK}���~,�*/�����\G��R%j(�Uc8hx��=S�����/W.�����w^������򛓿�n���v*�e��NX� r�8�� ���`�����5&12>�ِN�Z9��jqmb7�ڌk+ۆ�˺X?��� �(��}���>-��������)\_g�q���g��~�^��Ē�l�KK�"i-<��6H�R3�>)�+(I{0C�J��)��r�l�e��[~P��������")N�H)S�(}���9��O��V���o8bxָ�Xj�l�a���	��+&����e���)g�n�O���-��x���K�.2��N�3J���	���첬����/�~Q���"��ˑ��ur/�CQvBzYz]��2��J�f��߳�K�R2�}���|�vëD�Oh�t+;+}[�]�=���p��7�~@�rAJ��X�wJ`пJ~� �)���ɏ���a���.�T~A9B��6�O�2�����F%W��������[L��n
�O��=�~�&����GY���يHf�G���l���@��F�'�gM�ei����yy%c�%��nf2+F��>�4�p��{���Y	e���_�|��؆�"����LŴ]����xW}�J�4r�.*�>C�D�����J4�vPK�n����H�r�v@�_���~�=�e*V�Y�W8�Ń����A\=����Ɠ�R#K'R��#��Ӈp���P��F+NX�bgލM֐���{L�[a�X�MJv���;�gT=����}�*1w��ۣ�#�p�&꣖�c��D�h�ih��J)���طp�;;�}��~����2�7���o0<M#�O�w�G����#9�PNы��~����gi�d�4���8��Ӎ�G�V�@�����q�{�Zl8��=��JŰ���X�7��?���]�[]�7|�l���kV�ZY��dyqѲB�ciA��<{�-'[�.�Z�pAfFzڼԔ���9�Ą�8�Ѡ�#��VݩF�:#J������m^ �3����<�S���9]�콊ӥq��8�E-��B�걩��W��	���6��V����%o�a�ggc����R#�S�D���x:� n41��V�K(t�hB"�D@�t[p���� �{֍Jg�Q��*O$�V�-��v��'�tc��javv{�3�*�m]�UD���*����2bjT?����γ#�LX��ӑ�c�������\�\�VE�o��1݅�ʶ;gR�#��ʻ##w��c7�ͤf�2"���s���A�ZT��ho��;�P�~p�4�|6�t�P#�
[�ȎNL̂�5��[��u*z�xԑ�6[v�|���[�ht�4��t���)��Q�\-��s�u �<�M�$�9T�<W�-��""j�
K�l�i�|kh�{��ig��|�#�#�u�[����n��#o��v�w�1^c�[� �,�J4�cp��,]��T���7���B�	)bZT45!���uE~v6�ރ.�B'r��6��R��1r9�#R'���Q�o�1���N��I�2?�7�/ْ���_ai�C�i��[ݍ��T�H�ۺ�Y=��f��CL# �ŎH�ڐz���8��j���Y��#��m�B�]�������iJ2�%qY��(�g���VG,�5Zݞ���W��^�D3=L�)��1��~V�yI#2V��m##	�h�جFF�mj�H�w"z�˦Zl#��6�m$��M�D������{��D?[�Ԗ�b���q���j��vʂ�ѻZ��$&UvV����vJ%r	�ı�;*���ê����S.�����wO0���Q����,��<�ȅö{B�(��\��;�q���q�X8�4a�'A�>|��lm��<bE�"%�w>�D2��7�J�i���6Ig�ȠLH�xR�N2ʌ3΀.��
(��d���Ͳw�,��mz���[��Z^�=7{�[��U>{�e��quN_�B��O��2:3�e\�P(Õ!���.�q����p���l�=�_(��qj���Ò����qI����?��֕2gN�k�����ɇ��%+ə駥\v���펲M�K-���)k�ܵ�ƥ+��c9������s祥���^y��rn钼<[��2ۘ�ZvӤԹ&-�d_`�P����Z�X�ۥ��7K?�o���ʟH���|\��]5e$�M�X���L^%/NK+0��jM_6]��mqLߖ�3.<7��P���<8�����<gx.��3^L1����V���,K�4,�������a�OO�H�*�ܐyw�!Ք�)I�2�2�f9S2q�0�)U1O���x׼���,~B^�J��dG3�Ȕ2O�+�{Ǚ��x���2��?S;R��S��	fr��l]@�K=�ʝ�1UR3�fo!s���ׁǃ��!���K@�gZO�Q��!�t��R�e��7�oz}�%�%���;�w����{��3���ٙ�s�m���87%}�����k%���䭙�f��>��N���o����b�{h;f��p����+�V�b��&۪U+J��F�d�.Y�j�|�������y��s�;��⍏�u��Z��&߶�
��/�����S�y�p_�NN^^cY^�[���[0�%��%D/�%�����u�%�u�{��r�s�`M�����\��?'�������n^���S���=�����ߗ�&����ڸ�	v�x~��&������	���l����	v�d��QT�5�*�-���Y?ͣx问�&́tX�fr<�Ē&�a�J��J����0���+�W);Vz�T*�=�_w��I�R3W�f�٫S$f���ݯ��"V4�_r\*���R�ڢKˋ+��V-+Z����s�mٹ��l�h����KP�X�R��'�N\������՜�E����'��Xz>b��n�#�O�H�41Y�9y+K*-=mE	n�����g��Ϭ���Ǿ������������Eٙ�~8ݾ��������h�m���W6������;�������XՒ,g��ܘxd��nMV�{q>�ط���g�ܝՑ\�F\f�x���/���~�����'�')ƙ�'=�u����l\��/`®��3�z\_e��>&���$�+���hL)U~<Ǯ�~�wgN^�IZ��,F͑��LmR�+�9��ʐ��a#�H/谉�Ho�p�:O��a�9Oɉ���skt�Qr�f�Ȕң�29Sv��t�@I)�谑榌鰉֧���QFʤ�Sej����Jm�d��Е��;�Y2�"`#�/�����p��sC/(�a�pQ�#���:�.��#��~�È��u1�J�a�0k�#�Y_�a�0�Fop��q@���6�=N��<G��	��ms<)�T�)�g<O�h��9�&��)�^�B��Lp�q.�U�y����/�K��<������~%i�^_�C�e<��P1-�R@��O>��(@�(a�GA��Do0�����2P�4�K�f��0>L!����{��i�U�^�>�L��>�1=�����!G�� d��p7`<�clL�:e}1�'�9�[�U�m����� 2�i�λ�~`9u6��|�q�?�Ӟ^�*���c�"�}��tOU�e�n�/��B�^��ap��ȩ���6���ŸA��b�Op�ht�H��Z�-����/85��~pzV�12�(��%ƨԠ���]"�|~�`뀰��|Y�ߌV���o��º�TL
�)[D�BS����k0�ӣ�1�#���o���N�3����="��ҝb.{�Gk�o�n��uR%8��sq�+��_ϪB�1�����4�C�3.���-�?����Gd�������E����}"?�|
O��^!1,"��A1/�@�Ҳ�K��峇6C�{F��(A�=��-$��|����J��^��+|@�eM+��g6�����������n]��=��wy��'��+8sս�]����Gi暎���ڰ��{*S������v����KX���������A��y��S-��YQ����^k^i0�M���ʭ�3�����w���#3%�[Wܚa�����:E����g�ݻ��;g�8m���p�W$(˄��b/�����}�G�V���j�.�xŻ/�Mۉ4�c��-g�_y����Q��fM��ഈ���'�������;_c���gll����Ah�^�嗖1>]_���A}�8��C�����|���9��:���b|P?/4H�λ��l���}FL�������W��c�����'ՠ�u��;{H�n�{ϯ8f�i`�fĈϲf�֚���]�/�Ÿ��W9�ګb��z�8��W��k�.pz�O���:��Zz����w!m�B��:-4���-gh�s�~��a�>�!�R�l���ٹ��GuZC�˙��윞��^�]��y����.uP����4@ڝ�t\v��{�I~�=Y��{���kݻvs/���s�{��(vnL�(v6M�i�2{TH��|u�_���ǬME ��o��p��3��3Ϻ�=q�F�Fo+�8�i3([Ы�
�%�h��KČmgR�6��N�ь��v��U�*��W���c=�&tx �Ep6ٛ��G�����J`6���b7��5`��4S��������Sζ�Vh�Y�	�f���t��k�<n?�_-��);�uK�"F\2�Y�߇6�f�M�k���g���C5�/a׼L�U���٢S�q��qM{�1��Lǯm,��7��*N�F������y��qo�Eo�+m�*�7<�<U�7�l��]��5[�gH����>ͥ����J�F��f�R�Z�\q�S��f���Z��L�.��e*C�E�j�ǲS��8�M�ۙ�ĲZ}�5�I��7�3���EL�]-S��K�/�%��K��~��)0�����P00����T���������f_�7��׳L5�k|]C��jc�7����{����@��߭v������/^���f�Sm����`w�{'���j�pO�kj���ԁ�rzCj��k���Pu��	@�
u����z�|��`�oHs?j[�z�o0�[��|>շ������Q4���u���A�����B�Z��|!�Z����;���P,.�"�:]����
pK
�b��
q%���Y-H�BS˦֫��3����vy�v�������"L�ĜTy������^8��-a���o��r�������ޡ�`X]�vEI{`X��ݧ#Na>#�P�!5����Ʈ}"Ξ��n>�	z��êP�����1��{`��@8���CA̲���(?����T5�<08�O��hS7S�`���&i3�}��C�A��çd����%���#8�֞�����w�R��LE��� T���=�=<������Ȝ`N�s����SЩvyC0(08��������늊|����w����wY`������١'w�S��~$�s1�^��ZE��s�s��X��p�o�o +L�t�z��b�{M|B"�/Ƈq}C^�ǩ�a�!����C}�rp�8P]Xw�<,^�gpο�n�7
t��<z�ûx�����M>�8�_�E�4~X ,��A�_��k�{��~���UN=���1���沆�m���s��@����>��0
�;�����0�!������0$��֣tMS� �R[z��{����G���C�0F_�l���p,Ŧ39���k],ͽ]�=��?6#�6�E|5�sE'�����7k�zg�:�a�
�1IX�ڊ~�h��ƣ�4V�nu7{�����qKm��J]�nA�S�Z�ZӸ�UG����]m�V��j]mC�S��55{ZZ��f�vSS}��چ���U��
�kh�1S�����*W�����pa�<͕5�+j�k[۝jumk�Y�n����Z[�=�Ym�������*�m�m�n��&OC�2hN�lAGm�q��U�Ͱ�Y�W����\���U�i��� Y�e�z��
NUֻk79�*�&���)͂M�nk�G��ύ����܍�Ɔ�ft��uj����Su7׶��T77B<'F4
!��Ѥ�P��f,����3mK��]Y-|�L�e��	�'"�x�}̌g�x6��x.��b��h�˟�G��Ϡ��Oˏ�_~g�=�\ot�����F��]ot�����F��]ot�����F��]ot�����F���?��h�w2ӰW�ע�<����3��ўĮ-s@����+���J��A� 굳4B�{I��a������~a�$���smX���~6�]��ƾ%�A�*e�U��|���^3fY'�ߍ�K�����E�MG�W�<�B`,��Q���(��Y��q���5�ֱL�c�%�8al����_��>g��X�BAyi��BV�р�%��	�K�I~I>��(1j<Y�e�&��#+�A�\���s�J���������e>�1���'�����Oꔓ�s斐;$�K�΢~��e����(
%����4r�|B>;����.B	�BQٯ ����c����{��h>ڃ�D�%��~��hF��G����r�gu��觡���> �B�����b�?�����b\Xo�ɡ��V�{1�*J1��>@�!t��LA�����im	�]Z�p�:�mst�xzf�1��V��VD�VD�VR@�%�s��S(��[�sxnAT������GmAQQd�=��s|�Y���c���=y/�X ��w��[�d}�k]%�O˽�K���*94݋O���v��&s^�����8�7� Kk���=GC�h�\�R�*E��-���hW��X�K����~�R\�R��%�GH�����P`�(c�;���eK�_�o�7���!Y��Er��(wȆ���1Ӻ��T��VN<�I<��|�!b<k|�x�x�hP��F����i������`�Dْ�&'��V;�C��AmA	�FQ��U�C(����C��9�	=��/�5���d�%�l2�J&JJ'JP��(�1��2��,u���P_��F����3��y�
,��VQ�$�������A���N��_<1�������K��H;V�0WY��ĕ�*%%���a���8�l{ ?p\i�5���+�r{y~�q��Vd/�/:�XmV�5�z\9T�D���s�JG}�~��S7>�(.m���'�2��Nv����;����G�Ɋ��%��HO��b#.B)GiD�@1`�W���ڪ�8���q�ӥYt�?>�nE�{����(2d?��[����ߨ�x+��Y����6�����t�QtNފ#b+��ڊDyE����*o����q�q��2/�o��4�B)s�,n���L0��D�Q�-�rQ��l4�������o4/ ��7��D��Jt��t������)���|Qy�~+�Q;]��oe���m�c��������d�q�����<Q'��/ꍢ�s%Z�߱��Zͫ�f��a�N�^,ꅼf�=�\�L�O��p�b��XY�uB"Ѱ�X���X�4A�_ce��>��b�`co��^����Y�����?�Z:��2�>��P����X�m����Y��@9q��aj㎲Z���>�1g�~n̹Z?KN���1�E`?5��'ǜh�ٹ�;�ʖZ�sY�J������^�X�h7h�=cN>��+�`�c��h�p+�a6j�c6�dل�EdF/$�h�da��rD7f�R�O�/Z�\�4w��`�cG��|�mA�?X��	�N�p�Y�9'��)�ڞ�~;w�m��uNāp�9!���Q9^�=e}��g��MP��@�T-+�~ζ����1�m�g��o��y���섵�>�@v�A�+���6d]��	V;~º<w��R'��.��<�0e����J2�a��6u���n4�7�0�TS�i�i^\J�%nN\R\B\\�1N���(n�D���z8�h�I�"`��kI����$��H�\'յT�HJյVDV;�&L���G]$��m��}���t���6$(Gݱ��E�S�X��.��-w�����"g���K���?n�1�*2(mOyFy�s�VW]���k��'�1�����-��H	�Y�u��o���vKO�))ț��S�fi������U�Sl�#�Fe��l���(���z��4��T���hLϲZ΄�yV0�i�r���x6i1�
Y��bΆ|Є%��D,YKN"!lg����s���v0��W�i�ͮ��Nv���څƦy�5d��#Ł������ٸ��=��/�t�<>����=��]�:��s�O��uvu������櫊�ت�Qo�5�ݜ�U�R���m�������}����u�t�=��r�5����*��G�A���G��:����z����U�\���F㨢��&���:f�W�Y�7�ű>;�#O+�c+��I�UD�(�T�.tsV''��sG'e|d}����1�dz������WM��B�������ƪ�n��T�?R)�D\�U��g������e9Sv�L
��/;Tv��2��p;�)gr��H9���9�r��<�c䄛ڞr���C�<�tba|<UB�0Z����0�&DPB��9��m�����Q���PV����Q��(BQ�vԟB�"�8�ȅr�'�_�5�;���!���,Y3��۫�-۴�Ӡ�e��c�+�ɸ�ft�wQ~����B1�%r�>��m{�B�	�0�B�0s `<���A�����ىO,4L&�6ć�6��Kq�/���
endstream
endobj

18 0 obj
9824
endobj

19 0 obj
<</Type/FontDescriptor/FontName/CAAAAA+TimesNewRomanPSMT
/Flags 6
/FontBBox[-568 -306 2045 1040]/ItalicAngle 0
/Ascent 891
/Descent -216
/CapHeight 1039
/StemV 80
/FontFile2 17 0 R
>>
endobj

20 0 obj
<</Length 237/Filter/FlateDecode>>
stream
x�]PAj�0��:&� Y��JB����n KkWPKb-���䴅$f��avť�v�%������EX� ��R�:���f֑	��ے`�����7Җ�?<�0������O��q��k�_0�O\���Fʹ���g�u�,�.m'���o�*�ګ�`a�� j?k�lys������w�0�O�4YѤ�J��U�u�q�c��y�u�{8sr^��17+"�-�)5sA����1��*���tJ
endstream
endobj

21 0 obj
<</Type/Font/Subtype/TrueType/BaseFont/CAAAAA+TimesNewRomanPSMT
/FirstChar 0
/LastChar 4
/Widths[777 250 500 500 500 ]
/FontDescriptor 19 0 R
/ToUnicode 20 0 R
>>
endobj

22 0 obj
<</F1 16 0 R/F2 21 0 R
>>
endobj

23 0 obj
<</Font 22 0 R
/ProcSet[/PDF/Text]
>>
endobj

1 0 obj
<</Type/Page/Parent 11 0 R/Resources 23 0 R/MediaBox[0 0 612 792]/Annots[
10 0 R ]
/Group<</S/Transparency/CS/DeviceRGB/I true>>/Contents 2 0 R>>
endobj

4 0 obj
<</Type/Page/Parent 11 0 R/Resources 23 0 R/MediaBox[0 0 612 792]/Group<</S/Transparency/CS/DeviceRGB/I true>>/Contents 5 0 R>>
endobj

7 0 obj
<</Type/Page/Parent 11 0 R/Resources 23 0 R/MediaBox[0 0 612 792]/Group<</S/Transparency/CS/DeviceRGB/I true>>/Contents 8 0 R>>
endobj

11 0 obj
<</Type/Pages
/Resources 23 0 R
/MediaBox[ 0 0 612 792 ]
/Kids[ 1 0 R 4 0 R 7 0 R ]
/Count 3>>
endobj

10 0 obj
<</Type/Annot/Subtype/Link/Border[0 0 0]/Rect[56 356.7 148.2 370.5]/A<</Type/Action/S/URI/URI(http://www.google.com/)>>
>>
endobj

24 0 obj
<</Type/Catalog/Pages 11 0 R
/OpenAction[1 0 R /XYZ null null 0]
/Lang(en-US)
>>
endobj

25 0 obj
<</Author<FEFF004D00610072007300680061006C006C00200047007200650065006E0062006C006100740074>
/Creator<FEFF005700720069007400650072>
/Producer<FEFF004F00700065006E004F0066006600690063006500200034002E0030002E0031>
/CreationDate(D:20151014152341-04'00')>>
endobj

xref
0 26
0000000000 65535 f 
0000028317 00000 n 
0000000019 00000 n 
0000000586 00000 n 
0000028479 00000 n 
0000000606 00000 n 
0000000854 00000 n 
0000028623 00000 n 
0000000874 00000 n 
0000001122 00000 n 
0000028879 00000 n 
0000028767 00000 n 
0000001142 00000 n 
0000016741 00000 n 
0000016764 00000 n 
0000016955 00000 n 
0000017351 00000 n 
0000017598 00000 n 
0000027509 00000 n 
0000027531 00000 n 
0000027732 00000 n 
0000028039 00000 n 
0000028219 00000 n 
0000028262 00000 n 
0000029019 00000 n 
0000029117 00000 n 
trailer
<</Size 26/Root 24 0 R
/Info 25 0 R
/ID [ <FAEEF33AED68F85DC67884FA0044EE41>
<FAEEF33AED68F85DC67884FA0044EE41> ]
/DocChecksum /16478DC25D9E74C6FCF765844F1EBD78
>>
startxref
29386
%%EOF
          �� ���    0 	        <!DOCTYPE HTML>
<html>
  <head>
    <title>Performance Tests</title>
    <style>
      body { font-family: Tahoma, Serif; font-size: 9pt; }
    </style>
  </head>
  <body bgcolor="white">
    <h1>Performance Tests</h1>
    <input type="button" value="Run Tests" onClick="run();" id="run"/> Filter: <input type="text" size="50" id="filters"/>
    <div><span id="statusBox"></span> <progress id="progressBox" value="0" style="display:none"></progress></div>

    <div style="padding-top:10px; padding-bottom:10px">
    <table id="resultTable" border="1" cellspacing="1" cellpadding="4">
      <thead>
        <tr>
          <td>Name</td>
          <td>Iterations per Run</td>
          <td>Avg (ms)</td>
          <td>Min (ms)</td>
          <td>Max (ms)</td>
          <td>StdDev (ms)</td>
          <td>Runs (ms)</td>
        </tr>
      </thead>
      <!-- result rows here -->
    </table>
    </div>

    <hr width="80%">

    Result 1: <input type="text" size="100" id="result1"/>
    <br/>Result 2: <input type="text" size="100" id="result2"/>
    <br/><input type="button" value="Compare" onClick="compare();" id="compare"/>

    <div style="padding-top:10px; padding-bottom:10px">
    <table id="compareTable" border="1" cellspacing="1" cellpadding="4">
      <thead>
        <tr>
          <td>Name</td>
          <td>Result 1 Avg (ms)</td>
          <td>Result 2 Avg (ms)</td>
          <td>% Diff</td>
        </tr>
      </thead>
      <!-- result rows here -->
    </table>
    </div>

<script type="text/javascript">
function run() {
  var runElement = document.getElementById("run");
  var filtersElement = document.getElementById("filters");
  var compareElement = document.getElementById("compare");
  var result1Element = document.getElementById("result1");
  var result2Element = document.getElementById("result2");

  // Number of runs for each test.
  var testRuns = 10;

  // Delay between test runs.
  var runDelay = 0;

  // Retrieve the list of all tests.
  var allTests = window.GetPerfTests();

  // Populated with the list of tests that will be run.
  var tests = [];
  var currentTest = 0;

  var testList = filtersElement.value.trim();
  if (testList.length > 0) {
    // Include or exclude specific tests.
    var included = [];
    var excluded = [];

    var testNames = testList.split(",");

    // Identify included and excluded tests.
    for (i = 0; i < testNames.length; ++i) {
      var testName = testNames[i].trim();
      if (testName[0] == '-') {
        // Exclude the test.
        excluded.push(testName.substr(1));
      } else {
        // Include the test.
        included.push(testName);
      }
    }

    if (included.length > 0) {
      // Only use the included tests.
      for (i = 0; i < allTests.length; ++i) {
        var test = allTests[i];
        var testName = test[0];
        if (included.indexOf(testName) >= 0)
          tests.push(test);
      }
    } else if (excluded.length > 0) {
      // Use all tests except the excluded tests.
      for (i = 0; i < allTests.length; ++i) {
        var test = allTests[i];
        var testName = test[0];
        if (excluded.indexOf(testName) < 0)
          tests.push(test);
      }
    }
  } else {
    // Run all tests.
    tests = allTests;
  }

  function updateStatusComplete() {
    var statusBox = document.getElementById("statusBox");
    statusBox.innerText = 'All tests completed.';

    runElement.disabled = false;
    filtersElement.disabled = false;
    result1Element.disabled = false;
    result2Element.disabled = false;
    compareElement.disabled = false;
  }

  function updateStatus(test) {
    var statusBox = document.getElementById("statusBox");
    var progressBox = document.getElementById("progressBox");

    if (test.run >= test.totalRuns) {
      statusBox.innerText = test.name + " completed.";
      progressBox.style.display = 'none';
    } else {
      statusBox.innerText = test.name + " (" + test.run + "/" + test.totalRuns + ")";
      progressBox.value = (test.run / test.totalRuns);
      progressBox.style.display = 'inline';
    }
  }

  function appendResult(test) {
    var e = document.getElementById("resultTable");

    // Calculate the average.
    var avg = test.total / test.totalRuns;

    // Calculate the standard deviation.
    var sqsum = 0;
    for (i = 0; i < test.results.length; ++i) {
      var diff = test.results[i] - avg;
      sqsum += diff * diff;
    }
    var stddev = Math.round(Math.sqrt(sqsum / test.totalRuns) * 100.0) / 100.0;

    e.insertAdjacentHTML("beforeEnd", [
        "<tr>",
        "<td>", test.name, "</td>",
        "<td>", test.iterations, "</td>",
        "<td>", avg, "</td>",
        "<td>", test.min, "</td>",
        "<td>", test.max, "</td>",
        "<td>", stddev, "</td>",
        "<td>", test.results.join(", "), "</td>",
        "<tr>"
        ].join(""));

    if (result1Element.value.length > 0)
      result1Element.value += ",";
    result1Element.value += test.name + "=" + avg;
  }

  // Execute the test function.
  function execTestFunc(name) {
    return window.RunPerfTest(name);
  }

  // Schedule the next test.
  function nextTest(test) {
    appendResult(test);
    currentTest++;
    runTest();
  }

  // Schedule the next step for the current test.
  function nextTestStep(test) {
    setTimeout(function () { execTest(test); }, runDelay);
  }

  // Perform the next step for the current test.
  function execTest(test) {
    updateStatus(test);

    if (!test.warmedUp) {
      execTestFunc(test.name);
      test.warmedUp = true;
      return nextTestStep(test);
    }

    if (test.run >= test.totalRuns)
      return nextTest(test);

    var elapsed = execTestFunc(test.name);
    test.results.push(elapsed);

    test.total += elapsed;
    if (!test.min) test.min = elapsed;
    else if (test.min > elapsed) test.min = elapsed;
    if (!test.max) test.max = elapsed;
    else if (test.max < elapsed) test.max = elapsed;

    test.run++;

    return nextTestStep(test);
  }

  function runTest() {
    if (currentTest == tests.length) {
      updateStatusComplete();
      return;
    }

    var test = {
        name: tests[currentTest][0],
        iterations: tests[currentTest][1],
        warmedUp: false,
        total: 0,
        totalRuns: testRuns,
        run: 0,
        results: []
    };
    setTimeout(function () { execTest(test); }, runDelay);
  }

  // Schedule the first test.
  if (tests.length > 0) {
    runElement.disabled = true;
    filtersElement.disabled = true;
    result1Element.value = "";
    result1Element.disabled = true;
    result2Element.disabled = true;
    compareElement.disabled = true;

    runTest();
  }
}

function compare() {
  var result1 = document.getElementById("result1").value.trim();
  var result2 = document.getElementById("result2").value.trim();

  if (result1.length == 0 || result2.length == 0)
    return;

  var r1values = result1.split(",");
  var r2values = result2.split(",");
  for (i = 0; i < r1values.length; ++i) {
    var r1parts = r1values[i].split("=");
    var r1name = r1parts[0].trim();
    var r1val = r1parts[1].trim();

    for (x = 0; x < r2values.length; ++x) {
      var r2parts = r2values[x].split("=");
      var r2name = r2parts[0].trim();
      var r2val = r2parts[1].trim();

      if (r2name == r1name) {
        appendResult(r1name, r1val, r2val);

        // Remove the matching index.
        r2values.splice(x, 1);
        break;
      }
    }
  }
  
  function appendResult(name, r1val, r2val) {
    var e = document.getElementById("compareTable");
 
    // Calculate the percent difference.
    var diff = Math.round(((r2val - r1val) / r1val) * 10000.0) / 100.0;

    e.insertAdjacentHTML("beforeEnd", [
        "<tr>",
        "<td>", name, "</td>",
        "<td>", r1val, "</td>",
        "<td>", r2val, "</td>",
        "<td>", diff, "</td>",
        "<tr>"
        ].join(""));
  }
}
</script>

  </body>
</html>
�;      �� ���    0 	        <!DOCTYPE HTML>
<html>
    <head>
        <title>Performance Tests (2)</title>
        <style>
            body { font-family: Tahoma, Serif; font-size: 9pt; }

            .left { text-align: left; }
            .right { text-align: right; }
            .center { text-align: center; }

            table.resultTable 
            {
                border: 1px solid black;
                border-collapse: collapse;
                empty-cells: show;
                width: 100%;
            }
            table.resultTable td
            {
                padding: 2px 4px;
                border: 1px solid black;
            }
            table.resultTable > thead > tr
            {
                font-weight: bold;
                background: lightblue;
            }
            table.resultTable > tbody > tr:nth-child(odd)
            {
                background: white;
            }
            table.resultTable > tbody > tr:nth-child(even)
            {
                background: lightgray;
            }

            .hide { display: none; }
        </style>
    </head>
    <body bgcolor="white">
        <h1>Performance Tests (2)</h1>

        <form id="sForm" onsubmit="runTestSuite();return false">
            <table>
                <tr>
                    <td colspan="2">Settings:</td>
                </tr>
                <tr>
                    <td class="right">Iterations:</td>
                    <td><input id="sIterations" type="text" value="1000" required pattern="[0-9]+" /></td>
                </tr>
                <tr>
                    <td class="right">Samples:</td>
                    <td><input id="sSamples" type="text" value="100" required pattern="[0-9]+" /></td>
                </tr>
                <tr>
                    <td class="right">Mode:</td>
                    <td><input id="sAsync" name="sMode" type="radio" value="async" checked>Asynchronous</input>
                        <input id="sSync" name="sMode" type="radio" value="sync">Synchronous</input>
                    </td>
                </tr>
                <tr>
                    <td colspan="2"><button type="submit" id="sRun" autofocus>Run!</button></td>
                </tr>
            </table>
        </form>


        <div><span id="statusBox"></span> <progress id="progressBox" value="0" style="display:none"></progress></div>

        <div style="padding-top:10px; padding-bottom:10px">
        <table id="resultTable" class="resultTable">
            <thead>
                <tr>
                    <td class="center" style="width:1%">Enabled</td>
                    <td class="center" style="width:10%">Name</td>
                    <td class="center" style="width:5%">Samples x Iterations</td>
                    <td class="center" style="width:5%">Min,&nbsp;ms</td>
                    <td class="center" style="width:5%">Avg,&nbsp;ms</td>
                    <td class="center" style="width:5%">Max,&nbsp;ms</td>
                    <td class="center" style="width:5%">Average calls/sec</td>
                    <td class="center" style="width:5%">Measuring Inacurracy</td>
                    <td class="center hide" style="width:5%">Memory, MB</td>
                    <td class="center hide" style="width:5%">Memory delta, MB</td>
                    <td class="center" style="width:55%">Description</td>
                </tr>
            </thead>
            <tbody>
                <!-- result rows here -->
            </tbody>
        </table>
        </div>

<script type="text/javascript">
(function () {
    function getPrivateWorkingSet() {
        return 0; // TODO: window.PerfTestGetPrivateWorkingSet();
    }

    var disableWarmUp = true;

    var asyncExecution = true;
    var testIterations = 1000;
    var totalSamples = 100;
    var sampleDelay = 0;

    var collectSamples = false;

    var tests = [];
    var testIndex = -1;

    function execTestFunc(test) {
        try {
            var begin = new Date();
            test.func(test.totalIterations);
            var end = new Date();
            return (end - begin);
        } catch (e) {
            test.error = e.toString();
            return 0;
        }
    }

    function execTest(test) {
        if (disableWarmUp) { test.warmedUp = true; }

        function nextStep() {
            if (asyncExecution) {
                setTimeout(function () { execTest(test); }, sampleDelay);
            } else {
                execTest(test);
            }
        }

        function nextTest() {
            updateStatus(test);
            appendResult(test);

            return execNextTest();
        }

        updateStatus(test);
        if (!test.warmedUp) {
            execTestFunc(test);
            if (!test.error) {
                test.warmedUp = true;
                test.beginMemory = getPrivateWorkingSet();
                return nextStep();
            } else {
                return nextTest();
            }
        }

        if (test.sample >= test.totalSamples) {
            test.avg = test.total / test.totalSamples;
            test.endMemory = getPrivateWorkingSet();
            return nextTest();
        }

        if (test.skipped) return nextTest();

        var elapsed = execTestFunc(test);
        if (!test.error) {
            test.total += elapsed;
            if (!test.min) test.min = elapsed;
            else if (test.min > elapsed) test.min = elapsed;
            if (!test.max) test.max = elapsed;
            else if (test.max < elapsed) test.max = elapsed;
            if (collectSamples) {
                test.results.push(elapsed);
            }
            test.sample++;
            return nextStep();
        } else {
            return nextTest();
        }
    }

    function updateStatus(test) {
        var statusBox = document.getElementById("statusBox");
        var progressBox = document.getElementById("progressBox");

        if (test.skipped || test.error || test.sample >= test.totalSamples) {
            statusBox.innerText = "";
            progressBox.style.display = "none";
        } else {
            statusBox.innerText = (testIndex + 1) + "/" + tests.length + ": " + test.name + " (" + test.sample + "/" + test.totalSamples + ")";
            progressBox.value = (test.sample / test.totalSamples);
            progressBox.style.display = "inline";
        }
    }

    function appendResult(test) {
        if (test.name == "warmup") return;

        var id = "testResultRow_" + test.index;

        var nearBound = (test.max - test.avg) < (test.avg - test.min) ? test.max : test.min;
        var memoryDelta = test.endMemory - test.beginMemory;
        if (memoryDelta < 0) memoryDelta = "-" + Math.abs(memoryDelta).toFixed(2);
        else memoryDelta = "+" + Math.abs(memoryDelta).toFixed(2);

        var markup = ["<tr id='" + id + "'>",
                      "<td class='left'><input type='checkbox' id='test_enabled_", test.index ,"' ", (!test.skipped ? "checked" : "") ," /></td>",
                      "<td class='left'>", test.name, "</td>",
                      "<td class='right'>", test.totalSamples, "x", test.totalIterations, "</td>",
                      "<td class='right'>", test.skipped || test.error || !test.prepared ? "-" : test.min.toFixed(2), "</td>",
                      "<td class='right'>", test.skipped || test.error || !test.prepared ? "-" : test.avg.toFixed(2), "</td>",
                      "<td class='right'>", test.skipped || test.error || !test.prepared ? "-" : test.max.toFixed(2), "</td>",
                      "<td class='right'>", test.skipped || test.error || !test.prepared ? "-" : (test.totalIterations * 1000 / test.avg).toFixed(2), "</td>",
                      "<td class='right'>", test.skipped || test.error || !test.prepared ? "-" : ("&#x00B1; " + (Math.abs(test.avg - nearBound) / (test.avg) * (100)).toFixed(2) + "%"), "</td>",
                      "<td class='right hide'>", test.skipped || test.error || !test.prepared ? "-" : test.endMemory.toFixed(2), "</td>",
                      "<td class='right hide'>", test.skipped || test.error || !test.prepared ? "-" : memoryDelta, "</td>",
                      "<td class='left'>", test.description, test.error ? (test.description ? "<br/>" : "") + "<span style='color:red'>" + test.error + "</span>" : "", "</td>",
                      "</tr>"
                      ].join("");
        // test.results.join(", "), "<br/>",

        var row = document.getElementById(id);
        if (row) {
            row.outerHTML = markup;
        } else {
            var tbody = document.getElementById("resultTable").tBodies[0];
            tbody.insertAdjacentHTML("beforeEnd", markup);
        }
    }

    function prepareQueuedTests() {
        testIndex = -1;
        for (var i = 0; i < tests.length; i++) {
            var test = tests[i];
            test.index = i;
            test.prepared = false;
            test.warmedUp = false;
            test.sample = 0;
            test.total = 0;
            test.results = [];
            test.error = false;
            test.min = null;
            test.avg = null;
            test.max = null;
            test.beginMemory = null;
            test.endMemory = null;
            test.totalIterations = parseInt(testIterations / test.complex);
            test.totalSamples = parseInt(totalSamples / test.complex);

            var skipElement = document.getElementById('test_enabled_' + test.index);
            test.skipped = skipElement ? !skipElement.checked : (test.skipped || false);

            if (test.totalIterations <= 0) test.totalIterations = 1;
            if (test.totalSamples <= 0) test.totalSamples = 1;

            appendResult(test);
            test.prepared = true;
        }
    }

    function queueTest(func, name, description) {
        var test;
        if (typeof func === "function") {
            test = {
                name: name,
                func: func,
                description: description
            };
        } else {
            test = func;
        }
        test.warmedUp = false;
        test.complex = test.complex || 1;
        tests.push(test);
    }

    function execNextTest() {
        testIndex++;
        if (tests.length <= testIndex) {
            return testSuiteFinished();
        } else {
            return execTest(tests[testIndex]);
        }
    }

    function execQueuedTests() {
        prepareQueuedTests();
        execNextTest();
    }

    function setSettingsState(disabled) {
        document.getElementById('sIterations').disabled = disabled;
        document.getElementById('sSamples').disabled = disabled;
        document.getElementById('sAsync').disabled = disabled;
        document.getElementById('sSync').disabled = disabled;
        document.getElementById('sRun').disabled = disabled;
    }

    function testSuiteFinished() {
        setSettingsState(false);
    }

    window.runTestSuite = function () {
        setSettingsState(true);

        testIterations = parseInt(document.getElementById('sIterations').value);
        totalSamples = parseInt(document.getElementById('sSamples').value);
        asyncExecution = document.getElementById('sAsync').checked;

        setTimeout(execQueuedTests, 0);
    }

    setTimeout(prepareQueuedTests, 0);

    // Test queue.
    queueTest({
        name: "PerfTestReturnValue Default",
        func: function (count) {
            for (var i = 0; i < count; i++) {
                window.PerfTestReturnValue();
            }
        },
        description: "No arguments, returns int32 value.",
        skipped: true,
    });

    queueTest({
        name: "PerfTestReturnValue (0, Undefined)",
        func: function (count) {
            for (var i = 0; i < count; i++) {
                window.PerfTestReturnValue(0);
            }
        },
        description: "Int argument, returns undefined value."
    });

    queueTest({
        name: "PerfTestReturnValue (1, Null)",
        func: function (count) {
            for (var i = 0; i < count; i++) {
                window.PerfTestReturnValue(1);
            }
        },
        description: "Int argument, returns null value."
    });

    queueTest({
        name: "PerfTestReturnValue (2, Bool)",
        func: function (count) {
            for (var i = 0; i < count; i++) {
                window.PerfTestReturnValue(2);
            }
        },
        description: "Int argument, returns bool value."
    });

    queueTest({
        name: "PerfTestReturnValue (3, Int)",
        func: function (count) {
            for (var i = 0; i < count; i++) {
                window.PerfTestReturnValue(3);
            }
        },
        description: "Int argument, returns int value."
    });

    queueTest({
        name: "PerfTestReturnValue (4, UInt)",
        func: function (count) {
            for (var i = 0; i < count; i++) {
                window.PerfTestReturnValue(4);
            }
        },
        description: "Int argument, returns uint value."
    });

    queueTest({
        name: "PerfTestReturnValue (5, Double)",
        func: function (count) {
            for (var i = 0; i < count; i++) {
                window.PerfTestReturnValue(5);
            }
        },
        description: "Int argument, returns double value."
    });

    queueTest({
        name: "PerfTestReturnValue (6, Date)",
        func: function (count) {
            for (var i = 0; i < count; i++) {
                window.PerfTestReturnValue(6);
            }
        },
        description: "Int argument, returns date value.",
        skipped: true,
    });

    queueTest({
        name: "PerfTestReturnValue (7, String)",
        func: function (count) {
            for (var i = 0; i < count; i++) {
                window.PerfTestReturnValue(7);
            }
        },
        description: "Int argument, returns string value."
    });

    queueTest({
        name: "PerfTestReturnValue (8, Object)",
        func: function (count) {
            for (var i = 0; i < count; i++) {
                window.PerfTestReturnValue(8);
            }
        },
        description: "Int argument, returns object value."
    });

    queueTest({
        name: "PerfTestReturnValue (9, Array)",
        func: function (count) {
            for (var i = 0; i < count; i++) {
                window.PerfTestReturnValue(9);
            }
        },
        description: "Int argument, returns array value."
    });

    queueTest({
        name: "PerfTestReturnValue (10, Function)",
        func: function (count) {
            for (var i = 0; i < count; i++) {
                window.PerfTestReturnValue(10);
            }
        },
        description: "Int argument, returns function value.",
        skipped: true,
    });
    // add more tests to queueTest

})();
</script>

    </body>
</html>
  �.      �� ���    0 	        <!DOCTYPE HTML>
<html>
<head>
  <title>Preferences Test</title>

  <!-- When using the mode "code" it's important to specify charset utf-8 -->
  <meta http-equiv="Content-Type" content="text/html;charset=utf-8">

  <!-- jsoneditor project from https://github.com/josdejong/jsoneditor/
       script hosting from http://cdnjs.com/libraries/jsoneditor -->
  <link href="https://cdnjs.cloudflare.com/ajax/libs/jsoneditor/4.2.1/jsoneditor.min.css" rel="stylesheet" type="text/css">
  <script src="https://cdnjs.cloudflare.com/ajax/libs/jsoneditor/4.2.1/jsoneditor.min.js"></script>

  <script>
    function setup() {
      if (location.hostname === 'tests' || location.hostname === 'localhost') {
        if (location.hash === '#advanced') {
          toggleView();
        }
        return;
      }

      alert('This page can only be run from tests or localhost.');

      // Disable all elements.
      var elements = document.getElementById("form").elements;
      for (var i = 0, element; element = elements[i++]; ) {
        element.disabled = true;
      }
    }
  </script>
</head>
<body bgcolor="white" onload="setup()">
  <!-- Header -->
  <div id="simple_links">
    [ <b>Simple</b> ]
    [ <a href="#" onClick="toggleView(); return false;">Advanced</a> ]
  </div>
  <div id="advanced_links" style="display:none">
    [ <a href="#" onClick="toggleView(); return false;">Simple</a> ]
    [ <b>Advanced</b> ]
  </div>

  <form id="form">

  <!-- Simple view -->
  <div id="simple">
    <p>
      This page supports display and configuration of a few sample preferences.
      <table width="100%" style="border: 1px solid #97B0F8">
        <tr>
          <td>
            <input type="checkbox" id="enable_spellchecking"/> Enable spell checking
          </td>
        </tr>
        <tr>
          <td>
            <br/>
            <input type="checkbox" id="allow_running_insecure_content"/> Allow running insecure content
          </td>
        </tr>
        <tr>
          <td>
            <br/>
            Proxy type:
            <select id="proxy_type" onChange="proxyTypeChange()">
              <option value="direct">Direct</option>
              <option value="auto_detect">Auto-Detect</option>
              <option value="pac_script">PAC Script</option>
              <option value="fixed_servers">Fixed Servers</option>
              <option value="system">System</option>
            </select>
            <input id="proxy_value" type="text" size="80" disabled/>
          </td>
        </tr>
      </table>
      <table border="0" width="100%">
        <tr>
          <td align="left">
            <input type="button" value="Refresh" onClick="refreshSimple()"/>
          </td>
          <td align="right">
            <input type="button" value="Apply Changes" onClick="applySimpleChanges()"/>
          </td>
        </tr>
      </table>
    </p>
  </div>

  <!-- Advanced view -->
  <div id="advanced" style="display:none">
    <p>
      This page displays all preferences organized in a tree structure. Arbitrary changes are
      allowed, however <b>changing preferences in arbitrary ways may result in crashes</b>. If you
      experience a crash while setting preferences then run a Debug build of CEF/Chromium and watch
      for DCHECKs in the Chromium code to figure out what went wrong.
    </p>
    <div id="jsoneditor" style="width: 100%; height: 100%;"></div>
    <table border="0" width="100%">
      <tr>
        <td align="left">
          <input type="button" value="Refresh" onClick="refreshEditor()"/>
          <input type="checkbox" id="global_prefs" onChange="refreshEditor()"/> Show global preferences
          <input type="checkbox" id="hide_defaults" onChange="refreshEditor()"/> Show modified preferences only
        </td>
        <td align="right">
          <input type="button" value="Apply Changes" onClick="applyEditorChanges()"/>
        </td>
      </tr>
    </table>
  </div>

  </form>

  <script>
    // Reference to the JSONEditor.
    var editor = null;

    // Preferences state information.
    var preferences_state = null;

    // Toggle between the simple and advanced views.
    function toggleView() {
      var simple = document.getElementById("simple");
      var advanced = document.getElementById("advanced");
      var simple_links = document.getElementById("simple_links");
      var advanced_links = document.getElementById("advanced_links");

      if (simple.style.display == "none") {
        // Show the simple view.
        simple.style.display = "";
        simple_links.style.display = "";
        advanced.style.display = "none";
        advanced_links.style.display = "none";

        // Refresh the simple view contents.
        refreshSimple();
      } else {
        // Show the advanced view.
        simple.style.display = "none";
        simple_links.style.display = "none";
        advanced.style.display = "";
        advanced_links.style.display = "";

        if (editor == null) {
          // Create the editor.
          editor = new JSONEditor(document.getElementById("jsoneditor"));
        }

        // Refesh the editor contents.
        refreshEditor();
      }
    }

    // Send a request to C++.
    function sendRequest(request, onSuccessCallback) {
      // Results in a call to the OnQuery method in preferences_test.cpp.
      window.cefQuery({
        request: JSON.stringify(request),
        onSuccess: onSuccessCallback,
        onFailure: function(error_code, error_message) {
          alert(error_message + ' (' + error_code + ')');
        }
      });
    }

    // Get the preferences and execute |onSuccessCallback| with the resulting
    // JSON object.
    function getPreferences(global_prefs, include_defaults, onSuccessCallback) {
      // Create the request object.
      var request = {};
      request.name = "preferences_get";
      request.global_prefs = global_prefs;
      request.include_defaults = include_defaults;

      // Send the request to C++.
      sendRequest(
        request,
        function(response) {
          onSuccessCallback(JSON.parse(response));
        }
      );
    }

    // Set the preferences.
    function setPreferences(global_prefs, preferences) {
      // Create the request object.
      var request = {};
      request.name = "preferences_set";
      request.global_prefs = global_prefs;
      request.preferences = preferences;

      // Send the request to C++.
      sendRequest(
        request,
        function(response) {
          // Show the informative response message.
          alert(response);
        }
      );
    }

    // Get the global preference state.
    function getPreferenceState() {
      // Create the request object.
      var request = {};
      request.name = "preferences_state";

      // Send the request to C++.
      sendRequest(
        request,
        function(response) {
          // Populate the global state object.
          preferences_state = JSON.parse(response);

          // Refresh the simple view contents.
          refreshSimple();
        }
      );
    }

    // Refresh the editor view contents.
    function refreshEditor() {
      global_prefs = document.getElementById("global_prefs").checked;
      include_defaults = !document.getElementById("hide_defaults").checked;
      getPreferences(global_prefs, include_defaults, function(response) {
        // Set the JSON in the editor.
        editor.set(response);
      });
    }

    // Apply changes from the editor view.
    function applyEditorChanges() {
      global_prefs = document.getElementById("global_prefs").checked;
      setPreferences(global_prefs, editor.get());
    }

    // Refresh the simple view contents.
    function refreshSimple() {
      getPreferences(false, true, function(response) {
        // Spellcheck settings.
        if (preferences_state.spellcheck_disabled) {
          // Cannot enable spell checking when disabled via the command-line.
          document.getElementById("enable_spellchecking").checked = false;
          document.getElementById("enable_spellchecking").disabled = true;
        } else {
          document.getElementById("enable_spellchecking").checked =
              response.browser.enable_spellchecking;
        }

        // Web content settings.
        if (preferences_state.allow_running_insecure_content) {
          // Cannot disable running insecure content when enabled via the
          // command-line.
          document.getElementById("allow_running_insecure_content").checked =
              true;
          document.getElementById("allow_running_insecure_content").disabled =
              true;
        } else {
          document.getElementById("allow_running_insecure_content").checked =
              response.webkit.webprefs.allow_running_insecure_content;
        }

        // Proxy settings.
        document.getElementById("proxy_type").value = response.proxy.mode;

        // Some proxy modes have associated values.
        if (response.proxy.mode == "pac_script")
          proxy_value = response.proxy.pac_url;
        else if (response.proxy.mode == "fixed_servers")
          proxy_value = response.proxy.server;
        else
          proxy_value = null;

        if (proxy_value != null)
          document.getElementById("proxy_value").value = proxy_value;
        document.getElementById("proxy_value").disabled = (proxy_value == null);

        if (preferences_state.proxy_configured) {
          // Cannot modify proxy settings that are configured via the command-
          // line.
          document.getElementById("proxy_type").disabled = true;
          document.getElementById("proxy_value").disabled = true;
        }
      });
    }

    // Apply changes from the simple view.
    function applySimpleChanges() {
      has_preferences = false;
      preferences = {};

      // Spellcheck settings.
      if (!preferences_state.spellcheck_disabled) {
        has_preferences = true;

        preferences.browser = {};
        preferences.browser.enable_spellchecking =
            document.getElementById("enable_spellchecking").checked;
      }

      // Web content settings.
      if (!preferences_state.allow_running_insecure_content) {
        has_preferences = true;

        preferences.webkit = {};
        preferences.webkit.webprefs = {};
        preferences.webkit.webprefs.allow_running_insecure_content =
            document.getElementById("allow_running_insecure_content").checked;
      }

      // Proxy settings.
      if (!preferences_state.proxy_configured) {
        has_preferences = true;

        preferences.proxy = {};
        preferences.proxy.mode = document.getElementById("proxy_type").value;

        // Some proxy modes have associated values.
        if (preferences.proxy.mode == "pac_script") {
          preferences.proxy.pac_script =
              document.getElementById("proxy_value").value;
        } else  if (preferences.proxy.mode == "fixed_servers") {
          preferences.proxy.server =
              document.getElementById("proxy_value").value;
        }
      }

      if (has_preferences)
        setPreferences(false, preferences);
    }

    // Called when the proxy type is changed.
    function proxyTypeChange() {
      proxy_type = document.getElementById("proxy_type").value;
      document.getElementById("proxy_value").value = "";

      // Only enable the value field for the proxy modes that require it.
      document.getElementById("proxy_value").disabled =
          (proxy_type != "pac_script" && proxy_type != "fixed_servers");
    }

    // Retrieve global preferences state.
    getPreferenceState();
  </script>
</body>
</html>
 @)     �� ���    0 	        <html>
<head>
<title>Response Filter Test</title>
</head>
<body bgcolor="white">
<p>The text shown below in <font color="red">red</font> has been replaced by the filter. This document is > 64kb in order to exceed the standard output buffer size.</p>
<p><font color="red">REPLACE_THIS_STRING</font></p>
<p>0. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>1. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>2. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>3. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>4. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>5. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>6. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>7. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>8. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>9. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p><font color="red">REPLACE_THIS_STRING</font></p>
<p>0. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>1. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>2. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>3. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>4. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>5. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>6. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>7. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>8. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>9. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p><font color="red">REPLACE_THIS_STRING</font></p>
<p>0. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>1. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>2. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>3. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>4. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>5. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>6. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>7. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>8. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>9. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p><font color="red">REPLACE_THIS_STRING</font></p>
<p>0. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>1. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>2. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>3. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>4. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>5. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>6. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>7. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>8. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>9. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p><font color="red">REPLACE_THIS_STRING</font></p>
<p>0. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>1. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>2. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>3. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>4. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>5. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>6. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>7. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>8. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>9. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p><font color="red">REPLACE_THIS_STRING</font></p>
<p>0. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>1. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>2. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>3. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>4. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>5. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>6. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>7. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>8. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>9. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p><font color="red">REPLACE_THIS_STRING</font></p>
<p>0. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>1. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>2. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>3. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>4. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>5. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>6. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>7. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>8. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>9. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p><font color="red">REPLACE_THIS_STRING</font></p>
<p>0. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>1. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>2. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>3. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>4. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>5. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>6. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>7. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>8. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>9. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p><font color="red">REPLACE_THIS_STRING</font></p>
<p>0. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>1. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>2. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>3. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>4. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>5. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>6. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>7. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>8. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>9. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p><font color="red">REPLACE_THIS_STRING</font></p>
<p>0. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>1. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>2. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>3. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>4. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>5. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>6. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>7. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>8. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>9. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p><font color="red">REPLACE_THIS_STRING</font></p>
<p>0. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>1. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>2. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>3. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>4. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>5. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>6. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>7. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>8. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>9. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p><font color="red">REPLACE_THIS_STRING</font></p>
<p>0. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>1. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>2. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>3. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>4. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>5. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>6. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>7. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>8. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p>9. It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way -- in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.</p>
<p><font color="red">REPLACE_THIS_STRING</font></p>
<p>End.</p>
</body>
</html>
�      �� ���    0 	        <html>
<head>
<title>Server Test</title>
<script language="JavaScript">

// Send a query to the browser process.
function sendMessage(request, success_callback) {
  // Results in a call to the OnQuery method in server_test.cc
  window.cefQuery({
    request: JSON.stringify(request),
    onSuccess: function(response) {
      success_callback(response.length == 0 ? {} : JSON.parse(response));
    },
    onFailure: function(error_code, error_message) {
      alert("Request failed with error " + error_message + "(" + error_code + ")");
    }
  });
}

function setButtonState(start_enabled, stop_enabled) {
  document.getElementById('start').disabled = !start_enabled;
  document.getElementById('stop').disabled = !stop_enabled;
  document.getElementById('open').disabled = !stop_enabled;
}

function setup() {
  if (location.origin != 'https://tests') {
    document.getElementById('warning').style.display = 'block';
    return;
  }

  // Query the current server state.
  sendMessage({'action':'query'}, function(response) {
    if (response['result'] == 'success') {
      var running = (response['status'] == 'running')
      setButtonState(!running, running);

      var port_element = document.getElementById('port');
      port_element.value = response['port'];
      port_element.disabled = false;
    }
  });
}

function startServer() {  
  var port = parseInt(document.getElementById('port').value);
  if (port < 1025 || port > 65535) {
    alert('Specify a port number between 1025 and 65535');
    return;
  }

  setButtonState(false, false);

  sendMessage({'action':'start', 'port':port}, function(response) {
    if (response['result'] == 'success') {
      setButtonState(false, true);
    } else {
      setButtonState(true, false);
      alert(response['message']);
    }
  });
}

function stopServer() {
  setButtonState(false, false);

  sendMessage({'action':'stop'}, function(response) {
    if (response['result'] == 'success') {
      setButtonState(true, false);
    } else {
      setButtonState(false, true);
      alert(response['message']);
    }
  });
}

function openServer() {
  var port = document.getElementById('port').value;
  window.open('http://localhost:' + port);
}

</script>

</head>
<body bgcolor="white" onload="setup()">
<div id="warning" style="display:none;color:red;font-weight:bold;">
This page can only be run from the https://tests origin.
</div>
<p>
This page starts an HTTP/WebSocket server on localhost with the specified port number.
After starting the server click the "Open Example" button to open the WebSocket Client test in a popup window.
</p>
<p>
With this example each browser window can create/manage a separate server instance.
The server will be stopped automatically when the managing browser window is closed.
</p>
<form>
Server port: <input type="text" id="port" value="" disabled="true">
<br/><input type="button" id="start" onclick="startServer()" value="Start Server" disabled="true">
<input type="button" id="stop" onclick="stopServer()" value="Stop Server" disabled="true">
<input type="button" id="open" onclick="openServer()" value="Open Example" disabled="true">
</form>
</body>
</html>
  6      �� ���    0 	        <!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8" />
    <title>Task Manager</title>
    <style>
      table {
        width: 100%;
        border-collapse: collapse;
        background-color: white;
      }
      th,
      td {
        border: 1px solid black;
        padding: 8px;
        text-align: left;
      }
      th {
        background-color: #f2f2f2;
      }
      .highlight {
        font-weight: bold;
      }
    </style>
  </head>
  <body>
    <table id="taskTable">
      <tr>
        <th>Task ID</th>
        <th>Name</th>
        <th>Type</th>
        <th>CPU Usage</th>
        <th>Memory Footprint</th>
        <th>GPU Memory</th>
        <th>Actions</th>
      </tr>
    </table>
    <script>
      function sendCefQuery(payload, onSuccess, onFailure) {
        return window.cefQuery({
          request: payload,
          onSuccess: onSuccess,
          onFailure: onFailure,
        });
      }

      async function sendCefQueryAsync(payload) {
        return new Promise((resolve, reject) => {
          sendCefQuery(payload, resolve, (_error, message) => {
            onError(new Error(message));
          });
        });
      }

      async function fetchTasks() {
        const response = await sendCefQueryAsync("get_tasks");
        return JSON.parse(response);
      }

      async function endProcess(id) {
        await sendCefQueryAsync(`${id}`);
        await refresh();
      }

      function humanFileSize(bytes) {
        const step = 1024;
        if (bytes < 0) {
          return "N/A";
        }
        if (Math.abs(bytes) < step) {
          return bytes + " B";
        }

        const units = [" KB", " MB", " GB"];
        let u = -1;
        let count = 0;

        do {
          bytes /= step;
          u += 1;
          count += 1;
        } while (Math.abs(bytes) >= step && u < units.length - 1);

        return bytes.toFixed(2) + units[u];
      }

      async function refresh() {
        try {
          const tasks = await fetchTasks();

          const table = document.getElementById("taskTable");
          while (table.rows.length > 1) {
            table.deleteRow(1);
          }

          tasks.forEach((task) => {
            let row = table.insertRow();
            row.insertCell(0).textContent = task.id;
            row.insertCell(1).textContent = task.title;
            row.insertCell(2).textContent = task.type;
            row.insertCell(3).textContent = task.cpu_usage.toFixed(2) + "%";
            row.insertCell(4).textContent = humanFileSize(task.memory);
            row.insertCell(5).textContent = humanFileSize(task.gpu_memory);

            let actionCell = row.insertCell(6);
            if (task.is_killable) {
              let endButton = document.createElement("button");
              endButton.textContent = "End Process";
              endButton.onclick = () => endProcess(task.id);
              actionCell.appendChild(endButton);
            }

            if (task.is_this_browser) {
              row.classList.add('highlight');
            }
          });
        } catch (error) {
          console.error("Error fetching tasks:", error);
        }
      }

      setInterval(refresh, 5000);
      refresh();
    </script>
  </body>
</html>
  (      �� ���    0 	        <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<title>Transparency Examples</title>
<style type="text/css">
body {
font-family: Verdana, Arial;
}
img {
opacity:0.4;
}
img:hover {
opacity:1.0;
}
.box_white, .box_black {
font-size: 14px;
font-weight: bold;
text-align: center;
padding: 10px;
display: inline-block;
width: 100px;
}
.box_white {
background-color: white;
border: 2px solid black;
color: black;
}
.box_black {
background-color: black;
border: 2px solid white;
color: white;
}
.box_0 {
opacity: 1.0;
}
.box_25 {
opacity: 0.75;
}
.box_50 {
opacity: 0.5;
}
.box_75 {
opacity: 0.25;
}
.box_100 {
opacity: 0;
}
</style>
</head>
<body>

<h1>Image Transparency</h1>
Hover over an image to make it fully opaque.<br>
<img src="http://www.w3schools.com/css/klematis.jpg" width="150" height="113" alt="klematis" />
<img src="http://www.w3schools.com/css/klematis2.jpg" width="150" height="113" alt="klematis" />

<h1>Block Transparency</h1>
<span class="box_white box_0">White 0%</span> <span class="box_white box_25">White 25%</span> <span class="box_white box_50">White 50%</span> <span class="box_white box_75">White 75%</span> <span class="box_white box_100">White 100%</span>
<br>
<span class="box_black box_0">Black 0%</span> <span class="box_black box_25">Black 25%</span> <span class="box_black box_50">Black 50%</span> <span class="box_black box_75">Black 75%</span> <span class="box_black box_100">Black 100%</span>

</body>
</html>
      �� ���    0 	        <html>
<head>
<script language="JavaScript">

function setup() {
  if (location.hostname == 'tests' || location.hostname == 'localhost')
    return;

  alert('This page can only be run from tests or localhost');

  // Disable all elements.
  var elements = document.getElementById("form").elements;
  for (var i = 0, element; element = elements[i++]; ) {
    element.disabled = true;
  }
}

// Send a query to the browser process.
function execURLRequest() {
  document.getElementById('ta').value = 'Request pending...';

  // Results in a call to the OnQuery method in urlrequest_test.cpp
  window.cefQuery({
    request: 'URLRequestTest:' + document.getElementById("url").value,
    onSuccess: function(response) {
      document.getElementById('ta').value = response;
    },
    onFailure: function(error_code, error_message) {
      document.getElementById('ta').value = 'Failed with error ' + error_message + ' (' + error_code + ')';
    }
  });
}
</script>
</head>
<body bgcolor="white" onload="setup()">
<form id="form">
URL: <input type="text" id="url" value="https://www.google.com">
<br/><input type="button" onclick="execURLRequest();" value="Execute CefURLRequest">
<br/><textarea rows="10" cols="40" id="ta"></textarea>
</form>
</body>
</html>
 |      �� ��     0 	        <html>
<head>
<title>WebSocket Test</title>
<script language="JavaScript">

var ws = null;

function setup() {
  // Match the secure state of the current origin.
  var origin = location.origin;
  if (origin.indexOf('http://') == 0) {
    origin = origin.replace('http://', 'ws://');
  } else if (origin.indexOf('https://') == 0) {
    origin = origin.replace('https://', 'wss://');
  } else {
    origin = '';
  }

  if (origin.length > 0)
    document.getElementById('server').value = origin;
  document.getElementById('server').disabled = false;

  if (location.hostname != 'localhost')
    document.getElementById('warning').style.display = 'block';

  setConnected(false);
}

function setConnected(connected) {
  document.getElementById('connect').disabled = connected;
  document.getElementById('disconnect').disabled = !connected;
  document.getElementById('message').disabled = !connected;
  document.getElementById('response').disabled = !connected;
  document.getElementById('send').disabled = !connected;
}

function doConnect() {
  var url = document.getElementById('server').value;
  if (url.indexOf('ws://') < 0 && url.indexOf('wss://') < 0) {
    alert('Specify a valid WebSocket server URL.');
    return;
  }

  if (ws) {
    alert('WebSocket is already connected.');
    return;
  }

  ws = new WebSocket(url);
  ws.onopen = function() { setConnected(true); };
  ws.onmessage = function(event) {
    document.getElementById('response').value = event.data;
  };
  ws.onclose = function(event) {
    setConnected(false);
    ws = null;
  };
  ws.onerror = function(event) {
    if (ws.readyState == 3)
      alert('WebSocket connection failed.');
  }
}

function doDisconnect() {
  if (!ws) {
    alert('WebSocket is not currently connected.');
    return;
  }

  ws.close();
}

function doSend() {
  if (!ws) {
    alert('WebSocket is not currently connected.');
    return;
  }

  var value = document.getElementById('message').value;
  if (value.length > 0)
    ws.send(value);
}

</script>

</head>
<body bgcolor="white" onload="setup()">
<div id="warning" style="display:none;color:red;font-weight:bold;">
This page is most useful when loaded from localhost.
You should first create a server using the <a href="https://tests/server">HTTP/WebSocket Server test</a>.
</div>
<p>
This page tests a WebSocket connection.
The example implementation in server_test.cc will then echo the message contents in reverse.
</p>
<form>
Server URL: <input type="text" id="server" value="" disabled="true">
<br/><input type="button" id="connect" onclick="doConnect()" value="Connect" disabled="true">
<input type="button" id="disconnect" onclick="doDisconnect()" value="Disconnect" disabled="true">
<br/>Message: <input type="text" id="message" value="Test Message" disabled="true">
<input type="button" id="send" onclick="doSend()" value="Send" disabled="true">
<br/>Response: <input type="text" id="response" value="" disabled="true">
<br/><br/>
The example implementation in server_test.cc can also serve the HTTP-based <a href="other_tests">Other Tests</a>.
</form>
</body>
</html>
�      �� ��    0 	        <!DOCTYPE html>
<html lang="en-US">
<head>
<title>Window Test</title>
<style>
/* Background becomes pink in fullscreen mode. */
:fullscreen {
  background: pink;
}
</style>
<script>
function setup() {
  if (location.hostname == 'tests' || location.hostname == 'localhost')
    return;

  alert('This page can only be run from tests or localhost.');

  // Disable all elements.
  var elements = document.getElementById("form").elements;
  for (var i = 0, element; element = elements[i++]; ) {
    element.disabled = true;
  }
}

function send_message(test, params) {
  var message = 'WindowTest.' + test;
  if (typeof params != 'undefined')
    message += ':' + params;

  // Results in a call to the OnQuery method in window_test.cpp.
  window.cefQuery({'request' : message});
}

function minimize() {
  send_message('Minimize');
}

function maximize() {
  send_message('Maximize');
}

function restore() {
  minimize();
  setTimeout(function() { send_message('Restore'); }, 1000);
}

function fullscreenWindow() {
  send_message('Fullscreen');
}

function fullscreenBrowser() {
  if (document.fullscreenElement) {
    document.exitFullscreen();
  } else {
    document.getElementById('form').requestFullscreen();
  }
}

function position() {
  var x = parseInt(document.getElementById('x').value);
  var y = parseInt(document.getElementById('y').value);
  var width = parseInt(document.getElementById('width').value);
  var height = parseInt(document.getElementById('height').value);
  if (isNaN(x) || isNaN(y) || isNaN(width) || isNaN(height))
    alert('Please specify a valid numeric value.');
  else
    send_message('Position', x + ',' + y + ',' + width + ',' + height);
}

function setTitlebarHeight() {
  const height = parseFloat(document.getElementById('title_bar_height').value);
  if (isNaN(height))
    send_message('TitlebarHeight');
  else
    send_message('TitlebarHeight', height);
}
</script>
</head>
<body bgcolor="white" onload="setup()">
<form id="form">
Click a button to perform the associated window action.
<br/><input type="button" onclick="minimize();" value="Minimize">
<br/><input type="button" onclick="maximize();" value="Maximize">
<br/><input type="button" onclick="restore();" value="Restore"> (minimizes and then restores the window as topmost)
<br/><input type="button" onclick="fullscreenWindow();" value="Toggle Window Fullscreen"> (works with Views)
<br/><input type="button" onclick="fullscreenBrowser();" value="Toggle Browser Fullscreen"> (uses <a href="https://developer.mozilla.org/en-US/docs/Web/API/Fullscreen_API" target="_new">Fullscreen API</a>; background turns pink)
<br/><input type="button" onclick="position();" value="Set Position">
X: <input type="text" size="4" id="x" value="200">
Y: <input type="text" size="4" id="y" value="100">
Width: <input type="text" size="4" id="width" value="800">
Height: <input type="text" size="4" id="height" value="600">
<br/><input type="button" onclick="setTitlebarHeight();" value="Set Titlebar Height">
<input type="number" min="0" max="100" id="title_bar_height" value="50"> (works on macOS with Views)
</form>
</body>
</html>
   [      �� ��    0 	        �PNG

   IHDR         (-S   tEXtSoftware Adobe ImageReadyq�e<   �PLTE���}}}���~~~���2Q�������������������d�c����G^����w��@f�Zz�g����^�룹����RW|Ec����q���훲ה�����b�����b��������z��l��c�9Y�������E`�b����d�2Q����������(x����7o�De� s�o��l�����c���ㄴ����������i��3Q�������Dg�1O�?Psh��d�Eb�i��k�������   QtRNS�������������������������������������������������������������������������������� h��   �IDATx�d���@E��!��$��������R���ŭ�i���%�����>g����T5�^dIjȵ�;��A�/�m�Z�u&��΃�#Į3q#�	�Q*�*����� �#�����	U� ǋ`w!�n�
��T�盼�9"h��̈́[�|�` �;��/��    IEND�B`� �       �� ��    0 	        �PNG

   IHDR           D���   tEXtSoftware Adobe ImageReadyq�e<   PLTE���������  �   �����   tRNS����� ����   FIDATx�b`% *`�X���f< �&&"[�H<��*`�	F�* C�4I(� s7@� ��'�*    IEND�B`�'      �� ��    0 	        <html>
<body bgcolor="white">
<script language="JavaScript">
function execXMLHttpRequest()
{
  var url = document.getElementById("url").value;
  var warningElement = document.getElementById("warning");
  if (url.indexOf(location.origin) != 0) {
    warningElement.innerHTML =
      'For cross-origin requests to succeed the server must return CORS headers:' +
      '<pre>Access-Control-Allow-Origin: ' + location.origin +
      '<br/>Access-Control-Allow-Header: My-Custom-Header</pre>';
    warningElement.style.display = 'block';
  } else {
    warningElement.style.display = 'none';
  }

  xhr = new XMLHttpRequest();
  xhr.open("GET", url, true);
  xhr.setRequestHeader('My-Custom-Header', 'Some Value');
  xhr.onload = function(e) {
    if (xhr.readyState === 4) {
      var value = "Status Code: "+xhr.status;
      if (xhr.status === 200)
        value += "\n\n"+xhr.responseText;
      document.getElementById('ta').value = value;
    }
  }
  xhr.send();
}
</script>
<form>
URL: <input type="text" id="url" value="https://tests/request">
<br/><input type="button" onclick="execXMLHttpRequest();" value="Execute XMLHttpRequest">
<br/><textarea rows="10" cols="40" id="ta"></textarea>
</form>
<div id="warning" style="display:none;font-weight:bold;"></div>
</body>
</html>
 �      �� ��     	        (       @                                   �  �   �� �   � � ��  ��� ���   �  �   �� �   � � ��  ��� ����������������                wwwwwwwwwwwwwwwpx��������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������pxwwwwwwwwwwwwwxpx��������������pxDDDDDDDDD@    pxDDDDDDDDDH���pxDDDDDDDDDH���pxDDDDDDDDDDDDDDpx��������������pwwwwwwwwwwwwwwwp��������������������������������                                                                                                                                (      �� ��     	        (                                          �  �   �� �   � � ��  ��� ���   �  �   �� �   � � ��  ��� ��������        wwwwwwwpx������px������px������px������px������px������px������pxwwwwwwpxDDD���pxDDDDDDpx������pwwwwwwww��������                                                                �      �� ��     	        (   0   `                             qj� {r�     �R' �Q' �P' �H# �S$ �S% �R& �S& �R& �R' �hC �W! �V" �V" �U# �U$ �iP �Z �Z �Y �X  �X  �^ �] �] �[ �\ �a �` �` �_ �g �g �d �c �l
 �k �i �i �h �i �e) ʌP �b  �b �b �t �s �_ �[ �[ �c �r �v �p �b �q �o �p �x
 �n	 �h	 �w �o �t �y" �}' ߋ, Ȃ3 �E ֎@ ��U ��| ��� �s  �q  �f  �c  �b  �c  �t �u �t �r �j �e �c �c �] �[ �\ �u �v �t �u �t �e �] �\ �v �u �v �u �q �n �o �\ �v �w �u �v �u �w �v �w �w �v �w �x	 �x
 �y �z �z �z �{ �y �w ݂ �t �t �' �( �, �, �- �- �. �0 �0 �0 �0 �1 �3 ی1 �6 �7 �8 �8 �8 �: �= �> �= �@ �? �B �D �E �I �I �I �S �^ ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� Fp� cq� ��� sss ppp iii aaa ``` ___ ]]] [[[ YYY XXX                                                                                                                                                                                                                                                                     ����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������	��������������������������������������������
������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������!�� ��������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������%��������������������������������������������%��$��������������������������������������������$��"��������������������������������������������#��"��������������������������������������������#��"��������������������������������������������#��*��������������������������������������������+��(��������������������������������������������)��'��������������������������������������������'��&��������������������������������������������&��?��������������������������������������������?��<��������������������������������������������=��9��������������������������������������������;��7��������������������������������������������A��63[4]5mm]5\]m]mm5\mm5555555\\\5\\\5m\55\\5ed:���cOXY/P.Z0.0.QR00/ZPP0000000/0PPZR.BI@/DE0, �C��WkV21TSav^8{|}>qooggggggg1`_fhsnHK�{JLp��G���l�����������������������������������������-F�j���Nw~ytMMMMMMUbbrrrrrxxxxxxxxrriUMMMMMMMMMUuzt���������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������  ������  ������  ������  �                                                                                                                                                                                                                                                                         �      ������  ������  ������  ������  ������  �      �� ��     	        (       @                             ~r�     YRO �M" �M" �M" �O$ �S( �S) xH0 ~L3 wG0 wH0 rE. xI1 �YB \TP XRO �K �N! �O" �N" �N" �O$ xI0 pE. ZSO �h: �lA �j@ Ȕs Ǘz �B  �@  �i7 ̖q ʕr YSO b_] �F  �E  �C  �D  �E  �C  �n5 �l6 �f> Ηn ɗs [TO �L  �I  �J  �I  �s- �r. �p0 �o1 לj ��_ ՛k Қl Йm ZTO �Y  �K  �I �w* �v, ۞h ٝi �i  �Y  �S  �{$ �z& �x' ߢe ݡf �m  �k  �l  �m  �n  �o  �n  �j  �m  �k  �q �} �$ ކ* ݉* �7 �? ��D Ջ; �@ �Q �b �c �b �b �o  �f  �q �r �x � � � �{ �z �{ �z �u ۀ ܀ ܀ ܁ ܁ ܂ ܃ ܂ ݃ ݄ ܄ ݄ ݅ �! ݆ �$ ݆! �& �' �* �+ �- ۉ* �/ �/ �3 �3 ��5 �6 �5 �7 �7 �8 �; �= �? ԍ7 ��V �p ��� ^][ �Ҫ �Ѵ �϶ �ϴ �ϵ �ͳ �ѷ �ҹ �ӹ �ҹ �Ӹ �ӹ �ս ��� ��� ��� ��� ��� ��� ��� ��� ��� .j� ��� ��� ttt ```                                                                                                                                                                                                                                                                                         ����������������������������������������������������������������������������������������������������������������������������������		
&�������������������������������1������������������������������������������������������������"���������������������������$��.���������������������������#%��-���������������������������0%��:���������������������������?%��9���������������������������>%��8���������������������������=%��7���������������������������;��E���������������������������G@��D���������������������������F@��M���������������������������O@��L���������������������������N2��K���������������������������h2��\���������������������������g2��]���������������������������f2��[�������������������������������I3')+*+)))*))()*+++,6J!54 CBA���jYPQTVTSkllZTTXRTUiHceWda/� i���u����`�������������������_<bm����t^��}zy|yx~���{|yvrrwsqpon������������������������������������������������������������������������������������������������������������������������������������������������   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �  �  ����������������h      �� ��     	        (                                        |WR ��� �Q3 �O1 ��b sP? �Q2 �Q2 �Y9 �^G ײ� �`E ۹� �cE �bE ݹ� ��� �o7 �f@ �gD �eD 㼜 ໝ �Ü 徚 �b �c �c �d �c �d �d �s  �x( ·> �zZ 翘 ��� �g ഄ ��x �$ �& �* �+ �+ �, �- �- �/ �0 �4 �6 ��I ��� ��� ��� ��� �ڽ ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ���  ~~~ }}}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 PPPPPPPPPPPPPPPPPKMNNNNNNNNNNOLO	O&:
OJHHGGGGGGGGHI
OJEEEEEEEEEEFCOJEEEEEEEEEEFCOJEEEEEEEEEEFDOJEFEEEEEEEEEBO%JEEEEEEEEEFFBOJJIIIIJIIIIJJO(@>=77A779?<8;$O' "!)O6530./21+*-,4#4PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP����� ��  ��  ��  ��  ��  ��  �  ��  ��  ��  ��  �� ����������%      �� ��     	        (   0   `                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��H#��P'��Q'��Q'��Q'��Q'�   �   �Q&ݤR&��R&��R'��R&��R&��R&��R&��R&��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��R'�   �   �R&����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������S&�   �   �S%����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������S$�   �   �U$����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������U#�   �   �V"����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������V"�   �   �W!����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������X �   �   �Y����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������X �   �   �Z����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������Z�   �   �\����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������[�   �   �]����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������]�   �   �^����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������_�   �   �`����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������`�   �   �a����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������a�   �   �a����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������a�   �   �a����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������a�   �   �a����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������a�   �   �a����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������a�   �   �a����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������a�   �   �a����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������a�   �   �c����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������c�   �   �d����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������d�   �   �g����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������g�   �   �g����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������g�   �   �g����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������g�   �   �h����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������i��   �i����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������i��   !�k����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������k��   "�l
����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������l
��   "�n	����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������n	��   "�o����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������p��   "�p����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������q��   !�r����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������w��   �c��_��]��[��\��[��\��\��\��[��[��\��\��\��\��\��[��[��\��\��[��[��[��[��[��[��[��[��[��[��[��[��[��[��[��\��[��[��[��[��[��[��\��]��b��t��   �e��f ��e��c��b��c ��b ��c��b��b ��b��b ��b ��c ��b��b��b��c��c ��c ��b��b��b��b��b��b��b��b��b��c ��c ��c��c ��b ��o�֎@��h	��b��y"��}'��b��e)�qj���iP��t��t��   �j��n��r��s��t��u��t��u��w��u��v��y��{��z��{��z��x
��v��w��w��u��u��u��u��u��u��u��t��t��v��v��v��w��v��E���|�݂��y���U������u�{r��Fp��cq��Ȃ3��w�   �   �o��y��S��^��E��D��I��I��D��:��B��I��6��3��8��?��@��=��>��>��=��=��=��=��=��=��=��8��,��0��0��-��.��(��'��,��0��-��0��1��7��8�ʌP�ߋ,�ی1��q�   J   �w 1�q ��v��z��x	��v��s ��s ��s ��s ��s ��s ��t��t��t��u��u��u��u��u��w��w��w��w��w��w��w��w��u��u��u��t��s ��s ��s ��s ��s ��s ��s ��s ��s ��t��w��x
��v��` W                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ������  ������  ������  �                                                                                                                                                                                                                                                                                                                             ������  ������  ������  ������  ������  �      �� ��     	        (       @                                                                                                                                                                                                                                                                                                                                                                                                     ^   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   i   �G ��>�:��9��8��8��8��9��:��:��:��:��:��:��:��:��:�:�:�:�:�:�:�:�:�:�:�:�:�i2�	�   ,�K��S(��O$��N!��N!��N!��N!��N"��M"��M"��M"��M"��M"��M"��M"��M"��M"��M"��M"��M"��M"��M"��M"��M"��N"��M"��M"��O$��S)��O"��   1�lA�����������������������������������������������������������������������������������������������������������������ɗs�#�   -�j@�����������������������������������������������������������������������������������������������������������������Ǘz�
�   +�h:�����������������������������������������������������������������������������������������������������������������Ȕs�	 �   +�i7�����������������������������������������������������������������������������������������������������������������ʕr�
 �   +�l6�����������������������������������������������������������������������������������������������������������������̖q�
 �   +�n5�����������������������������������������������������������������������������������������������������������������Ηn�
 �   +�o1�����������������������������������������������������������������������������������������������������������������Йm� �   +�p0�����������������������������������������������������������������������������������������������������������������Қl� �   *�r.�����������������������������������������������������������������������������������������������������������������՛k� �   #�r.�����������������������������������������������������������������������������������������������������������������՛k� �   "�s-�����������������������������������������������������������������������������������������������������������������לj� �   "�v,�����������������������������������������������������������������������������������������������������������������ٝi� �   "�w*�����������������������������������������������������������������������������������������������������������������۞h� �   "�x'�����������������������������������������������������������������������������������������������������������������ݡf� �   "�z&�����������������������������������������������������������������������������������������������������������������ߢe� �   "�{$������������������������������������������������������������������������������������������������������������������b� �   "�$������������������������������������������������������������������������������������������������������������������b� �   "ކ*������������������������������������������������������������������������������������������������������������������c� �   "�}������ս��ҹ��ҹ��ӹ��ӹ��ҹ��ӹ��ӹ��ӹ��ӹ��ҹ��ӹ��ҹ��ҹ��ҹ��ҹ��ҹ��ҹ��Ӹ��϶��ͳ��ѷ��ϵ��ϴ��Ѵ��Ҫ�����ԍ7��   "�Y ��L ��F ��C ��E ��D ��E ��C ��C ��C ��D ��C ��C ��E ��C ��C ��D ��E ��E ��E ��C ��I ��S ��@ ��J ��I ��B ��I��K ��Y ��   $�f ��k ��m ��k ��n ��n ��n ��m ��q��r��r��q��n ��n ��m ��m ��l ��n ��o ��o ��i ��@��b��j ��Q���D��f>�.j��~r���o ��   �n �ۉ*���V��=��;��?��7��3��?��/��/��8��7��5��6��6��-��&��*��'��!��+��3��$��3���5��7���_�Ջ;��x�h   �t b�x�܄�܀��}��{��z��z
��|��z	��y
��|��}��}������~��{��|��z	��y��s ��s ��y��t ��t ��{ ��} ��|��m �                                                                                                                                                                                                                                                                                                                                                                                                       ���������                                                                                                          ������������h      �� ��     	        (                                                                                      
      k   �   �   �   �   �   �   �   �   �   �   �   �   {   O�O&��F#�C!�C!�C!�C!�C!�C!�C!�C!�C!�C!�A �E$�R(�   pְ������������������������������������������������������rE+�   pٵ������������������������������������������������������qD)�   p۵������������������������������������������������������tF'�   p޷������������������������������������������������������wH'�   pḖ�����������������������������������������������������zI&�   p五�����������������������������������������������������}L%�   p滒������������������������������������������������������N%�   p���������������������������������������������������������M!�   pް}��������������������������������������������������ڽ��c>�   p�c��d��c��d��d��d��c��b��c��c��x(��s ��o7�|WR��zW�   R�y��*����������������������$��1�mp   	                                                                                                                                � :�  ��  ��  ��  ��  ��  ��  ��  ��  ��  ��  ��  ��  ����������v       �� ��e     0	                 �      (   00    �         �       h   00     �%          �        h     �      �� ��	     	        (       @                                   �  �   �� �   � � ��  ��� ���   �  �   �� �   � � ��  ��� ����������������                wwwwwwwwwwwwwwwpx��������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������px�������������pxwwwwwwwwwwwwwxpx��������������pxDDDDDDDDD@    pxDDDDDDDDDH���pxDDDDDDDDDH���pxDDDDDDDDDDDDDDpx��������������pwwwwwwwwwwwwwwwp��������������������������������                                                                                                                                (      �� ��
     	        (                                          �  �   �� �   � � ��  ��� ���   �  �   �� �   � � ��  ��� ��������        wwwwwwwpx������px������px������px������px������px������px������pxwwwwwwpxDDD���pxDDDDDDpx������pwwwwwwww��������                                                                �      �� ��     	        (   0   `                             qj� {r�     �R' �Q' �P' �H# �S$ �S% �R& �S& �R& �R' �hC �W! �V" �V" �U# �U$ �iP �Z �Z �Y �X  �X  �^ �] �] �[ �\ �a �` �` �_ �g �g �d �c �l
 �k �i �i �h �i �e) ʌP �b  �b �b �t �s �_ �[ �[ �c �r �v �p �b �q �o �p �x
 �n	 �h	 �w �o �t �y" �}' ߋ, Ȃ3 �E ֎@ ��U ��| ��� �s  �q  �f  �c  �b  �c  �t �u �t �r �j �e �c �c �] �[ �\ �u �v �t �u �t �e �] �\ �v �u �v �u �q �n �o �\ �v �w �u �v �u �w �v �w �w �v �w �x	 �x
 �y �z �z �z �{ �y �w ݂ �t �t �' �( �, �, �- �- �. �0 �0 �0 �0 �1 �3 ی1 �6 �7 �8 �8 �8 �: �= �> �= �@ �? �B �D �E �I �I �I �S �^ ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� Fp� cq� ��� sss ppp iii aaa ``` ___ ]]] [[[ YYY XXX                                                                                                                                                                                                                                                                     ����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������	��������������������������������������������
������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������!�� ��������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������%��������������������������������������������%��$��������������������������������������������$��"��������������������������������������������#��"��������������������������������������������#��"��������������������������������������������#��*��������������������������������������������+��(��������������������������������������������)��'��������������������������������������������'��&��������������������������������������������&��?��������������������������������������������?��<��������������������������������������������=��9��������������������������������������������;��7��������������������������������������������A��63[4]5mm]5\]m]mm5\mm5555555\\\5\\\5m\55\\5ed:���cOXY/P.Z0.0.QR00/ZPP0000000/0PPZR.BI@/DE0, �C��WkV21TSav^8{|}>qooggggggg1`_fhsnHK�{JLp��G���l�����������������������������������������-F�j���Nw~ytMMMMMMUbbrrrrrxxxxxxxxrriUMMMMMMMMMUuzt���������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������  ������  ������  ������  �                                                                                                                                                                                                                                                                         �      ������  ������  ������  ������  ������  �      �� ��     	        (       @                             ~r�     YRO �M" �M" �M" �O$ �S( �S) xH0 ~L3 wG0 wH0 rE. xI1 �YB \TP XRO �K �N! �O" �N" �N" �O$ xI0 pE. ZSO �h: �lA �j@ Ȕs Ǘz �B  �@  �i7 ̖q ʕr YSO b_] �F  �E  �C  �D  �E  �C  �n5 �l6 �f> Ηn ɗs [TO �L  �I  �J  �I  �s- �r. �p0 �o1 לj ��_ ՛k Қl Йm ZTO �Y  �K  �I �w* �v, ۞h ٝi �i  �Y  �S  �{$ �z& �x' ߢe ݡf �m  �k  �l  �m  �n  �o  �n  �j  �m  �k  �q �} �$ ކ* ݉* �7 �? ��D Ջ; �@ �Q �b �c �b �b �o  �f  �q �r �x � � � �{ �z �{ �z �u ۀ ܀ ܀ ܁ ܁ ܂ ܃ ܂ ݃ ݄ ܄ ݄ ݅ �! ݆ �$ ݆! �& �' �* �+ �- ۉ* �/ �/ �3 �3 ��5 �6 �5 �7 �7 �8 �; �= �? ԍ7 ��V �p ��� ^][ �Ҫ �Ѵ �϶ �ϴ �ϵ �ͳ �ѷ �ҹ �ӹ �ҹ �Ӹ �ӹ �ս ��� ��� ��� ��� ��� ��� ��� ��� ��� .j� ��� ��� ttt ```                                                                                                                                                                                                                                                                                         ����������������������������������������������������������������������������������������������������������������������������������		
&�������������������������������1������������������������������������������������������������"���������������������������$��.���������������������������#%��-���������������������������0%��:���������������������������?%��9���������������������������>%��8���������������������������=%��7���������������������������;��E���������������������������G@��D���������������������������F@��M���������������������������O@��L���������������������������N2��K���������������������������h2��\���������������������������g2��]���������������������������f2��[�������������������������������I3')+*+)))*))()*+++,6J!54 CBA���jYPQTVTSkllZTTXRTUiHceWda/� i���u����`�������������������_<bm����t^��}zy|yx~���{|yvrrwsqpon������������������������������������������������������������������������������������������������������������������������������������������������   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �  �  ����������������h      �� ��     	        (                                        |WR ��� �Q3 �O1 ��b sP? �Q2 �Q2 �Y9 �^G ײ� �`E ۹� �cE �bE ݹ� ��� �o7 �f@ �gD �eD 㼜 ໝ �Ü 徚 �b �c �c �d �c �d �d �s  �x( ·> �zZ 翘 ��� �g ഄ ��x �$ �& �* �+ �+ �, �- �- �/ �0 �4 �6 ��I ��� ��� ��� ��� �ڽ ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ���  ~~~ }}}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 PPPPPPPPPPPPPPPPPKMNNNNNNNNNNOLO	O&:
OJHHGGGGGGGGHI
OJEEEEEEEEEEFCOJEEEEEEEEEEFCOJEEEEEEEEEEFDOJEFEEEEEEEEEBO%JEEEEEEEEEFFBOJJIIIIJIIIIJJO(@>=77A779?<8;$O' "!)O6530./21+*-,4#4PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP����� ��  ��  ��  ��  ��  ��  �  ��  ��  ��  ��  �� ����������%      �� ��     	        (   0   `                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��H#��P'��Q'��Q'��Q'��Q'�   �   �Q&ݤR&��R&��R'��R&��R&��R&��R&��R&��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��Q'��R'�   �   �R&����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������S&�   �   �S%����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������S$�   �   �U$����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������U#�   �   �V"����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������V"�   �   �W!����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������X �   �   �Y����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������X �   �   �Z����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������Z�   �   �\����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������[�   �   �]����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������]�   �   �^����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������_�   �   �`����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������`�   �   �a����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������a�   �   �a����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������a�   �   �a����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������a�   �   �a����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������a�   �   �a����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������a�   �   �a����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������a�   �   �a����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������a�   �   �c����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������c�   �   �d����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������d�   �   �g����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������g�   �   �g����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������g�   �   �g����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������g�   �   �h����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������i��   �i����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������i��   !�k����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������k��   "�l
����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������l
��   "�n	����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������n	��   "�o����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������p��   "�p����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������q��   !�r����������������������������������������������������������������������������������������������������������������������������������������������������������������������������������w��   �c��_��]��[��\��[��\��\��\��[��[��\��\��\��\��\��[��[��\��\��[��[��[��[��[��[��[��[��[��[��[��[��[��[��[��\��[��[��[��[��[��[��\��]��b��t��   �e��f ��e��c��b��c ��b ��c��b��b ��b��b ��b ��c ��b��b��b��c��c ��c ��b��b��b��b��b��b��b��b��b��c ��c ��c��c ��b ��o�֎@��h	��b��y"��}'��b��e)�qj���iP��t��t��   �j��n��r��s��t��u��t��u��w��u��v��y��{��z��{��z��x
��v��w��w��u��u��u��u��u��u��u��t��t��v��v��v��w��v��E���|�݂��y���U������u�{r��Fp��cq��Ȃ3��w�   �   �o��y��S��^��E��D��I��I��D��:��B��I��6��3��8��?��@��=��>��>��=��=��=��=��=��=��=��8��,��0��0��-��.��(��'��,��0��-��0��1��7��8�ʌP�ߋ,�ی1��q�   J   �w 1�q ��v��z��x	��v��s ��s ��s ��s ��s ��s ��t��t��t��u��u��u��u��u��w��w��w��w��w��w��w��w��u��u��u��t��s ��s ��s ��s ��s ��s ��s ��s ��s ��t��w��x
��v��` W                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ������  ������  ������  �                                                                                                                                                                                                                                                                                                                             ������  ������  ������  ������  ������  �      �� ��     	        (       @                                                                                                                                                                                                                                                                                                                                                                                                     ^   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   �   i   �G ��>�:��9��8��8��8��9��:��:��:��:��:��:��:��:��:�:�:�:�:�:�:�:�:�:�:�:�:�i2�	�   ,�K��S(��O$��N!��N!��N!��N!��N"��M"��M"��M"��M"��M"��M"��M"��M"��M"��M"��M"��M"��M"��M"��M"��M"��N"��M"��M"��O$��S)��O"��   1�lA�����������������������������������������������������������������������������������������������������������������ɗs�#�   -�j@�����������������������������������������������������������������������������������������������������������������Ǘz�
�   +�h:�����������������������������������������������������������������������������������������������������������������Ȕs�	 �   +�i7�����������������������������������������������������������������������������������������������������������������ʕr�
 �   +�l6�����������������������������������������������������������������������������������������������������������������̖q�
 �   +�n5�����������������������������������������������������������������������������������������������������������������Ηn�
 �   +�o1�����������������������������������������������������������������������������������������������������������������Йm� �   +�p0�����������������������������������������������������������������������������������������������������������������Қl� �   *�r.�����������������������������������������������������������������������������������������������������������������՛k� �   #�r.�����������������������������������������������������������������������������������������������������������������՛k� �   "�s-�����������������������������������������������������������������������������������������������������������������לj� �   "�v,�����������������������������������������������������������������������������������������������������������������ٝi� �   "�w*�����������������������������������������������������������������������������������������������������������������۞h� �   "�x'�����������������������������������������������������������������������������������������������������������������ݡf� �   "�z&�����������������������������������������������������������������������������������������������������������������ߢe� �   "�{$������������������������������������������������������������������������������������������������������������������b� �   "�$������������������������������������������������������������������������������������������������������������������b� �   "ކ*������������������������������������������������������������������������������������������������������������������c� �   "�}������ս��ҹ��ҹ��ӹ��ӹ��ҹ��ӹ��ӹ��ӹ��ӹ��ҹ��ӹ��ҹ��ҹ��ҹ��ҹ��ҹ��ҹ��Ӹ��϶��ͳ��ѷ��ϵ��ϴ��Ѵ��Ҫ�����ԍ7��   "�Y ��L ��F ��C ��E ��D ��E ��C ��C ��C ��D ��C ��C ��E ��C ��C ��D ��E ��E ��E ��C ��I ��S ��@ ��J ��I ��B ��I��K ��Y ��   $�f ��k ��m ��k ��n ��n ��n ��m ��q��r��r��q��n ��n ��m ��m ��l ��n ��o ��o ��i ��@��b��j ��Q���D��f>�.j��~r���o ��   �n �ۉ*���V��=��;��?��7��3��?��/��/��8��7��5��6��6��-��&��*��'��!��+��3��$��3���5��7���_�Ջ;��x�h   �t b�x�܄�܀��}��{��z��z
��|��z	��y
��|��}��}������~��{��|��z	��y��s ��s ��y��t ��t ��{ ��} ��|��m �                                                                                                                                                                                                                                                                                                                                                                                                       ���������                                                                                                          ������������h      �� ��     	        (                                                                                      
      k   �   �   �   �   �   �   �   �   �   �   �   �   {   O�O&��F#�C!�C!�C!�C!�C!�C!�C!�C!�C!�C!�A �E$�R(�   pְ������������������������������������������������������rE+�   pٵ������������������������������������������������������qD)�   p۵������������������������������������������������������tF'�   p޷������������������������������������������������������wH'�   pḖ�����������������������������������������������������zI&�   p五�����������������������������������������������������}L%�   p滒������������������������������������������������������N%�   p���������������������������������������������������������M!�   pް}��������������������������������������������������ڽ��c>�   p�c��d��c��d��d��d��c��b��c��c��x(��s ��o7�|WR��zW�   R�y��*����������������������$��1�mp   	                                                                                                                                � :�  ��  ��  ��  ��  ��  ��  ��  ��  ��  ��  ��  ��  ����������v       �� ��l     0	                 �  	    (  
 00    �         �       h   00     �%          �        h     ,      �� ��e     0	             & F i l e     �~& F i n d . . .         � i E & x i t    & H e l p   � h & A b o u t   . . .   � T e s t s     �G e t   S o u r c e     �G e t   T e x t     �N e w   W i n d o w     �P o p u p   W i n d o w     �R e q u e s t     �Z o o m   I n     �Z o o m   O u t     �Z o o m   R e s e t     �S e t   F P S     �S e t   S c a l e   F a c t o r     �B e g i n   T r a c i n g     �E n d   T r a c i n g     �P r i n t     �P r i n t   t o   P D F     �M u t e   A u d i o     �U n m u t e   A u d i o   � �O t h e r   T e s t s          ��	 ��e     0 	         ? h   � / h   �       �� ��g     0	        � �        � K     A b o u t    S y s t e m       P     	    ��� ��e   � P    1 
 w  ����� c e f c l i e n t   V e r s i o n   1 . 0       P    1  w  ����� C o p y r i g h t   ( C )   2 0 0 8        P    �     ��� O K       �      �� ��     0 	        �4   V S _ V E R S I O N _ I N F O     ���    �     �                             Z   S t r i n g F i l e I n f o   6   0 4 0 9 0 4 b 0   � 5  F i l e D e s c r i p t i o n     C h r o m i u m   E m b e d d e d   F r a m e w o r k   ( C E F )   C l i e n t   A p p l i c a t i o n     r )  F i l e V e r s i o n     1 3 4 . 3 . 8 + g f e 6 6 d 8 0 + c h r o m i u m - 1 3 4 . 0 . 6 9 9 8 . 1 6 6     4 
  I n t e r n a l N a m e   c e f c l i e n t   � ;  L e g a l C o p y r i g h t   C o p y r i g h t   ( C )   2 0 2 5   T h e   C h r o m i u m   E m b e d d e d   F r a m e w o r k   A u t h o r s     D   O r i g i n a l F i l e n a m e   c e f c l i e n t . e x e   � 5  P r o d u c t N a m e     C h r o m i u m   E m b e d d e d   F r a m e w o r k   ( C E F )   C l i e n t   A p p l i c a t i o n     v )  P r o d u c t V e r s i o n   1 3 4 . 3 . 8 + g f e 6 6 d 8 0 + c h r o m i u m - 1 3 4 . 0 . 6 9 9 8 . 1 6 6     D    V a r F i l e I n f o     $    T r a n s l a t i o n     	�D       �� ��     0	                  	 C E F C L I E N T   	 c e f c l i e n t                 