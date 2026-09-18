import Toybox.Application;
import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.FitContributor;
import Toybox.Lang;
import Toybox.Sensor;
import Toybox.System;
import Toybox.WatchUi;

class GarminGolfTrainerApp extends Application.AppBase {

    // Acceleration is supplied in milli-g. A full swing creates a much larger
    // wrist acceleration than normal address movement. This deliberately errs
    // on the conservative side; the manual "LOG SHOT" action remains available.
    private const SHOT_ACCELERATION_SQUARED = 9000000;
    private const SHOT_COOLDOWN_MS = 3000;

    private var _rangeSession as ActivityRecording.Session?;
    private var _rangeRunning as Lang.Boolean = false;
    private var _rangePaused as Lang.Boolean = false;
    private var _awaitingShotInput as Lang.Boolean = false;
    private var _lastShotMillis as Lang.Number = 0;
    // Elapsed time is accumulated across pauses rather than derived from a
    // single start stamp, so the timer freezes in the stop menu like a
    // native activity does.
    private var _elapsedAccumMs as Lang.Number = 0;
    private var _resumeMillis as Lang.Number = 0;
    private var _rangeShotCount as Lang.Number = 0;
    private var _rangeShots as Lang.Array = [];
    private var _fitFields as Lang.Dictionary = {};
    private var _currentHeartRate as Lang.Number?;
    private var _heartRateTotal as Lang.Number = 0;
    private var _heartRateSamples as Lang.Number = 0;
    private var _maxHeartRate as Lang.Number = 0;

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        return [new PreStartView(), new PreStartDelegate()];
    }

    function startRangeSession() as Lang.Boolean {
        if (_rangeRunning) { return true; }

        try {
            _rangeSession = ActivityRecording.createSession({
                :name => "Driving Range",
                :sport => Activity.SPORT_GOLF
            });
            createSessionFitFields();
            _rangeSession.start();

            Sensor.registerSensorDataListener(method(:onSensorData), {
                :period => 1,
                :accelerometer => { :enabled => true, :sampleRate => 25 }
            });
            Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
            Sensor.enableSensorEvents(method(:onSensorInfo));

            _rangeRunning = true;
            _rangePaused = false;
            _awaitingShotInput = false;
            _rangeShotCount = 0;
            _rangeShots = [];
            _heartRateTotal = 0;
            _heartRateSamples = 0;
            _maxHeartRate = 0;
            _currentHeartRate = null;
            _lastShotMillis = System.getTimer();
            _elapsedAccumMs = 0;
            _resumeMillis = System.getTimer();
            return true;
        } catch (e) {
            System.println("Could not start range: " + e.getErrorMessage());
            if (_rangeSession != null) {
                try {
                    _rangeSession.stop();
                    _rangeSession.discard();
                } catch (cleanupError) {}
            }
            _rangeSession = null;
            return false;
        }
    }

    // Recording pauses while the stop menu is open, matching native activities
    // where the timer holds until you choose Resume, Save or Discard.
    function pauseRangeSession() as Void {
        if (!_rangeRunning || _rangePaused) { return; }
        _elapsedAccumMs += System.getTimer() - _resumeMillis;
        _rangePaused = true;
        try {
            if (_rangeSession != null) { _rangeSession.stop(); }
        } catch (e) {
            System.println("Could not pause range: " + e.getErrorMessage());
        }
    }

    function resumeRangeSession() as Void {
        if (!_rangeRunning || !_rangePaused) { return; }
        _resumeMillis = System.getTimer();
        _rangePaused = false;
        try {
            if (_rangeSession != null) { _rangeSession.start(); }
        } catch (e) {
            System.println("Could not resume range: " + e.getErrorMessage());
        }
    }

    function isRangePaused() as Lang.Boolean {
        return _rangePaused;
    }

    function isRangeRunning() as Lang.Boolean {
        return _rangeRunning;
    }

    function saveRangeSession() as Void {
        if (!_rangeRunning) { return; }
        try {
            Sensor.unregisterSensorDataListener();
            Sensor.enableSensorEvents(null);
            if (_rangeSession != null) {
                writeSessionFitSummary();
                _rangeSession.stop();
                _rangeSession.save();
            }
        } catch (e) {
            System.println("Could not save range: " + e.getErrorMessage());
        }
        clearRangeState();
    }

    function discardRangeSession() as Void {
        if (!_rangeRunning) { return; }
        try {
            Sensor.unregisterSensorDataListener();
            Sensor.enableSensorEvents(null);
            if (_rangeSession != null) {
                _rangeSession.stop();
                _rangeSession.discard();
            }
        } catch (e) {
            System.println("Could not discard range: " + e.getErrorMessage());
        }
        clearRangeState();
    }

    private function clearRangeState() as Void {
        _rangeSession = null;
        _fitFields = {};
        _rangeRunning = false;
        _rangePaused = false;
        _awaitingShotInput = false;
    }

    function getRangeShotCount() as Lang.Number {
        return _rangeShotCount;
    }

    function getRangeElapsedSeconds() as Lang.Number {
        if (!_rangeRunning) { return 0; }
        var elapsed = _elapsedAccumMs;
        if (!_rangePaused) { elapsed += System.getTimer() - _resumeMillis; }
        return (elapsed / 1000).toNumber();
    }

    function getRangeShots() as Lang.Array {
        return _rangeShots;
    }

    function getCurrentHeartRate() as Lang.Number? {
        return _currentHeartRate;
    }

    function getAverageHeartRate() as Lang.Number? {
        return _heartRateSamples > 0 ? (_heartRateTotal / _heartRateSamples).toNumber() : null;
    }

    function getMaxHeartRate() as Lang.Number? {
        return _heartRateSamples > 0 ? _maxHeartRate : null;
    }

    function completeRangeShot(shot as Lang.Dictionary) as Void {
        _rangeShots.add(shot);
        _rangeShotCount += 1;
        _awaitingShotInput = false;
        WatchUi.requestUpdate();
    }

    function cancelRangeShotPrompt() as Void {
        _awaitingShotInput = false;
    }

    // Heart rate comes from the watch optical sensor or a connected strap.
    // The event source is separate from the high-rate accelerometer listener.
    function onSensorInfo(sensorInfo as Sensor.Info) as Void {
        if (!_rangeRunning || _rangePaused || sensorInfo.heartRate == null) { return; }
        var heartRate = sensorInfo.heartRate as Lang.Number;
        _currentHeartRate = heartRate;
        _heartRateTotal += heartRate;
        _heartRateSamples += 1;
        if (heartRate > _maxHeartRate) { _maxHeartRate = heartRate; }
        WatchUi.requestUpdate();
    }

    private function createSessionFitFields() as Void {
        if (_rangeSession == null) { return; }
        try {
            _fitFields["shots"] = _rangeSession.createField("shots", 0, FitContributor.DATA_TYPE_UINT16, { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "shots" });
            _fitFields["solid"] = _rangeSession.createField("solidShots", 1, FitContributor.DATA_TYPE_UINT16, { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "shots" });
            _fitFields["solidPct"] = _rangeSession.createField("solidPercent", 2, FitContributor.DATA_TYPE_UINT8, { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "%" });
            _fitFields["averageDistance"] = _rangeSession.createField("averageDistance", 3, FitContributor.DATA_TYPE_UINT16, { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "distance" });
            _fitFields["slice"] = _rangeSession.createField("slices", 4, FitContributor.DATA_TYPE_UINT16, { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "shots" });
            _fitFields["pull"] = _rangeSession.createField("pulls", 5, FitContributor.DATA_TYPE_UINT16, { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "shots" });
            _fitFields["duff"] = _rangeSession.createField("duffs", 6, FitContributor.DATA_TYPE_UINT16, { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "shots" });
            _fitFields["thin"] = _rangeSession.createField("thins", 7, FitContributor.DATA_TYPE_UINT16, { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "shots" });
            _fitFields["shank"] = _rangeSession.createField("shanks", 8, FitContributor.DATA_TYPE_UINT16, { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "shots" });
            _fitFields["averageHr"] = _rangeSession.createField("averageHeartRate", 9, FitContributor.DATA_TYPE_UINT8, { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "bpm" });
            _fitFields["maxHr"] = _rangeSession.createField("maxHeartRate", 10, FitContributor.DATA_TYPE_UINT8, { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "bpm" });
        } catch (e) {
            System.println("Could not create FIT fields: " + e.getErrorMessage());
            _fitFields = {};
        }
    }

    private function setFitField(key as Lang.String, value as Lang.Number) as Void {
        if (_fitFields.hasKey(key)) {
            (_fitFields[key] as FitContributor.Field).setData(value);
        }
    }

    private function writeSessionFitSummary() as Void {
        var totalDistance = 0;
        var measured = 0;
        var solid = 0;
        var counts = { "slice" => 0, "pull" => 0, "duff" => 0, "thin" => 0, "shank" => 0 } as Lang.Dictionary;
        for (var i = 0; i < _rangeShots.size(); i++) {
            var shot = _rangeShots[i] as Lang.Dictionary;
            var distance = shot.get("distance") as Lang.Number?;
            if (distance != null) {
                totalDistance += distance;
                measured += 1;
            }
            var quality = shot.get("quality") as Lang.String?;
            if (quality == null) {
                // Nothing to count.
            } else if (quality.equals("solid")) {
                solid += 1;
            } else if (counts.hasKey(quality)) {
                counts[quality] = (counts[quality] as Lang.Number) + 1;
            }
        }

        var shots = _rangeShots.size();
        setFitField("shots", shots);
        setFitField("solid", solid);
        setFitField("solidPct", shots > 0 ? ((solid * 100) / shots).toNumber() : 0);
        setFitField("averageDistance", measured > 0 ? (totalDistance / measured).toNumber() : 0);
        setFitField("slice", counts["slice"] as Lang.Number);
        setFitField("pull", counts["pull"] as Lang.Number);
        setFitField("duff", counts["duff"] as Lang.Number);
        setFitField("thin", counts["thin"] as Lang.Number);
        setFitField("shank", counts["shank"] as Lang.Number);
        setFitField("averageHr", getAverageHeartRate() == null ? 0 : getAverageHeartRate() as Lang.Number);
        setFitField("maxHr", getMaxHeartRate() == null ? 0 : getMaxHeartRate() as Lang.Number);
    }

    // Receives 25 Hz accelerometer batches while a range session is running.
    // The cooldown prevents the follow-through from producing duplicate prompts.
    function onSensorData(sensorData as Sensor.SensorData) as Void {
        if (!_rangeRunning || _rangePaused || _awaitingShotInput) { return; }
        if (!ShotHistory.shouldLogShots()) { return; }

        var accel = sensorData.accelerometerData;
        if (accel == null || accel.x == null || accel.y == null || accel.z == null) {
            return;
        }

        var now = System.getTimer();
        if (now - _lastShotMillis < SHOT_COOLDOWN_MS) { return; }

        for (var i = 0; i < accel.x.size(); i++) {
            var x = accel.x[i];
            var y = accel.y[i];
            var z = accel.z[i];
            if ((x * x) + (y * y) + (z * z) >= SHOT_ACCELERATION_SQUARED) {
                _lastShotMillis = now;
                _awaitingShotInput = true;
                WatchUi.pushView(
                    new ClubMenu(),
                    new ClubDelegate({ "rangeShot" => true } as Lang.Dictionary),
                    WatchUi.SLIDE_UP
                );
                return;
            }
        }
    }
}

function getApp() as GarminGolfTrainerApp {
    return Application.getApp() as GarminGolfTrainerApp;
}
