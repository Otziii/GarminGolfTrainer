import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class GarminGolfTrainerApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        return [new HomeMenuView(), new HomeMenuDelegate()];
    }
}

function getApp() as GarminGolfTrainerApp {
    return Application.getApp() as GarminGolfTrainerApp;
}
