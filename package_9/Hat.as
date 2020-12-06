// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_9.Hat = package_9.class_143

package package_9
{
    import flash.geom.ColorTransform;
    import com.jiggmin.data.CommandHandler;
    import package_6.Course;

    public class Hat extends class_81 
    {

        private var m:HatGraphic = new HatGraphic();
        private var id:int;

        // _loc8 = ct
        // _loc9 = ct2
        public function Hat(x:int, y:int, rot:int, num:int, color:int, color2:int, id:int)
        {
            super(x, y, rot);
            this.id = id;
            velY = -5;
            scaleX = scaleY = 0.15;
            this.m.gotoAndStop(num);
            this.m.colorMC.gotoAndStop(num);
            this.m.colorMC2.gotoAndStop(num);
            var ct:ColorTransform = new ColorTransform();
            ct.color = color;
            this.m.colorMC.transform.colorTransform = ct;
            if (color2 == -1 && num != 16) {
                this.m.colorMC2.visible = false;
            } else {
                var ct2:ColorTransform = new ColorTransform();
                ct2.color = num == 16 && color2 == -1 ? 0 : color2; // cheese hat epic is black when epic upgrade not won
                this.m.colorMC2.transform.colorTransform = ct2;
            }
            addChild(this.m);
            CommandHandler.commandHandler.defineCommand("removeHat" + this.id, this.remoteRemove);
        }

        override protected function onTouchLocalPlayer()
        {
            if (!Course.course.isDonePlaying()) {
                this.remove();
                Main.socket.write("get_hat`" + this.id);
            }
        }

        public function remoteRemove(_arg_1:Array)
        {
            this.remove();
        }

        override public function remove()
        {
            CommandHandler.commandHandler.defineCommand("removeHat" + this.id, null);
            super.remove();
        }


    }
}
