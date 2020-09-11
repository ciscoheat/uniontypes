enum UnionClassType {
	Null;
	String(s : String);
	Int(i : Int);
	Date(d : Date);
	Bool(b : Bool);
    Float(f : Float);
    //Unknown(d : Dynamic);
}

abstract UnionClass(Dynamic) from String from Int from Date from Bool from Float {
	public function type() : UnionClassType {
		return if(this == null) 
			Null
		else if(Std.isOfType(this, std.String))
			String(cast this)
		else if(Std.isOfType(this, std.Date))
			Date(cast this)
		else if(Std.isOfType(this, StdTypes.Bool))
			Bool(cast this)
		else if(Std.isOfType(this, StdTypes.Int))
			Int(cast this) // Must be before Floating!
		else //if(Std.isOfType(this, Float))
            Float(cast this);
        //else
        //    Unknown(this);
	}
}