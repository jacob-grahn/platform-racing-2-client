// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// gameplay.CatImage

package gameplay
{
    import com.jiggmin.data.Data;
    import flash.display.Loader;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.net.URLRequest;
    import flash.net.URLVariables;

    public class CatImage extends Sprite 
    {

        private var bg:BlueSquareButton = new BlueSquareButton();
        private var img:Loader = new Loader();
        private var id:int;

        public function CatImage(n:int)
        {
            this.id = n;
            addChild(this.bg);
            addChild(this.img);
            this.getImg();
        }

        // method_140 = getId
        public function getId():int
        {
            return this.id;
        }

        // _loc2 = vars
        // _loc3 = request
        // method_602 = getImg
        private function getImg()
        {
            var vars:URLVariables = new URLVariables();
            vars.img = this.id;
            var request:URLRequest = new URLRequest(Main.baseURL + "/cat/cat-img.php");
            request.data = vars;
            this.img.contentLoaderInfo.addEventListener(Event.COMPLETE, this.onImgLoad, false, 0, true);
            this.img.load(request);
        }

        // depreciated; using onImgLoad
        /*private function method_281(_arg_1:Event)
        {
            this.onImgLoad();
        }*/

        private function onImgLoad(e:* = null)
        {
            Data.method_314(this.img, 200, 200);
            this.img.x = Math.round((200 - this.img.width) / 2) + 5;
            this.img.y = Math.round((200 - this.img.height) / 2) + 5;
            this.img.mouseEnabled = this.img.mouseChildren = false;
        }

        public function remove()
        {
            this.img.removeEventListener(Event.COMPLETE, this.onImgLoad);
            if (parent != null) {
                parent.removeChild(this);
            }
        }


    }
}
