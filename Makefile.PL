use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
              'NAME'         => 'Devel::TraceLoad',
              'VERSION_FROM' => 'Devel/TraceLoad.pm',
	      #'PREREQ_PM' => {},
	      #'clean' => { FILES => '' },
	      # how to use the winzip tool here?
	      #'dist' => { COMPRESS => "gzip", SUFFIX => "gz" }
             );
