package Devel::TraceLoad;
$VERSION = '0.01';

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
	    Carp::carp "require $m";
	    require $m;
	}
    };
}

1;
