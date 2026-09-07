import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

// The active driving-range screen. Back is intentionally the explicit
// finish control so users get the same start/stop flow as native activities.
class RangeActivityView extends WatchUi.View {
    private var _refreshTimer as Timer.Timer;

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
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var elapsed = formatElapsed(getApp().getRangeElapsedSeconds());
        var heartRate = getApp().getCurrentHeartRate();
        var cardGap = (w * 0.04).toNumber();
        var cardW = ((w - (w * 0.16).toNumber() - cardGap) / 2).toNumber();
        var cardH = (h * 0.22).toNumber();
        var cardY = (h * 0.43).toNumber();
        var leftCardX = (w * 0.08).toNumber();
        var rightCardX = leftCardX + cardW + cardGap;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Recording state pill
        var pillW = (w * 0.42).toNumber();
        var pillH = (h * 0.07).toNumber();
        var pillX = cx - pillW / 2;
        var pillY = (h * 0.06).toNumber();
        dc.setColor(0x164A32, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(pillX, pillY, pillW, pillH, pillH / 2);
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(pillX + pillH / 2, pillY + pillH / 2, 4);
        dc.drawText(cx + 8, pillY + 5, Graphics.FONT_XTINY,
            "RECORDING", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.18).toNumber(), Graphics.FONT_SMALL,
            "DRIVING RANGE", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.25).toNumber(), Graphics.FONT_NUMBER_HOT,
            elapsed, Graphics.TEXT_JUSTIFY_CENTER);

        // Live stat cards
        dc.setColor(0x24282C, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(leftCardX, cardY, cardW, cardH, 16);
        dc.fillRoundedRectangle(rightCardX, cardY, cardW, cardH, 16);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftCardX + cardW / 2, cardY + (cardH * 0.16).toNumber(), Graphics.FONT_XTINY,
            "SHOTS", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(rightCardX + cardW / 2, cardY + (cardH * 0.16).toNumber(), Graphics.FONT_XTINY,
            "HEART RATE", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftCardX + cardW / 2, cardY + (cardH * 0.38).toNumber(), Graphics.FONT_NUMBER_HOT,
            getApp().getRangeShotCount().toString(), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(rightCardX + cardW / 2, cardY + (cardH * 0.38).toNumber(), Graphics.FONT_NUMBER_HOT,
            heartRate == null ? "--" : heartRate.toString(), Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rightCardX + cardW / 2, cardY + (cardH * 0.75).toNumber(), Graphics.FONT_XTINY,
            heartRate == null ? "WAITING FOR SENSOR" : "BPM",
            Graphics.TEXT_JUSTIFY_CENTER);

        // These are the two meaningful controls while recording.
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.74).toNumber(), Graphics.FONT_SMALL,
            "SWING TO LOG A SHOT", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.82).toNumber(), Graphics.FONT_XTINY,
            "SELECT: LOG MANUALLY", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, (h * 0.88).toNumber(), Graphics.FONT_XTINY,
            "BACK: SAVE & FINISH", Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class RangeActivityDelegate extends WatchUi.BehaviorDelegate {
    private var _view as RangeActivityView;

    function initialize(view as RangeActivityView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // Lets a user log a shot if the swing threshold did not trigger.
    function onSelect() as Lang.Boolean {
        WatchUi.pushView(
            new ClubMenu(),
            new ClubDelegate({ "rangeShot" => true } as Lang.Dictionary),
            WatchUi.SLIDE_LEFT
        );
        return true;
    }

    function onBack() as Lang.Boolean {
        getApp().stopRangeSession();
        WatchUi.pushView(
            new SessionSummaryView(getApp().getRangeShots()),
            new SessionSummaryDelegate(),
            WatchUi.SLIDE_UP
        );
        return true;
    }
}
