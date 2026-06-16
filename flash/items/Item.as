// items.Item = items.class_124

package items
{
    import character.LocalCharacter;
    import com.jiggmin.data.SecureData;
    import flash.utils.setTimeout;
    import flash.geom.Point;
    import background.EffectBackground;
    import flash.utils.clearTimeout;

    public class Item extends Removable 
    {

        protected var localChar:LocalCharacter;
        protected var space:Boolean = false;
        protected var reloading:Boolean = false;
        private var reloadListener:uint;
        private var available:Boolean = false;

        public function Item(lc:LocalCharacter)
        {
            this.localChar = lc;
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
            var uses:int = SecureData.getNumber("uses");
            if (this.space && uses > 0 && !this.reloading && this.available) {
                this.useItem();
            }
        }

        protected function setUses(uses:int)
        {
            SecureData.setNumber("uses", uses);
            this.localChar.setAmmo(uses);
        }

        protected function setReloadTime(time:int)
        {
            SecureData.setNumber("reloadTime", time);
        }

        // _loc1 = uses
        public function useItem()
        {
            var uses:int = SecureData.getNumber("uses");
            uses--;
            SecureData.setNumber("uses", uses);
            this.localChar.setAmmo(uses);
            if (uses <= 0) {
                this.localChar.setItem(0);
            } else {
                this.reloading = true;
                this.reloadListener = setTimeout(this.reloadingOnComplete, SecureData.getNumber("reloadTime"));
            }
        }

        private function reloadingOnComplete()
        {
            this.reloading = false;
        }

        protected function getWeaponEffectPos():Point
        {
            var _local_1:Point = new Point(this.localChar.curWeapon.x, this.localChar.curWeapon.y);
            _local_1 = this.localChar.curWeapon.parent.localToGlobal(_local_1);
            return EffectBackground.instance.globalToLocal(_local_1);
        }

        override public function remove()
        {
            clearTimeout(this.reloadListener);
            if (this.localChar != null) {
                this.localChar = null;
            }
            super.remove();
        }


    }
}
