// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com


package level_management
{
    import com.jiggmin.data.Data;
    import flash.events.Event;
    import flash.net.URLRequest;
    import flash.net.URLVariables;
    import levelEditor.GetLevelsPopupItem;
    import package_4.ConfirmPopup;
    import package_4.GetLevelsPopup;
    import ui.SelectableButton;
    import levelEditor.LevelEditorMenu;
    import flash.net.URLRequestMethod;

    public class GetLevels extends GetLevelsPopup
    {

        protected var dataURL:String = '/levels_get.php';
        protected var loader:SuperLoader = new SuperLoader(true, SuperLoader.j);

        // _loc1 = request
        public function GetLevels(customURL:String = null)
        {
            m.titleBox.text = '-- My Levels --';
            this.dataURL = customURL != null ? customURL : this.dataURL;
            this.itemSpacing = 18;
            var request:URLRequest = new URLRequest(Main.baseURL + this.dataURL);
            request.data = new URLVariables();
            request.method = URLRequestMethod.POST;
            this.loader.addEventListener(Event.COMPLETE, this.onComplete, false, 0, true);
            this.loader.load(request);
        }

        // _loc3 = item
        protected function onComplete(e:Event)
        {
            if (e.target.data != "") {
                var levels:Object = this.loader.parsedData.levels;
                for each (var level:Object in levels) {
                    var item:GetLevelsPopupItem = new GetLevelsPopupItem(level);
                    this.addListing(item);
                }
            }
            this.hideLoadingGraphic();
        }

        // _loc2 = item
        override protected function loadListing(listing:SelectableButton)
        {
            var item:GetLevelsPopupItem = GetLevelsPopupItem(listing);
            new LoadingLevelPopup(item.level.level_id, item.level.version);
            startFadeOut();
        }

        // _loc2 = item
        override protected function deleteListing(listing:SelectableButton)
        {
            var item:GetLevelsPopupItem = GetLevelsPopupItem(listing);
            new ConfirmPopup(this.confirmDelete, "Are you sure you want to delete \"" + Data.escapeString(item.level.title) + "\"?");
        }

        // _loc1 = item
        // method_73 = confirmDelete
        public function confirmDelete()
        {
            var item:GetLevelsPopupItem = GetLevelsPopupItem(this.getSelected());
            new DeletingLevelPopup(item.level.level_id);
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
