[![Build Status](https://travis-ci.org/mcmillhj/%{dist}.svg?branch=master)](https://travis-ci.org/mcmillhj/%{dist})
[![Coverage Status](https://coveralls.io/repos/mcmillhj/%{dist}/badge.png?branch=master)](https://coveralls.io/r/mcmillhj/%{dist}?branch=master)
[![Kwalitee status](http://cpants.cpanauthors.org/dist/File-Dedup.png)](http://cpants.charsbar.org/dist/overview/File-Dedup)

# NAME

File::Dedup - Deduplicate files across directories

# VERSION

version 0.003

# SYNOPSIS

    use File::Dedup;
    File::Dedup->new( directory => '/home/hunter/', recursive => 1 )->dedup;

    or 

    use File::Dedup
    my $deduper = File::Dedup->new( 
       directory => '/home/hunter/', 
       recursive => 1, 
       ask       => 0,
    );
    $deduper->dedup;

# DESCRIPTION

A small utility to identify duplicate files in a given directory and optionally delete them

# NAME 

File::Dedup

# ATTRIBUTES 

- `directory`

    Directory to start searching for duplicates in. \[required\]

- `ask`
- `recursive`

    Recursively search the directory tree for duplicates. \[optional\]

- `group`

    \*NOT YET IMPLEMENTED\*. Instead of deleting duplicates this option will write all duplicates into their own subfolders for deletion at the user's leisure.

# METHODS

- `dedup`

    Identifies and eliminates duplicate files based on the options supplied by the user. 

# AUTHOR

Hunter McMillen <mcmillhj@gmail.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Hunter McMillen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
