// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// OutfitPopupGraphic = class_258

package 
{
    import flash.display.MovieClip;
    import fl.controls.Button;
    import fl.controls.TextArea;
    //import com.jiggmin.data.EpicFlash;

    public dynamic class OutfitPopupGraphic extends MovieClip 
    {

        public var c:MovieClip;
        public var main:ConfirmPopupGraphic;

        /*
            Outfit input should be in the following format:

            var outfit:Object = {
                hats: [hat1Id, hat2Id, hat3Id, hat4Id],
                head: headId,
                body: bodyId,
                feet: feetId,
                colors: {
                    hats: [
                        [hat1Color, hat1Color2],
                        [hat2Color, hat2Color2],
                        [hat3Color, hat3Color2],
                        [hat4Color, hat4Color2]
                    ],
                    head: [headColor, headColor2],
                    body: [bodyColor, bodyColor2],
                    feet: [feetColor, feetColor2]
                }
            }
         */

        public function OutfitPopupGraphic(outfit:Object)
        {//hatIds:Array = null, headId:int = 1, bodyId:int = 1, feetId:int = 1, colors:Object = null
            outfit.hatIds = outfit.hatIds == null || !(outfit.hatIds is Array) || outfit.hatIds.length != 4 ? [1, 1, 1, 1] : outfit.hatIds;
            addFrameScript(0, function() {
                frame1(outfit.hats, outfit.head, outfit.body, outfit.feet, outfit.colors);
            });
        }

        private function frame1(hatIds:Array, headId:int, bodyId:int, feetId:int, colors:Object)
        {
            //this.c.y -= 20;
            //var flash:EpicFlash = new EpicFlash();

            this.c.head.gotoAndStop(headId);
            this.c.head.colorMC.gotoAndStop(headId);
            this.c.head.colorMC2.gotoAndStop(headId);
            //flash.addItem(this.c.head.colorMC2);

            this.c.body.gotoAndStop(bodyId);
            this.c.body.colorMC.gotoAndStop(bodyId);
            this.c.body.colorMC2.gotoAndStop(bodyId);
            //flash.addItem(this.c.body.colorMC2);

            this.c.foot1.gotoAndStop(feetId);
            this.c.foot1.colorMC.gotoAndStop(feetId);
            this.c.foot1.colorMC2.gotoAndStop(feetId);
            this.c.foot2.gotoAndStop(feetId);
            this.c.foot2.colorMC.gotoAndStop(feetId);
            this.c.foot2.colorMC2.gotoAndStop(feetId);
            //flash.addItem(this.c.foot1.colorMC2);
            //flash.addItem(this.c.foot2.colorMC2);

            this.c.weapon.gotoAndStop("None");

            this.c.head.hat1.gotoAndStop(hatIds[0]);
            this.c.head.hat1.colorMC.gotoAndStop(hatIds[0]);
            this.c.head.hat1.colorMC2.gotoAndStop(hatIds[0]);

            this.c.head.hat2.gotoAndStop(hatIds[1]);
            this.c.head.hat2.colorMC.gotoAndStop(hatIds[1]);
            this.c.head.hat2.colorMC2.gotoAndStop(hatIds[1]);

            this.c.head.hat3.gotoAndStop(hatIds[2]);
            this.c.head.hat3.colorMC.gotoAndStop(hatIds[2]);
            this.c.head.hat3.colorMC2.gotoAndStop(hatIds[2]);

            this.c.head.hat4.gotoAndStop(hatIds[3]);
            this.c.head.hat4.colorMC.gotoAndStop(hatIds[3]);
            this.c.head.hat4.colorMC2.gotoAndStop(hatIds[3]);

            if (colors != null) {
                if (colors.head != null) {
                    this.c.setHeadColors(colors.head[0], colors.head[1]);
                }
                if (colors.body != null) {
                    this.c.setBodyColors(colors.body[0], colors.body[1]);
                }
                if (colors.feet != null) {
                    this.c.setFeetColors(colors.feet[0], colors.feet[1]);
                }

                if (colors.hats != null) {
                    if (hatIds[0] > 1 && colors.hats[0] != null) {
                        this.c.setHatColors(colors.hats[0][0], colors.hats[0][1], 1);
                    }
                    if (hatIds[1] > 1 && colors.hats[1] != null) {
                        this.c.setHatColors(colors.hats[1][0], colors.hats[1][1], 2);
                    }
                    if (hatIds[2] > 1 && colors.hats[2] != null) {
                        this.c.setHatColors(colors.hats[2][0], colors.hats[2][1], 3);
                    }
                    if (hatIds[3] > 1 && colors.hats[3] != null) {
                        this.c.setHatColors(colors.hats[3][0], colors.hats[3][1], 4);
                    }
                }
            }
            //flash.start();
        }

    }
}
