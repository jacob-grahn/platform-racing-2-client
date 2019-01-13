// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// menu.IntroPage = menu.class_6

package menu
{
    import page.Page;
    import flash.display.MovieClip;
    import flash.events.MouseEvent;
    import flash.media.SoundTransform;
    import pixelEffects.class_21;
    import flash.events.Event;

    public class IntroPage extends Page 
    {

        private static const jiggIntro:int = 1; // const_21
        private static const armorIntro:int = 2; // const_66
        private static const bubBoxIntro:int = 3; // const_74
        private static const kongIntro:int = 4; // const_65

        private var toPlay:Array = new Array(); // var_257
        private var m:IntroPageGraphic;
        private var currentIntro:MovieClip; // var_55
        private var mute:SoundTransform = new SoundTransform();

        public function IntroPage()
        {
            this.m = new IntroPageGraphic();
            addChild(this.m);
            this.mute.volume = 0;
            if (Main.siteMode == "inXile") {
                this.toPlay = [jiggIntro];
            } else if (Main.siteMode == "bubbleBox") {
                this.toPlay = [jiggIntro, bubBoxIntro];
            } else if (Main.siteMode == "kongregate") {
                this.toPlay = [jiggIntro, kongIntro];
            } else if (Main.siteMode == "armorGames") {
                this.toPlay = [jiggIntro, armorIntro];
            }
            Main.stage.addEventListener(MouseEvent.CLICK, this.onClick, false, 0, true);
            this.method_302();
        }

        private function onClick(_arg_1:MouseEvent)
        {
            this.endIntro();
        }

        // _loc1 = type
        private function method_302()
        {
            var _local_2:class_21;
            this.method_322();
            if (this.toPlay.length <= 0) {
                this.endIntro();
            } else {
                var type:int = this.toPlay.shift();
                if (type == jiggIntro) {
                    this.currentIntro = new JiggminIntroGraphic();
                    _local_2 = new class_21(new JiggminLogo(300, 87));
                    this.currentIntro.logo.logo_mc.addChild(_local_2);
                } else if (type == armorIntro) {
                    this.currentIntro = new ArmorIntroGraphic();
                } else if (type == bubBoxIntro) {
                    this.currentIntro = new BubbleBoxIntroGraphic();
                } else if (type == kongIntro) {
                    this.currentIntro = new KongregateIntroGraphic();
                }
                this.currentIntro.addEventListener(Event.COMPLETE, this.onComplete, false, 0, true);
                this.m.var_526.addChild(this.currentIntro);
            }
        }

        private function method_322()
        {
            if (this.currentIntro != null) {
                this.currentIntro.stop();
                this.currentIntro.soundTransform = this.mute;
                this.currentIntro.removeEventListener(Event.COMPLETE, this.onComplete);
                this.m.var_526.removeChild(this.currentIntro);
                this.currentIntro = null;
            }
        }

        private function onComplete(_arg_1:Event)
        {
            this.method_302();
        }

        private function endIntro()
        {
            this.method_322();
            Main.pageHolder.changePage(new LoginPage());
        }

        override public function remove()
        {
            Main.stage.removeEventListener(MouseEvent.CLICK, this.onClick);
            this.method_322();
            this.m = null;
            this.currentIntro = null;
            super.remove();
        }


    }
}
