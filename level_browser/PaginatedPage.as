

package level_browser
{
    import page.Page;
    import ui.PageNavigation;
    import flash.events.Event;

    public class PaginatedPage extends Page 
    {

        private var pageNavigation:PageNavigation;
        private var currentPage:int = 0;
        private var loadingGraphic:LoadingGraphic;
        private var superLoader:SuperLoader;

        public function PaginatedPage(dataMode:String="json")
        {
            this.loadingGraphic = new LoadingGraphic();
            this.loadingGraphic.x = 164;
            this.loadingGraphic.y = 150;
            addChild(this.loadingGraphic);
            this.pageNavigation = new PageNavigation(this, "vertical", 1, 9, 283);
            this.pageNavigation.x = 328;
            this.pageNavigation.y = 26;
            addChild(this.pageNavigation);
            Main.socket.write("set_right_room`none");
            this.superLoader = new SuperLoader(true, dataMode);
            this.superLoader.addEventListener(SuperLoader.d, this.onDataLoaded);
        }

        private function showLoading()
        {
            this.loadingGraphic.visible = true;
        }

        private function onDataLoaded(e:Event)
        {
            this.displayData(this.superLoader.parsedData);
        }

        protected function displayData(data:Object)
        {
            this.clear();
        }

        protected function clear()
        {
        }

        public function setPageNum(pageNum:int)
        {
            this.currentPage = pageNum;
            this.showLoading();
        }

        override public function remove()
        {
            this.clear();
            this.pageNavigation.remove();
            this.pageNavigation = null;
            this.loadingGraphic = null;
            this.superLoader.remove();
            this.superLoader.removeEventListener(SuperLoader.d, this.onDataLoaded);
            this.superLoader = null;
            super.remove();
        }


    }
}//package level_browser

