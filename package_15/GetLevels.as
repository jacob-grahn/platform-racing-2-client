// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_15.GetLevels

package package_15
{
    import flash.events.Event;
    import flash.net.URLRequest;
    import flash.net.URLVariables;
    import levelEditor.GetLevelsPopupItem;
    import package_4.ConfirmPopup;
    import package_4.GetLevelsPopup;
    import ui.class_229;

    public class GetLevels extends GetLevelsPopup
    {

        private var loader:SuperLoader = new SuperLoader(true, SuperLoader.j);

        // _loc1 = request
        public function GetLevels()
        {
            this.var_454 = 18;
            var request:URLRequest = new URLRequest(Main.baseURL + "/get_levels.php");
            this.loader.addEventListener(Event.COMPLETE, this.onComplete);
            this.loader.load(request);
        }

        // _loc3 = item
        private function onComplete(e:Event)
        {
            if (e.target.data != "") {
                var levels:Object = this.loader.parsedData.levels;
                var level:Object;
                for each (level in levels) {
                    var item:GetLevelsPopupItem = new GetLevelsPopupItem(level.level_id, level.version, level.title, level.live);
                    this.method_455(item);
                }
            }
            this.hideLoadingGraphic();
        }

        // _loc2 = item
        override protected function loadListing(_arg_1:class_229)
        {
            var item:GetLevelsPopupItem = GetLevelsPopupItem(_arg_1);
            new LoadingLevelPopup(item.id, item.version);
            startFadeOut();
        }

        // _loc2 = item
        override protected function deleteListing(_arg_1:class_229)
        {
            var item:GetLevelsPopupItem = GetLevelsPopupItem(_arg_1);
            new ConfirmPopup(this.method_73, "Are you sure you want to delete \"" + item.title + "\"?");
        }

        // _loc1 = item
        public function method_73()
        {
            var item:GetLevelsPopupItem = GetLevelsPopupItem(this.method_321());
            new DeletingLevelPopup(item.id);
            startFadeOut();
        }

        override public function remove()
        {
            this.loader.removeEventListener(Event.COMPLETE, this.onComplete);
            this.loader.remove();
            super.remove();
        }


    }
}
