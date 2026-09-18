import Toybox.Lang;
import Toybox.WatchUi;

// Labels live outside the view so the delegate can rewrite them in place after
// a toggle. Rebuilding the menu instead would reset focus to the first item.
function unitsLabel() as Lang.String {
    return ShotHistory.isMetric() ? "Units: Metric" : "Units: Imperial";
}

function logShotsLabel() as Lang.String {
    return ShotHistory.shouldLogShots() ? "Log Shots: On" : "Log Shots: Off";
}

function shotLengthLabel() as Lang.String {
    return ShotHistory.shouldLogDistance() ? "Shot Length: On" : "Shot Length: Off";
}

class SettingsMenuView extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize({ :title => "Settings" });
        addItem(new WatchUi.MenuItem(unitsLabel(),      null, :toggleUnits,    {}));
        addItem(new WatchUi.MenuItem(logShotsLabel(),   null, :toggleLogShots, {}));
        addItem(new WatchUi.MenuItem(shotLengthLabel(), null, :toggleLogDist,  {}));
        addItem(new WatchUi.MenuItem("Clear Stats",     null, :clearStats,     {}));
    }
}

class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();

        if (id == :toggleUnits) {
            ShotHistory.setUnits(ShotHistory.isMetric() ? "imperial" : "metric");
            item.setLabel(unitsLabel());
        } else if (id == :toggleLogShots) {
            ShotHistory.setLogShots(!ShotHistory.shouldLogShots());
            item.setLabel(logShotsLabel());
        } else if (id == :toggleLogDist) {
            ShotHistory.setLogDistance(!ShotHistory.shouldLogDistance());
            item.setLabel(shotLengthLabel());
        } else if (id == :clearStats) {
            ShotHistory.clearAll();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            return;
        }

        WatchUi.requestUpdate();
    }
}
