import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

class DistancePickerView extends WatchUi.View {

    // Public so delegate can mutate it on button presses
    var distance as Lang.Number;
    private var _club as Lang.String;

    function initialize(shotData as Lang.Dictionary, defaultDistance as Lang.Number) {
        View.initialize();
        distance = defaultDistance;
        _club = shotData.get("club") as Lang.String;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w  = dc.getWidth();
        var h  = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Club name
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - (h * 0.35).toNumber(), Graphics.FONT_MEDIUM,
            fullClubName(_club), Graphics.TEXT_JUSTIFY_CENTER);

        // Distance number
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - (h * 0.15).toNumber(), Graphics.FONT_NUMBER_HOT,
            distance.toString(), Graphics.TEXT_JUSTIFY_CENTER);

        // Unit
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + (h * 0.15).toNumber(), Graphics.FONT_SMALL,
            ShotHistory.getUnitText(), Graphics.TEXT_JUSTIFY_CENTER);

        // Hints
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - (h * 0.45).toNumber(), Graphics.FONT_XTINY,
            "UP +1  |  DOWN -1", Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class DistancePickerDelegate extends WatchUi.BehaviorDelegate {

    private var _view     as DistancePickerView;
    private var _shotData as Lang.Dictionary;

    function initialize(shotData as Lang.Dictionary, view as DistancePickerView) {
        BehaviorDelegate.initialize();
        _shotData = shotData;
        _view     = view;
    }

    function onPreviousPage() as Lang.Boolean {
        _view.distance += 1;
        if (_view.distance > 400) { _view.distance = 400; }
        WatchUi.requestUpdate();
        return true;
    }

    function onNextPage() as Lang.Boolean {
        _view.distance -= 1;
        if (_view.distance < 5) { _view.distance = 5; }
        WatchUi.requestUpdate();
        return true;
    }

    function onSelect() as Lang.Boolean {
        _shotData["distance"] = _view.distance;

        // Every shot is classified before it is stored, so quality data is
        // available for both ad-hoc logging and driving-range summaries.
        // Three views to unwind afterwards: quality, this picker, club menu.
        WatchUi.pushView(
            new ShotQualityMenu(),
            new ShotQualityDelegate(_shotData, 3),
            WatchUi.SLIDE_UP
        );
        return true;
    }

    function onBack() as Lang.Boolean {
        if (_shotData.hasKey("rangeShot")) {
            getApp().cancelRangeShotPrompt();
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // distance picker
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // club menu
            return true;
        }
        return false;
    }
}
