package File::Dedup;
# ABSTRACT: Deduplicate files across directories

use strict;
use warnings;

use Digest::MD5 qw(md5_hex);
use feature qw(say);

my @VALID_OPTIONS = qw(ask directory group recursive);
sub new {
   my ($class, %opts) = @_;

   die "Must pass a directory to process"
      unless exists $opts{directory};
   die "Supplied directory argument '$opts{directory}' is not a directory"
      unless -d $opts{directory};
   warn "Supplied option 'group' not implemented yet"
      if exists $opts{group} and defined $opts{group};
   
   # do not allow undefined options
   foreach my $opt ( keys %opts ) {
      die "Invalid argument '$opt' passed to new"
         unless grep { $_ eq $opt } @VALID_OPTIONS;
   }
   
   # default to always asking before purging
   $opts{ask} = 1
      unless exists $opts{ask} && defined $opts{ask};
   
   # default to non-recursive
   $opts{recursive} = 0 
      unless exists $opts{recursive} && defined $opts{recursive};
   
   return bless \%opts, $class;
}

sub directory {
   return shift->{directory};
}

sub recursive {
   return shift->{recursive};
}

sub ask {
   return shift->{ask};
}

sub group {
   return shift->{group};
}

sub dedup {
   my ($self) = @_;
   my @results = $self->_dirwalk(
      $self->directory, 
      sub { [ $_[0], _file_md5 $_[0] ] }, 
      sub { shift; @_ } 
   );

   my %files_by_md5sum;
   foreach my $result ( @results ) {
      push @{ $files_by_md5sum{$result->[1]} }, $result->[0];
   }

   my %duplicates_by_md5sum =
      map  { $_ => [ sort @{$files_by_md5sum{$_}} ] }
      grep { @{ $files_by_md5sum{$_} } > 1 } keys %files_by_md5sum;

   my @files_to_purge = $self->_handle_duplicates(\%duplicates_by_md5sum);
   $self->_purge_files(\@files_to_purge);
   
   return;
}

sub _file_md5 {
   my ($filename) = @_;

   open my $fh, '<', $filename
      or die "$!";
   
   my $checksum = Digest::MD5->new->addfile($fh)->hexdigest;
   close($fh);

   return $checksum;
}

sub _handle_duplicates {
   my ($self, $duplicates) = @_;
   return unless keys %$duplicates;

   my @files_to_purge; 
   while ( my ($md5, $files) = each %$duplicates ) {
      my $to_keep; 
      if ( $self->ask ) { 
         say 'The following files are duplicates '
            . " indicate which one(s) you would like to keep\n"
            . '(-1 to SKIP or CTRL-C to quit):';
      
         my $number_of_files = $#{ $files };
         foreach my $i ( 0 .. $number_of_files ) {
            my $file = $files->[$i];
            say "[  $i]\t$file";
         }
         say "[ -1]\tSKIP";
         say "[C-c]\tQUIT";
         $to_keep = _get_numeric_response($number_of_files);
         next if !$to_keep || $to_keep && $to_keep == -1;
      }
      else { # if ask = 0 keep the first duplicate
         $to_keep = 0;
      }
      
      push @files_to_purge, 
         grep { $_ ne $files->[$to_keep] } @$files;
   }

   return sort @files_to_purge;
}

sub _purge_files {
   my ($self, $files) = @_;

   foreach my $file ( @$files ) {
      my $response;
      if ( $self->ask ) { 
         do {
            print "About to delete '$file'; continue? [Y/n] ";
            $response = _prompt();
         }
         while ( !grep { $response eq $_ } ('y', 'Y', '') );
      }

      _delete_file($file)
         if !$self->ask 
         || ($self->ask 
             && ($response eq '' || $response =~ m/^[yY]$/));
   }

   return;
}

sub _delete_file {
   my ($file) = @_;

   unlink($file)
      or die "Unable to delete file '$file': $!";
}

sub _get_numeric_response {
   my ($max) = @_;

   my $input;
   my $valid_response = 0;
   do {
      print "\n>> ";
      $input = _prompt();

      if ( ! defined $input ) {
         say 'You did not enter any input.';
      }
      elsif ( $input !~ m/^\-?\d+$/ ) {
         say "You must enter a number between 0 and $max";
      }
      elsif ( $input && $input > $max ) {
         say "You must enter a number between 0 and $max";
      }
      else {
         $valid_response = 1;
      }
   } while( !$valid_response );

   return $input;
}

sub _prompt {
   my $input = <>;
   chomp($input);

   return $input;
}

sub _dirwalk {
   my ($self, $top, $filefunc, $dirfunc) = @_;

   if ( -d $top ) {
      # stop processing non-recursive searches when a directory that
      # was not the starting directory is encountered
      return 
         if $top ne $self->directory && !$self->recursive;
      
      my $DIR;
      unless ( opendir $DIR, $top ) {
         warn "Couldn't open directory '$top': $!; skipping.\n";
         return;
      }

      my @results;
      while ( my $file = readdir $DIR ) {
         next if $file =~ m/^\./; # ignore hidden files, '.', and '..'
         
         push @results, $self->_dirwalk("$top/$file", $filefunc, $dirfunc);
      }
      return $dirfunc ? $dirfunc->($top, @results) : ();
   }
   
   return $filefunc ? $filefunc->($top) : ();
}

1;

__END__

=pod 

=head1 NAME 

File::Dedup

=head1 DESCRIPTION

A small utility to identify duplicate files in a given directory and optionally delete them

=head1 SYNOPSIS

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

=head1 METHODS

=over 4

=item C<dedup>

Identifies and eliminates duplicate files based on the options supplied by the user. 

=item C<_file_md5>

Private subroutine. Given a filename, computes the MD5 checksum of the contents of the file.

=item C<_handle_duplicates>

Private subroutine. Passed a hashref of duplicates files group by MD5 checksum, this subroutine determines which files should be deleted. Some user input is required unless the ask option was set to 0.

=item C<_purge_files>

Private subroutine. Passed an arrayref of filenames, deletes these files.

=item C<_delete_file>

Private subroutine. Given a filename, deletes the corresponding file using the unlink built-in

=item C<_prompt>

Private subroutine. Reads user input from STDIN, encapsulated in a subroutine for testing purposes.

=item C<_dirwalk>

Private subroutine. Recursively (if the recursive option is enabled) walks the supplied directory path. Two functions are supplied as input to _dirwalk: one for files and one for directories. They are applied respectively to each file or directory encountered during the recursive search.

=back

=cut
