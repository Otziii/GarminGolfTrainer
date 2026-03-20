import Toybox.Lang;
import Toybox.WatchUi;

class SettingsMenuView extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize({ :title => "Settings" });
        var unitsLabel = ShotHistory.isMetric() ? "Units: Metric" : "Units: Imperial";
        addItem(new WatchUi.MenuItem(unitsLabel,    null, :toggleUnits, {}));
        addItem(new WatchUi.MenuItem("Clear Stats", null, :clearStats,  {}));
    }
}

class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();

        if (id == :toggleUnits) {
            if (ShotHistory.isMetric()) {
                ShotHistory.setUnits("imperial");
            } else {
                ShotHistory.setUnits("metric");
            }
            // Pop and re-push to refresh the label
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            WatchUi.pushView(
                new SettingsMenuView(),
                new SettingsMenuDelegate(),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (id == :clearStats) {
            ShotHistory.clearAll();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }
}