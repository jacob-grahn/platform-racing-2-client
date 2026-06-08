// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//character.DjinnEffects

package character
{
    public class DjinnEffects 
    {

        private var owner:Character; // var_5
        private var hat:ParticleEmitter;
        private var head:ParticleEmitter;
        private var body:ParticleEmitter;
        private var foot1:ParticleEmitter;
        private var foot2:ParticleEmitter;
        private var djinnBody:Object; // var_25
        private var djinnFeet:Object; // var_26

        public function DjinnEffects(c:Character)
        {
            this.owner = c;
            this.djinnBody = new Object();
            this.djinnBody.graphic = "DjinnIceGraphic";
            this.djinnBody.colors = new Array(this.owner.bodyColor, this.owner.bodyColor2);
            this.djinnBody.life = 16;
            this.djinnBody.startAlpha = 0.1;
            this.djinnBody.minVelAlpha = 0;
            this.djinnBody.maxVelAlpha = 0.5;
            this.djinnBody.minVelY = 2;
            this.djinnBody.maxVelY = 3;
            this.djinnBody.velScaleX = 0.1;
            this.djinnBody.velScaleY = 0.1;
            this.djinnBody.fricY = 0.9;
            this.djinnBody.fricX = 1.05;
            this.djinnBody.minOffsetX = -5;
            this.djinnBody.maxOffsetX = 5;
            this.djinnBody.minOffsetY = -10;
            this.djinnBody.maxOffsetY = 10;
            this.djinnBody.minScale = -1;
            this.djinnBody.maxScale = -0.75;
            this.djinnFeet = new Object();
            this.djinnFeet.graphic = "DjinnIceGraphic";
            this.djinnFeet.colors = new Array(this.owner.feetColor, this.owner.feetColor2);
            this.djinnFeet.life = 8;
            this.djinnFeet.startAlpha = 0.1;
            this.djinnFeet.minVelAlpha = 0;
            this.djinnFeet.maxVelAlpha = 0.5;
            this.djinnFeet.minVelX = -2;
            this.djinnFeet.maxVelX = 2;
            this.djinnFeet.velScaleX = 0.1;
            this.djinnFeet.velScaleY = 0.1;
            this.djinnFeet.minOffsetX = -5;
            this.djinnFeet.maxOffsetX = 5;
            this.djinnFeet.minOffsetY = -5;
            this.djinnFeet.maxOffsetY = 5;
            this.djinnFeet.minScale = 0.075;
            this.djinnFeet.maxScale = 0.1;
        }

        public function update()
        {
            this.clear();
            if (this.owner.parent && this.owner.curAnim) {
                if (this.owner.body == 35) {
                    this.djinnBody.colors = new Array(this.owner.bodyColor, this.owner.bodyColor2);
                    this.body = new PositionedParticleEmitter(75, 9999999999, this.owner.curAnim.body, this.owner.parent, this.djinnBody, -15, -10);
                }
                if (this.owner.feet == 35) {
                    this.djinnFeet.colors = new Array(this.owner.feetColor, this.owner.feetColor2);
                    this.foot1 = new PositionedParticleEmitter(75, 9999999999, this.owner.curAnim.foot1, this.owner.parent, this.djinnFeet);
                    this.foot2 = new PositionedParticleEmitter(75, 9999999999, this.owner.curAnim.foot2, this.owner.parent, this.djinnFeet);
                }
            }
        }

        public function newAlpha(num:Number)
        {
            this.djinnBody.startAlpha = this.djinnFeet.startAlpha = num / 5;
            this.djinnBody.minVelAlpha = this.djinnFeet.minVelAlpha = 0;
            this.djinnBody.maxVelAlpha = this.djinnFeet.maxVelAlpha = num;
            
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
            this.owner = null;
        }


    }
}//package character

