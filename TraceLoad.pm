package Devel::TraceLoad;
$VERSION = '0.02';

BEGIN {
    require 5.00556;
    require Carp;
    *CORE::GLOBAL::require = sub (*) {
	my $m = $_[0];
	if ($m =~ m/^[\d.]+$/) {
	    $m <= $[;
	} else {
	    if ($m !~ m/\.pm$/) {
		$m =~ s,::,/,g;
		$m .= '.pm';
	    }
	    return 1 if $INC{$m};
	    require $m;
	    Carp::carp "require $m via $INC{$m}";
	}
    };
}

1;
