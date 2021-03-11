// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// items.Item = items.class_124

package items
{
    import package_8.LocalPlayer;
    import com.jiggmin.data.class_33;
    import flash.utils.setTimeout;
    import flash.geom.Point;
    import background.EffectBackground;
    import flash.utils.clearTimeout;

    public class Item extends Removable 
    {

        protected var player:LocalPlayer; // var_5
        protected var space:Boolean = false;
        protected var reloading:Boolean = false; // var_410
        private var reloadListener:uint; // var_581
        private var available:Boolean = false; // var_572

        public function Item(p:LocalPlayer)
        {
            this.player = p;
            this.setReloadTime(10);
            this.setUses(1);
        }

        // _loc2 = uses
        public function setSpace(pressed:Boolean)
        {
            this.space = pressed;
            if (!this.space) {
                this.available = true;
            }
            var uses:int = class_33.getNumber("uses");
            if (this.space && uses > 0 && !this.reloading && this.available) {
                this.useItem();
            }
        }

        // method_48 = setUses
        protected function setUses(uses:int)
        {
            class_33.setNumber("uses", uses);
            this.player.setAmmo(uses);
        }

        // method_45 = setReloadTime
        protected function setReloadTime(time:int)
        {
            class_33.setNumber("reloadTime", time);
        }

        // _loc1 = uses
        public function useItem()
        {
            var uses:int = class_33.getNumber("uses");
            uses--;
            class_33.setNumber("uses", uses);
            this.player.setAmmo(uses);
            if (uses <= 0) {
                this.player.setItem(0);
            } else {
                this.reloading = true;
                this.reloadListener = setTimeout(this.reloadingOnComplete, class_33.getNumber("reloadTime"));
            }
        }

        // method_688 = reloadingOnComplete
        private function reloadingOnComplete()
        {
            this.reloading = false;
        }

        protected function method_37():Point
        {
            var _local_1:Point = new Point(this.player.curWeapon.x, this.player.curWeapon.y);
            _local_1 = this.player.curWeapon.parent.localToGlobal(_local_1);
            return EffectBackground.instance.globalToLocal(_local_1);
        }

        override public function remove()
        {
            clearTimeout(this.reloadListener);
            if (this.player != null) {
                this.player = null;
            }
            super.remove();
        }


    }
}
