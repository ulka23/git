@ optint @
identifier opts;
type T;
T var;
expression SHORT, LONG, HELP;
position p;
@@
struct option opts[] = { ..., OPT_INTEGER(SHORT, LONG, &var@p, HELP), ...};

@ script:python @
p << optint.p;
var << optint.var;
vartype << optint.T;
@@
if vartype != "int":
	print "potential error at %s:%s:%s:" % (p[0].file, p[0].line, p[0].column)
	print "  passing variable '%s' of type '%s' to OPT_INTEGER" % (var, vartype)
	print "  OPT_INTEGER expects an int"
