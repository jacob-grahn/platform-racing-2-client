// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// com.jiggmin.data.Data = data.class_28

package com.jiggmin.data
{
    import com.hurlant.crypto.hash.MD5;
    import com.hurlant.util.Hex;
    import flash.display.DisplayObject;
    import flash.display.MovieClip;
    import flash.geom.Point;
    import flash.globalization.DateTimeFormatter;
    import flash.globalization.DateTimeStyle;
    import flash.globalization.LastOperationStatus;
    import flash.globalization.LocaleID;
    import flash.utils.getDefinitionByName;

    public class Data
    {

        public static const RAD_DEG:Number = 180 / Math.PI; // const_93 (from class_74/Maths)
        public static const DEG_RAD:Number = Math.PI / 180; // const_78 (from class_74/Maths)

        public static var md5:MD5 = new MD5();
        public static var df:DateTimeFormatter = new DateTimeFormatter(LocaleID.DEFAULT, DateTimeStyle.MEDIUM, DateTimeStyle.NONE);

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

        // capitalize first letter of string (and convert the rest to lowercase)
        public static function ucfirst(s:String)
        {
            return s.substr(0,1).toUpperCase() + s.substr(1, s.length).toLowerCase();
        }

        // method_26 = getMS
        public static function getMS():Number
        {
            var date:Date = new Date();
            return date.time;
        }

        // method_79 = getTimestamp
        public static function getTimestamp():Number
        {
            return Math.round(getMS() / 1000);
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
            return Hex.fromArray(Data.md5.hash(Hex.toArray(Hex.fromString(s))));
        }

        // unused??
        /*public static function method_849(a:Array):Array
        {
            return a.concat();
        }*/

        // _loc2 = date
        // _loc3 = monthArray
        // _loc4 = monthName
        // _loc5 moved to return line
        // method_687 = getDateStr
        public static function getDateStr(t:Number):String
        {
            var date:Date = new Date(t);
            var monthName:String = Data.getMonthStr(date.month);
            return monthName + " " + date.date;
        }

        private static function getMonthStr(m:int):String
        {
            var monthArray:Array = new Array("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
            return monthArray[m];
        }

        public static function getShortDateStr(t:Number)
        {
            var date:Date = new Date(t * 1000);
            return date.date + '/' + Data.getMonthStr(date.month) + '/' + date.getFullYear();
        }

        public static function getDateTimeStr(t:Number, customStyle:Array = null):String
        {
            var date:Date = new Date(t * 1000);
            if (customStyle != null && customStyle.length == 2) {
                df.setDateTimeStyles(customStyle[0], customStyle[1]);
                if (df.lastOperationStatus != LastOperationStatus.NO_ERROR) {
                    df.setDateTimeStyles(DateTimeStyle.MEDIUM, DateTimeStyle.NONE);
                    customStyle = null;
                }
            }
            var ret:String = df.format(date);
            if (customStyle != null) {
                df.setDateTimeStyles(DateTimeStyle.MEDIUM, DateTimeStyle.NONE);
            }
            return ret;
        }

        public static function getLocale()
        {
            return df.actualLocaleIDName;
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
            var minsStr:String = Data.padString(1, "0", mins.toString());
            var secsStr:String = Data.padString(2, "0", secs.toString());
            var deciStr:String = Data.padString(2, "0", deci.toString());
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
                s = Data.trimWhitespace(s);
                s = Data.cleanHTML(s);
                s = Data.filterSwears(s);
            }
            return s;
        }

        // method_312 = escapeString
        public static function escapeString(s:String, preserveNewLine:Boolean = false):String
        {
            s = Data.trimWhitespace(s, preserveNewLine);
            s = Data.cleanHTML(s);
            return s;
        }

        // method_88 = cleanHTML
        public static function cleanHTML(s:String):String
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
            s = s.replace(/damn/gi, Data.randArrayKey(Data.damnArray));
            s = s.replace(/fuck/gi, Data.randArrayKey(Data.fuckArray));
            s = s.replace(/nigg(a|er)/gi, Data.randArrayKey(Data.niggaArray));
            s = s.replace(/\b(spic)\b/gi, Data.randArrayKey(Data.niggaArray));
            s = s.replace(/shit/gi, Data.randArrayKey(Data.shitArray));
            s = s.replace(/bitch/gi, Data.randArrayKey(Data.bitchArray));
            s = s.replace(/cunt/gi, Data.randArrayKey(Data.bitchArray));
            s = s.replace(/whore/gi, Data.randArrayKey(Data.bitchArray));
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

        public static function urlify(link:String, disp:String, color:String = '#0000FF')
        {
            link = escapeString(link);
            disp = escapeString(disp);
            return '<a href="' + link + '" target="_blank"><u><font color="' + color + '">' + disp + '</font></u></a>';
        }

        // method_232 = pythag (from class_74/Maths)
        public static function pythag(xDist:Number, yDist:Number):Number
        {
            return Math.sqrt(xDist * xDist + yDist * yDist);
        }

        public static function numLimit(value:Number, minimum:Number, maximum:Number)
        {
            if (value > maximum) {
                value = maximum;
            } else if (value < minimum) {
                value = minimum;
            }
            return value;
        }

        // (from class_74/Maths)
        public static function method_314(_arg_1:DisplayObject, _arg_2:Number, _arg_3:Number)
        {
            var _local_6:Number;
            var _local_4:Number = (_arg_2 / _arg_1.width);
            var _local_5:Number = (_arg_3 / _arg_1.height);
            if (_local_4 < _local_5) {
                _local_6 = _local_4;
            } else {
                _local_6 = _local_5;
            }
            if (_local_6 < 1) {
                _arg_1.width = (_arg_1.width * _local_6);
                _arg_1.height = (_arg_1.height * _local_6);
            }
        }

        // removed _loc6 (combined w/ return)
        public static function method_9(posX:Number, posY:Number, rot:Number):Point
        {
            var _local_4:int = posX;
            var _local_5:int = posY;
            if (rot > 180) {
                rot = -360 + rot;
            } else if (rot < -180) {
                rot = 360 + rot;
            }
            if (rot == 90) {
                _local_4 = posY;
                _local_5 = -posX;
            } else if (Math.abs(rot) == 180) {
                _local_4 = -posX;
                _local_5 = -posY;
            } else if (rot == -90) {
                _local_4 = -posY;
                _local_5 = posX;
            }
            return new Point(_local_4, _local_5);
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
            var _local_2:* = "0123456789_!@#$%&*()-=+/abcdfghjkmnpqrstvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_!@#$%&*()-=+/";
            var _local_3:int = _local_2.length;
            var _local_4:* = "";
            var _local_5:int;
            while (_local_5 < _arg_1) {
                var _local_6:int = int(Math.floor(Math.random() * _local_3));
                var _local_7:String = _local_2.substr(_local_6, 1);
                _local_4 = _local_4 + _local_7;
                _local_5++;
            }
            return _local_4;
        }


    }
}//package com.jiggmin.data
