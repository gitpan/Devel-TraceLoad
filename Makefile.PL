use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
              'NAME'         => 'Devel::TraceLoad',
              'VERSION_FROM' => 'TraceLoad.pm', 
	      #'PREREQ_PM' => {},
	      #'clean' => { FILES => '' },
	      #'dist' => { COMPRESS => "gzip", SUFFIX => "gz" }
             );
