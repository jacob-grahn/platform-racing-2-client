// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_8.class_127

package package_8
{
    public class class_127 
    {

        private var var_5:Character;
        private var hat:class_125;
        private var head:class_125;
        private var body:class_125;
        private var foot1:class_125;
        private var foot2:class_125;
        private var var_25:Object;
        private var var_26:Object;

        public function class_127(_arg_1:Character)
        {
            this.var_5 = _arg_1;
            this.var_25 = new Object();
            this.var_25.graphic = "DjinnIceGraphic";
            this.var_25.colors = new Array(_arg_1.bodyColor, _arg_1.bodyColor2);
            this.var_25.life = 16;
            this.var_25.startAlpha = 0.1;
            this.var_25.minVelAlpha = 0;
            this.var_25.maxVelAlpha = 0.5;
            this.var_25.minVelY = 2;
            this.var_25.maxVelY = 3;
            this.var_25.velScaleX = 0.1;
            this.var_25.velScaleY = 0.1;
            this.var_25.fricY = 0.9;
            this.var_25.fricX = 1.05;
            this.var_25.minOffsetX = -5;
            this.var_25.maxOffsetX = 5;
            this.var_25.minOffsetY = -10;
            this.var_25.maxOffsetY = 10;
            this.var_25.minScale = -1;
            this.var_25.maxScale = -0.75;
            this.var_26 = new Object();
            this.var_26.graphic = "DjinnIceGraphic";
            this.var_26.colors = new Array(_arg_1.feetColor, _arg_1.feetColor2);
            this.var_26.life = 8;
            this.var_26.startAlpha = 0.1;
            this.var_26.minVelAlpha = 0;
            this.var_26.maxVelAlpha = 0.5;
            this.var_26.minVelX = -2;
            this.var_26.maxVelX = 2;
            this.var_26.velScaleX = 0.1;
            this.var_26.velScaleY = 0.1;
            this.var_26.minOffsetX = -5;
            this.var_26.maxOffsetX = 5;
            this.var_26.minOffsetY = -5;
            this.var_26.maxOffsetY = 5;
            this.var_26.minScale = 0.075;
            this.var_26.maxScale = 0.1;
        }

        public function update()
        {
            this.clear();
            if (((this.var_5.parent) && (this.var_5.var_301))) {
                if (this.var_5.body == 35) {
                    this.var_25.colors = new Array(this.var_5.bodyColor, this.var_5.bodyColor2);
                    this.body = new class_179(75, 9999999999, this.var_5.var_301.body, this.var_5.parent, this.var_25, -15, -10);
                }
                if (this.var_5.feet == 35) {
                    this.var_26.colors = new Array(this.var_5.feetColor, this.var_5.feetColor2);
                    this.foot1 = new class_179(75, 9999999999, this.var_5.var_301.foot1, this.var_5.parent, this.var_26);
                    this.foot2 = new class_179(75, 9999999999, this.var_5.var_301.foot2, this.var_5.parent, this.var_26);
                }
            }
        }

        public function clear()
        {
            if (this.hat) {
                this.hat.remove();
                this.hat = null;
            }
            if (this.head) {
                this.head.remove();
                this.head = null;
            }
            if (this.body) {
                this.body.remove();
                this.body = null;
            }
            if (this.foot1) {
                this.foot1.remove();
                this.foot1 = null;
            }
            if (this.foot2) {
                this.foot2.remove();
                this.foot2 = null;
            }
        }

        public function remove()
        {
            this.clear();
            this.var_5 = null;
        }


    }
}//package package_8

