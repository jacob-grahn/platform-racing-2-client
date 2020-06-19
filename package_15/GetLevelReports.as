package package_15
{
    import data.class_28;
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
                    this.method_455(item);
                }
            }
            this.hideLoadingGraphic();
        }

        // _loc2 = item
        override protected function loadListing(_arg_1:class_229)
        {
            var item:GetReportedLevelsPopupItem = GetReportedLevelsPopupItem(_arg_1);
            new LoadingLevelPopup(item.level.level_id, item.level.version, true);
            startFadeOut();
        }

        // _loc2 = item
        // CHANGE CONTENTS OF THIS FN TO DO REPORT HANDLING (popup?)
        override protected function deleteListing(_arg_1:class_229)
        {
            var item:GetReportedLevelsPopupItem = GetReportedLevelsPopupItem(_arg_1);
            new MessagePopup('Coming soon!');
            //new ConfirmPopup(this.confirmDelete, "Are you sure you want to delete \"" + class_28.escapeString(item.level.title) + "\"?");
        }

        // _loc1 = item
        // method_73 = confirmDelete
        /*override public function confirmDelete()
        {
            var item:GetReportedLevelsPopupItem = GetReportedLevelsPopupItem(this.getSelected());
            new MessagePopup('Placeholder!');
            startFadeOut();
        }*/

        override public function remove()
        {
            this.loader.removeEventListener(Event.COMPLETE, this.onComplete);
            this.loader.remove();
            super.remove();
        }


    }
}
