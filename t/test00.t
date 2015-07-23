#!/usr/bin/env perl

use strict;
use warnings;

use File::Dedup;
File::Dedup->new( directory => '/home/hunter/Dropbox/git/File-Dedup' )->dedup;
File::Dedup->new( directory => '/home/hunter/Dropbox/git/File-Dedup', recursive => 1 )->dedup;
File::Dedup->new( directory => '/home/hunter/Dropbox/git/File-Dedup/lib/File/Dedup.pm' )->dedup;
