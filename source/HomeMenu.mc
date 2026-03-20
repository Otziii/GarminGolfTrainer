import Toybox.Lang;
import Toybox.WatchUi;

class HomeMenuView extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize({ :title => "Golf Trainer" });
        addItem(new WatchUi.MenuItem("Log Shot",  null, :logShot,  {}));
        addItem(new WatchUi.MenuItem("History",   null, :history,  {}));
        addItem(new WatchUi.MenuItem("Settings",  null, :settings, {}));
    }
}

class HomeMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();

        if (id == :logShot) {
            WatchUi.pushView(
                new ClubMenu(),
                new ClubDelegate({} as Lang.Dictionary),
                WatchUi.SLIDE_LEFT
            );
        } else if (id == :history) {
            var view = new StatsView();
            WatchUi.pushView(
                view,
                new StatsDelegate(view),
                WatchUi.SLIDE_LEFT
            );
        } else if (id == :settings) {
            WatchUi.pushView(
                new SettingsMenuView(),
                new SettingsMenuDelegate(),
                WatchUi.SLIDE_LEFT
            );
        }
    }
}