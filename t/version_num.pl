# perl -Ilib -MDevel::TraceLoad t/version_num.pl
require v5.5.0;
require 5.6.0;
require 5.005_03;
use lib t;
use Data::Bar 1.0;
my $version = 'v5.5.1';
require $version;

