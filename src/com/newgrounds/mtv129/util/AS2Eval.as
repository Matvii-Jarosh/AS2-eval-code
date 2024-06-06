/**
 * A utility class for evaluating ActionScript 2 code dynamically.
 */
class com.newgrounds.mtv129.util.AS2Eval
{
	/**
     * Evaluates the given ActionScript 2 code.
     * 
     * @param code The ActionScript 2 code to evaluate.
     * @return The original code.
     */
    public static function evalCode(code:String):String {
        try {
            var parsed:Object = parseString(code);
			var name = (parsed.name.charCodeAt(0) == 32) ? parsed.name.substring(1, parsed.name.length) : parsed.name;
            var target:Object = eval(name) || _global;
            var func:Function = target[parsed.func_name];
            if (typeof(func) == "function") {
                var args:Array = [];
                for (var i:Number = 0; i < parsed.param.length; i++) {
                    args.push(convertParam(parsed.param[i]));
                }
                func.apply(target, args);
            } else {
                throw new Error("Function " + parsed.func_name + " not found on " + parsed.name);
            }
        } catch (e:Error) {
             throw new Error("Error: " + e.message);
        }
		return code;
    }

	/**
     * Converts the given parameter object to its corresponding value.
     * 
     * @param param The parameter object to convert.
     * @return The converted value.
     */
    private static function convertParam(param:Object) {
		
		switch (param.type) {
			case "string":
				if (param.value.charCodeAt(0) == 34) 
					return param.value.substring(1, param.length);
				else 
					return param.value
			case "boolean":
				return param.value;
			case "number":
				return Number(param.value);
			case "array":
				return param.value;
			case "function":
				return function() {
					evalCode(param.value);
				};
			case "null":
				return null;
			default:
				return param.value;
		}
	}

	private static function convertTargetToPath(target:String):String {return "_level0" + target.split("/").join(".");}

	/**
     * Parses the input string into a structured object.
     * 
     * @param input The input string to parse.
     * @return The parsed object.
     */
    private static function parseString(input:String):Object {
        var result:Object = { name: null, func_name: null, param: [] };
        var startIndex:Number = input.indexOf('(');
        var endIndex:Number = input.lastIndexOf(')');

        if (startIndex != -1 && endIndex != -1) {
            var prefix:String = input.substring(0, startIndex);
            var params:String = input.substring(startIndex + 1, endIndex);

            var lastDotIndex:Number = prefix.lastIndexOf('.');
            if (lastDotIndex != -1) {
                result.name = prefix.substring(0, lastDotIndex);
                result.func_name = prefix.substring(lastDotIndex + 1);
            } else {
                result.func_name = prefix;
            }

            if (params.length > 0) {
                var paramArray:Array = [];
                var currentParam:String = "";
                var inString:Boolean = false;
                var inArray:Boolean = false; 
                var nestedCount:Number = 0;
                var quoteChar:String = "";

                for (var i:Number = 0; i < params.length; i++) {
                    var char:String = params.charAt(i);
                    if (inString) {
                        if (char == quoteChar) {
                            inString = false;
                            currentParam += char;
                        } else {
                            currentParam += char;
                        }
                    } else {
                        if (char == '"' || char == "'") {
                            inString = true;
                            quoteChar = char;
                            currentParam += char;
                        } else if (char == '[') {
                            inArray = true;
                            nestedCount++; 
                            currentParam += char;
                        } else if (char == ']') {
                            nestedCount--; 
                            currentParam += char;
                            if (nestedCount == 0) { 
                                paramArray.push(currentParam);
                                currentParam = ""; 
                                inArray = false;
                            }
                        } else if (char == ',' && !inArray) {
                            if (currentParam.length > 0) { // Добавить проверку
                                paramArray.push(currentParam);
                                currentParam = "";
                            }
                        } else {
                            currentParam += char;
                        }
                    }
                }

                if (currentParam.length > 0) {
                    paramArray.push(currentParam); 
                }

                for (var j:Number = 0; j < paramArray.length; j++) {
                    var param:String = paramArray[j];
                    var trimmedParam:String = param.split(' ').join('');
                    var value;
                    var type:String;

                    if (trimmedParam.charAt(0) == '"' || trimmedParam.charAt(0) == "'") {
                        value = param.substring(1, param.length - 1);
                        type = "string";
                    } else if (trimmedParam.toLowerCase() == "true" || trimmedParam.toLowerCase() == "false") {
                        value = (trimmedParam.toLowerCase() == "true");
                        type = "boolean";
                    } else if (!isNaN(Number(trimmedParam))) {
                        value = Number(trimmedParam);
                        type = "number";
                    } else if (trimmedParam.charAt(0) == '[') {
                        value = parseArray(param);
                        type = "array";
                    } else if (trimmedParam.indexOf('(') != -1 && trimmedParam.indexOf(')') != -1) {
                        value = param;
                        type = "function";
                    } else {
                        value = param;
                        type = "null";
                    }

                    result.param.push({ value: value, type: type });
                }
            }
        }

        return result;
    }

