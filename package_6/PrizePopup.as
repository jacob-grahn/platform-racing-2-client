// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_6.PrizePopup = package_6.class_97

package package_6
{
    import flash.errors.Error;
    import package_4.Popup;
    import flash.display.MovieClip;
    import data.class_153;
    import data.class_28;
    import flash.events.MouseEvent;

    public class PrizePopup extends Popup 
    {
        public static var instance:PrizePopup;

        private var m:PrizePopupGraphic = new PrizePopupGraphic();
        private var target:MovieClip;
        private var var_207:class_153 = new class_153();

        public function PrizePopup(type:String, id:int, prizeName:String, desc:String = "", universal:Boolean = false, finished:Boolean = false)
        {
            if (PrizePopup.instance !== null) {
                PrizePopup.instance.remove();
            }
            super(false);
            this.m.exp.visible = false;
            this.m.hat.visible = false;
            this.m.head.visible = false;
            this.m.body.visible = false;
            this.m.foot.visible = false;
            this.m.flavorBg.visible = false;
            this.m.flavor.visible = false;
            if (desc != "" && type != "exp" && type != 'cancel') {
                this.m.flavorBg.visible = true;
                this.m.flavor.visible = true;
                this.m.flavor.text = desc;
                this.m.flavor.autoSize = "left";
                this.m.flavorBg.height = this.m.flavor.height + 15;
            } else if ((type == "eHat" || type == "eHead" || type == "eBody" || type == "eFeet") && desc == '' && finished == true) {
                this.m.flavorBg.visible = true;
                this.m.flavor.visible = true;
                this.m.flavor.htmlText = 'This is an epic upgrade, not a part. For more information, please see <a href="https://jiggmin2.com/forums/showthread.php?tid=123" target="_blank"><font color="#0000FF">this guide</font></a>.';
                this.m.flavor.autoSize = 'left';
                this.m.flavorBg.height = this.m.flavor.height + 15;
            }
            this.m.head.hat1.visible = false;
            this.m.head.hat2.visible = false;
            this.m.head.hat3.visible = false;
            this.m.head.hat4.visible = false;
            if (type == "hat" || type == "eHat") {
                this.target = this.m.hat;
            }
            if (type == "head" || type == "eHead") {
                this.target = this.m.head;
            }
            if (type == "body" || type == "eBody") {
                this.target = this.m.body;
            }
            if (type == "feet" || type == "eFeet") {
                this.target = this.m.foot;
            }
            if (type == "exp") {
                this.m.titleBox.y = -105;
                this.target = this.m.exp;
                if (desc != '') {
                    this.target.y = -80;
                    this.target.textBox.text = desc;
                } else {
                    this.target.textBox.text = 'You already have this prize, so here are ' + class_28.formatNumber(id) + ' experience points instead!';
                }
            }
            if (type == 'cancel') {
                this.m.bg.y = -120;
                this.m.bg.height = 150;
                this.m.titleBox.y = -105;
                this.m.textBox.visible = false;
                this.m.close_bt.y = -10;
                this.target = this.m.exp;
                this.target.y = -80;
                this.target.textBox.text = desc + ' cancelled the prize for finishing this race.';
            }
            if (type == "eHat" || type == "eHead" || type == "eBody" || type == "eFeet") {
                this.activateEpicAnimation();
            } else if (type != "exp" && type != 'cancel') {
                this.target.colorMC2.visible = type == 'hat' && id == 16; // cheese hat workaround
            }
            this.target.visible = true;
            if (type != "exp" && type != 'cancel') {
                this.target.gotoAndStop(id);
                this.target.colorMC.gotoAndStop(id);
                this.target.colorMC2.gotoAndStop(id);
            }
            var aOrAn:String = class_28.aOrAn(prizeName);
            if (type == "feet") {
                aOrAn = 'a pair of';
            }
            if (finished) {
                this.m.textBox.text = "You won " + aOrAn + ":";
            } else {
                if (universal) {
                    this.m.textBox.text = "Anyone who finishes this race wins " + aOrAn + ":";
                } else {
                    this.m.textBox.text = "The winner of this race will earn " + aOrAn + ":";
                }
            }
            this.m.titleBox.text = type === 'cancel' ? '-- ' + prizeName + ' --' : "--- " + prizeName + "! ---";
            this.m.close_bt.addEventListener(MouseEvent.CLICK, this.clickClose, false, 0, true);
            addChild(this.m);
            PrizePopup.instance = this;
        }

        // method_714 = activateEpicAnimation
        private function activateEpicAnimation()
        {
            this.var_207.addItem(this.target.colorMC2);
            this.var_207.method_580(300);
            this.var_207.start();
        }

        // method_292 = clickClose
        private function clickClose(e:MouseEvent)
        {
            startFadeOut();
        }

        override public function remove()
        {
            PrizePopup.instance = null;
            if (this.var_207 != null) {
                this.var_207.remove();
                this.var_207 = null;
            }
            this.m.close_bt.removeEventListener(MouseEvent.CLICK, this.clickClose);
            super.remove();
        }


    }
}//package package_6

