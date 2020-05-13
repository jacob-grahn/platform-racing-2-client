// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//data.class_28

package data
{
    import com.hurlant.crypto.hash.MD5;
    import com.hurlant.util.Hex;
    import flash.utils.getDefinitionByName;
    import flash.display.MovieClip;
    import flash.geom.Point;

    public class class_28
    {

        public static var md5:MD5 = new MD5();
        private static var groupColors:Array = new Array("#676666", "#047B7B", "#1C369F", "#870A6F");
        private static var modGroupColors:Array = new Array("#006400", "#0092FF", "#1C369F");
        private static var damnArray:Array = new Array("dang", "dingy-goo", "condemnation"); // var_397
        private static var fuckArray:Array = new Array("fooey", "fingilly", "funk-master", "freak monster", "jiminy cricket"); // var_449
        private static var shitArray:Array = new Array("shoot", "shewet"); // var_434
        private static var niggaArray:Array = new Array("someone cooler than me", "ladies magnet", "cooler race"); // var_355
        private static var bitchArray:Array = new Array("cooler gender", "female dog"); // var_373


        // _loc2 = ret
        // _loc3 = startsWith
        // name_5 = aOrAn
        public static function aOrAn(s:String):String
        {
            var ret:String = "a";
            if (s != null && s.length > 0) {
                var startsWith:String = s.charAt(0).toLowerCase();
                if (startsWith == "a" || startsWith == "e" || startsWith == "i" || startsWith == "o" || startsWith == "u") {
                    ret = "an";
                }
            }
            return ret;
        }

        // convert string to uppercase first 
        public static function ucfirst(s:String)
        {
            return (s.substr(0,1).toUpperCase() + (s.substr(1, s.length)).toLowerCase());
        }

        // method_26 = getTime
        public static function getTime():Number
        {
            var date:Date = new Date();
            return date.time;
        }

        // method_79 = getMS
        public static function getMS():Number
        {
            return Math.round(getTime() / 1000);
        }

        // _loc3 = numStr
        // method_78 = formatNumber
        public static function formatNumber(num:Number):String
        {
            var _local_2:String = num.toString();
            var numStr:String = "";
            while (_local_2.length > 3) {
                var _local_4:String = _local_2.substr(-3);
                _local_2 = _local_2.substr(0, _local_2.length - 3);
                numStr = "," + _local_4 + numStr;
            }
            if (_local_2.length > 0) {
                numStr = _local_2 + numStr;
            }
            return numStr;
        }

        public static function hash(s:String):String
        {
            return Hex.fromArray(class_28.md5.hash(Hex.toArray(Hex.fromString(s))));
        }

        public static function method_849(a:Array):Array
        {
            return a.concat();
        }

        // _loc2 = date
        // _loc3 = monthArray
        // _loc4 = monthName
        // _loc5 moved to return line
        // method_687 = getDateStr
        public static function getDateStr(t:Number):String
        {
            var date:Date = new Date();
            date.setTime(t);
            var monthName:String = class_28.getMonthStr(date.month);
            return monthName + " " + date.date;
        }

        public static function getMonthStr(m:int):String
        {
            var monthArray:Array = new Array("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
            return monthArray[m];
        }

        // _loc2 = c
        // unused??
        /*public static function method_830(s:String):MovieClip
        {
            var c:Class = (getDefinitionByName(s) as Class);
            return (new (c)());
        }*/

        // _loc3 = mins
        // _loc4 = secs
        // _loc5 = deci
        // _loc6 = minsStr
        // _loc7 = secsStr
        // _loc8 = deciStr
        // _loc9 = str
        // method_434 = formatTime
        public static function formatTime(timeInput:Number, mode:String="seconds"):String
        {
            var mins:Number = Math.floor(timeInput / 60);
            var secs:Number = Math.floor(timeInput % 60);
            var deci:Number = Math.round((timeInput % 1) * 100);
            var minsStr:String = class_28.padString(1, "0", mins.toString());
            var secsStr:String = class_28.padString(2, "0", secs.toString());
            var deciStr:String = class_28.padString(2, "0", deci.toString());
            var str:String = minsStr + ":" + secsStr;
            if (mode == "decimal") {
                str = str + "." + deciStr;
            }
            return str;
        }

        // method_160 = padString
        public static function padString(minPlaces:Number, paddingChar:String, str:String):String
        {
            while (str.length < minPlaces) {
                str = paddingChar + str;
            }
            return str;
        }

        // method_669 = escapeAndFilterString
        public static function escapeAndFilterString(s:String):String
        {
            if (s != null) {
                s = class_28.trimWhitespace(s);
                s = class_28.escapeChars(s);
                s = class_28.filterSwears(s);
            }
            return s;
        }

        // method_312 = escapeString
        public static function escapeString(s:String, preserveNewLine:Boolean = false):String
        {
            s = class_28.trimWhitespace(s, preserveNewLine);
            s = class_28.escapeChars(s);
            return s;
        }

        // method_88 = escapeChars
        public static function escapeChars(s:String):String
        {
            s = s.replace(/&/gi, "&amp;");
            s = s.replace(/>/gi, "&gt;");
            s = s.replace(/</gi, "&lt;");
            s = s.replace(/'/gi, "&apos;");
            s = s.replace(/"/gi, "&quot;");
            return s;
        }

        // method_164 = trimWhitespace
        public static function trimWhitespace(s:String, keepNL:Boolean = false):String
        {
            s = (s == null) ? '' : s;
            s = s.replace(/^\s+|\s+$/g, "");
	        return keepNL ? s.replace(/(\t|\f)/gi, " ") : s.replace(/(\t|\n|\r|\v|\f)/gi, " ");
	    }

        // method_168 = filterSwears
        public static function filterSwears(s:String):String
        {
            s = s.replace(/damn/gi, class_28.randArrayKey(class_28.damnArray));
            s = s.replace(/fuck/gi, class_28.randArrayKey(class_28.fuckArray));
            s = s.replace(/nigg(a|er)/gi, class_28.randArrayKey(class_28.niggaArray));
            s = s.replace(/\b(spic)\b/gi, class_28.randArrayKey(class_28.niggaArray));
            s = s.replace(/shit/gi, class_28.randArrayKey(class_28.shitArray));
            s = s.replace(/bitch/gi, class_28.randArrayKey(class_28.bitchArray));
            s = s.replace(/cunt/gi, class_28.randArrayKey(class_28.bitchArray));
            s = s.replace(/whore/gi, class_28.randArrayKey(class_28.bitchArray));
            return s;
        }

        // method_36 = randArrayKey
        public static function randArrayKey(a:Array):String
        {
            return a[Math.floor(Math.random() * a.length)];
        }

        public static function rand(lowerLim:int, higherLim:int):int
        {
            return lowerLim + Math.floor(Math.random() * (higherLim - lowerLim + 1));
        }

        // method_495 = parseLinks
        public static function parseLinks(s:String):String
        {
            // user link: [user=group]display text[/user]
            s = parseUser(s);
            
            // urls: [url]link[/url], [url=link]display text[/url]
            s = parseURL(s);

            // level: [level=id]display text[/level]
            s = s.replace(/(\[level=)(\d{1,8})(\])(.+)(\[\/level\])/gi, "<a href='event:level`$2'><u><font color='#0000FF'>$4</font></u></a>");

            // guild link: [guild=id]display text[/guild], [guildlink=id]display text[/guildlink]
            s = s.replace(/(\[guild=)(\d{1,6})(\])(.+)(\[\/guild\])/gi, "<a href='event:guild`$2'><u><font color='#0000FF'>$4</font></u></a>");
            s = s.replace(/(\[guildlink=)(\d{1,6})(\])(.+)(\[\/guildlink\])/gi, "<a href='event:guild`$2'><u><font color='#0000FF'>$4</font></u></a>");

            // invite link: [invite=guildid]display text[/invite], [invitelink=guildid]display text[/invite]
            s = s.replace(/(\[invite=)(\d+)(\])(.+)(\[\/invite\])/gi, "<a href='event:invite`$2'><u><font color='#0000FF'>$4</font></u></a>"); // [invite=id]text[/invite]
            s = s.replace(/(\[invitelink=)(\d+)(\])(.+)(\[\/invitelink\])/gi, "<a href='event:invite`$2'><u><font color='#0000FF'>$4</font></u></a>"); // [invitelink=id]text[/invitelink]

            // text color: [color=#hex]text[/color]
            s = s.replace(/(\[color=)(#[0-9a-fA-F]{6})(\])(.+)(\[\/color\])/gi, "<font color='$2'>$4</font>");

            // bold text: [b]text[/b], [bold]text[/bold]
            s = s.replace(/(\[b\])(.+)(\[\/b\])/gi, "<b>$2</b>");
            s = s.replace(/(\[bold\])(.+)(\[\/bold\])/gi, "<b>$2</b>");

            // text sizing: [small]text[/small], [medium]text[/medium], [large]text[/large] (or big)
            s = s.replace(/(\[small\])(.+)(\[\/small\])/gi, "<font size='6'>$2</font>");
            s = s.replace(/(\[medium\])(.+)(\[\/medium\])/gi, "<font size='12'>$2</font>");
            s = s.replace(/(\[large\])(.+)(\[\/large\])/gi, "<font size='24'>$2</font>");
            s = s.replace(/(\[big\])(.+)(\[\/big\])/gi, "<font size='24'>$2</font>");

            return s;
        }

        private static function parseUser(s:String):String
        {
            var sNew:String = s.replace(/(\[user=)(\d{1}(?:\,\d{1}){0,1})(\])([a-zA-Z0-9-.:;=?~!()@*,+$#% ]+)(\[\/user\])/gi, "<a href='event:user`$2`$4`1'><u><font color='<*>$2<*>'>$4</font></u></a>");
            if (s == sNew) {
                return s;
            }

            // replace power value with corresponding group color
            var arr:Array = sNew.split('<*>');
            for (var i = 1; i < arr.length; i += 2) {
                if (arr[i].indexOf(',') == -1) {
                    arr[i] = groupColors[numLimit(int(arr[i]), 0, 3)];
                } else {
                    var mod_power:* = arr[i].split(',');
                    arr[i] = modGroupColors[numLimit(int(mod_power[1]), 0, 2)];
                }
            }

            return arr.join('');
        }

        private static function parseURL(s:String):String
        {
            var sNew:String = s.replace(/\[[uU][rR][lL]\](https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,4}\b(((?:&amp;)|[-a-zA-Z0-9@:%_\+.~#?&\/=])*))\[\/[uU][rR][lL]\]/g, "<a href='event:url`<*>$1<*>'><u><font color='#0000FF'><*>$1<*></font></u></a>");
            sNew = sNew.replace(/\[[uU][rR][lL]=(https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,4}\b(((?:&amp;)|[-a-zA-Z0-9@:%_\+.~#?&\/=])*))\](.+?)\[\/[uU][rR][lL]\]/g, "<a href='event:url`$1'><u><font color='#0000FF'>$5</font></u></a>");
            if (s == sNew) {
                return s;
            }

            // replace &amp; with &
            var arr:Array = sNew.split('<*>');
            for (var i = 1; i < arr.length; i += 2) {
                arr[i] = arr[i].replace(/(?:&amp;)/gi, '&');
            }

            return arr.join('');
        }

        public static function urlify(url:String, disp:String, color:String = '#0000FF')
        {
            link = escapeString(link);
            disp = escapeString(disp);
            return '<a href="' + link + '" target="_blank"><u><font color="' + $color + '">' + disp + '</font></u></a>';
        }

        public static function numLimit(value:Number, minimum:Number, maximum:Number)
        {
            if (value > maximum) {
                value = maximum;
            }
            if (value < minimum) {
                value = minimum;
            }
            return value;
        }

        public static function method_9(_arg_1:Number, _arg_2:Number, _arg_3:Number):Point
        {
            var _local_4:int = _arg_1;
            var _local_5:int = _arg_2;
            if (_arg_3 > 180) {
                _arg_3 = -360 + _arg_3;
            }
            if (_arg_3 < -180) {
                _arg_3 = 360 + _arg_3;
            }
            if (_arg_3 == 90) {
                _local_4 = _arg_2;
                _local_5 = -_arg_1;
            } else {
                if (Math.abs(_arg_3) == 180) {
                    _local_4 = -_arg_1;
                    _local_5 = -_arg_2;
                } else {
                    if (_arg_3 == -90) {
                        _local_4 = -_arg_2;
                        _local_5 = _arg_1;
                    }
                }
            }
            var _local_6:Point = new Point(_local_4, _local_5);
            return _local_6;
        }

        public static function method_852(_arg_1:int):Object
        {
            var _local_2:Number = 25;
            var _local_3:Object = new Object();
            if (_arg_1 < _local_2) {
                _local_3.lowExp = 0;
                _local_3.highExp = _local_2;
            } else {
                while (_local_2 < _arg_1) {
                    _local_2 = _local_2 * 1.25;
                }
                _local_3.lowExp = _local_2 * (1 / 1.25);
                _local_3.highExp = _local_2;
            }
            return _local_3;
        }

        public static function method_439(_arg_1:int=8):String
        {
            var _local_6:int;
            var _local_7:String;
            var _local_2:* = "0123456789_!@#$%&*()-=+/abcdfghjkmnpqrstvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_!@#$%&*()-=+/";
            var _local_3:int = _local_2.length;
            var _local_4:* = "";
            var _local_5:int;
            while (_local_5 < _arg_1) {
                _local_6 = int(Math.floor(Math.random() * _local_3));
                _local_7 = _local_2.substr(_local_6, 1);
                _local_4 = _local_4 + _local_7;
                _local_5++;
            }
            return _local_4;
        }


    }
}//package data
