// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// background.class_87 = background.EffectBackground

package background
{
    import com.jiggmin.data.CommandHandler;
    import page.GamePage;
    import package_9.Hat;
    import package_9.IceWaveShot;
    import package_9.LaserShot;
    import package_9.MineAppear;
    import package_9.Slash;
    import package_9.TeleportPop;
    import sounds.SoundEffects;

    public class EffectBackground extends Background 
    {

        public static var instance:EffectBackground; // var_276

        public function EffectBackground(_arg_1:GamePage)
        {
            EffectBackground.instance = this;
            CommandHandler.commandHandler.defineCommand("addEffect", this.addEffect);
            super(_arg_1);
        }

        // _loc2 = type
        // _loc3 = originX
        // _loc4 = originY
        // _loc6 = direction
        // _loc7 = tempID
        // _loc8 = _loc9 = rot
        // _loc10 = num (hat part number)
        // _loc11 = color (decimal)
        // _loc12 = color2
        // _loc13 = id (hat ID in hats array server-side)
        public function addEffect(a:Array)
        {
            var _local_5:int;
            var tempID:int;
            var type:String = a[0];
            var originX:int = int(a[1]);
            var originY:int = int(a[2]);
            if (type == 'Laser' || type == 'Slash') {
                var dir:String = a[3];
            } else {
                var rot:int = int(a[3]);
            }
            if (type == "Laser") {
                _local_5 = int(a[4]);
                tempID = int(a[5]);
                new LaserShot(originX, originY, dir, _local_5, tempID);
            } else if (type == "Slash") {
                tempID = int(a[4]);
                new Slash(originX, originY, dir, tempID);
            } else if (type == "Mine") {
                new MineAppear(originX, originY);
            } else if (type == "Hat") {
                var num:int = int(a[4]);
                var color:int = int(a[5]);
                var color2:int = int(a[6]);
                var id:int = int(a[7]);
                new Hat(originX, originY, rot, num, color, color2, id);
            } else if (type == "IceWave") {
                _local_5 = int(a[4]);
                tempID = int(a[5]);
                this.generateIceWaveShots(originX, originY, rot, _local_5, tempID);
            } else if (type == 'Teleport') {
                new TeleportPop(originX, originY);
            }
        }

        // method_622 = generateIceWaveShots
        // public -> private
        private function generateIceWaveShots(originX:int, originY:int, rot:int, _arg_4:int, tempID:int)
        {
            new IceWaveShot(originX, originY, rot, _arg_4, tempID, rot);
            new IceWaveShot(originX, originY, rot + 30, _arg_4, tempID, rot);
            new IceWaveShot(originX, originY, rot - 30, _arg_4, tempID, rot);
            SoundEffects.playGameSound(new IceWaveSound(), originX, originY, 1.5);
        }

        override public function clear()
        {
            while (numChildren > 0) {
                Removable(getChildAt(numChildren - 1)).remove();
            }
        }

        override public function remove()
        {
            this.clear();
            EffectBackground.instance = null;
            CommandHandler.commandHandler.defineCommand("addEffect", null);
            super.remove();
        }


    }
}//package background

