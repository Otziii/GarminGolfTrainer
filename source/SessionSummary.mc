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
        var measured = 0;
        var misses = {} as Lang.Dictionary;
        for (var i = 0; i < _shots.size(); i++) {
            var shot = _shots[i] as Lang.Dictionary;
            var distance = shot.get("distance") as Lang.Number?;
            if (distance != null) {
                totalDistance += distance;
                measured += 1;
            }
            var quality = shot.get("quality") as Lang.String?;
            if (quality != null && quality.equals("solid")) {
                _solidCount += 1;
            } else if (quality != null) {
                var label = qualityLabel(quality);
                var count = misses.hasKey(label) ? misses[label] as Lang.Number : 0;
                misses[label] = count + 1;
                if ((count + 1) > _topMissCount) {
                    _topMissCount = count + 1;
                    _topMiss = label;
                }
            }
        }
        _average = measured > 0 ? (totalDistance / measured).toNumber() : 0;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var h = dc.getHeight();
        var count = _shots.size();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        Layout.drawFitted(dc, (h * 0.14).toNumber(),
            [Graphics.FONT_XTINY] as Lang.Array, "RANGE SUMMARY");

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        Layout.drawFitted(dc, (h * 0.30).toNumber(),
            [Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_LARGE] as Lang.Array,
            count.toString() + (count == 1 ? " shot" : " shots"));

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        Layout.drawFitted(dc, (h * 0.47).toNumber(),
            [Graphics.FONT_SMALL, Graphics.FONT_TINY] as Lang.Array,
            _average > 0
                ? "Avg " + _average.toString() + " " + ShotHistory.getUnitText()
                : "No distances logged");

        Layout.drawFitted(dc, (h * 0.60).toNumber(),
            [Graphics.FONT_SMALL, Graphics.FONT_TINY] as Lang.Array,
            "Solid " + _solidCount.toString() + "/" + count.toString());

        var averageHr = getApp().getAverageHeartRate();
        var maxHr = getApp().getMaxHeartRate();
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        Layout.drawFitted(dc, (h * 0.72).toNumber(),
            [Graphics.FONT_XTINY] as Lang.Array,
            averageHr == null
                ? "HR --"
                : "HR " + averageHr.toString() + " / " + maxHr.toString() + " bpm");

        Layout.drawFitted(dc, (h * 0.84).toNumber(),
            [Graphics.FONT_XTINY] as Lang.Array,
            _topMissCount > 0
                ? "Top miss: " + _topMiss + " (" + _topMissCount.toString() + ")"
                : "No misses tagged");
    }
}

class SessionSummaryDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() as Lang.Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function onBack() as Lang.Boolean {
        return onSelect();
    }
}
