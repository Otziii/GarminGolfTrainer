import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

// ── Step 2: Distance Picker ───────────────────────────────────────────────────
// UP   → +5 meters
// DOWN → -5 meters
// SELECT → save shot and return to home

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
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - (h * 0.35).toNumber(), Graphics.FONT_SMALL,
            _club, Graphics.TEXT_JUSTIFY_CENTER);

        // Distance number
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - (h * 0.15).toNumber(), Graphics.FONT_NUMBER_HOT,
            distance.toString(), Graphics.TEXT_JUSTIFY_CENTER);

        // Unit
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + (h * 0.15).toNumber(), Graphics.FONT_SMALL,
            "meters", Graphics.TEXT_JUSTIFY_CENTER);

        // Hints
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - (h * 0.45).toNumber(), Graphics.FONT_XTINY,
            "UP +5  |  DOWN -5", Graphics.TEXT_JUSTIFY_CENTER);
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
        _view.distance += 5;
        if (_view.distance > 400) { _view.distance = 400; }
        WatchUi.requestUpdate();
        return true;
    }

    function onNextPage() as Lang.Boolean {
        _view.distance -= 5;
        if (_view.distance < 5) { _view.distance = 5; }
        WatchUi.requestUpdate();
        return true;
    }

    function onSelect() as Lang.Boolean {
        _shotData["distance"]  = _view.distance;
        _shotData["timestamp"] = Time.now().value();

        ShotHistory.addShot(_shotData);

        // Don't pop — confirmation sits on top, dismisses back here
        WatchUi.pushView(
            new ConfirmationView(
                _shotData["club"] as Lang.String,
                _view.distance
            ),
            new ConfirmationDelegate(),
            WatchUi.SLIDE_UP
        );
        return true;
    }
}