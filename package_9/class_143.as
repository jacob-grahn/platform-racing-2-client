// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_9.class_143

package package_9
{
    import flash.geom.ColorTransform;
    import data.CommandHandler;

    public class class_143 extends class_81 
    {

        private var m:HatGraphic = new HatGraphic();
        private var id:int;

        public function class_143(_arg_1:int, _arg_2:int, _arg_3:int, _arg_4:int, _arg_5:int, _arg_6:int, _arg_7:int)
        {
            var _local_9:ColorTransform;
            super(_arg_1, _arg_2, _arg_3);
            this.id = _arg_7;
            velY = -5;
            scaleX = (scaleY = 0.15);
            this.m.gotoAndStop(_arg_4);
            this.m.colorMC.gotoAndStop(_arg_4);
            this.m.colorMC2.gotoAndStop(_arg_4);
            var _local_8:ColorTransform = new ColorTransform();
            _local_8.color = _arg_5;
            this.m.colorMC.transform.colorTransform = _local_8;
            if (_arg_6 == -1) {
                this.m.colorMC2.visible = false;
            } else {
                _local_9 = new ColorTransform();
                _local_9.color = _arg_6;
                this.m.colorMC2.transform.colorTransform = _local_9;
            }
            addChild(this.m);
            CommandHandler.commandHandler.defineCommand(("removeHat" + _arg_7), this.remoteRemove);
        }

        override protected function onTouchLocalPlayer()
        {
            this.remove();
            Main.socket.write(("get_hat`" + this.id));
        }

        public function remoteRemove(_arg_1:Array)
        {
            this.remove();
        }

        override public function remove()
        {
            CommandHandler.commandHandler.defineCommand(("removeHat" + this.id), null);
            super.remove();
        }


    }
}//package package_9

