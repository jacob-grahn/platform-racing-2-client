// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_22.class_251

package package_22
{
    import __AS3__.vec.Vector;
    import __AS3__.vec.*;

    public class class_251 extends class_250 
    {

        private var listings:Vector.<class_286> = new Vector.<class_286>();
        private var var_454:int = 50;

        public function class_251()
        {
            super(SuperLoader.j);
        }

        override protected function displayData(_arg_1:Object)
        {
            var _local_2:Object;
            var _local_3:class_286;
            super.displayData(_arg_1);
            for each (_local_2 in _arg_1.listings) {
                _local_3 = new class_286(_local_2);
                _local_3.y = (this.listings.length * this.var_454);
                this.listings.push(_local_3);
                addChild(_local_3);
            }
        }

        override protected function clear()
        {
            var _local_1:class_286;
            for each (_local_1 in this.listings) {
                _local_1.remove();
            }
            this.listings = new Vector.<class_286>();
            super.clear();
        }


    }
}//package package_22

