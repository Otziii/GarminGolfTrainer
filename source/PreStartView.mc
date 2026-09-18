import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Sensor;
import Toybox.Timer;
import Toybox.WatchUi;

// The pre-start screen, mirroring a native activity: activity name, a ready
// state, and a hint that START begins recording. MENU opens the activity
// menu, BACK leaves the app.
class PreStartView extends WatchUi.View {
    private var _refreshTimer as Timer.Timer;
    private var _heartRate as Lang.Number?;

    function initialize() {
        View.initialize();
        _refreshTimer = new Timer.Timer();
    }

    function onShow() as Void {
        // Heart rate is shown before starting, the way native activities
        // display sensor status on the pre-start screen.
        Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
        Sensor.enableSensorEvents(method(:onSensor));
        _refreshTimer.start(method(:refresh), 1000, true);
    }

    function onHide() as Void {
        _refreshTimer.stop();
        // Leaving this screen to start recording hands the sensors over to
        // the session, which registered its own listeners in
        // startRangeSession(). Clearing them here would kill heart rate for
        // the whole activity.
        if (!getApp().isRangeRunning()) {
            Sensor.enableSensorEvents(null);
        }
    }

    function onSensor(info as Sensor.Info) as Void {
        _heartRate = info.heartRate;
        WatchUi.requestUpdate();
    }

    function refresh() as Void {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var h = dc.getHeight();
        // No GPS is needed at a driving range, so "ready" means the optical
        // sensor has a heart rate -- the same condition native activities
        // wait on before filling their status bar green.
        var ready = _heartRate != null;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        Layout.drawFitted(dc, (h * 0.24).toNumber(),
            [Graphics.FONT_MEDIUM, Graphics.FONT_SMALL, Graphics.FONT_TINY] as Lang.Array,
            "Driving Range");

        Layout.drawStatusBar(dc, (h * 0.40).toNumber(), ready);

        dc.setColor(ready ? Graphics.COLOR_GREEN : Graphics.COLOR_LT_GRAY,
            Graphics.COLOR_TRANSPARENT);
        Layout.drawFitted(dc, (h * 0.56).toNumber(),
            [Graphics.FONT_MEDIUM, Graphics.FONT_SMALL] as Lang.Array,
            ready ? "READY" : "SEARCHING");

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        Layout.drawFitted(dc, (h * 0.70).toNumber(),
            [Graphics.FONT_SMALL, Graphics.FONT_TINY] as Lang.Array,
            _heartRate == null ? "-- bpm" : _heartRate.toString() + " bpm");

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        Layout.drawFitted(dc, (h * 0.85).toNumber(),
            [Graphics.FONT_XTINY] as Lang.Array, "PRESS START");
    }
}

class PreStartDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    // Key level again, so a brushed screen cannot start a session either.
    function onKey(keyEvent as WatchUi.KeyEvent) as Lang.Boolean {
        if (keyEvent.getKey() == WatchUi.KEY_ENTER) {
            start();
            return true;
        }
        return false;
    }

    private function start() as Void {
        if (getApp().startRangeSession()) {
            var view = new RangeActivityView();
            WatchUi.pushView(view, new RangeActivityDelegate(view), WatchUi.SLIDE_LEFT);
        }
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Lang.Boolean {
        return true;
    }

    function onSelect() as Lang.Boolean {
        return true;
    }

    function onMenu() as Lang.Boolean {
        // Guidelines: menus slide in from the right and dismiss back to it.
        WatchUi.pushView(new PreStartMenu(), new PreStartMenuDelegate(), WatchUi.SLIDE_LEFT);
        return true;
    }
}
