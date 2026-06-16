//gameplay.CatCaptcha = gameplay.class_34

package gameplay
{
    import dialogs.Popup;
    import flash.net.URLRequest;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.net.URLVariables;

    public class CatCaptcha extends Popup 
    {

        private var m:CatCaptchaPopupGraphic = new CatCaptchaPopupGraphic();
        private var imgX:int = -215;
        private var imgY:int = -91;
        private var imgSpacing:int = 220;
        private var imgCount:int = 2;
        private var captchaLoader:SuperLoader = new SuperLoader(true, SuperLoader.j);
        private var submitLoader:SuperLoader = new SuperLoader(true, SuperLoader.j);

        public function CatCaptcha()
        {
            addChild(this.m);
            this.captchaLoader.addEventListener(SuperLoader.d, this.onCaptchaLoad, false, 0, true);
            this.captchaLoader.addEventListener(SuperLoader.e, this.onError, false, 0, true);
            this.submitLoader.addEventListener(SuperLoader.d, this.onSubmitComplete, false, 0, true);
            this.submitLoader.addEventListener(SuperLoader.e, this.onError, false, 0, true);
            this.loadCaptcha();
        }

        private function loadCaptcha()
        {
            this.captchaLoader.load(new URLRequest(Main.baseURL + "/cat/cat-captcha.php"));
        }

        private function onCaptchaLoad(_arg_1:Event)
        {
            this.showCatImages();
        }

        // _loc1 = i
        // _loc2 = img
        private function showCatImages()
        {
            var i:int = 0;
            while (i < this.imgCount) {
                var img:CatImage = new CatImage(i);
                img.addEventListener(MouseEvent.CLICK, this.clickHandler, false, 0, true);
                this.m.addChild(img);
                img.x = this.imgX + (this.imgSpacing * i);
                img.y = this.imgY;
                i++;
            }
        }

        // _loc2 = img
        private function clickHandler(e:MouseEvent)
        {
            if (!fadeOutStarted && (e.currentTarget is CatImage)) {
                var img:CatImage = CatImage(e.currentTarget);
                this.submit(img.getId());
            }
        }

        private function submit(_arg_1:int)
        {
            var _local_2:URLVariables = new URLVariables();
            _local_2.answer = _arg_1;
            var _local_3:URLRequest = new URLRequest(Main.baseURL + "/cat/captcha-submit.php");
            _local_3.data = _local_2;
            this.submitLoader.load(_local_3);
            startFadeOut();
        }

        private function onSubmitComplete(_arg_1:Event)
        {
            startFadeOut();
        }

        private function onError(_arg_1:Event)
        {
            startFadeOut();
        }

        override public function remove()
        {
            this.captchaLoader.removeEventListener(SuperLoader.e, this.onError);
            this.captchaLoader.removeEventListener(SuperLoader.d, this.onCaptchaLoad);
            this.captchaLoader.remove();
            this.captchaLoader = null;
            this.submitLoader.removeEventListener(SuperLoader.e, this.onError);
            this.submitLoader.removeEventListener(SuperLoader.d, this.onSubmitComplete);
            this.submitLoader.remove();
            this.submitLoader = null;
            removeChild(this.m);
            this.m = null;
            super.remove();
        }


    }
}//package gameplay

