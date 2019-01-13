// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_6.class_101

package package_6
{
    import flash.display.Sprite;
    import flash.display.Loader;
    import flash.net.URLVariables;
    import flash.net.URLRequest;
    import flash.events.Event;

    public class class_101 extends Sprite 
    {

        private var bg:BlueSquareButton = new BlueSquareButton();
        private var img:Loader = new Loader();
        private var id:int;

        public function class_101(n:int)
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
            this.img.contentLoaderInfo.addEventListener(Event.COMPLETE, this.method_566, false, 0, true);
            this.img.load(request);
        }

        // depreciated; using method_566
        /*private function method_281(_arg_1:Event)
        {
            this.method_566();
        }*/

        private function method_566(e:* = null)
        {
            class_74.method_314(this.img, 200, 200);
            this.img.x = Math.round((200 - this.img.width) / 2) + 5;
            this.img.y = Math.round((200 - this.img.height) / 2) + 5;
            this.img.mouseEnabled = this.img.mouseChildren = false;
        }

        public function remove()
        {
            this.img.removeEventListener(Event.COMPLETE, this.method_566);
            if (parent != null) {
                parent.removeChild(this);
            }
        }


    }
}
