class Test extends MovieClip {
    function test1() {
        for (var i:Number = 0; i < arguments.length; i++) {
            var param = arguments[i];
            var type = typeof(param);
            trace("param " + i + ": " + param + " (type: " + type + ")");
        }

        var lastParam = arguments[arguments.length - 1];
        if (typeof(lastParam) == "function") {
            trace("Calling callback function:");
            lastParam.call();
        }
    }

    function test2(callback:Function ) {
		trace("somthing code..");
        callback.call();
    }
	
	function test3(mass :String) {
        trace("callback mass: " + mass);
    }
}