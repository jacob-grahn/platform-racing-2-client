// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_6.CatCaptcha = package_6.class_34

package package_6
{
    import dialogs.Popup;
    import flash.net.URLRequest;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.net.URLVariables;

    public class CatCaptcha extends Popup 
    {

        private var m:CatCaptchaPopupGraphic = new CatCaptchaPopupGraphic();
        private var var_567:int = -215;
        private var var_608:int = -91;
        private var var_639:int = 220;
        private var var_629:int = 2;
        private var var_181:SuperLoader = new SuperLoader(true, SuperLoader.j);
        private var var_191:SuperLoader = new SuperLoader(true, SuperLoader.j);

        public function CatCaptcha()
        {
            addChild(this.m);
            this.var_181.addEventListener(SuperLoader.d, this.method_441, false, 0, true);
            this.var_181.addEventListener(SuperLoader.e, this.method_99, false, 0, true);
            this.var_191.addEventListener(SuperLoader.d, this.method_465, false, 0, true);
            this.var_191.addEventListener(SuperLoader.e, this.method_99, false, 0, true);
            this.method_694();
        }

        private function method_694()
        {
            this.var_181.load(new URLRequest(Main.baseURL + "/cat/cat-captcha.php"));
        }

        private function method_441(_arg_1:Event)
        {
            this.method_561();
        }

        // _loc1 = i
        // _loc2 = img
        private function method_561()
        {
            var i:int = 0;
            while (i < this.var_629) {
                var img:class_101 = new class_101(i);
                img.addEventListener(MouseEvent.CLICK, this.clickHandler, false, 0, true);
                this.m.addChild(img);
                img.x = this.var_567 + (this.var_639 * i);
                img.y = this.var_608;
                i++;
            }
        }

        // _loc2 = img
        private function clickHandler(e:MouseEvent)
        {
            if (!fadeOutStarted && (e.currentTarget is class_101)) {
                var img:class_101 = class_101(e.currentTarget);
                this.submit(img.getId());
            }
        }

        private function submit(_arg_1:int)
        {
            var _local_2:URLVariables = new URLVariables();
            _local_2.answer = _arg_1;
            var _local_3:URLRequest = new URLRequest(Main.baseURL + "/cat/captcha-submit.php");
            _local_3.data = _local_2;
            this.var_191.load(_local_3);
            startFadeOut();
        }

        private function method_465(_arg_1:Event)
        {
            startFadeOut();
        }

        private function method_99(_arg_1:Event)
        {
            startFadeOut();
        }

        override public function remove()
        {
            this.var_181.removeEventListener(SuperLoader.e, this.method_99);
            this.var_181.removeEventListener(SuperLoader.d, this.method_441);
            this.var_181.remove();
            this.var_181 = null;
            this.var_191.removeEventListener(SuperLoader.e, this.method_99);
            this.var_191.removeEventListener(SuperLoader.d, this.method_465);
            this.var_191.remove();
            this.var_191 = null;
            removeChild(this.m);
            this.m = null;
            super.remove();
        }


    }
}//package package_6

