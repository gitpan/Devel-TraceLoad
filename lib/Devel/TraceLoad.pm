#use warnings;
#use strict;
package Devel::TraceLoad;
use vars qw($VERSION);
$VERSION = 0.05;
sub trace;
my $pkg = __PACKAGE__;
my @info;
my $outfh;
my $indent;
my $filter = '[.](al|ix)';
# please, define the separator of your platform and send me a mail
my $dirsep = { MSWin32 => '/', }->{$^O} || '/';
my %opts = (
	    after => 0,
	    all => 0,
	    flat => 0,
	    pretty => 0,
	    noversion => 0,
	    path => 0,
	    stdout => 0,
	    sort => 0,
	    test => 0, # compare with the native require()
	    trace => 0,
	    );
sub import {
    shift;
    $opts{$_} = 1 foreach @_;
    $outfh = $opts{stdout} ? *STDOUT : *STDERR;
    $opts{after} = 1 if $opts{sort};
    $opts{after} = 1 if $opts{test};

    *trace = $opts{trace} ? sub {print STDERR "@_\n"} : sub {};
    trace "Definition of ", __PACKAGE__;
    $indent = $opts{flat} ? '' : '   ';
    if ($opts{all}) {
	print $outfh join("\n\t", "Already loaded:", keys %INC) . "\n";
    }
}
BEGIN {
    my $level = -1;
    my $prefix = '';
    *CORE::GLOBAL::require = sub (*) {
	trace "require's args: @_";
	my ($arg, $isnvar, $isquoted, $rstatus);
	unless (@_) {
	    $arg = $_;
	    $isnvar = 0;
	} else {
	    local $@;
	    $arg = $_[0];
	    eval { $_[0] = $arg }; # doesn't work with require "string$var"
	    $isnvar =  $@ ? 1 : 0;
	    $isquoted = $@ ? $isquoted : 0;
	}
	if ($isnvar) { # convert chars in number if necessary
	    trace "arg isn't var";
	    unless ($arg =~ /^[A-Za-z\d_]/) { # certainly a version number
                $arg = join '.', map { ord } split //, $arg;
		trace "Convert char to number: $arg";
	    }
	} else {
	    trace "arg is a var";
	}
	# version number
	if ($isnvar and $arg =~ /^v?(\d[\d._]*)$/) {
	    trace "Required version: $1";
	    #local $@;
	    $rstatus = eval qq!return CORE::require $arg!;
	    if ($@) {
		die $@;
	    }
	    trace "status: $rstatus";
	    return $rstatus;
	} else {
	    if ($isnvar) { 
		my $mod = $arg;
		unless (defined $isquoted) {
		    trace "\$quote not yet defined!";
		    # certainly a quoted string (like: 'Bar.pm')
		    if ($mod =~ /[.]p[lm]$/ or $mod =~ /$dirsep/o) {
			$isquoted = 1;
		    } else {
			$isquoted = 0;
		    }
		}
		unless ($isquoted) {
		    $mod =~ s{::}{$dirsep}g;
		    $mod .= ".pm";
		}
		trace "Module file: $mod";

		unless ($opts{flat}) {
		    $prefix = $INC{$mod} ? '.' : '+';
		} else {
		    $prefix = '';
		}
		return 1 if $INC{$mod} && $opts{flat};
	    }
	    $level++ unless $opts{flat};
	    unless ($opts{after}) {
		print $outfh $indent x $level, "$prefix$arg";
		print $outfh $indent x $level, " [from: ", join(" ", (caller())[1,2]), "]\n";
	    } else {
		push @info, [$arg => $level]
	    }
	    my $rstatus;
	    if ($isnvar) { # argument isn't a var
		#local $@;
		if ($isquoted) {
		    trace "quoted!";
		    $rstatus = eval "return CORE::require '$arg'";
		} else {
		    trace "unquoted $arg!";
		    $rstatus = eval "return CORE::require $arg";
		    if ($@ =~ /^Can\'t locate/) {
			if ($opts{try}) {
			    trace "try";
			    $rstatus = eval "return CORE::require '$arg'";
			}
		    } else {
		    }
		}
		if ($@) { # recontextualize
		    trace "$@";
		    pop @info if $opts{after};
		    $level-- unless $opts{flat};
		    $@ =~ s/at \(eval \d+\) line \d+/
			sprintf "at %s line %d",(caller())[1,2]/e;
		    die $@;
		}
	    } else {
		eval {
		    $rstatus = CORE::require $arg;
		};
		if ($@) { # recontextualize
		    trace "$@";
		    pop @info if $opts{after};
		    $level-- unless $opts{flat};
		    $@ =~ s/at .+ line \d+/
			sprintf "at %s line %d",(caller())[1,2]/e;
		    die $@;
		}
	    }
	    $level-- unless $opts{flat};
	    trace "status: $rstatus";
	    return $rstatus;
	}
    };
}

