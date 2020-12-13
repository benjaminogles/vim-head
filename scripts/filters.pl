#!/usr/bin/perl

use strict;
use warnings;

my %keywords =
(
  TODO => 1,
  NEXT => 1,
  STARTED => 1,
  WAITING => 1,
  DONE => 1,
  MISSED => 1,
  CANCELLED => 1,
  MEETING => 1
);

my %words = ();
my %plus_tags = ();
my %minus_tags = ();

while (my $word = shift)
{
  if (exists ${keywords}{$word})
  {
    $words{$word} = 1;
  }
  elsif ($word =~ /\+(.*)/)
  {
    $plus_tags{$1} = 1;
  }
  elsif ($word =~ /-(.*)/)
  {
    $minus_tags{$1} = 1;
  }
}

LINE: while (<>)
{
  next unless /^.*\|\*+\s*([^: ]+)?[^:]*(:.*:)?\s*$/;

  my $word = $1;
  next if %words and not $words{$word};

  my @list;
  if (defined $2)
  {
    @list = grep /\S/, split(/:/, $2);
  }

  my %tags = map { $_ => 1 } @list;

  if (%plus_tags)
  {
    my %found = map { $_ => exists $plus_tags{$_} } (keys %tags);
    next unless grep /1/, values %found;
  }

  if (%minus_tags)
  {
    my %found = map { $_ => exists $minus_tags{$_} } (keys %tags);
    next if grep /1/, values %found;
  }

  print;
}

