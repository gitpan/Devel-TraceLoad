#!/usr/local/bin/perl
# usage examples from the root dir:
# nmake test TEST_FILES=t/all.t TEST_CMD=t/t1.pl TEST_VERBOSE=1 TEST_SAVE=1 TEST_TRACE=1
# perl -It -Ilib -MDevel::TraceLoad t/version_num.pl

use strict;
use warnings;
BEGIN { push @INC, './t' }	# where is W.pm
use W;

my $TRACE = $ENV{TEST_TRACE};
sub trace {return unless $TRACE ; print STDERR "@_\n"}
trace;

my @tests = defined($ENV{TEST_CMD}) && $ENV{TEST_CMD} ne ''? ($ENV{TEST_CMD}) : ();
@tests = <t/*.pl> unless @tests;
unless (@tests) {
    die "no file to test";
}
trace "test files: @tests";

my $t = 0;
my $num = @tests;
trace "Total number of tests: $num";

#perl -MDevel::TraceLoad=after,path script.pl
# if some options are needed:
my %PerlOpts = (
		Default => '-MDevel::TraceLoad',
		'' => '',
		);
my $test = '';
foreach my $prog (@tests) {
    unless (-s $prog) {
	warn "'$prog' not a program";
	next;
    }
    $test = W->new({
	Program => $prog,
	Range => ++$t . ".." . $num,
	PerlOpts => $PerlOpts{$prog} || $PerlOpts{Default}
	});
    $test->result($prog);
    my $file = $prog;
    $file =~ s![.](pl|t)!.ref!;
    if ($ENV{TEST_SAVE}) { # save the result in a file.ref
	print STDERR "\n";
	print STDERR "Save execution result of '$prog'\n";
	print STDERR "\n";
	print STDERR $test->result;
	open OUT, "> $file" or die "$!";
	print OUT $test->result;
	print "ok result saved";
    } else {
	if (-s $file) {
	    open my $result, "$file" or die "can't open '$file' ($!)";
	    $test->expected($result);
	    print $test->test($t, undef, undef, undef, undef, 'in @INC.*', 'in @INC.*');
	}
    }
}
