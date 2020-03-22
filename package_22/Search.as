// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_22.Search

package package_22
{
    import data.class_28;
    import data.Memory;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.utils.setTimeout;
    import flash.net.URLVariables;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.utils.clearTimeout;

    public class Search extends LevelListing 
    {

        private var m:SearchGraphic = new SearchGraphic();
        private var memory:Object = Memory.memory;
        private var var_421:uint;

        public function Search(s:String = '', search_mode:String = 'user')
        {
            mode = "search";
            this.m.x = 36;
            this.m.y = 8;
            this.m.search_bt.addEventListener(MouseEvent.CLICK, this.doSearch);
            this.m.searchBox.addEventListener(KeyboardEvent.KEY_DOWN, this.doSearch);
            class_10.addChild(this.m);
            loadingGraphic.visible = false;
            if (this.memory.searchStr != null) {
                this.m.searchBox.text = this.memory.searchStr;
                this.m.mode_cb.selectedIndex = this.memory.searchModeIndex;
                this.m.order_cb.selectedIndex = this.memory.searchOrderIndex;
                this.m.dir_cb.selectedIndex = this.memory.searchDirIndex;
                if (this.memory.searchStr != "") {
                    this.var_421 = setTimeout(this.requestCourses, 10);
                }
            }
            if (s != "") {
                this.m.searchBox.text = s;
                this.setSearchMode(search_mode);
                this.var_421 = setTimeout(this.requestCourses, 10);
            }
        }

        private function setSearchMode(s:String = 'user')
        {
            var option:int = 0; // user; default
            for (var key:int = 0; key < this.m.mode_cb.dataProvider.length; key++) {
                if (this.m.mode_cb.dataProvider.getItemAt(key).data == s) {
                    option = key;
                    break;
                }
            }
            this.m.mode_cb.selectedIndex = option;
        }

        // _loc1 = vars
        // _loc2 = request
        override protected function requestCourses()
        {
            if (class_28.trimWhitespace(this.m.searchBox.text) == '' || (this.m.mode_cb.selectedItem.data == 'id' && pageNum > 1)) {
                return; // don't send a request with a blank search string, or on a page higher than one while searching by id
            }
            var vars:URLVariables = new URLVariables();
            vars.search_str = this.m.searchBox.text;
            if (this.m.mode_cb.selectedItem != null) {
                vars.mode = this.m.mode_cb.selectedItem.data;
            }
            if (this.m.order_cb.selectedItem != null) {
                vars.order = this.m.order_cb.selectedItem.data;
            }
            if (this.m.dir_cb.selectedItem != null) {
                vars.dir = this.m.dir_cb.selectedItem.data;
            }
            vars.page = pageNum;
            var request:URLRequest = new URLRequest(Main.levelsURL.substr(0, -7) + "/search_levels.php");
            request.method = URLRequestMethod.POST;
            request.data = vars;
            superLoader.load(request);
            loadingGraphic.visible = true;
        }

        override protected function loadHandler(e:Event)
        {
            super.loadHandler(e);
            if (e.target.data == "") { // not needed??
            }
        }

        // clickSearch = doSearch
        private function doSearch(e:Event)
        {
            if (e is KeyboardEvent) {
                if (e.keyCode !== 13) {
                    return;
                } else {
                    Main.stage.focus = Main.stage;
                }
            }
            if (this.m.searchBox.text != "") {
                pageNavigation.setPageNum(1);
            }
        }

        override public function remove()
        {
            this.memory.searchStr = this.m.searchBox.text;
            this.memory.searchModeIndex = this.m.mode_cb.selectedIndex;
            this.memory.searchOrderIndex = this.m.order_cb.selectedIndex;
            this.memory.searchDirIndex = this.m.dir_cb.selectedIndex;
            clearTimeout(this.var_421);
            this.m.search_bt.removeEventListener(MouseEvent.CLICK, this.doSearch);
            this.m.searchBox.removeEventListener(KeyboardEvent.KEY_DOWN, this.doSearch);
            super.remove();
        }


    }
}
