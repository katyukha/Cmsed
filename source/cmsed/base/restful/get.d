module cmsed.base.restful.get;
import cmsed.base.restful.defs;
import cmsed.base.routing;
import vibe.data.json;
import dvorm;
import std.traits : moduleName;

pure string getRestfulData(TYPE)() {
	string ret;
	TYPE type = new TYPE;
	
	ret ~= """
#line 1 \"cmsed.base.restful.get." ~ TYPE.stringof ~ "\"
@RouteFunction(RouteType.Get, \"/" ~ getTableName!TYPE ~ "/:key\")
void handleRestfulData" ~ TYPE.stringof ~ "Get() {
    import " ~ moduleName!TYPE ~ ";
    auto value = " ~ TYPE.stringof ~ ".findOne(http_request.params[\"key\"]);
    if (value !is null) {
        """;
	static if (__traits(hasMember, TYPE, "canView") && typeof(&type.canView).stringof == "bool delegate()") {
		ret ~= "if (value.canView()) {";
	} else {
		ret ~= "if (true) {";
	}
	ret ~= "
	    Json output = Json.emptyObject;\n";
	foreach (m; __traits(allMembers, TYPE)) {
		static if (isUsable!(TYPE, m)() && !shouldBeIgnored!(TYPE, m)()) {
			ret ~= "            output[\"" ~ m ~ "\"] = outputRestfulTypeJson!(" ~ TYPE.stringof ~ ", \"" ~ m ~ "\")(value);\n";
		}
	}
	ret ~= """
            http_response.writeBody(output.toString());
        }
    }
}
""";
	return ret;
}

Json outputRestfulTypeJson(TYPE, string m)(TYPE value) {
	Json output = Json.emptyObject();
	
	static if (is(typeof(__traits(getMember, value, m)) : Object)) {
		static if (isUsable!(TYPE, m) && !shouldBeIgnored!(TYPE, m)) {
			foreach (n; __traits(allMembers, typeof(__traits(getMember, value, m)))) {
				static if (isUsable!(typeof(__traits(getMember, value, m)), n) && isAnId!(typeof(__traits(getMember, value, m)), n)) {
					output[n] = mixin("value." ~ m ~ "." ~ n);
				}
			}
		}
	} else static if ((is(typeof(__traits(getMember, value, m)) == string) ||
	                   is(typeof(__traits(getMember, value, m)) == dstring) ||
	                   is(typeof(__traits(getMember, value, m)) == wstring)) ||
	                  typeof(__traits(getMember, value, m)).stringof != "void") {
		output = __traits(getMember, value, m);
	}
	
	return output;
}