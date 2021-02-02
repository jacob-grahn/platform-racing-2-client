// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// menu.IntroPage = menu.class_6

package menu
{
    import com.jiggmin.pixelEffects.PixelEffect1;
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.media.SoundTransform;
    import page.Page;

    public class IntroPage extends Page 
    {

        private static const JIGG_INTRO:int = 1; // const_21
        private static const ARMOR_INTRO:int = 2; // const_66
        private static const BUBBOX_INTRO:int = 3; // const_74
        private static const KONG_INTRO:int = 4; // const_65

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
                this.toPlay = [JIGG_INTRO];
            } else if (Main.siteMode == "bubbleBox") {
                this.toPlay = [JIGG_INTRO, BUBBOX_INTRO];
            } else if (Main.siteMode == "kongregate") {
                this.toPlay = [JIGG_INTRO, KONG_INTRO];
            } else if (Main.siteMode == "armorGames") {
                this.toPlay = [JIGG_INTRO, ARMOR_INTRO];
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
            this.method_322();
            if (this.toPlay.length <= 0) {
                this.endIntro();
            } else {
                var type:int = this.toPlay.shift();
                if (type == JIGG_INTRO) {
                    this.currentIntro = new JiggminIntroGraphic();
                    var _local_2:PixelEffect1 = new PixelEffect1(new JiggminLogo(300, 87));
                    this.currentIntro.logo.logo_mc.addChild(_local_2);
                } else if (type == ARMOR_INTRO) {
                    this.currentIntro = new ArmorIntroGraphic();
                } else if (type == BUBBOX_INTRO) {
                    this.currentIntro = new BubbleBoxIntroGraphic();
                } else if (type == KONG_INTRO) {
                    this.currentIntro = new KongregateIntroGraphic();
                }
                this.currentIntro.addEventListener(Event.COMPLETE, this.onComplete, false, 0, true);
                this.m.introHolder.addChild(this.currentIntro);
            }
        }

        private function method_322()
        {
            if (this.currentIntro != null) {
                this.currentIntro.stop();
                this.currentIntro.soundTransform = this.mute;
                this.currentIntro.removeEventListener(Event.COMPLETE, this.onComplete);
                this.m.introHolder.removeChild(this.currentIntro);
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
