import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

// Fast, descriptive tags keep the post-shot interaction useful without
// requiring a numeric rating or launch-monitor data.
class ShotQualityMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({ :title => "Shot Result" });
        // Ids are Strings, not Symbols: shots are persisted through
        // Application.Storage, whose ValueType does not include Lang.Symbol.
        addItem(new WatchUi.MenuItem("Solid", null, "solid", {}));
        addItem(new WatchUi.MenuItem("Slice", null, "slice", {}));
        addItem(new WatchUi.MenuItem("Pull",  null, "pull",  {}));
        addItem(new WatchUi.MenuItem("Duff",  null, "duff",  {}));
        addItem(new WatchUi.MenuItem("Thin",  null, "thin",  {}));
        addItem(new WatchUi.MenuItem("Shank", null, "shank", {}));
    }
}

class ShotQualityDelegate extends WatchUi.Menu2InputDelegate {
    private var _shotData as Lang.Dictionary;
    private var _viewsToPop as Lang.Number;

    // viewsToPop is however many views the wizard pushed, which varies: the
    // distance step is optional, so the caller reports its own depth.
    function initialize(shotData as Lang.Dictionary, viewsToPop as Lang.Number) {
        Menu2InputDelegate.initialize();
        _shotData = shotData;
        _viewsToPop = viewsToPop;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        _shotData["quality"] = item.getId() as Lang.String;
        // Set here rather than in the distance picker, which is skippable.
        _shotData["timestamp"] = Time.now().value();
        ShotHistory.addShot(_shotData);

        if (_shotData.hasKey("rangeShot")) {
            getApp().completeRangeShot(_shotData);
        }

        // Return to the screen that initiated the shot. A range shot resumes
        // detection immediately; an ad-hoc shot returns to the home menu.
        for (var i = 0; i < _viewsToPop; i++) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        }
    }
}
