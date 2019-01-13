// package_6.ItemDisplay = package_6.class_90

package package_6
{
    public class ItemDisplay extends class_7 
    {

        private var m:ItemDisplayGraphic = new ItemDisplayGraphic();

        public function ItemDisplay()
        {
            addChild(this.m);
            this.m.gotoAndStop("None");
        }

        public function setItem(item:String)
        {
            this.m.gotoAndStop(item);
            this.m.holder1.textBox.text = this.m.holder2.textBox.text = item;
            this.setAmmo(1);
            if (item == "None") {
                this.setAmmo(0);
            }
        }

        public function setAmmo(ammo:int)
        {
            this.m.a1.visible = this.m.a2.visible = this.m.a3.visible = false;
            while (ammo > 0) {
                this.m["a" + ammo].visible = true;
                ammo--;
            }
        }


    }
}
