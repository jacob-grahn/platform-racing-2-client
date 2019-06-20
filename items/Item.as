// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// items.Item = items.class_124

package items
{
    import package_8.LocalCharacter;
    import data.class_33;
    import flash.utils.setTimeout;
    import flash.geom.Point;
    import background.class_87;
    import flash.utils.clearTimeout;

    public class Item extends class_7 
    {

        protected var racer:LocalCharacter; // var_5
        protected var space:Boolean = false;
        protected var reloading:Boolean = false; // var_410
        private var reloadListener:uint; // var_581
        private var available:Boolean = false; // var_572

        public function Item(r:LocalCharacter)
        {
            this.racer = r;
            this.method_45(10);
            this.method_48(1);
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

        protected function method_48(uses:int)
        {
            class_33.setNumber("uses", uses);
            this.racer.setAmmo(uses);
        }

        protected function method_45(_arg_1:int)
        {
            class_33.setNumber("reloadTime", _arg_1);
        }

        // _loc1 = uses
        public function useItem()
        {
            var uses:int = class_33.getNumber("uses");
            uses--;
            class_33.setNumber("uses", uses);
            this.racer.setAmmo(uses);
            if (uses <= 0) {
                this.racer.setItem(0);
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
            var _local_1:Point = new Point(this.racer.curWeapon.x, this.racer.curWeapon.y);
            _local_1 = this.racer.curWeapon.parent.localToGlobal(_local_1);
            return class_87.var_276.globalToLocal(_local_1);
        }

        override public function remove()
        {
            clearTimeout(this.reloadListener);
            if (this.racer != null) {
                this.racer = null;
            }
            super.remove();
        }


    }
}
