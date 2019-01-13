// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// KongOutfitPopupGraphic = class_258

package 
{
    import flash.display.MovieClip;
    import fl.controls.Button;
    import fl.controls.TextArea;

    public dynamic class KongOutfitPopupGraphic extends MovieClip 
    {

        public var c:MovieClip;
        public var main:ConfirmPopupGraphic;

        public function KongOutfitPopupGraphic()
        {
            addFrameScript(0, this.frame1);
        }

        private function frame1()
        {
            this.c.head.gotoAndStop(20);
            this.c.head.colorMC.gotoAndStop(20);
            this.c.head.colorMC2.gotoAndStop(20);
            this.c.body.gotoAndStop(17);
            this.c.body.colorMC.gotoAndStop(17);
            this.c.body.colorMC2.gotoAndStop(17);
            this.c.foot1.gotoAndStop(16);
            this.c.foot1.colorMC.gotoAndStop(16);
            this.c.foot1.colorMC2.gotoAndStop(16);
            this.c.foot2.gotoAndStop(16);
            this.c.foot2.colorMC.gotoAndStop(16);
            this.c.foot2.colorMC2.gotoAndStop(16);
            this.c.weapon.gotoAndStop("None");
            this.c.head.hat1.gotoAndStop(1);
            this.c.head.hat2.gotoAndStop(1);
            this.c.head.hat3.gotoAndStop(1);
            this.c.head.hat4.gotoAndStop(1);
            this.c.head.hat1.colorMC.gotoAndStop(1);
            this.c.head.hat2.colorMC.gotoAndStop(1);
            this.c.head.hat3.colorMC.gotoAndStop(1);
            this.c.head.hat4.colorMC.gotoAndStop(1);
            this.c.head.hat1.colorMC2.gotoAndStop(1);
            this.c.head.hat2.colorMC2.gotoAndStop(1);
            this.c.head.hat3.colorMC2.gotoAndStop(1);
            this.c.head.hat4.colorMC2.gotoAndStop(1);
        }

    }
}
