// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// data.Random = data.class_133

package data
{
    import __AS3__.vec.Vector;
    import flash.utils.ByteArray;
    import __AS3__.vec.*;

    public class Random 
    {

        private const const_96:int = 2147483647;
        private const const_97:int = 161803398;
        private const const_95:int = 0;

        private var var_464:int;
        private var var_471:int;
        private var var_520:int;
        private var var_53:Vector.<int>;

        public function Random(_arg_1:int)
        {
            var _local_6:int;
            var _local_7:int;
            super();
            this.var_520 = _arg_1;
            this.var_53 = new Vector.<int>(56, true);
            var _local_2:int = (161803398 - Math.abs(_arg_1));
            this.var_53[55] = _local_2;
            var _local_3:int = 1;
            var _local_4:int = 1;
            while (_local_4 < 55) {
                _local_6 = ((21 * _local_4) % 55);
                this.var_53[_local_6] = _local_3;
                _local_3 = (_local_2 - _local_3);
                if (_local_3 < 0) {
                    _local_3 = (_local_3 + 2147483647);
                }
                _local_2 = this.var_53[_local_6];
                _local_4++;
            }
            var _local_5:int = 1;
            while (_local_5 < 5) {
                _local_7 = 1;
                while (_local_7 < 56) {
                    this.var_53[_local_7] = (this.var_53[_local_7] - this.var_53[(1 + ((_local_7 + 30) % 55))]);
                    if (this.var_53[_local_7] < 0) {
                        this.var_53[_local_7] = (this.var_53[_local_7] + 2147483647);
                    }
                    _local_7++;
                }
                _local_5++;
            }
            this.var_464 = 0;
            this.var_471 = 21;
            _arg_1 = 1;
        }

        public function get method_154():int
        {
            return (this.var_520);
        }

        private function method_703():Number
        {
            var _local_1:int = this.method_84();
            if ((this.method_84() % 2) == 0) {
                _local_1 = -(_local_1);
            }
            var _local_2:Number = _local_1;
            _local_2 = (_local_2 + 2147483646);
            return (_local_2 / 0xFFFFFFFD);
        }

        private function method_84():int
        {
            var _local_1:int = this.var_464;
            var _local_2:int = this.var_471;
            if (++_local_1 >= 56) {
                _local_1 = 1;
            }
            if (++_local_2 >= 56) {
                _local_2 = 1;
            }
            var _local_3:int = (this.var_53[_local_1] - this.var_53[_local_2]);
            if (_local_3 < 0) {
                _local_3 = (_local_3 + 2147483647);
            }
            this.var_53[_local_1] = _local_3;
            this.var_464 = _local_1;
            this.var_471 = _local_2;
            return (_local_3);
        }

        public function method_841():int
        {
            return (this.method_84());
        }

        public function method_837(_arg_1:int):int
        {
            if (_arg_1 < 0) {
                throw (new ArgumentError('Argument "maxValue" must be positive.'));
            }
            return (int((this.method_166() * _arg_1)));
        }

        public function method_55(_arg_1:int, _arg_2:int):int
        {
            if (_arg_1 > _arg_2) {
                throw (new ArgumentError('Argument "minValue" must be less than or equal to "maxValue".'));
            }
            var _local_3:Number = (_arg_2 - _arg_1);
            if (_local_3 <= 2147483647) {
                return (int((this.method_166() * _local_3)) + _arg_1);
            }
            return (int(Number((this.method_703() * _local_3))) + _arg_1);
        }

        public function method_309(_arg_1:ByteArray, _arg_2:int)
        {
            if (_arg_1 == null) {
                throw (new ArgumentError('Argument "buffer" cannot be null.'));
            }
            var _local_3:int;
            while (_local_3 < _arg_2) {
                _arg_1.writeByte((this.method_84() % 0x0100));
                _local_3++;
            }
        }

        public function method_853():Number
        {
            return (this.method_166());
        }

        protected function method_166():Number
        {
            return (this.method_84() * 4.6566128752458E-10);
        }


    }
}//package data

