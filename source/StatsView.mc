import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

const CLUB_ORDER = ["Dr", "3W", "Hy", "4i", "5i", "6i",
                    "7i", "8i", "9i", "PW", "GW", "SW", "LW"];

class StatsView extends WatchUi.View {

    private var _rows    as Lang.Array;
    private var _total   as Lang.Number;
    private var _scroll  as Lang.Number;
    private const ROWS_PER_PAGE = 4;

    function initialize() {
        View.initialize();
        _scroll = 0;
        _rows   = buildRows();
        _total  = ShotHistory.getShotCount();
    }

    private function buildRows() as Lang.Array {
        var averages = ShotHistory.getClubAverages();
        var rows = [] as Lang.Array;
        for (var i = 0; i < CLUB_ORDER.size(); i++) {
            var club = CLUB_ORDER[i];
            if (averages.hasKey(club)) {
                var entry = averages[club] as Lang.Dictionary;
                rows.add({
                    "club"        => club,
                    "count"       => entry["count"],
                    "avgDistance" => entry["avgDistance"]
                });
            }
        }
        return rows;
    }

    function scrollUp() as Void {
        if (_scroll > 0) { _scroll--; WatchUi.requestUpdate(); }
    }

    function scrollDown() as Void {
        if (_scroll < _rows.size() - ROWS_PER_PAGE) { _scroll++; WatchUi.requestUpdate(); }
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w  = dc.getWidth();
        var h  = dc.getHeight();
        var cx = w / 2;
        var unit = ShotHistory.isMetric() ? "m" : "yd";

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        if (_total == 0) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h / 2 - 20, Graphics.FONT_SMALL,
                "No shots logged", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(cx, h / 2 + 10, Graphics.FONT_XTINY,
                "yet", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        // Header
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 35, Graphics.FONT_SMALL,
            "History", Graphics.TEXT_JUSTIFY_CENTER);

        // Total
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 80, Graphics.FONT_XTINY,
            "Total: " + _total.toString() + " shots", Graphics.TEXT_JUSTIFY_CENTER);

        // Divider
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(16, 112, w - 16, 112);

        // Rows
        var rowH   = 40;
        var startY = 120;
        var end    = _scroll + ROWS_PER_PAGE;
        if (end > _rows.size()) { end = _rows.size(); }

        for (var i = _scroll; i < end; i++) {
            var row  = _rows[i] as Lang.Dictionary;
            var club = row["club"] as Lang.String;
            var avg  = (row["avgDistance"] as Lang.Number).toString();
            var cnt  = (row["count"] as Lang.Number).toString();
            var y    = startY + (i - _scroll) * rowH;

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(16, y, Graphics.FONT_SMALL,
                club, Graphics.TEXT_JUSTIFY_LEFT);

            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx + 20, y, Graphics.FONT_SMALL,
                avg + unit, Graphics.TEXT_JUSTIFY_LEFT);

            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w - 16, y, Graphics.FONT_XTINY,
                "(" + cnt + ")", Graphics.TEXT_JUSTIFY_RIGHT);
        }
    }
}

class StatsDelegate extends WatchUi.BehaviorDelegate {

    private var _view as StatsView;

    function initialize(view as StatsView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onPreviousPage() as Lang.Boolean {
        _view.scrollUp();
        return true;
    }

    function onNextPage() as Lang.Boolean {
        _view.scrollDown();
        return true;
    }

    function onBack() as Lang.Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}