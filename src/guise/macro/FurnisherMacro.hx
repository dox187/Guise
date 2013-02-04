package guise.macro;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Tools;

class FurnisherMacro 
{

	@:macro public static function path(within:Expr,path:String):Expr {
		return interpXmlFile(within, path);
	}
	@:macro public static function trace(e:Expr):Expr {
		trace(e);
		return e;
	}
	
	#if macro
	
	private static function interpXmlFile(within:Expr, path:String):Expr {
		var content = sys.io.File.getContent(path);
		return interpXml(within, Xml.parse(content).firstElement());
	}
	
	private static function interpXml(within:Expr, xml:Xml):Expr {
		var pos = Context.currentPos();
		
		var exprs:Array<Expr> = [];
		for (child in xml.elements()) {
			switch(child.nodeName) {
				case "tag": interpTag(within, child, exprs);
				default: // ignore
			}
		}
		
		return {expr:EBlock(exprs), pos:pos};
	}
	private static function interpTag(within:Expr, tag:Xml, addTo:Array<Expr>):Void {
		var pos = Context.currentPos();
		
		var type:String = tag.get("type");
		
		var checkEnumParams:Array<Int>;
		
		var handleType:String;
		if (tag.get("isEnum") == "true") {
			handleType = type.substr(0, type.lastIndexOf("."));
			
			var checkEnumParamsStr:String = tag.get("checkEnumParams");
			if (checkEnumParamsStr != null && checkEnumParamsStr.length > 0) {
				var checkStrs = checkEnumParamsStr.split(",");
				checkEnumParams = [];
				for (enumIndex in checkStrs) {
					checkEnumParams.push(Std.parseInt(enumIndex));
				}
			}
		}else {
			handleType = type;
		}
		
		var catchType:Expr = createIdent(type);
		var handleType:ComplexType = createComplexType(handleType);
		
		var furnish:Array<Expr> = [];
		
		var natExpr = getNaturesExpr(tag.get("natures"));
		if (natExpr != null) {
			furnish.push(natExpr);
		}
		
		for (child in tag.elements()) {
			switch(child.nodeName) {
				case "layer": interpLayer(child, furnish);
				case "add": addTrait(child, furnish);
			}
		}
		
		var siblE = Context.makeExpr(tag.get("sibl") != "false", pos);
		var descE = Context.makeExpr(tag.get("desc") != "false", pos);
		var ascE  = Context.makeExpr(tag.get("asc")  == "true", pos);
		var checkEnumParamsE  = Context.makeExpr(checkEnumParams, pos);
		
		if(furnish.length>0){
			var furnishE = { expr : EArrayDecl(furnish), pos : pos };
			addTo.push(macro $within.addTrait(new composure.utilTraits.Furnisher($catchType, $furnishE, null, $siblE, $descE, $ascE, $checkEnumParamsE)));
		}
	}
	private static function addTrait(tag:Xml, addTo:Array<Expr>):Void {
		var pos = Context.currentPos();
		var rules:Array<Expr> = [];
		for (child in tag.elements()) {
			switch(child.nodeName) {
				case "rule": addRule(child, rules);
			}
		}
		
		var ruleE = { expr : EArrayDecl(rules), pos : pos };
		
		var type = tag.get("type");
		var e = tag.get("e");
		if (type != null && type.length > 0 && e != null && e.length > 0) {
			var typeE = createIdent(type);
			var expr = createIdent(e);
			addTo.push( { expr:ECall(typeE, [expr, ruleE]), pos:pos } );
		}
	}
	private static function addRule(tag:Xml, addTo:Array<Expr>):Void {
		var pos = Context.currentPos();
		var type = tag.get("type");
		var e = tag.get("e");
		if (type != null && type.length > 0 && e != null && e.length > 0) {
			var typeE = createIdent(type);
			var expr = createIdent(e);
			addTo.push( { expr:ECall(typeE, [expr]), pos:pos } );
		}
	}
	private static function interpLayer(tag:Xml, addTo:Array<Expr>):Void {
		var natExpr = getNaturesExpr(tag.get("natures"), tag.get("name"));
		if (natExpr != null) {
			addTo.push(natExpr);
		}
	}
	private static function getNaturesExpr(natStr:String, ?layerName:String):Null<Expr>{
		var pos = Context.currentPos();
		
		if(natStr!=null && natStr.length>0){
			var natArr:Array<Expr> = [];
			var natures:Array<String> = natStr.split(",");
			
			for (naturePath in natures) {
				natArr.push(createIdent(naturePath));
			}
			var nameExpr = Context.makeExpr(layerName, pos);
			var natureExpr:Expr = { expr : EArrayDecl(natArr), pos:pos };
			return macro TInst(new guise.layer.LayerAccessRequire($nameExpr, $natureExpr));
		}else {
			return null;
		}
	}
	private static function createComplexType(typePath:String):ComplexType {
		var parts = typePath.split(".");
		return  TPath( { name : parts.pop(), pack : parts, params : [], sub : null } );
	}
	private static function createIdent(typePath:String):Expr {
		var pos = Context.currentPos();
		
		if ((typePath.charAt(0) == "'" && typePath.charAt(typePath.length - 1) == "'") || 
			(typePath.charAt(0) == '"' && typePath.charAt(typePath.length - 1) == '"')) {
				
			return { expr : EConst(CString(typePath.substring(1, typePath.length-1))), pos:pos };
		}
		var bracket = typePath.indexOf("(");
		var paramsE:Array<Expr>;
		if (bracket != -1) {
			var paramsStr = typePath.substring(bracket + 1, typePath.length - 1);
			typePath = typePath.substr(0, bracket);
			paramsE = [];
			if(paramsStr.length>0){
				var params = paramsStr.split(",");
				for (param in params) {
					paramsE.push(createIdent(param));
				}
		}
		}else {
			paramsE = null;
		}
		var parts = typePath.split(".");
		var ret:Expr;
		for (part in parts) {
			if (ret == null) {
				ret = { expr : EConst(CIdent(part)), pos:pos };
			}else {
				ret = { expr : EField( ret, part), pos : pos };
			}
		}
		if (paramsE != null) {
			return { expr:ECall(ret, paramsE), pos:pos };
		}else{
			return ret;
		}
	}
	
	#end
}