	/**
     * Trims leading and trailing whitespaces from the given string.
     * 
     * @param str The string to trim.
     * @return The trimmed string.
     */
    private static function trimString(str:String):String {
        var startIndex:Number = 0;
        var endIndex:Number = str.length - 1;
        
        while (str.charAt(startIndex) == " " || str.charAt(startIndex) == "\t" || str.charAt(startIndex) == "\n" || str.charAt(startIndex) == "\r") {
            startIndex++;
        }
        
        while (str.charAt(endIndex) == " " || str.charAt(endIndex) == "\t" || str.charAt(endIndex) == "\n" || str.charAt(endIndex) == "\r") {
            endIndex--;
        }
        
        if (endIndex >= startIndex) {
            return str.substring(startIndex, endIndex + 1);
        } else {
            return "";
        }
    }

	/**
     * Parses the input string representing an array into an array.
     * 
     * @param input The input string to parse.
     * @return The parsed array.
     */
    private static function parseArray(input:String):Array {
        var array:Array = [];
        var nestedCount:Number = 0;
        var current:String = "";

        for (var i:Number = 0; i < input.length; i++) {
            var char:String = input.charAt(i);
            if (char == '[') {
                nestedCount++;
                if (nestedCount > 1) {
                    current += char;
                }
            } else if (char == ']') {
                nestedCount--;
                if (nestedCount == 0) {
                    if (current.length > 0) {
                        array.push(parseParam(trimString(current)));
                    }
                    current = "";
                } else {
                    current += char;
                }
            } else if (char == ',' && nestedCount == 1) {
                array.push(parseParam(trimString(current)));
                current = "";
            } else {
                current += char;
            }
        }

        return array;
    }

	/**
     * Parses the input string representing a parameter into a value.
     * 
     * @param param The input string to parse.
     * @return The parsed value.
     */
    private static function parseParam(param:String) {
        var trimmedParam:String = param;
        var value;
        var type:String;

        if (trimmedParam.charAt(0) == '"' || trimmedParam.charAt(0) == "'") {
            value = param.substring(1, param.length - 1);
			/*
			if (param.value.charCodeAt(0) == 34) 
				value = param.value.substring(1, param.length);
			else 
				value = param.value
			*/	
            type = "string";
        } else if (trimmedParam.toLowerCase() == "true" || trimmedParam.toLowerCase() == "false") {
            value = (trimmedParam.toLowerCase() == "true");
            type = "boolean";
        } else if (!isNaN(Number(trimmedParam))) {
            value = Number(trimmedParam);
            type = "number";
        } else if (trimmedParam.charAt(0) == '[') {
            value = parseArray(param); 
            type = "array";
        } else if (trimmedParam.indexOf('(') != -1 && trimmedParam.indexOf(')') != -1) {
			trace(param);
            value = function() {
				evalCode(param);
			};
            type = "function";
        } else {
            value = param;
            type = "null";
        }

        return value;
    }
}
