# Examples: 
# make test TEST_FILES=t/test3.t TEST_VERBOSE=2
# verbose levels:
# 1 : print configuration and major operations
# 2 : more details
# 3 : print the execution result

require 5.004;
use strict;
package W;			# Test::Wrapper
use vars qw($VERBOSE $LOG);
$W::VERSION = '1.2';
$W::VERBOSE = $ENV{TEST_VERBOSE} || 0;
$W::LOG = $ENV{TEST_LOG} ? 'testlog' : 0;

if ($LOG) {
  if (open(LOG, ">>$LOG")) {
    print STDERR "see informations in the '$LOG' file\n";
  } else {
    warn "unable to open '$LOG' ($!)";
    $LOG = '';
  }
} 
sub new {
  my $self = shift;
  my $class = ref $self || $self;
  my $param = shift;
  my $range = '';
  if (defined $param) {
      unless (ref($param) eq 'HASH') {
	  $param = { 
	      Range => $param,
	      PerlOpts => @_ ? shift : '',
	  };
      } 
  } else { # defaults
      $param = { 
	  Range => '1..1',
	  PerlOpts => '',
      };
  }
  print "\n";
  print "Verbosity level: $VERBOSE\n" if $VERBOSE;
  print "$param->{Range}\n";
  print "Program to test: $param->{Program}\n" if $VERBOSE;
  print "Perl Options: $param->{PerlOpts}\n" if $VERBOSE;
  bless $param, $class;
}
sub result {
  my $self = shift;
  my $cmd = shift;
  my @result;
  my @err;
  my $result;
  if ($cmd) {
    my $popts = $self->{PerlOpts};
    print "Execution of: $^X $popts $cmd\n" if $VERBOSE;
    die "unable to find '$cmd'" unless -f $cmd;
    # the following line doesn't work on Win95 (ActiveState's Perl, build 516):
    # open( CMD, "$^X $cmd 2>err |" ) or warn "$0: Can't run. $!\n";
    # corrected by Stefan Becker:
    local *SAVED_STDERR;
    #local $| = 1;
    open( SAVED_STDERR, ">&STDERR" );
    open( STDERR, "> err" ) or warn "$0: can't open 'err'";
    open( CMD, "$^X $popts $cmd |" ) or warn "$0: Can't run '$^X $popts $cmd' ($!)\n";
    @result = <CMD>;
    close CMD;
    close STDERR;
    open(STDERR, ">&SAVED_STDERR");

    if (open( CMD, "< err" )) {
	@err = <CMD>;
	close CMD;
    } else {
	warn "$0: Can't open 'err' ($!)\n";
    }

    push @result, @err if @err;

    $self->{Result} = join('', @result);
    if ($LOG) {
      print LOG "=" x 80, "\n";
      print LOG "Execution of $^X $popts $cmd 2>err\n";
      print LOG "=" x 80, "\n";
      print LOG "* Result:\n";
      print LOG "-" x 80, "\n";
      print LOG $self->{Result};
    }
    if ($VERBOSE > 2) {
	print $self->{Result};
    }
  } else {
    $self->{Result};
  }
}
sub expected {
  my $self = shift;
  my $ref = shift;
  if ($ref) {
      if (fileno $ref) {
	  $self->{Expected} = join('', <$ref>);
      } else {
	  $self->{Expected} = $ref;
      }
      if ($LOG) {
	  print LOG "-" x 80, "\n";
	  print LOG "* Expected:\n";
	  print LOG "-" x 80, "\n";
	  print LOG $self->{Expected};
      }
  } else {
    $self->{Expected};
  }
}
sub assert {
  my $self = shift;
  my $onwhat = shift;
  my $regexp = @_ ? shift : die "regexp not defined\n";
  if ($self->{$onwhat} !~ /$regexp/) {
    die "'$regexp' doesn't match $onwhat string";
  }
}
sub report {			
  my $self = shift;
  my $label = shift;
  my $sub = shift;
  unless (ref $sub eq 'CODE') {
      die "'$sub' not a coderef";
  }
  my $s = $self->$sub(@_);
  $s ? "ok $label\n" : "not ok $label\n";
}

my $delim_start = ">>>>\n";
my $delim_end = "\n<<<<";

# W->new()->detector("abc", "acv");
sub detector {
    my $self = shift;
    my $s1 = shift;
    my $s2 = shift;
    print "-----------$s1\n$s2----------";
    my ($c1, $c2);
    my $l = 1;
    while ( ($s1 =~ /(.)/gc) or (($s1 =~ /(.)/gs) and $l++) ) {
	$c1 = $1;
	$s2 =~ /(.)/gs;
	$c2 = $1;
	print "$c1$c2";
	unless ($c1 eq $c2) {
	    print STDERR "At line: $l\n";
	    print STDERR ">>>", substr($s1, pos($s1) - 1, 20), "\n";
	    print STDERR ">>>", substr($s2, pos($s2) - 1, 20), "\n";
	    return 1;
	}
    }
    return 0;
}
sub comparator { 
    my $self = shift;
    my $detector = @_ && defined $_[0] ? shift : $self->can('detector'); 
    my $red = @_ ? shift : '\s+$'; # edit the result
    my $eed = @_ ? shift : '\s+$'; # edit the reference

    my $expected = $self->expected;
    my $result = $self->result;
    # could be a specific editor
    $expected =~ s/$eed/(...deleted...)/g;
    $result =~ s/$red/(...deleted...)/g;
    if ($VERBOSE) {
	print STDERR "\n";
	print STDERR ">>>Expected:\n$expected\n";
	print STDERR ">>>Effective:\n$result\n";
    }
    unless ($expected eq $result) {
	print STDERR "not equals\n" if $VERBOSE;
	if ($VERBOSE >= 2 and defined $detector) {
	    print STDERR "Difference between expected and effective result: \n";
	    $self -> $detector($expected, $result);
	} elsif ($VERBOSE) {
	}
	0;
    } else {
	print STDERR "equals\n" if $VERBOSE;
	1;
    }
}
# todo: defined named parameters
sub test {
  my $self = shift;
  my $label = @_ ? shift : 1;	# specific label for the test
  my $prog_to_test = @_ ? shift : undef; # filename of the program to test
  my $reference = @_ ? shift : undef;	# string or filehandle
  my $comparator = @_ ? shift : undef; # sub, compare result with a ref and say yes or no
  my $detector = @_ ? shift : undef; # sub, localize the first difference
  my $r_ed = @_ ? shift : ''; # regexp for editing the effective result
  my $e_ed = @_ ? shift : ''; # regexp for editing the expected result

  $self->result("$prog_to_test") if defined $prog_to_test;
  $self->expected($reference) if defined $reference;

  $comparator = $self->can('comparator') unless defined $comparator;
  $detector = $self->can('detector') unless defined $detector;
  $self->report($label, $comparator, $detector, $r_ed, $e_ed);
}

"End of Package"

