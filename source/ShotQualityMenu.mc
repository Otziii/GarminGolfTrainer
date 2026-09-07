import Toybox.Lang;
import Toybox.WatchUi;

// Fast, descriptive tags keep the post-shot interaction useful without
// requiring a numeric rating or launch-monitor data.
class ShotQualityMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({ :title => "Shot Result" });
        addItem(new WatchUi.MenuItem("Solid", null, :solid, {}));
        addItem(new WatchUi.MenuItem("Slice", null, :slice, {}));
        addItem(new WatchUi.MenuItem("Pull",  null, :pull,  {}));
        addItem(new WatchUi.MenuItem("Duff",  null, :duff,  {}));
        addItem(new WatchUi.MenuItem("Thin",  null, :thin,  {}));
        addItem(new WatchUi.MenuItem("Shank", null, :shank, {}));
    }
}

class ShotQualityDelegate extends WatchUi.Menu2InputDelegate {
    private var _shotData as Lang.Dictionary;

    function initialize(shotData as Lang.Dictionary) {
        Menu2InputDelegate.initialize();
        _shotData = shotData;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        _shotData["quality"] = item.getId() as Lang.Symbol;
        ShotHistory.addShot(_shotData);

        if (_shotData.hasKey("rangeShot")) {
            getApp().completeRangeShot(_shotData);
        }

        // Return to the screen that initiated the shot. A range shot resumes
        // detection immediately; an ad-hoc shot returns to the home menu.
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // quality menu
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // distance picker
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // club menu
    }
}
