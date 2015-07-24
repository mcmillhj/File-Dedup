[![Build Status](https://travis-ci.org/mcmillhj/File-Dedup.svg?branch=master)](https://travis-ci.org/mcmillhj/file-dedup)
[![Coverage Status](https://coveralls.io/repos/mcmillhj/file-dedup/badge.png?branch=master)](https://coveralls.io/r/mcmillhj/file-dedup?branch=master)
[![Kwalitee status](http://cpants.cpanauthors.org/dist/File-Dedup.png)](http://cpants.charsbar.org/dist/overview/File-Dedup)

# NAME

File::Dedup - Deduplicate files across directories

# VERSION

version 0.002

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

- `_file_md5`

    Private subroutine. Given a filename, computes the MD5 checksum of the contents of the file.

- `_handle_duplicates`

    Private subroutine. Passed a hashref of duplicates files group by MD5 checksum, this subroutine determines which files should be deleted. Some user input is required unless the ask option was set to 0.

- `_purge_files`

    Private subroutine. Passed an arrayref of filenames, deletes these files.

- `_delete_file`

    Private subroutine. Given a filename, deletes the corresponding file using the unlink built-in

- `_prompt`

    Private subroutine. Reads user input from STDIN, encapsulated in a subroutine for testing purposes.

- `_dirwalk`

    Private subroutine. Recursively (if the recursive option is enabled) walks the supplied directory path. Two functions are supplied as input to \_dirwalk: one for files and one for directories. They are applied respectively to each file or directory encountered during the recursive search.

# AUTHOR

Hunter McMillen <mcmillhj@gmail.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Hunter McMillen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
