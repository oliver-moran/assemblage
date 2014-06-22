/*

url is http://www.random.org/integers/?num=1&min=1&max=6&col=1&base=10&format=plain&rnd=new
random is from url
number is 12
felix is from https://upload.wikimedia.org/wikipedia/commons/2/23/Felix_Laff_clean.svg
show random
show number
show felix

*/

{
    var canvas = document.createElement("canvas");
    canvas.setAttribute("id", "canvas");
    document.body.appendChild(canvas);

    var stage = new createjs.Stage("canvas");

    function setCanvasSize(){
        canvas.setAttribute("width", window.innerWidth);
        canvas.setAttribute("height", window.innerHeight);
        stage.update();
    }
    window.addEventListener("resize", setCanvasSize);
    setCanvasSize();

    var start = (new Date()).getTime();
    var variables = {};
    var lines = [];
    var wait = false;

    function Item(url) {
        this.bitmap = new createjs.Bitmap(url);
        this.bitmap.visible = false;
        this.bitmap.x = window.innerWidth / 2;
        this.bitmap.y = window.innerHeight / 2;
        
        stage.addChild(this.bitmap); 
        var _that = this;

        wait = true;
        this.bitmap.image.addEventListener("load", function onload(){
            _that.bitmap.image.removeEventListener("load", onload);
            stage.update();
            execute();
        });
    }
    
    Item.prototype.bitmap = null;
    Item.prototype.updateRegistrationPoint = function () {
        this.bitmap.regX = this.bitmap.image.width / 2;
        this.bitmap.regY = this.bitmap.image.height / 2;
    };

    Item.prototype.setProperty = function (property, value) {
        switch (property.toLowerCase()) {
            case "x":
                if (/\d+%/.test(value)) this.bitmap.x = window.innerWidth * (parseInt(value) / 100);
                else this.bitmap.x = parseInt(value);
                break;
            case "y":
                if (/\d+%/.test(value)) this.bitmap.y = window.innerHeight * (parseInt(value) / 100);
                else this.bitmap.y = parseInt(value);
                break;
            case "width":
                if (/\d+%/.test(value)) this.bitmap.scaleX = parseInt(value) / 100;
                else this.bitmap.scaleX = parseInt(value) / this.bitmap.image.width;
                break;
            case "height":
                var scaleY = null;
                if (/\d+%/.test(value)) this.bitmap.scaleY = parseInt(value) / 100;
                else this.bitmap.scaleY = parseInt(value) / this.bitmap.image.height;
                break;
            case "rotation":
                this.bitmap.rotation = parseInt(value);
                break;
            default:
                break;
        }
        
        this.updateRegistrationPoint();
        stage.update();
    };
    
    Item.prototype.setState = function (state, value) {
        switch (state.toLowerCase()) {
            case "visible":
                this.bitmap.visible = value;
                break;
            default:
                break;
        }
        
        stage.update();
    };
    
    Item.prototype.getProperty = function (property) {
        switch (property.toLowerCase()) {
            case "x":
            case "y":
                return this.bitmap[property];
                break;
            case "width":
            case "height":
                return this.bitmap.image[property];
                break;
            default:
                break;
        }
    };

    function getVariable(id) {
        var variable = variables[id];
        return (variable == undefined) ? id : variable;
    }

    function setVariable(id, val) {
        variables[id] = val;
        return val;
    }

    function setProperty(id, prop, val) {
        var variable = variables[id];
        if (variable == undefined) return undefined;
        else {
            variables[id].setProperty(prop, val);
            return val;
        }
    }

    function getProperty(id, prop) {
        var variable = variables[id];
        if (variable == undefined) return undefined;
        else {
            return variables[id].getProperty(prop);
        }
    }
    
    function setState(id, state, negation) {
        var variable = variables[id];
        if (variable == undefined) return undefined;
        else {
            var val = negation == null;
            variables[id].setState(state, val);
            return val;
        }
    }

    var mimes = {
        text: "text/plain",
        images: [
            "image/gif",
            "image/jpeg",
            "image/png",
            "image/svg+xml",
            "image/example"
        ]
    };

    function getValueFromURL(url) {
        var request = new XMLHttpRequest();
        request.open("HEAD", url, false);
        request.send();
        var type = request.getResponseHeader("Content-Type");
        var i = type.indexOf(";");
        var mime = (i > -1) ? type.substring(0, i) : type;
        if (mime == mimes.text) {
            var request = new XMLHttpRequest();
            request.open("GET", url, false);
            request.send();
            if (typeof request.responseText == "string") {
                return request.responseText.trim();
            }
        } else if (mimes.images.indexOf(mime) > -1) {
            return new Item(url);
        }
        return undefined;
    }

    function parseTime(num, unit) {
        switch (unit) {
            case "s":
                return num * 1000;
            case "ms":
                return num;
        }
    }

    function log(msg) {
        console.log(msg);
        return msg;
    }

    function execute(){
        wait = false;
        while(lines.length > 0 && !wait) {
            lines.shift().call();
        }
    }
}

start = line

line
    = (newline / (result:statement (newline / endofinput)) { return lines.push(result); })+ { return execute(); }

/* STATEMENTS */

statement
    = comment / after / every / setstate / assign / setproperty / log

setstate
    = id:id space "is" negation:(space not:"not" { return true; }) ? space state:state { return function() { setState(id, state, negation) }; }

assign
    = id:id space "is" space val:value { return function() { setVariable(id, val()) }; }

setproperty
    = id:id space prop:property space "is" space val:value { return function() { setProperty(id, prop, val()); } }

log
    = "log" space msg:value { return function() { log(msg()); } }

comment
    = ">" [^\n]* { return function () {}}

/* TIMERS */

after
    = "after" space ms:time space result:statement { return function() { setTimeout(result, ms); } }

every
    = "every" space ms:time space result:statement { return function() { setInterval(result, ms); } }


/* VALUES */

value "value"
    = from / prop / unit / url / variable

from
    = "from" space url:value { return function() { return getValueFromURL(url()); }; }

prop
    = id:id space prop:value { return function() { return getProperty(id, prop()); }; }

unit "unit"
    = val:number unit:("px" / "deg" / "%") { return function() { return val + unit; }; }

url "URL"
    = protocol:("http://" / "https://") url:[a-zA-Z0-9-\._~:/?#\[\]@!$&'()*+,;=]* { return function() { return protocol + url.join(""); }; }

variable "variable"
    = id:id { return function() { return getVariable(id); }; }

/* TYPES */

number "number"
    = sign:"-"? num:[0-9]+ { return sign + parseInt(num.join(""), 10); }

time "time"
    = num:[0-9]+ unit:("ms" / "s") { return parseTime(num, unit); }

id "id"
    = id:[A-zA-z0-9]+ { return id.join(""); }

property "property"
    = ("x" / "y" / "width" / "height" / "rotation")

state "state"
    = ("visible")

/* WHITESPACE */

newline "new line"
    = [\n]

endofinput "end of input"
    = !.

space "white space"
    = " "+

