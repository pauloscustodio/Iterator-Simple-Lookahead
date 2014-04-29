use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Iterator::Simple::Lookahead',
    VERSION_FROM      => 'lib/Iterator/Simple/Lookahead.pm',
    PREREQ_PM         => {
		'Class::XSAccessor'			=> 1.18,
		'Iterator::Simple'			=> 0.06,
        'Test::More' 				=> 0.98,	# needs done_testing()		
	},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Iterator/Simple/Lookahead.pm', # retrieve abstract from module
       AUTHOR         => 'Paulo Custodio <pscust@cpan.org>') : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => [ 'Iterator-Simple-Lookahead-*',
										'*.tmp',
										'*.bak',
									  ]
						   },
);
