use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
              'NAME'         => 'Devel::TraceLoad',
              'VERSION_FROM' => 'lib/Devel/TraceLoad.pm',
	      #'PREREQ_PM' => {},
	      'clean' => { FILES => 'err' },
	      'dist' => { 
		  COMPRESS => "gzip", 
		  SUFFIX => "gz",
	      },
	      'dist' => { 
		  COMPRESS => "c:/Program Files/WinZip/WINZIP32.EXE", 
		  SUFFIX => "" ,
	      }
             );