END {
    trace "END block";
    return unless $opts{after};
    return if $opts{test};
    my ($mod, $level, $inc, $path, $version);
    #while (my($k, $v) = each %INC) { trace "$k -> $v"; }
    foreach (@info) {
	$mod = $_->[0];
	trace "mod: $mod";
	if ($mod =~ /$filter/o or $mod eq __PACKAGE__) {
	    $_->[0] = '';
	    next;
	}
	$inc = $mod;
	if ($mod =~ s![.]pm$!!) {
	    $mod =~ s!$dirsep!::!g;
	} else {
	    $inc =~ s!::!$dirsep!g;
	    $inc .= ".pm";
	}
	$version = $opts{noversion} ? '' : $ { "$mod\::VERSION" } || 
	    '(no version number)';
	$path = $INC{$inc};
	push @$_, $path, $version;
    }
    if ($opts{sort}) {
	$opts{flat} = 1;
	$indent = $opts{flat} ? '' : '   ';
	my %dejavu;
	if ($opts{path}) {
	    @info = sort { $a->[2] cmp $b->[2] } grep {!$dejavu{$_->[2]}++} @info;
	} else {
	    @info = sort { $a->[0] cmp $b->[0] } grep {!$dejavu{$_->[0]}++} @info;
	}
    }
    print $outfh "=" x 80, "\n" if $opts{pretty};
    foreach (@info) {
	($mod, $level, $path, $version) = @$_;
	next unless $mod;
	if ($opts{path}) {
	    print $outfh $indent x $level . "$path\n";
	} else {
	    print $outfh $indent x $level . "$mod $version\n";
	}
    }
    print $outfh "=" x 80, "\n" if $opts{pretty};
}
sub DB::DB {
    if ($opts{stop}) {
	trace "STOP";
	exit;
    }
}
1;
__END__

=head1 NAME

Devel::TraceLoad - Trace loadings of Perl Programs

    # with perldb
    perl -d:TraceLoad script.pl

    # without perldb
    perl -MDevel::TraceLoad script.pl

    # without perldb and with options
    perl -MDevel::TraceLoad=after,path script.pl

    # with perldb and options
    perl -d:TraceLoad -MDevel::TraceLoad=stop,after,path script.pl

=head1 DESCRIPTION

The module B<Devel::TraceLoad> traces the B<require()>
and the B<use()> appearing in a program.  The trace makes it
possible to know the dependencies of a program with respect to other
programs and in particular of the modules.

The generated report can be obtained in various forms.  The loadings are
indicated in the order in which they are carried out.  The trace can be
obtained either during the execution of the loadings or the end of the
execution.  By default, the trace is generated during the execution and the
overlaps of loadings are marked by indentations.  All the B<require()> are
indicated, even if it is about a B<require()> of a program already charged.
A B<+> indicates that the program is charged for the first time.  A B<.>
indicates that the program was already charged.

When the trace is differed, the number of version of the modules is
indicated.  A differed trace can be sorted and if it is wished the
names of the modules can be replaced by the absolute name of
the files.

The module is close to B<Devel::Modlist> but uses a redefinition of
B<require()> instead of exploiting B<%INC>.  In a will of homogeneity the
module also borrows many things from B<Devel::Modlist>.

=head1 USE

B<Devel::TraceLoad> can be used with or without perldb:

    perl -d:TraceLoad script.pl

    perl -MDevel::TraceLoad script.pl

For the majority of the uses the two possibilities are
equivalent.

=head1 OPTIONS

To pass from the options to the module B<Devel::TraceLoad>
one will write:

    perl -MDevel::TraceLoad=option1[,option2,...]

With this writing the option B<stop> is not taken into
account.  So that B<stop> is taken into account one will write:

    perl -d:TraceLoad -MDevel::TraceLoad=option1[,option2,...]

=over

=item after

The trace is given at the end of the execution.

=item flat

Removes the indentations which indicate nestings of B<require()>.

=item noversion

Removes the indication of version of the necessary modules.

=item path

Indicates the absolute names of the files corresponding to the
modules charged instead of names with modules.

This option functions only when the trace is produced at the end
of the execution, i.e. in the presence of the option B<after>.

=item sort

The trace is provided at the end of the execution and gives a
list sorted alphabetically on the names of module or the paths.

=item stdout

Redirect the trace towards B<STDOUT>. By defect the trace
is redirected towards B<STDERR>.

=item stop

Stop the program before the first of the program is not
carried out if the execution with place with perldb.  Does not allow
to see the loadings carried out by the B<require()> and the
loadings which are in a B<eval()>.

=item try

If the execution fails with the message C<Can' T locate Bar.pm in @INC... >
and that you are sure of your code, use the option B<try>. This option
activates heuristics to compensate for the fact that it is not possible to
know if the argument of a c<require() > is placed between quotation marks
or not (I am mistaken?).  To try to determine it we use heuristics which
consists, amongst other things, to consider that the argument is placed
between quotation marks if it is not suffixed by ".pl" or ".pm".

=back

=head1 BUG

Some modules and pragmas are loaded because of the presence
with B<-MDevel::TraceLoad>. These modules do not appear in the
trace (with the version of Perl on which we made our tests the modules
concerned are Exporter.pm Carp.pm vars.pm warnings::register.pm
Devel::TraceLoad.pm warnings.pm).

=head1 AUTHOR

Philippe Verdret < pverdret@dalet.com >, on the basis of idea of
Joshua Pritikin < vishnu@pobox.com >.

the English version of documentation is produced from a machine
translation carried out by C<babel.altavista.com>.

=HEAD1 SEE ALSO

B<Devel::Modlist>.

=cut

