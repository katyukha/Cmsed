import io = std.stdio;

import std.file;
import std.string;
import std.traits : isBasicType;
import std.array;

void main(string[] args) {
	string moduleName;
	string fileName;
	if (args.length == 2) {
		moduleName = args[1];
		ptrdiff_t lio = moduleName.lastIndexOf(".");
		if (lio > 0 && lio + 1 < moduleName.length) {
			fileName = moduleName[lio + 1 .. $] ~ ".d";
		} else if (lio == -1) {
			fileName = moduleName ~ ".d";
		}
	} else {
		io.writeln("You can specify a module name to generate with");
		io.writeln("Syntax: rdmd generator <moduleName>");
		return;
	}
	
	string names;
	string values;
	string extensions;
	string extensionNames;
	names ~= "immutable mimeTypes = [\n";
	values ~= "immutable mimeTemplates = [\n";
	extensionNames ~= "immutable mimeExtensionNames = [\n";
	extensions ~= "immutable mimeExtensions = [\n";
	
	foreach (file; ["application", "audio", "image", "model", "multipart", "text", "video"]) {
		foreach(i, string line; readText(file ~ ".csv").splitLines()) {
			if (i == 0) continue;
			
			string[] items = line.split(",");
			if (items.length >= 2) {
				names ~= "    \"" ~ items[0] ~ "\",\n";
				if (items[1] !is null && items[1] != "")
					values ~= "    \"" ~ items[1] ~ "\",\n";
				else
					values ~= "    \"" ~ file ~ "/" ~ items[0] ~ "\",\n";
			}
		}
	}
	
	foreach(i, string line; readText("extensionNames.csv").splitLines()) {
		if (i == 0) continue;
		
		string[] items = line.split(",");
		if (items.length >= 2) {
			foreach(value; items[1 .. $]) {
				extensionNames ~= "    \"" ~ items[0] ~ "\",\n";
				extensions ~= "    \"" ~ value ~ "\",\n";
			}
		}
	}
	
	names.length -= 2;
	values.length -= 2;
	extensionNames.length -= 2;
	extensions.length -= 2;
	
	names ~= "\n";
	values ~= "\n";
	extensionNames ~= "\n";
	extensions ~= "\n";
	
	names ~= "];";
	values ~= "];";
	extensionNames ~= "];";
	extensions ~= "];";
	
	string funcs = """
pure string getTemplateForType(string type) {
    foreach(i, mt; mimeTypes) {
        if (mt == type) {
            return mimeTemplates[i];
        }
    }

    return null;
}

pure string getNameFromExtension(string name) {
	foreach(i, mt; mimeExtensions) {
        if (mt == name) {
            return mimeExtensionNames[i];
        }
    }

    return getTemplateForType(name);
}
""";
	
	write(fileName,
		"module " ~ moduleName ~ ";\n" ~
		funcs ~ "\n" ~
		names ~ "\n" ~
		values ~ "\n" ~
		extensionNames ~ "\n" ~
		extensions ~ "\n");
}