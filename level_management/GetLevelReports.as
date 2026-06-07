package level_management
{
    import com.jiggmin.data.Data;
    import flash.events.Event;
    import flash.net.URLRequest;
    import flash.net.URLVariables;
    import levelEditor.GetReportedLevelsPopupItem;
    import package_4.ConfirmPopup;
    import package_4.GetLevelsPopup;
    import ui.class_229;
    import levelEditor.LevelEditorMenu;
    import package_4.MessagePopup;

    public class GetLevelReports extends GetLevels
    {

        public function GetLevelReports()
        {
            super('/levels_get_reported.php');
            m.titleBox.text = '-- Reported Levels --';
            m.delete_bt.label = 'Handle';
        }

        // _loc3 = item
        override protected function onComplete(e:Event)
        {
            if (e.target.data != "") {
                var levels:Object = this.loader.parsedData.levels;
                for each (var level:Object in levels) {
                    var item:GetReportedLevelsPopupItem = new GetReportedLevelsPopupItem(level);
                    this.addListing(item);
                }
            }
            this.hideLoadingGraphic();
        }

        // _loc2 = item
        override protected function loadListing(listing:class_229)
        {
            var item:GetReportedLevelsPopupItem = GetReportedLevelsPopupItem(listing);
            new LoadingLevelPopup(item.level.level_id, item.level.version, true);
            startFadeOut();
        }

        // _loc2 = item
        // level report handling function
        override protected function deleteListing(listing:class_229)
        {
            new HandleLevelReportPopup(this, listing.level);
        }

        override public function remove()
        {
            this.loader.removeEventListener(Event.COMPLETE, this.onComplete);
            this.loader.remove();
            super.remove();
        }


    }
}
