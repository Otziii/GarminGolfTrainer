import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

// The recording screen. Laid out like a native activity data page: stacked
// label/value fields, system fonts and colours only, and page dots. The
// earlier custom rounded cards and hand-picked hex colours quantised badly on
// this MIP display and overflowed the circle.
class RangeActivityView extends WatchUi.View {
    private const PAGE_COUNT = 2;

    private var _refreshTimer as Timer.Timer;
    private var _page as Lang.Number = 0;
    private var _blink as Lang.Boolean = true;

    function initialize() {
        View.initialize();
        _refreshTimer = new Timer.Timer();
    }

    function onShow() as Void {
        _refreshTimer.start(method(:refresh), 1000, true);
    }

    function onHide() as Void {
        _refreshTimer.stop();
    }

    function refresh() as Void {
        // The native paused indicator blinks rather than sitting static.
        _blink = !_blink;
        WatchUi.requestUpdate();
    }

    function nextPage() as Void {
        _page = (_page + 1) % PAGE_COUNT;
        WatchUi.requestUpdate();
    }

    function previousPage() as Void {
        _page = (_page + PAGE_COUNT - 1) % PAGE_COUNT;
        WatchUi.requestUpdate();
    }

    private function formatElapsed(seconds as Lang.Number) as Lang.String {
        var minutes = (seconds / 60).toNumber();
        var remainingSeconds = seconds % 60;
        var minuteText = minutes < 10 ? "0" + minutes.toString() : minutes.toString();
        var secondText = remainingSeconds < 10 ? "0" + remainingSeconds.toString() : remainingSeconds.toString();
        return minuteText + ":" + secondText;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var h = dc.getHeight();
        var app = getApp();
        var bigFonts = [Graphics.FONT_NUMBER_HOT, Graphics.FONT_NUMBER_MEDIUM,
            Graphics.FONT_NUMBER_MILD, Graphics.FONT_LARGE] as Lang.Array;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // A paused session shows a blinking pause glyph where native
        // activities put theirs; otherwise the header stays out of the way.
        if (app.isRangePaused() && _blink) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            Layout.drawPauseIcon(dc, (h * 0.12).toNumber(), 18);
        }

        if (_page == 0) {
            Layout.drawField(dc, (h * 0.25).toNumber(), (h * 0.38).toNumber(),
                "TIMER", formatElapsed(app.getRangeElapsedSeconds()), bigFonts);
            Layout.drawField(dc, (h * 0.62).toNumber(), (h * 0.75).toNumber(),
                "SHOTS", app.getRangeShotCount().toString(), bigFonts);
        } else {
            var heartRate = app.getCurrentHeartRate();
            Layout.drawField(dc, (h * 0.25).toNumber(), (h * 0.38).toNumber(),
                "HEART RATE", heartRate == null ? "--" : heartRate.toString(), bigFonts);

            var averageHr = app.getAverageHeartRate();
            var maxHr = app.getMaxHeartRate();
            var hrText = averageHr == null
                ? "-- / --"
                : averageHr.toString() + " / " + maxHr.toString();
            Layout.drawField(dc, (h * 0.62).toNumber(), (h * 0.75).toNumber(),
                "AVG / MAX", hrText, bigFonts);
        }

        Layout.drawPageDots(dc, PAGE_COUNT, _page);
    }
}

// Key mapping follows the fenix 8 owner's manual: the upper-right button
// stops the timer, the lower-right button records a lap (here: a shot), and
// up/down or swipe up/down change data screen.
//
// Input is handled at key level, not behaviour level, on purpose. This device
// maps a screen tap to onSelect and a right swipe to onBack, so a behaviour-
// level handler turns an accidental brush of the screen into a stopped
// activity or a stray shot. Touch is swallowed here instead.
class RangeActivityDelegate extends WatchUi.BehaviorDelegate {
    private var _view as RangeActivityView;
    private var _stopTimer as Timer.Timer;
    private var _stopping as Lang.Boolean = false;

    function initialize(view as RangeActivityView) {
        BehaviorDelegate.initialize();
        _view = view;
        _stopTimer = new Timer.Timer();
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Lang.Boolean {
        var key = keyEvent.getKey();

        if (key == WatchUi.KEY_ENTER) {
            beginStop();
            return true;
        }
        if (key == WatchUi.KEY_ESC || key == WatchUi.KEY_LAP) {
            logShot();
            return true;
        }
        // Up and down fall through to the page behaviours.
        return false;
    }

    // Native activities pause and show the pause indicator, then bring up the
    // stop menu. The short delay is what makes that sequence readable.
    private function beginStop() as Void {
        if (_stopping) { return; }
        _stopping = true;
        getApp().pauseRangeSession();
        WatchUi.requestUpdate();
        _stopTimer.start(method(:showStopMenu), 450, false);
    }

    function showStopMenu() as Void {
        _stopping = false;
        WatchUi.pushView(new StopMenu(), new StopMenuDelegate(), WatchUi.SLIDE_UP);
    }

    private function logShot() as Void {
        if (!ShotHistory.shouldLogShots()) { return; }
        WatchUi.pushView(
            new ClubMenu(),
            new ClubDelegate({ "rangeShot" => true } as Lang.Dictionary),
            WatchUi.SLIDE_LEFT
        );
    }

    // Tapping the screen must not stop the activity.
    function onTap(clickEvent as WatchUi.ClickEvent) as Lang.Boolean {
        return true;
    }

    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Lang.Boolean {
        var direction = swipeEvent.getDirection();
        if (direction == WatchUi.SWIPE_UP) {
            _view.nextPage();
        } else if (direction == WatchUi.SWIPE_DOWN) {
            _view.previousPage();
        }
        // Left and right swipes do nothing while recording.
        return true;
    }

    // Reached only by a gesture, since the physical keys are handled above.
    // Neither may leave or alter the activity.
    function onSelect() as Lang.Boolean {
        return true;
    }

    function onBack() as Lang.Boolean {
        return true;
    }

    function onNextPage() as Lang.Boolean {
        _view.nextPage();
        return true;
    }

    function onPreviousPage() as Lang.Boolean {
        _view.previousPage();
        return true;
    }

    function onMenu() as Lang.Boolean {
        // Holding MENU during a native activity opens settings without
        // pausing, so the session keeps running here.
        WatchUi.pushView(
            new SettingsMenuView(),
            new SettingsMenuDelegate(),
            WatchUi.SLIDE_LEFT
        );
        return true;
    }
}
