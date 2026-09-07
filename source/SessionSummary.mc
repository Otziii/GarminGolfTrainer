import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class SessionSummaryView extends WatchUi.View {
    private var _shots as Lang.Array;
    private var _average as Lang.Number = 0;
    private var _solidCount as Lang.Number = 0;
    private var _topMiss as Lang.String = "None";
    private var _topMissCount as Lang.Number = 0;

    function initialize(shots as Lang.Array) {
        View.initialize();
        _shots = shots;
        calculateSummary();
    }

    private function calculateSummary() as Void {
        if (_shots.size() == 0) { return; }

        var totalDistance = 0;
        var misses = {} as Lang.Dictionary;
        for (var i = 0; i < _shots.size(); i++) {
            var shot = _shots[i] as Lang.Dictionary;
            totalDistance += shot["distance"] as Lang.Number;
            var quality = shot.get("quality") as Lang.Symbol?;
            if (quality != null && quality == :solid) {
                _solidCount += 1;
            } else if (quality != null) {
                var label = quality.toString();
                var count = misses.hasKey(label) ? misses[label] as Lang.Number : 0;
                misses[label] = count + 1;
                if ((count + 1) > _topMissCount) {
                    _topMissCount = count + 1;
                    _topMiss = label;
                }
            }
        }
        _average = (totalDistance / _shots.size()).toNumber();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - (h * 0.40).toNumber(), Graphics.FONT_MEDIUM,
            "RANGE SUMMARY", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - (h * 0.22).toNumber(), Graphics.FONT_LARGE,
            _shots.size().toString() + " SHOTS", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - (h * 0.02).toNumber(), Graphics.FONT_SMALL,
            "AVG " + _average.toString() + " " + ShotHistory.getUnitText(),
            Graphics.TEXT_JUSTIFY_CENTER);

        dc.drawText(cx, cy + (h * 0.15).toNumber(), Graphics.FONT_SMALL,
            "SOLID " + _solidCount.toString() + "/" + _shots.size().toString(),
            Graphics.TEXT_JUSTIFY_CENTER);

        var averageHr = getApp().getAverageHeartRate();
        var maxHr = getApp().getMaxHeartRate();
        var hrText = averageHr == null ? "HR --" : "HR " + averageHr.toString() + "/" + maxHr.toString() + " BPM";
        dc.drawText(cx, cy + (h * 0.26).toNumber(), Graphics.FONT_XTINY,
            hrText, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        var missText = _topMissCount > 0 ? "TOP MISS: " + _topMiss + " (" + _topMissCount.toString() + ")" : "NO MISSES TAGGED";
        dc.drawText(cx, cy + (h * 0.36).toNumber(), Graphics.FONT_XTINY,
            missText, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, cy + (h * 0.45).toNumber(), Graphics.FONT_XTINY,
            "SELECT OR BACK TO CLOSE", Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class SessionSummaryDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() as Lang.Boolean {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // summary
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // stopped range screen
        return true;
    }

    function onBack() as Lang.Boolean {
        return onSelect();
    }
}
