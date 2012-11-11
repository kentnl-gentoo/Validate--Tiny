
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Minimalistic data validation",
  "AUTHOR" => "minimalist <minimal\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Validate-Tiny",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Validate::Tiny",
  "PREREQ_PM" => {
    "Carp" => 0,
    "List::MoreUtils" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.984",
  "test" => {
    "TESTS" => "t/*.t t/checks/*.t t/filters/*.t t/subs/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



