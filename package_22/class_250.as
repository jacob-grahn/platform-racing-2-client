// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_22.class_250

package package_22
{
    import page.Page;
    import ui.PageNavigation;
    import flash.events.Event;

    public class class_250 extends Page 
    {

        private var pageNavigation:PageNavigation;
        private var var_167:int = 0;
        private var loadingGraphic:LoadingGraphic;
        private var superLoader:SuperLoader;

        public function class_250(dataMode:String="json")
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
            this.superLoader.addEventListener(SuperLoader.d, this.method_352);
        }

        private function method_551()
        {
            this.loadingGraphic.visible = true;
        }

        private function method_352(_arg_1:Event)
        {
            this.displayData(this.superLoader.parsedData);
        }

        protected function displayData(_arg_1:Object)
        {
            this.clear();
        }

        protected function clear()
        {
        }

        public function setPageNum(_arg_1:int)
        {
            this.var_167 = _arg_1;
            this.method_551();
        }

        override public function remove()
        {
            this.clear();
            this.pageNavigation.remove();
            this.pageNavigation = null;
            this.loadingGraphic = null;
            this.superLoader.remove();
            this.superLoader.removeEventListener(SuperLoader.d, this.method_352);
            this.superLoader = null;
            super.remove();
        }


    }
}//package package_22

