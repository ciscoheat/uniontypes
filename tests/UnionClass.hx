enum UnionClassType {
	Null;
	String(s : String);
	Integer(i : Int);
	Date(d : Date);
	Boolean(b : Bool);
	Floating(f : Float);
}

abstract UnionClass(Dynamic) from String from Int from Date from Bool from Float {
	public function type() : UnionClassType {
		return if(this == null) 
			Null
		else if(Std.isOfType(this, std.String))
			String(cast this)
		else if(Std.isOfType(this, std.Date))
			Date(cast this)
		else if(Std.isOfType(this, Bool))
			Boolean(cast this)
		else if(Std.isOfType(this, Int))
			Integer(cast this) // Must be before Floating!
		else
			Floating(cast this);
	}
}