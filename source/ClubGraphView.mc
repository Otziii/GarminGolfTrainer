import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class ClubGraphView extends WatchUi.View {

    private var _club    as Lang.String;
    private var _shots   as Lang.Array;
    private var _avg     as Lang.Number;
    private var _min     as Lang.Number;
    private var _max     as Lang.Number;
    var _cursor          as Lang.Number;
    private const MAX_VISIBLE = 8;

    function initialize(club as Lang.String) {
        View.initialize();
        _club   = club;
        _shots  = loadShots(club);
        _cursor = _shots.size() > 0 ? _shots.size() - 1 : 0; // start on latest
        _avg    = calcAvg();
        _min    = calcMin();
        _max    = calcMax();
    }

    private function loadShots(club as Lang.String) as Lang.Array {
        var all    = ShotHistory.getShots();
        var result = [] as Lang.Array;
        for (var i = 0; i < all.size(); i++) {
            var shot = all[i] as Lang.Dictionary;
            if ((shot.get("club") as Lang.String).equals(club)) {
                result.add(shot.get("distance") as Lang.Number);
            }
        }
        return result;
    }

    private function calcAvg() as Lang.Number {
        if (_shots.size() == 0) { return 0; }
        var total = 0;
        for (var i = 0; i < _shots.size(); i++) { total += _shots[i] as Lang.Number; }
        return total / _shots.size();
    }

    private function calcMin() as Lang.Number {
        if (_shots.size() == 0) { return 0; }
        var m = _shots[0] as Lang.Number;
        for (var i = 1; i < _shots.size(); i++) {
            var v = _shots[i] as Lang.Number;
            if (v < m) { m = v; }
        }
        return m;
    }

    private function calcMax() as Lang.Number {
        if (_shots.size() == 0) { return 0; }
        var m = _shots[0] as Lang.Number;
        for (var i = 1; i < _shots.size(); i++) {
            var v = _shots[i] as Lang.Number;
            if (v > m) { m = v; }
        }
        return m;
    }

    function cursorLeft() as Void {
        if (_cursor > 0) { _cursor--; WatchUi.requestUpdate(); }
    }

    function cursorRight() as Void {
        if (_cursor < _shots.size() - 1) { _cursor++; WatchUi.requestUpdate(); }
    }

    // Compute the visible window so cursor is always in view
    private function visibleWindow() as Lang.Array {
        var total = _shots.size();
        var start = _cursor - MAX_VISIBLE / 2;
        if (start < 0) { start = 0; }
        var end = start + MAX_VISIBLE;
        if (end > total) {
            end = total;
            start = end - MAX_VISIBLE;
            if (start < 0) { start = 0; }
        }
        return [start, end] as Lang.Array;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w    = dc.getWidth();
        var h    = dc.getHeight();
        var cx   = w / 2;
        var unit = ShotHistory.isMetric() ? "m" : "yd";

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Header
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 28, Graphics.FONT_SMALL,
            fullClubName(_club), Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 55, Graphics.FONT_XTINY,
            "Avg " + _avg.toString() + unit,
            Graphics.TEXT_JUSTIFY_CENTER);

        if (_shots.size() == 0) {
            dc.drawText(cx, h / 2, Graphics.FONT_SMALL,
                "No shots", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        // Graph area
        var graphX = 20;
        var graphY = 75;
        var graphW = w - 36;
        var graphH = h - 155;

        // Y range
        var yMin   = _min - 10;
        var yMax   = _max + 10;
        if (yMin < 0) { yMin = 0; }
        var yRange = yMax - yMin;
        if (yRange == 0) { yRange = 1; }

        // Average line
        var avgY = graphY + graphH - (((_avg - yMin).toFloat() / yRange) * graphH).toNumber();
        dc.setColor(0x005500, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(graphX, avgY, graphX + graphW, avgY);

        // Visible window
        var window   = visibleWindow();
        var visStart = window[0] as Lang.Number;
        var visEnd   = window[1] as Lang.Number;
        var visCount = visEnd - visStart;
        if (visCount < 1) { visCount = 1; }
        var slotW = graphW / visCount;

        // Connecting lines first (drawn under dots)
        for (var i = visStart; i < visEnd - 1; i++) {
            var d1 = _shots[i]     as Lang.Number;
            var d2 = _shots[i + 1] as Lang.Number;
            var x1 = graphX + (i     - visStart) * slotW + slotW / 2;
            var x2 = graphX + (i + 1 - visStart) * slotW + slotW / 2;
            var y1 = graphY + graphH - (((d1 - yMin).toFloat() / yRange) * graphH).toNumber();
            var y2 = graphY + graphH - (((d2 - yMin).toFloat() / yRange) * graphH).toNumber();
            dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(x1, y1, x2, y2);
        }

        // Dots
        for (var i = visStart; i < visEnd; i++) {
            var dist = _shots[i] as Lang.Number;
            var dotX = graphX + (i - visStart) * slotW + slotW / 2;
            var dotY = graphY + graphH - (((dist - yMin).toFloat() / yRange) * graphH).toNumber();

            if (i == _cursor) {
                // Selected: large green filled dot with white ring
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dotX, dotY, 9);
                dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dotX, dotY, 7);
                // Vertical marker line
                dc.setColor(0x004400, Graphics.COLOR_TRANSPARENT);
                dc.drawLine(dotX, graphY, dotX, graphY + graphH);
                dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(dotX, dotY, 7);
            } else {
                // Unselected: smaller, color by above/below avg
                if (dist >= _avg) {
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                } else {
                    dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                }
                dc.fillCircle(dotX, dotY, 4);
            }
        }

        // Y axis labels
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(graphX + 4, graphY - 2, Graphics.FONT_XTINY,
            yMax.toString(), Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(graphX + 4, graphY + graphH - 14, Graphics.FONT_XTINY,
            yMin.toString(), Graphics.TEXT_JUSTIFY_LEFT);

        // Selected shot distance — large, centred below graph
        var selDist = _shots[_cursor] as Lang.Number;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, graphY + graphH + 2, Graphics.FONT_MEDIUM,
            selDist.toString() + unit, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, graphY + graphH + 35, Graphics.FONT_XTINY,
            "shot " + (_cursor + 1).toString() + " of " + _shots.size().toString(),
            Graphics.TEXT_JUSTIFY_CENTER);

        // Scroll hints
        if (_cursor > 0) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(graphX - 8, graphY + graphH / 2 - 8, Graphics.FONT_XTINY,
                "<", Graphics.TEXT_JUSTIFY_RIGHT);
        }
        if (_cursor < _shots.size() - 1) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(graphX + graphW + 8, graphY + graphH / 2 - 8, Graphics.FONT_XTINY,
                ">", Graphics.TEXT_JUSTIFY_LEFT);
        }
    }
}

class ClubGraphDelegate extends WatchUi.BehaviorDelegate {

    private var _view as ClubGraphView;

    function initialize(view as ClubGraphView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onPreviousPage() as Lang.Boolean {
        _view.cursorLeft();
        return true;
    }

    function onNextPage() as Lang.Boolean {
        _view.cursorRight();
        return true;
    }

    function onBack() as Lang.Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}