module cmsed.base.internal.generators.js.routes.defs;
//import cmsed.base.internal.generators.js.routes.generate;
import cmsed.base.internal.generators.js.defs;
import cmsed.base.internal.registration.staticfiles;
import cmsed.base.registration.onload;
import cmsed.base.internal.restful.defs;
import dvorm.util;
import std.traits : isBasicType, isBoolean;
import std.functional : toDelegate;

struct GenerateData {
	string ret;
}

struct shouldNotGenerateJavascriptRoute {}
struct ignoreGenerateJavascriptRoute {}

/**
 * Properties
 */

protected shared {
	string pathToRouteClasses = "/js/routes/";
	
	alias string delegate() modelBindingGetFunc;
	modelBindingGetFunc[string] bindingFuncs;
	
	bool disableGeneration = false;
	string pathToRestfulRoute = "/.svc/";
}

void pathOfRouteClasses(string path) {
	synchronized {
		pathToRouteClasses = path;
	}
}

void pathOfLibraries(string path) {
	synchronized {
		pathToLibraries = path;
	}
}

void disableJavascriptGeneration() {
	synchronized {
		disableGeneration = true;
	}
}

void pathOfRestfulRoute(string path) {
	synchronized {
		pathToRestfulRoute = path;
	}
}

/**
 * functions
 */

/**
 * Creates a javascript model from a data model
 * 
 * Compliant with a dvorm data model.
 * Wraps a dvorm query and hooking it via ajax.
 * 
 * Params:
 * 		T = 				The data model to be based upon
 * 		ajaxProtection = 	The restful protection to work with for generation
 * 		overrideChecks = 	Forces the generation of this model. Meant for manual generation
 */
void generateJavascriptModel(T, ushort ajaxProtection = RestfulProtection.All, bool overrideChecks = false)() {
	synchronized {
		static if (overrideChecks) {
			bindingFuncs[getTableName!T] = toDelegate(cast(shared)&(generateJsFunc!(T, ajaxProtection)));
		} else static if (shouldGenerateJavascriptModel!T) {
			if (!disableGeneration) {
				bindingFuncs[getTableName!T] = toDelegate(cast(shared)&(generateJsFunc!(T, ajaxProtection)));
			}
		}
	}
}

pure bool shouldGenerateJavascriptRoute(T)() {
	foreach(UDA; __traits(getAttributes, T)) {
		static if (is(UDA == shouldNotGenerateJavascriptRoute)) {
			return false;
		}
	}
	return true;
}

pure bool shouldIgnoreGenerateJavascriptRoute(T, string m)() {
	T c = newValueOfType!T;
	
	static if (__traits(compiles, __traits(getProtection, mixin("c." ~ m))) &&
	           __traits(getProtection, mixin("c." ~ m)) == "public") {
		foreach(UDA; __traits(getAttributes, mixin("c." ~ m))) {
			static if (is(UDA : ignoreGenerateJavascriptRoute)) {
				return true;
			}
		}
		return false;
	} else {
		return true;
	}
}

shared static this() {
	void jsRoutes(bool isInstall) {
		foreach(name, value; bindingFuncs) {
			registerStaticFile(pathToRouteClasses ~ name, value(), "javascript");
		}
	}
	
	registerOnLoad(&jsRoutes);
}