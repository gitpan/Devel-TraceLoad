# perl -MDevel::TraceLoad=test
#print STDERR "$Devel::TraceLoad::VERSION\n";

my $ext = '.pl';
require "t/data/toload$ext";
require 't/data/toload.pl';
require "t/data/toload.pl";

eval {
    require Some::Thing; # doesn't exist
    print STDERR "PROBLEM! after     require Some::Thing;\n";
};
print "$@" if $@;
eval {
    require 't/data/toload'; # doen't exist
    print "PROBLEM! after require 't/data/toload';\n"
};
print "$@" if $@;
eval {
    require 'nothing'; # doesn't exist
    print "PROBLEM! after require 'nothing';\n"
};
print "$@" if $@;

__END__
